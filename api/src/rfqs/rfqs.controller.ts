import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { RfqsService } from './rfqs.service';
import { CreateRfqDto, RespondRfqDto, UpdateRfqDto } from './dto/rfq.dto';

@Controller('rfqs')
@UseGuards(JwtAuthGuard)
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

  @Post()
  create(
    @CurrentUser() user: { companyId: string | null },
    @Body() dto: CreateRfqDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.create(user.companyId, dto);
  }

  @Post(':id/responses')
  respond(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
    @Body() dto: RespondRfqDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.respond(user.companyId, id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
    @Body() dto: UpdateRfqDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.updateStatus(user.companyId, id, dto.status);
  }

  @Patch(':id/close')
  close(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.rfqs.close(user.companyId, id);
  }
}
