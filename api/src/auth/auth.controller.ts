import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import {
  LoginDto,
  RegisterDto,
  RequestOtpDto,
  RefreshTokenDto,
  VerifyOtpDto,
} from './dto/auth.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { ActiveCompanyGuard } from './active-company.guard';
import { CurrentUser } from './current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('otp/request')
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.auth.requestOtp(dto);
  }

  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('otp/verify')
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.auth.verifyOtp(dto);
  }

  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Throttle({ default: { limit: 8, ttl: 60_000 } })
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  @UseGuards(JwtAuthGuard, ActiveCompanyGuard)
  @Get('me')
  me(@CurrentUser() user: { userId: string }) {
    return this.auth.me(user.userId);
  }
}
