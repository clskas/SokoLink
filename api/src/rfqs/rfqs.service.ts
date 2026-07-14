import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RfqStatus, SubscriptionPlan } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FreePlanLimits, ProPlanLimits } from '../common/plan-limits';
import { CreateRfqDto, RespondRfqDto } from './dto/rfq.dto';

@Injectable()
export class RfqsService {
  constructor(private readonly prisma: PrismaService) {}

  listForCompany(companyId: string) {
    return this.prisma.rfq.findMany({
      where: {
        OR: [
          { issuerCompanyId: companyId },
          { status: RfqStatus.PUBLISHED, isOpen: true },
        ],
      },
      include: {
        category: true,
        issuerCompany: { select: { id: true, name: true, province: true } },
        responses: {
          include: {
            company: { select: { id: true, name: true, province: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
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
    return rfq;
  }

  async create(companyId: string, dto: CreateRfqDto) {
    await this.assertRfqQuota(companyId);
    let categoryId = dto.categoryId;
    if (!categoryId) {
      const first = await this.prisma.category.findFirst();
      if (!first) throw new ForbiddenException('Aucune catégorie');
      categoryId = first.id;
    }
    return this.prisma.rfq.create({
      data: {
        issuerCompanyId: companyId,
        title: dto.title,
        type: dto.type ?? 'FINISHED',
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
      include: { category: true, responses: true },
    });
  }

  async respond(companyId: string, rfqId: string, dto: RespondRfqDto) {
    const rfq = await this.get(rfqId);
    if (rfq.status !== RfqStatus.PUBLISHED || !rfq.isOpen) {
      throw new ForbiddenException('RFQ fermée');
    }
    if (rfq.issuerCompanyId === companyId) {
      throw new ForbiddenException('Vous ne pouvez pas répondre à votre RFQ');
    }
    await this.assertResponseQuota(companyId);

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

  async updateStatus(companyId: string, rfqId: string, status?: string) {
    const rfq = await this.get(rfqId);
    if (rfq.issuerCompanyId !== companyId) throw new ForbiddenException();
    const closed =
      !status ||
      status.toLowerCase() === 'closed' ||
      status.toUpperCase() === 'CLOSED';
    if (closed) {
      return this.prisma.rfq.update({
        where: { id: rfqId },
        data: { status: RfqStatus.CLOSED, isOpen: false },
      });
    }
    return rfq;
  }

  async close(companyId: string, rfqId: string) {
    return this.updateStatus(companyId, rfqId, 'CLOSED');
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
      throw new ForbiddenException('Limite de réponses mensuelle atteinte');
    }
  }
}
