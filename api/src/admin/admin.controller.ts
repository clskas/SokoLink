import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { DocumentStatus, SubscriptionPlan } from '@prisma/client';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { PrismaService } from '../prisma/prisma.service';

class ReviewDocDto {
  @IsEnum(DocumentStatus)
  status: DocumentStatus;

  @IsOptional()
  @IsString()
  rejectReason?: string;
}

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('stats')
  async stats() {
    const [companies, products, rfqs, pendingDocs, pendingPro] =
      await Promise.all([
        this.prisma.company.count(),
        this.prisma.product.count({ where: { isArchived: false } }),
        this.prisma.rfq.count(),
        this.prisma.document.count({ where: { status: 'IN_REVIEW' } }),
        this.prisma.proRequest.count({ where: { status: 'PENDING' } }),
      ]);
    return { companies, products, rfqs, pendingDocs, pendingPro };
  }

  @Get('companies')
  companies() {
    return this.prisma.company.findMany({
      include: {
        documents: true,
        user: { select: { email: true, fullName: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  @Patch('companies/:id/suspend')
  suspend(@Param('id') id: string, @Body() body: { suspended?: boolean }) {
    return this.prisma.company.update({
      where: { id },
      data: { isSuspended: body.suspended ?? true },
    });
  }

  @Get('documents')
  documents() {
    return this.prisma.document.findMany({
      where: { status: 'IN_REVIEW' },
      include: { company: true },
      orderBy: { createdAt: 'asc' },
    });
  }

  @Patch('documents/:id')
  review(@Param('id') id: string, @Body() dto: ReviewDocDto) {
    return this.prisma.document.update({
      where: { id },
      data: {
        status: dto.status,
        rejectReason:
          dto.status === 'REJECTED' ? dto.rejectReason ?? 'Rejeté' : null,
      },
    });
  }

  @Get('pro-requests')
  proRequests() {
    return this.prisma.proRequest.findMany({
      where: { status: 'PENDING' },
      orderBy: { createdAt: 'asc' },
    });
  }

  @Post('pro-requests/:id/activate')
  async activatePro(@Param('id') id: string) {
    const req = await this.prisma.proRequest.findUniqueOrThrow({
      where: { id },
    });
    await this.prisma.$transaction([
      this.prisma.proRequest.update({
        where: { id },
        data: { status: 'APPROVED' },
      }),
      this.prisma.company.update({
        where: { id: req.companyId },
        data: {
          plan: SubscriptionPlan.PRO,
          planStatus: 'ACTIVE',
        },
      }),
    ]);
    return { ok: true };
  }
}
