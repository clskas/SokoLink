import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { ProductsService } from './products.service';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';

@Controller('products')
export class ProductsController {
  constructor(private readonly products: ProductsService) {}

  @UseGuards(JwtAuthGuard)
  @Get()
  listMine(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return [];
    return this.products.listMine(user.companyId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('mine')
  mine(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return [];
    return this.products.listMine(user.companyId);
  }

  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.products.getPublic(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(
    @CurrentUser() user: { companyId: string | null },
    @Body() dto: CreateProductDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.products.create(user.companyId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  update(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.products.update(user.companyId, id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  archive(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.products.archive(user.companyId, id);
  }
}
