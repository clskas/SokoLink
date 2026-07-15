import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { IsOptional, IsString, MinLength } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ActiveCompanyGuard } from '../auth/active-company.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { MessagesService } from './messages.service';

class StartConversationDto {
  @IsOptional()
  @IsString()
  otherCompanyId?: string;

  // Alias accepté par l'app mobile (Contacter depuis une entreprise).
  @IsOptional()
  @IsString()
  companyId?: string;

  @IsOptional()
  @IsString()
  productId?: string;

  @IsOptional()
  @IsString()
  rfqId?: string;

  // Premier message optionnel envoyé à la création de la conversation.
  @IsOptional()
  @IsString()
  message?: string;
}

class PostMessageDto {
  @IsString()
  @MinLength(1)
  body: string;
}

@Controller('conversations')
@UseGuards(JwtAuthGuard, ActiveCompanyGuard)
export class MessagesController {
  constructor(private readonly messages: MessagesService) {}

  @Get()
  list(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return [];
    return this.messages.list(user.companyId);
  }

  @Post()
  start(
    @CurrentUser() user: { companyId: string | null; userId: string },
    @Body() dto: StartConversationDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.messages.start(user.companyId, user.userId, {
      otherCompanyId: dto.otherCompanyId ?? dto.companyId,
      productId: dto.productId,
      rfqId: dto.rfqId,
      message: dto.message,
    });
  }

  @Get(':id')
  get(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.messages.get(user.companyId, id);
  }

  @Post(':id/messages')
  post(
    @CurrentUser() user: { companyId: string | null; userId: string },
    @Param('id') id: string,
    @Body() dto: PostMessageDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.messages.postMessage(user.companyId, user.userId, id, dto.body);
  }
}
