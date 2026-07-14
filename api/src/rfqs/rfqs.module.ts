import { Module } from '@nestjs/common';
import { RfqsController } from './rfqs.controller';
import { RfqsService } from './rfqs.service';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [RfqsController],
  providers: [RfqsService],
})
export class RfqsModule {}
