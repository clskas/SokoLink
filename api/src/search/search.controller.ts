import { Controller, Get, Param, Query } from '@nestjs/common';
import { ProductType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

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
      ...(province ? { OR: [{ originProvince: province }, { company: { province } }] } : {}),
      ...(q
        ? {
            OR: [
              { name: { contains: q, mode: 'insensitive' as const } },
              { description: { contains: q, mode: 'insensitive' as const } },
              { company: { name: { contains: q, mode: 'insensitive' as const } } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
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

    return { items, total, page: Number(page) || 1 };
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
        roles: true,
        documents: { select: { type: true, status: true } },
        products: {
          where: { isArchived: false },
          include: { category: true },
          take: 50,
        },
      },
    });
    return company;
  }
}
