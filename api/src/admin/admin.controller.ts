import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  CompanyRole,
  DocumentStatus,
  PaymentMethod,
  PaymentPurpose,
  PaymentStatus,
  SubscriptionPlan,
} from '@prisma/client';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { BillingService } from '../billing/billing.service';
import { NotificationsService } from '../notifications/notifications.service';

class ReviewDocDto {
  @IsEnum(DocumentStatus)
  status: DocumentStatus;

  @IsOptional()
  @IsString()
  rejectReason?: string;
}

class UpdateRolesDto {
  @IsArray()
  @ArrayMinSize(1)
  @IsEnum(CompanyRole, { each: true })
  roles: CompanyRole[];
}

class RecordPaymentDto {
  @IsString()
  companyId: string;

  @IsEnum(PaymentPurpose)
  purpose: PaymentPurpose;

  @IsNumber()
  amount: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsEnum(PaymentMethod)
  method?: PaymentMethod;

  @IsOptional()
  @IsString()
  provider?: string;

  @IsOptional()
  @IsString()
  reference?: string;

  @IsOptional()
  @IsInt()
  periodMonths?: number;

  @IsOptional()
  @IsInt()
  quantity?: number;

  @IsOptional()
  @IsString()
  productId?: string;

  @IsOptional()
  @IsString()
  note?: string;
}

class UpdateSubscriptionDto {
  @IsOptional()
  @IsInt()
  extendMonths?: number;

  @IsOptional()
  @IsBoolean()
  downgrade?: boolean;

  @IsOptional()
  @IsInt()
  verifyMonths?: number;

  @IsOptional()
  @IsBoolean()
  unverify?: boolean;

  @IsOptional()
  @IsInt()
  leadCredits?: number;
}

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly billing: BillingService,
    private readonly notifications: NotificationsService,
  ) {}

  @Get('stats')
  async stats() {
    const [companies, products, rfqs, pendingDocs, pendingPro, pendingPay] =
      await Promise.all([
        this.prisma.company.count(),
        this.prisma.product.count({ where: { isArchived: false } }),
        this.prisma.rfq.count(),
        this.prisma.document.count({ where: { status: 'IN_REVIEW' } }),
        this.prisma.proRequest.count({ where: { status: 'PENDING' } }),
        this.prisma.payment.count({ where: { status: 'PENDING' } }),
      ]);
    return { companies, products, rfqs, pendingDocs, pendingPro, pendingPay };
  }

  @Get('revenue')
  revenue() {
    return this.billing.revenue();
  }

  @Get('payments')
  payments(@Query('status') status?: string) {
    const valid =
      status && Object.values(PaymentStatus).includes(status as PaymentStatus)
        ? (status as PaymentStatus)
        : undefined;
    return this.billing.listPayments(valid);
  }

  @Post('payments')
  record(
    @CurrentUser() admin: { userId: string },
    @Body() dto: RecordPaymentDto,
  ) {
    return this.billing.recordPayment(dto, admin.userId, true);
  }

  @Post('payments/:id/confirm')
  confirm(
    @Param('id') id: string,
    @CurrentUser() admin: { userId: string },
  ) {
    return this.billing.confirmPayment(id, admin.userId);
  }

  @Post('payments/:id/reject')
  reject(@Param('id') id: string, @CurrentUser() admin: { userId: string }) {
    return this.billing.rejectPayment(id, admin.userId);
  }

  @Post('companies/:id/subscription')
  async subscription(
    @Param('id') id: string,
    @Body() dto: UpdateSubscriptionDto,
  ) {
    const result = await this.billing.updateSubscription(id, dto);
    if (dto.downgrade) {
      await this.notifications.notify(id, {
        type: 'SUBSCRIPTION',
        title: 'Plan rétrogradé',
        body: 'Votre entreprise est repassée au plan Free.',
        link: '/profile',
      });
    } else if (dto.extendMonths && dto.extendMonths > 0) {
      await this.notifications.notify(id, {
        type: 'SUBSCRIPTION',
        title: 'Abonnement PRO prolongé',
        body: `Votre plan PRO a été prolongé de ${dto.extendMonths} mois.`,
        link: '/profile',
      });
    }
    if (dto.verifyMonths && dto.verifyMonths > 0) {
      await this.notifications.notify(id, {
        type: 'SUBSCRIPTION',
        title: 'Badge Vérifié accordé',
        body: 'Votre entreprise affiche désormais le badge Vérifié.',
        link: '/profile',
      });
    }
    if (typeof dto.leadCredits === 'number' && dto.leadCredits > 0) {
      await this.notifications.notify(id, {
        type: 'SUBSCRIPTION',
        title: 'Crédits ajoutés',
        body: `${dto.leadCredits} crédit(s) de mise en relation ont été ajoutés.`,
        link: '/profile',
      });
    }
    return result;
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
  async suspend(
    @Param('id') id: string,
    @Body() body: { suspended?: boolean },
  ) {
    const suspended = body.suspended ?? true;
    const company = await this.prisma.company.update({
      where: { id },
      data: { isSuspended: suspended },
    });
    await this.notifications.notify(id, {
      type: 'SYSTEM',
      title: suspended ? 'Compte suspendu' : 'Compte réactivé',
      body: suspended
        ? 'Votre entreprise a été suspendue. Contactez le support pour plus d’informations.'
        : 'Votre entreprise a été réactivée. Bienvenue à nouveau !',
      link: '/profile',
    });
    return company;
  }

  @Patch('companies/:id/roles')
  setRoles(@Param('id') id: string, @Body() dto: UpdateRolesDto) {
    return this.prisma.company.update({
      where: { id },
      data: { roles: { set: dto.roles } },
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
  async review(@Param('id') id: string, @Body() dto: ReviewDocDto) {
    const doc = await this.prisma.document.update({
      where: { id },
      data: {
        status: dto.status,
        rejectReason:
          dto.status === 'REJECTED' ? dto.rejectReason ?? 'Rejeté' : null,
      },
    });
    const accepted = dto.status === 'ACCEPTED';
    await this.notifications.notify(doc.companyId, {
      type: 'DOCUMENT',
      title: accepted ? 'Document validé' : 'Document rejeté',
      body: accepted
        ? `Votre document ${doc.type} a été validé.`
        : `Votre document ${doc.type} a été rejeté : ${doc.rejectReason ?? 'motif non précisé'}.`,
      link: '/profile',
    });
    return doc;
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
    await this.notifications.notify(req.companyId, {
      type: 'SUBSCRIPTION',
      title: 'Plan PRO activé',
      body: 'Votre passage au plan PRO a été validé. Profitez des fonctions premium !',
      link: '/profile',
    });
    return { ok: true };
  }
}
