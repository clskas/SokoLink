import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { BillingModule } from '../billing/billing.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [BillingModule, NotificationsModule],
  controllers: [AdminController],
})
export class AdminModule {}
