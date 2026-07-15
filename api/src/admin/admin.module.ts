import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { BillingModule } from '../billing/billing.module';

@Module({
  imports: [BillingModule],
  controllers: [AdminController],
})
export class AdminModule {}
