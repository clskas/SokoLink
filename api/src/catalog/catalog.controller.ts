import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DRC_PROVINCES } from '../common/constants';

@Controller()
export class CatalogController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('provinces')
  provinces() {
    return DRC_PROVINCES.map((name) => ({ id: name, name }));
  }

  @Get('categories')
  async categories() {
    const cats = await this.prisma.category.findMany({
      orderBy: { nameFr: 'asc' },
    });
    return cats.map((c) => ({
      id: c.id,
      slug: c.slug,
      name: c.nameFr,
      nameFr: c.nameFr,
    }));
  }

  @Get('health')
  health() {
    return { status: 'ok', app: 'SokoLink API', version: '1.0.0' };
  }
}
