import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminWebModule } from './admin-web/admin-web.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    AdminWebModule,
  ],
})
export class AppModule {}
