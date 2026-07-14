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
  @IsString()
  otherCompanyId: string;

  @IsOptional()
  @IsString()
  productId?: string;

  @IsOptional()
  @IsString()
  rfqId?: string;
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
    @CurrentUser() user: { companyId: string | null },
    @Body() dto: StartConversationDto,
  ) {
    if (!user.companyId) throw new BadRequestException('Entreprise requise');
    return this.messages.start(
      user.companyId,
      dto.otherCompanyId,
      dto.productId,
      dto.rfqId,
    );
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
