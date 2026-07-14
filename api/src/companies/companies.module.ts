import { Module } from '@nestjs/common';
import { MeController } from './me.controller';
import { BillingController } from '../billing/billing.controller';

@Module({
  controllers: [MeController, BillingController],
})
export class CompaniesModule {}
