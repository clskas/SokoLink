import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, RfqStatus, SubscriptionPlan } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FreePlanLimits, ProPlanLimits } from '../common/plan-limits';
import { CreateRfqDto, RespondRfqDto, UpdateRfqDto } from './dto/rfq.dto';

/** Ajoute les alias attendus par l'app mobile (description, message). */
function mapRfq<
  T extends {
    details?: string;
    responses?: Array<{ comment: string | null }>;
  },
>(rfq: T) {
  return {
    ...rfq,
    description: rfq.details,
    responses: rfq.responses?.map((r) => ({ ...r, message: r.comment })),
  };
}

@Injectable()
export class RfqsService {
  constructor(private readonly prisma: PrismaService) {}

  private readonly rfqInclude = {
    category: true,
    issuerCompany: { select: { id: true, name: true, province: true } },
    responses: {
      include: {
        company: { select: { id: true, name: true, province: true } },
      },
    },
  } satisfies Prisma.RfqInclude;

  async listForCompany(companyId: string) {
    const rows = await this.prisma.rfq.findMany({
      where: {
        OR: [
          { issuerCompanyId: companyId },
          { status: RfqStatus.PUBLISHED, isOpen: true },
        ],
      },
      include: this.rfqInclude,
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return rows.map(mapRfq);
  }

  async get(id: string) {
    const rfq = await this.prisma.rfq.findUnique({
      where: { id },
      include: {
        category: true,
        issuerCompany: {
          select: { id: true, name: true, province: true, phone: true },
        },
        responses: {
          include: {
            company: { select: { id: true, name: true, province: true } },
          },
        },
      },
    });
    if (!rfq) throw new NotFoundException();
    return mapRfq(rfq);
  }

  async create(companyId: string, dto: CreateRfqDto) {
    await this.assertRfqQuota(companyId);
    let categoryId = dto.categoryId;
    let type = dto.type;
    // Si la RFQ est lancée depuis une fiche produit, on hérite catégorie/type.
    if (dto.productId) {
      const product = await this.prisma.product.findUnique({
        where: { id: dto.productId },
        select: { categoryId: true, type: true },
      });
      if (product) {
        categoryId ??= product.categoryId;
        type ??= product.type;
      }
    }
    if (!categoryId) {
      const first = await this.prisma.category.findFirst();
      if (!first) throw new ForbiddenException('Aucune catégorie');
      categoryId = first.id;
    }
    const rfq = await this.prisma.rfq.create({
      data: {
        issuerCompanyId: companyId,
        title: dto.title,
        type: type ?? 'FINISHED',
        categoryId,
        quantity: dto.quantity ?? '1',
        unit: dto.unit ?? 'u',
        budgetHint: dto.budgetHint,
        targetProvinces: dto.targetProvinces ?? [],
        deadline: dto.deadline ? new Date(dto.deadline) : undefined,
        details: dto.details ?? dto.description ?? dto.title,
        status: RfqStatus.PUBLISHED,
        isOpen: dto.isOpen ?? true,
      },
      include: this.rfqInclude,
    });
    return mapRfq(rfq);
  }

  async respond(companyId: string, rfqId: string, dto: RespondRfqDto) {
    const rfq = await this.get(rfqId);
    if (rfq.status !== RfqStatus.PUBLISHED || !rfq.isOpen) {
      throw new ForbiddenException('RFQ fermée');
    }
    if (rfq.issuerCompanyId === companyId) {
      throw new ForbiddenException('Vous ne pouvez pas répondre à votre RFQ');
    }
    // Le quota ne s'applique qu'à une NOUVELLE réponse (pas à une mise à jour).
    const existing = await this.prisma.rfqResponse.findUnique({
      where: { rfqId_companyId: { rfqId, companyId } },
    });
    if (!existing) {
      await this.assertResponseQuota(companyId);
    }

    return this.prisma.rfqResponse.upsert({
      where: { rfqId_companyId: { rfqId, companyId } },
      create: {
        rfqId,
        companyId,
        price: dto.price ?? 'À négocier',
        leadTime: dto.leadTime ?? 'À préciser',
        comment: dto.comment ?? dto.message,
      },
      update: {
        price: dto.price ?? 'À négocier',
        leadTime: dto.leadTime ?? 'À préciser',
        comment: dto.comment ?? dto.message,
      },
    });
  }

  /** Retire la réponse de l'entreprise à une RFQ. */
  async removeResponse(companyId: string, rfqId: string) {
    const existing = await this.prisma.rfqResponse.findUnique({
      where: { rfqId_companyId: { rfqId, companyId } },
    });
    if (!existing) throw new NotFoundException('Aucune réponse à retirer');
    await this.prisma.rfqResponse.delete({
      where: { rfqId_companyId: { rfqId, companyId } },
    });
    return { ok: true };
  }

  /** Édition d'une RFQ par son émetteur (champs + statut). */
  async edit(companyId: string, rfqId: string, dto: UpdateRfqDto) {
    const rfq = await this.prisma.rfq.findUnique({ where: { id: rfqId } });
    if (!rfq) throw new NotFoundException();
    if (rfq.issuerCompanyId !== companyId) throw new ForbiddenException();

    const wantsClose =
      dto.status != null &&
      ['closed', 'CLOSED'].includes(dto.status);

    const updated = await this.prisma.rfq.update({
      where: { id: rfqId },
      data: {
        title: dto.title,
        quantity: dto.quantity,
        unit: dto.unit,
        budgetHint: dto.budgetHint,
        details: dto.details ?? dto.description,
        targetProvinces: dto.targetProvinces,
        deadline: dto.deadline ? new Date(dto.deadline) : undefined,
        ...(wantsClose
          ? { status: RfqStatus.CLOSED, isOpen: false }
          : {}),
      },
      include: this.rfqInclude,
    });
    return mapRfq(updated);
  }

  async remove(companyId: string, rfqId: string) {
    const rfq = await this.prisma.rfq.findUnique({ where: { id: rfqId } });
    if (!rfq) throw new NotFoundException();
    if (rfq.issuerCompanyId !== companyId) throw new ForbiddenException();
    await this.prisma.rfq.delete({ where: { id: rfqId } });
    return { ok: true };
  }

  async close(companyId: string, rfqId: string) {
    return this.edit(companyId, rfqId, { status: 'CLOSED' });
  }

  private async assertRfqQuota(companyId: string) {
    const company = await this.prisma.company.findUniqueOrThrow({
      where: { id: companyId },
    });
    const limit =
      company.plan === SubscriptionPlan.PRO
        ? ProPlanLimits.maxRfqsPerMonth
        : FreePlanLimits.maxRfqsPerMonth;
    const start = new Date();
    start.setDate(1);
    start.setHours(0, 0, 0, 0);
    const count = await this.prisma.rfq.count({
      where: { issuerCompanyId: companyId, createdAt: { gte: start } },
    });
    if (count >= limit) {
      throw new ForbiddenException('Limite de RFQ mensuelle atteinte');
    }
  }

  private async assertResponseQuota(companyId: string) {
    const company = await this.prisma.company.findUniqueOrThrow({
      where: { id: companyId },
    });
    const limit =
      company.plan === SubscriptionPlan.PRO
        ? ProPlanLimits.maxResponsesPerMonth
        : FreePlanLimits.maxResponsesPerMonth;
    const start = new Date();
    start.setDate(1);
    start.setHours(0, 0, 0, 0);
    const count = await this.prisma.rfqResponse.count({
      where: { companyId, createdAt: { gte: start } },
    });
    if (count >= limit) {
      // Au-delà du quota, on consomme un crédit de mise en relation si disponible.
      if (company.leadCredits > 0) {
        await this.prisma.company.update({
          where: { id: companyId },
          data: { leadCredits: { decrement: 1 } },
        });
        return;
      }
      throw new ForbiddenException(
        'Quota de réponses atteint. Achetez un pack de mise en relation ou passez au plan PRO.',
      );
    }
  }
}
