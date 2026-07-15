import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { PaymentMethod, PaymentPurpose } from '@prisma/client';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { IsOptional, IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ActiveCompanyGuard } from '../auth/active-company.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { BillingService } from './billing.service';
import { PricingPlans } from '../common/pricing';

class ProRequestDto {
  @IsOptional()
  @IsString()
  note?: string;
}

const uploadRoot = join(process.cwd(), 'uploads');
if (!existsSync(uploadRoot)) mkdirSync(uploadRoot, { recursive: true });

const proofStorage = diskStorage({
  destination: uploadRoot,
  filename: (_req, file, cb) => {
    const unique = `pay-${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${extname(file.originalname)}`);
  },
});

function num(v: unknown): number | undefined {
  if (v === undefined || v === null || v === '') return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
}

@Controller('billing')
@UseGuards(JwtAuthGuard, ActiveCompanyGuard)
export class BillingController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly billing: BillingService,
  ) {}

  @Get('plans')
  plans() {
    return this.billing.plans();
  }

  @Get('payments')
  myPayments(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.billing.listForCompany(user.companyId);
  }

  /** Soumission d'un paiement (mobile money + preuve facultative). Reste PENDING. */
  @Post('payments')
  @UseInterceptors(
    FileInterceptor('proof', {
      storage: proofStorage,
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async submitPayment(
    @CurrentUser() user: { companyId: string | null },
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body()
    body: {
      purpose?: string;
      planCode?: string;
      amount?: string;
      currency?: string;
      method?: string;
      provider?: string;
      reference?: string;
      periodMonths?: string;
      quantity?: string;
      productId?: string;
      note?: string;
    },
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');

    const plan = body.planCode
      ? PricingPlans.find((p) => p.code === body.planCode)
      : undefined;

    const purposeStr = body.purpose ?? plan?.purpose;
    if (
      !purposeStr ||
      !Object.values(PaymentPurpose).includes(purposeStr as PaymentPurpose)
    ) {
      throw new BadRequestException('Objet du paiement invalide');
    }
    const purpose = purposeStr as PaymentPurpose;

    const amount = num(body.amount) ?? plan?.amount;
    if (amount === undefined) {
      throw new BadRequestException('Montant requis');
    }

    const methodStr = body.method ?? PaymentMethod.MOBILE_MONEY;
    const method = Object.values(PaymentMethod).includes(
      methodStr as PaymentMethod,
    )
      ? (methodStr as PaymentMethod)
      : PaymentMethod.MOBILE_MONEY;

    return this.billing.createPayment(user.companyId, {
      purpose,
      amount,
      currency: body.currency ?? plan?.currency,
      method,
      provider: body.provider,
      reference: body.reference,
      proofUrl: file ? `/uploads/${file.filename}` : undefined,
      periodMonths: num(body.periodMonths) ?? plan?.periodMonths,
      quantity: num(body.quantity) ?? plan?.quantity,
      productId: body.productId,
      note: body.note,
    });
  }

  /** Legacy : demande de passage PRO (conservée pour compatibilité mobile). */
  @Post('pro-request')
  @UseInterceptors(
    FileInterceptor('proof', {
      storage: proofStorage,
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async requestPro(
    @CurrentUser() user: { companyId: string | null },
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: ProRequestDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    const proofUrl = file ? `/uploads/${file.filename}` : '';
    await this.prisma.company.update({
      where: { id: user.companyId },
      data: { planStatus: 'PENDING' },
    });
    return this.prisma.proRequest.create({
      data: {
        companyId: user.companyId,
        proofUrl,
        note: dto.note,
        status: 'PENDING',
      },
    });
  }
}
