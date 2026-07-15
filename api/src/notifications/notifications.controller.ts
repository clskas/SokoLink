import { Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ActiveCompanyGuard } from '../auth/active-company.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard, ActiveCompanyGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  list(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return [];
    return this.notifications.list(user.companyId);
  }

  @Get('unread-count')
  unread(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return { count: 0 };
    return this.notifications.unreadCount(user.companyId);
  }

  @Patch('read-all')
  readAll(@CurrentUser() user: { companyId: string | null }) {
    if (!user.companyId) return { ok: true };
    return this.notifications.markAllRead(user.companyId);
  }

  @Patch(':id/read')
  read(
    @CurrentUser() user: { companyId: string | null },
    @Param('id') id: string,
  ) {
    if (!user.companyId) return { ok: true };
    return this.notifications.markRead(user.companyId, id);
  }
}
