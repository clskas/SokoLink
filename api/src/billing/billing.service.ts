import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  PaymentMethod,
  PaymentPurpose,
  PaymentStatus,
  Prisma,
  SubscriptionPlan,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { Pricing, PricingPlans } from '../common/pricing';

export interface CreatePaymentInput {
  purpose: PaymentPurpose;
  amount: number;
  currency?: string;
  method?: PaymentMethod;
  provider?: string;
  reference?: string;
  proofUrl?: string;
  periodMonths?: number;
  quantity?: number;
  productId?: string;
  rfqId?: string;
  note?: string;
}

function addMonths(base: Date, months: number): Date {
  const d = new Date(base);
  d.setMonth(d.getMonth() + months);
  return d;
}

function addDays(base: Date, days: number): Date {
  const d = new Date(base);
  d.setDate(d.getDate() + days);
  return d;
}

function toNumber(amount: Prisma.Decimal | number | null | undefined): number {
  if (amount == null) return 0;
  return typeof amount === 'number' ? amount : Number(amount);
}

@Injectable()
export class BillingService {
  constructor(private readonly prisma: PrismaService) {}

  plans() {
    return { currency: Pricing.currency, plans: PricingPlans };
  }

  /** Une entreprise soumet un paiement (mobile money / preuve) : reste PENDING. */
  async createPayment(companyId: string, input: CreatePaymentInput) {
    if (input.purpose === PaymentPurpose.BOOST && !input.productId) {
      throw new BadRequestException('Produit requis pour un boost');
    }
    const payment = await this.prisma.payment.create({
      data: {
        companyId,
        purpose: input.purpose,
        plan:
          input.purpose === PaymentPurpose.SUBSCRIPTION
            ? SubscriptionPlan.PRO
            : null,
        method: input.method ?? PaymentMethod.MOBILE_MONEY,
        provider: input.provider,
        amount: new Prisma.Decimal(input.amount),
        currency: input.currency ?? Pricing.currency,
        reference: input.reference,
        proofUrl: input.proofUrl,
        periodMonths: input.periodMonths,
        quantity: input.quantity,
        productId: input.productId,
        rfqId: input.rfqId,
        note: input.note,
        status: PaymentStatus.PENDING,
      },
    });
    if (input.purpose === PaymentPurpose.SUBSCRIPTION) {
      await this.prisma.company.update({
        where: { id: companyId },
        data: { planStatus: 'PENDING' },
      });
    }
    return payment;
  }

