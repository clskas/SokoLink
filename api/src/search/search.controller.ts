import { Controller, Get, NotFoundException, Param, Query } from '@nestjs/common';
import { ProductType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

function mapCategory(category: { id: string; slug: string; nameFr: string } | null) {
  if (!category) return null;
  return { ...category, name: category.nameFr };
}

function mapProduct<T extends {
  indicativePrice: unknown;
  category?: { id: string; slug: string; nameFr: string } | null;
}>(product: T) {
  return {
    ...product,
    price: product.indicativePrice,
    category: mapCategory(product.category ?? null),
  };
}

@Controller()
export class SearchController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('search')
  async search(
    @Query('intent') intent?: string,
    @Query('q') q?: string,
    @Query('province') province?: string,
    @Query('categoryId') categoryId?: string,
    @Query('page') page = '1',
  ) {
    const take = 20;
    const skip = (Math.max(parseInt(page, 10) || 1, 1) - 1) * take;
    const type: ProductType | undefined =
      intent === 'finished'
        ? ProductType.FINISHED
        : intent === 'mp'
          ? ProductType.MP
          : undefined;

    const where = {
      isArchived: false,
      company: { isSuspended: false },
      ...(type ? { type } : {}),
      ...(categoryId ? { categoryId } : {}),
      ...(province
        ? {
            OR: [
              { originProvince: province },
              { company: { province } },
            ],
          }
        : {}),
      ...(q
        ? {
            OR: [
              { name: { contains: q, mode: 'insensitive' as const } },
              { description: { contains: q, mode: 'insensitive' as const } },
              {
                company: {
                  name: { contains: q, mode: 'insensitive' as const },
                },
              },
            ],
          }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        include: {
          category: true,
          company: {
            select: {
              id: true,
              name: true,
              province: true,
              city: true,
              plan: true,
              isVerified: true,
              documents: { select: { type: true, status: true } },
            },
          },
        },
        orderBy: [{ isFeatured: 'desc' }, { updatedAt: 'desc' }],
        skip,
        take,
      }),
      this.prisma.product.count({ where }),
    ]);

    const items = rows.map((row) => {
      const mapped = mapProduct(row);
      const docsOk = row.company.documents.some((d) => d.status === 'ACCEPTED');
      return {
        ...mapped,
        province: row.originProvince ?? row.company.province,
        docsVerified: docsOk,
        isPro: row.company.plan === 'PRO',
        isVerified: row.company.isVerified,
      };
    });

    return { items, total, page: Number(page) || 1, take };
  }

  @Get('companies')
  async companies(@Query('q') q?: string) {
    return this.prisma.company.findMany({
      where: {
        isSuspended: false,
        ...(q
          ? { name: { contains: q, mode: 'insensitive' as const } }
          : {}),
      },
      select: {
        id: true,
        name: true,
        province: true,
        roles: true,
        plan: true,
        isVerified: true,
      },
      orderBy: { name: 'asc' },
      take: 50,
    });
  }

  @Get('companies/:id')
  async company(@Param('id') id: string) {
    const company = await this.prisma.company.findFirst({
      where: { id, isSuspended: false },
      select: {
        id: true,
        name: true,
        description: true,
        province: true,
        city: true,
        phone: true,
        whatsapp: true,
        email: true,
        plan: true,
        isVerified: true,
        roles: true,
        documents: { select: { type: true, status: true } },
        products: {
          where: { isArchived: false },
          include: { category: true },
          take: 50,
          orderBy: { updatedAt: 'desc' },
        },
      },
    });
    if (!company) throw new NotFoundException('Entreprise introuvable');
    return {
      ...company,
      products: company.products.map(mapProduct),
      docsVerified: company.documents.some((d) => d.status === 'ACCEPTED'),
    };
  }
}
