import { Module } from '@nestjs/common';
import { MeController } from './me.controller';
import { BillingController } from '../billing/billing.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [MeController, BillingController],
})
export class CompaniesModule {}
