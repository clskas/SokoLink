import {
  BadRequestException,
  Body,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { IsOptional, IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

class ProRequestDto {
  @IsOptional()
  @IsString()
  note?: string;
}

const uploadRoot = join(process.cwd(), 'uploads');
if (!existsSync(uploadRoot)) mkdirSync(uploadRoot, { recursive: true });

@Controller('billing')
@UseGuards(JwtAuthGuard)
export class BillingController {
  constructor(private readonly prisma: PrismaService) {}

  @Post('pro-request')
  @UseInterceptors(
    FileInterceptor('proof', {
      storage: diskStorage({
        destination: uploadRoot,
        filename: (_req, file, cb) => {
          const unique = `pro-${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `${unique}${extname(file.originalname)}`);
        },
      }),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async requestPro(
    @CurrentUser() user: { companyId: string | null },
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: ProRequestDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    const proofUrl = file ? `/uploads/${file.filename}` : '/uploads/none.png';
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
