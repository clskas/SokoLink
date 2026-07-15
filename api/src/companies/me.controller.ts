import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  NotFoundException,
  Param,
  Patch,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CompanyRole, DocumentType } from '@prisma/client';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ActiveCompanyGuard } from '../auth/active-company.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

class UpdateCompanyDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsString()
  province?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  whatsapp?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  // Rôles métier de l'entreprise (au moins un requis si fourni).
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @IsEnum(CompanyRole, { each: true })
  roles?: CompanyRole[];
}

const uploadRoot = join(process.cwd(), 'uploads');
if (!existsSync(uploadRoot)) mkdirSync(uploadRoot, { recursive: true });

@Controller('me')
@UseGuards(JwtAuthGuard, ActiveCompanyGuard)
export class MeController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('company')
  async company(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.prisma.company.findUnique({
      where: { id: user.companyId },
      include: { documents: true, products: { where: { isArchived: false } } },
    });
  }

  @Patch('company')
  async updateCompany(
    @CurrentUser() user: { companyId: string | null },
    @Body() dto: UpdateCompanyDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    const { roles, ...rest } = dto;
    return this.prisma.company.update({
      where: { id: user.companyId },
      data: {
        ...rest,
        ...(roles ? { roles: { set: roles } } : {}),
      },
    });
  }

  @Post('company/documents')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: uploadRoot,
        filename: (_req, file, cb) => {
          const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `${unique}${extname(file.originalname)}`);
        },
      }),
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        const ok = ['application/pdf', 'image/jpeg', 'image/png'].includes(
          file.mimetype,
        );
        cb(ok ? null : new Error('Type de fichier non autorisé'), ok);
      },
    }),
  )
  async uploadDoc(
    @CurrentUser() user: { companyId: string | null },
    @UploadedFile() file: Express.Multer.File,
    @Body() body: { type?: string },
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    if (!file) throw new BadRequestException('Fichier requis');
    const type = body.type as DocumentType;
    if (!Object.values(DocumentType).includes(type)) {
      throw new BadRequestException('Type de document invalide');
    }
    const fileUrl = `/uploads/${file.filename}`;
    return this.prisma.document.upsert({
      where: { companyId_type: { companyId: user.companyId, type } },
      create: {
        companyId: user.companyId,
        type,
        fileUrl,
        status: 'IN_REVIEW',
      },
      update: {
        fileUrl,
        status: 'IN_REVIEW',
        rejectReason: null,
      },
    });
  }

  @Delete('company/documents/:id')
  async deleteDoc(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    const doc = await this.prisma.document.findUnique({ where: { id } });
    if (!doc) throw new NotFoundException('Document introuvable');
    if (doc.companyId !== user.companyId) throw new ForbiddenException();
    await this.prisma.document.delete({ where: { id } });
    return { ok: true };
  }
}