  listForCompany(companyId: string) {
    return this.prisma.payment.findMany({
      where: { companyId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  listPayments(status?: PaymentStatus) {
    return this.prisma.payment.findMany({
      where: status ? { status } : undefined,
      include: { company: { select: { id: true, name: true, plan: true } } },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  /** Admin : enregistre un paiement (souvent cash / déjà reçu). */
  async recordPayment(
    input: CreatePaymentInput & { companyId: string },
    adminUserId: string,
    autoConfirm = true,
  ) {
    const { companyId, ...rest } = input;
    const payment = await this.createPayment(companyId, rest);
    if (autoConfirm) {
      return this.confirmPayment(payment.id, adminUserId);
    }
    return payment;
  }

  async confirmPayment(id: string, adminUserId: string) {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    if (!payment) throw new NotFoundException('Paiement introuvable');
    if (payment.status === PaymentStatus.CONFIRMED) return payment;

    return this.prisma.$transaction(async (tx) => {
      await this.applyEffect(tx, payment);
      return tx.payment.update({
        where: { id },
        data: {
          status: PaymentStatus.CONFIRMED,
          confirmedAt: new Date(),
          confirmedById: adminUserId,
        },
      });
    });
  }

  async rejectPayment(id: string, adminUserId: string) {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    if (!payment) throw new NotFoundException('Paiement introuvable');
    const updated = await this.prisma.payment.update({
      where: { id },
      data: {
        status: PaymentStatus.REJECTED,
        confirmedAt: new Date(),
        confirmedById: adminUserId,
      },
    });
    if (payment.purpose === PaymentPurpose.SUBSCRIPTION) {
      const company = await this.prisma.company.findUnique({
        where: { id: payment.companyId },
        select: { plan: true },
      });
      if (company && company.plan !== SubscriptionPlan.PRO) {
        await this.prisma.company.update({
          where: { id: payment.companyId },
          data: { planStatus: 'ACTIVE' },
        });
      }
    }
    return updated;
  }

  private async applyEffect(
    tx: Prisma.TransactionClient,
    payment: {
      companyId: string;
      purpose: PaymentPurpose;
      periodMonths: number | null;
      quantity: number | null;
      productId: string | null;
    },
  ) {
    const now = new Date();
    switch (payment.purpose) {
      case PaymentPurpose.SUBSCRIPTION: {
        const months = payment.periodMonths ?? 1;
        const company = await tx.company.findUniqueOrThrow({
          where: { id: payment.companyId },
          select: { planRenewsAt: true },
        });
        const base =
          company.planRenewsAt && company.planRenewsAt > now
            ? company.planRenewsAt
            : now;
        await tx.company.update({
          where: { id: payment.companyId },
          data: {
            plan: SubscriptionPlan.PRO,
            planStatus: 'ACTIVE',
            planRenewsAt: addMonths(base, months),
          },
        });
        break;
      }
      case PaymentPurpose.VERIFICATION: {
        const months = payment.periodMonths ?? Pricing.verificationMonths;
        const company = await tx.company.findUniqueOrThrow({
          where: { id: payment.companyId },
          select: { verifiedUntil: true },
        });
        const base =
          company.verifiedUntil && company.verifiedUntil > now
            ? company.verifiedUntil
            : now;
        await tx.company.update({
          where: { id: payment.companyId },
          data: { isVerified: true, verifiedUntil: addMonths(base, months) },
        });
        break;
      }
      case PaymentPurpose.BOOST: {
        if (!payment.productId) {
          throw new BadRequestException('Produit requis pour un boost');
        }
        const days = payment.quantity ?? Pricing.boostDaysPerUnit;
        const product = await tx.product.findUniqueOrThrow({
          where: { id: payment.productId },
          select: { featuredUntil: true },
        });
        const base =
          product.featuredUntil && product.featuredUntil > now
            ? product.featuredUntil
            : now;
        await tx.product.update({
          where: { id: payment.productId },
          data: { isFeatured: true, featuredUntil: addDays(base, days) },
        });
        break;
      }
      case PaymentPurpose.LEAD: {
        const credits = payment.quantity ?? Pricing.leadPackCredits;
        await tx.company.update({
          where: { id: payment.companyId },
          data: { leadCredits: { increment: credits } },
        });
        break;
      }
    }
  }

  /** Contrôles manuels admin (prolonger, rétrograder, vérifier, créditer). */
  async updateSubscription(
    companyId: string,
    input: {
      extendMonths?: number;
      downgrade?: boolean;
      verifyMonths?: number;
      unverify?: boolean;
      leadCredits?: number;
    },
  ) {
    const now = new Date();
    const company = await this.prisma.company.findUnique({
      where: { id: companyId },
    });
    if (!company) throw new NotFoundException('Entreprise introuvable');

    const data: Prisma.CompanyUpdateInput = {};
    if (input.downgrade) {
      data.plan = SubscriptionPlan.FREE;
      data.planStatus = 'CANCELLED';
      data.planRenewsAt = null;
    } else if (input.extendMonths && input.extendMonths > 0) {
      const base =
        company.planRenewsAt && company.planRenewsAt > now
          ? company.planRenewsAt
          : now;
      data.plan = SubscriptionPlan.PRO;
      data.planStatus = 'ACTIVE';
      data.planRenewsAt = addMonths(base, input.extendMonths);
    }
    if (input.unverify) {
      data.isVerified = false;
      data.verifiedUntil = null;
    } else if (input.verifyMonths && input.verifyMonths > 0) {
      const base =
        company.verifiedUntil && company.verifiedUntil > now
          ? company.verifiedUntil
          : now;
      data.isVerified = true;
      data.verifiedUntil = addMonths(base, input.verifyMonths);
    }
    if (typeof input.leadCredits === 'number' && input.leadCredits !== 0) {
      data.leadCredits = { increment: input.leadCredits };
    }
    return this.prisma.company.update({ where: { id: companyId }, data });
  }

  /** Repasse les abonnements/boosts/vérifs échus à l'état inactif. */
  async applyExpirations() {
    const now = new Date();
    await this.prisma.$transaction([
      this.prisma.company.updateMany({
        where: {
          plan: SubscriptionPlan.PRO,
          planRenewsAt: { lt: now },
        },
        data: { plan: SubscriptionPlan.FREE, planStatus: 'EXPIRED' },
      }),
      this.prisma.company.updateMany({
        where: { isVerified: true, verifiedUntil: { lt: now } },
        data: { isVerified: false },
      }),
      this.prisma.product.updateMany({
        where: { isFeatured: true, featuredUntil: { lt: now } },
        data: { isFeatured: false },
      }),
    ]);
  }

  async revenue() {
    await this.applyExpirations();
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [confirmed, activePro, expiringSoon, pendingCount, verifiedCount] =
      await Promise.all([
        this.prisma.payment.findMany({
          where: { status: PaymentStatus.CONFIRMED },
          select: {
            amount: true,
            currency: true,
            purpose: true,
            confirmedAt: true,
          },
        }),
        this.prisma.company.count({
          where: { plan: SubscriptionPlan.PRO, planStatus: 'ACTIVE' },
        }),
        this.prisma.company.count({
          where: {
            plan: SubscriptionPlan.PRO,
            planRenewsAt: {
              gte: now,
              lte: addDays(now, 7),
            },
          },
        }),
        this.prisma.payment.count({ where: { status: PaymentStatus.PENDING } }),
        this.prisma.company.count({ where: { isVerified: true } }),
      ]);

    let total = 0;
    let month = 0;
    const byPurpose: Record<string, number> = {
      SUBSCRIPTION: 0,
      BOOST: 0,
      VERIFICATION: 0,
      LEAD: 0,
    };
    for (const p of confirmed) {
      const amt = toNumber(p.amount);
      total += amt;
      byPurpose[p.purpose] = (byPurpose[p.purpose] ?? 0) + amt;
      if (p.confirmedAt && p.confirmedAt >= monthStart) month += amt;
    }
    const mrr = activePro * Pricing.proMonthly;

    return {
      currency: Pricing.currency,
      total,
      month,
      mrr,
      activePro,
      verifiedCount,
      expiringSoon,
      pendingCount,
      byPurpose,
      transactions: confirmed.length,
    };
  }
}
