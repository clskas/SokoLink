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
import { RfqsService } from './rfqs.service';
import { CreateRfqDto, RespondRfqDto, UpdateRfqDto } from './dto/rfq.dto';

@Controller('rfqs')
@UseGuards(JwtAuthGuard, ActiveCompanyGuard)
export class RfqsController {
  constructor(private readonly rfqs: RfqsService) {}

  @Get()
  list(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return [];
    return this.rfqs.listForCompany(user.companyId);
  }

  @Get(':id')
  get(@Param('id') id: string) {
    return this.rfqs.get(id);
  }

  @UseGuards(CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.BUYER)
  @Post()
  create(
    @CurrentUser() user: { companyId: string | null },
    @Body() dto: CreateRfqDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.create(user.companyId, dto);
  }

  @UseGuards(CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.SUPPLIER_MP, CompanyRole.PROCESSOR)
  @Post(':id/responses')
  respond(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
    @Body() dto: RespondRfqDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.respond(user.companyId, id, dto);
  }

  @UseGuards(CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.SUPPLIER_MP, CompanyRole.PROCESSOR)
  @Delete(':id/responses')
  withdraw(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.removeResponse(user.companyId, id);
  }

  @UseGuards(CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.BUYER)
  @Patch(':id')
  update(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
    @Body() dto: UpdateRfqDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.edit(user.companyId, id, dto);
  }

  @UseGuards(CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.BUYER)
  @Delete(':id')
  remove(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.remove(user.companyId, id);
  }

  @UseGuards(CompanyRolesGuard)
  @RequireCompanyRoles(CompanyRole.BUYER)
  @Patch(':id/close')
  close(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.close(user.companyId, id);
  }
}
