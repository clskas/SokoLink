import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module';
import { CatalogModule } from './catalog/catalog.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProductsModule } from './products/products.module';
import { SearchModule } from './search/search.module';
import { RfqsModule } from './rfqs/rfqs.module';
import { MessagesModule } from './messages/messages.module';
import { CompaniesModule } from './companies/companies.module';
import { AdminModule } from './admin/admin.module';
import { LegalModule } from './legal/legal.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    PrismaModule,
    AuthModule,
    CatalogModule,
    ProductsModule,
    SearchModule,
    RfqsModule,
    MessagesModule,
    CompaniesModule,
    AdminModule,
    LegalModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
