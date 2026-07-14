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
import { CompanyRole } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ActiveCompanyGuard } from '../auth/active-company.guard';
import { CompanyRolesGuard } from '../auth/company-roles.guard';
import { RequireCompanyRoles } from '../auth/company-roles.decorator';
import { CurrentUser } from '../auth/current-user.decorator';
import { ProductsService } from './products.service';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';

@Controller('products')
export class ProductsController {
  constructor(private readonly products: ProductsService) {}

  @UseGuards(JwtAuthGuard, ActiveCompanyGuard)
  @Get()
  listMine(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return [];
    return this.products.listMine(user.companyId);
  }

  @UseGuards(JwtAuthGuard, ActiveCompanyGuard)
  @Get('mine')
  mine(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return [];
    return this.products.listMine(user.companyId);
  }

  @Get(':id')
  getOne(@Param('id') id: string) {
    return this.products.getPublic(id);
  }

  @UseGuards(JwtAuthGuard, ActiveCompanyGuard, CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.SUPPLIER_MP, CompanyRole.PROCESSOR)
  @Post()
  create(
    @CurrentUser() user: { companyId: string | null },
    @Body() dto: CreateProductDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.products.create(user.companyId, dto);
  }

  @UseGuards(JwtAuthGuard, ActiveCompanyGuard, CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.SUPPLIER_MP, CompanyRole.PROCESSOR)
  @Patch(':id')
  update(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.products.update(user.companyId, id, dto);
  }

  @UseGuards(JwtAuthGuard, ActiveCompanyGuard, CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.SUPPLIER_MP, CompanyRole.PROCESSOR)
  @Delete(':id')
  archive(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.products.archive(user.companyId, id);
  }
}
