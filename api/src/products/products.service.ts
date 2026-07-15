import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ProductType, SubscriptionPlan } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FreePlanLimits, ProPlanLimits } from '../common/plan-limits';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async listMine(companyId: string) {
    const products = await this.prisma.product.findMany({
      where: { companyId, isArchived: false },
      include: { category: true },
      orderBy: { updatedAt: 'desc' },
    });
    return products.map((p) => ({
      ...p,
      price: p.indicativePrice,
      category: p.category
        ? { ...p.category, name: p.category.nameFr }
        : null,
    }));
  }

  async create(companyId: string, dto: CreateProductDto) {
    await this.assertProductQuota(companyId);
    await this.assertProductTypeAllowed(companyId, dto.type ?? ProductType.FINISHED);
    let categoryId = dto.categoryId;
    if (!categoryId) {
      const first = await this.prisma.category.findFirst();
      if (!first) throw new BadRequestException('Aucune catégorie');
      categoryId = first.id;
    } else {
      const category = await this.prisma.category.findUnique({
        where: { id: categoryId },
      });
      if (!category) throw new BadRequestException('Catégorie invalide');
    }

    const price =
      dto.indicativePrice ??
      (dto.price != null ? String(dto.price) : undefined);

    return this.prisma.product.create({
      data: {
        companyId,
        categoryId,
        type: dto.type ?? ProductType.FINISHED,
        name: dto.name,
        description: dto.description ?? dto.name,
        unit: dto.unit ?? 'u',
        indicativePrice: price,
        currency: dto.currency ?? 'CDF',
        moq: dto.moq,
        capacityPerMonth: dto.capacityPerMonth,
        originProvince: dto.originProvince,
      },
      include: { category: true },
    });
  }

  async update(companyId: string, id: string, dto: UpdateProductDto) {
    const product = await this.getOwned(companyId, id);
    if (dto.type) {
      await this.assertProductTypeAllowed(companyId, dto.type);
    }
    if (dto.categoryId) {
      const category = await this.prisma.category.findUnique({
        where: { id: dto.categoryId },
      });
      if (!category) throw new BadRequestException('Catégorie invalide');
    }
    const price =
      dto.indicativePrice ??
      (dto.price != null ? String(dto.price) : undefined);
    return this.prisma.product.update({
      where: { id: product.id },
      data: {
        ...(dto.type ? { type: dto.type } : {}),
        ...(dto.categoryId ? { categoryId: dto.categoryId } : {}),
        name: dto.name,
        description: dto.description,
        unit: dto.unit,
        ...(price !== undefined ? { indicativePrice: price } : {}),
        currency: dto.currency,
        moq: dto.moq,
        capacityPerMonth: dto.capacityPerMonth,
        originProvince: dto.originProvince,
        isArchived: dto.isArchived,
      },
      include: { category: true },
    });
  }

  async archive(companyId: string, id: string) {
    return this.update(companyId, id, { isArchived: true });
  }

  async getPublic(id: string) {
    const product = await this.prisma.product.findFirst({
      where: { id, isArchived: false, company: { isSuspended: false } },
      include: {
        category: true,
        company: {
          select: {
            id: true,
            name: true,
            province: true,
            city: true,
            phone: true,
            whatsapp: true,
            plan: true,
            roles: true,
            documents: { select: { type: true, status: true } },
          },
        },
      },
    });
    if (!product) throw new NotFoundException('Produit introuvable');
    return product;
  }

  private async getOwned(companyId: string, id: string) {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product || product.companyId !== companyId) {
      throw new ForbiddenException();
    }
    return product;
  }

  private async assertProductTypeAllowed(
    companyId: string,
    type: ProductType,
  ) {
    const company = await this.prisma.company.findUniqueOrThrow({
      where: { id: companyId },
      select: { roles: true },
    });
    if (type === ProductType.MP && !company.roles.includes('SUPPLIER_MP')) {
      throw new ForbiddenException(
        'Seuls les fournisseurs de matières premières peuvent publier des MP.',
      );
    }
    if (
      type === ProductType.FINISHED &&
      !company.roles.includes('PROCESSOR')
    ) {
      throw new ForbiddenException(
        'Seuls les transformateurs peuvent publier des produits finis.',
      );
    }
  }

  private async assertProductQuota(companyId: string) {
    const company = await this.prisma.company.findUniqueOrThrow({
      where: { id: companyId },
    });
    const limit =
      company.plan === SubscriptionPlan.PRO
        ? ProPlanLimits.maxProducts
        : FreePlanLimits.maxProducts;
    const count = await this.prisma.product.count({
      where: { companyId, isArchived: false },
    });
    if (count >= limit) {
      throw new ForbiddenException(
        `Limite Free atteinte (${limit} produits). Passez en Pro.`,
      );
    }
  }
}
