import {
  IsArray,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
  ArrayMinSize,
  Matches,
  Length,
} from 'class-validator';
import { CompanyRole } from '@prisma/client';

export class RegisterDto {
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  password?: string;

  @IsOptional()
  @IsString()
  fullName?: string;

  @IsString()
  @MinLength(2)
  companyName: string;

  @IsString()
  province: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsString()
  phone: string;

  @IsOptional()
  @IsString()
  whatsapp?: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsEnum(CompanyRole, { each: true })
  roles: CompanyRole[];
}

export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}

export class RequestOtpDto {
  @IsString()
  @Matches(/^\+?[0-9]{9,15}$/)
  phone: string;
}

export class VerifyOtpDto {
  @IsString()
  @Matches(/^\+?[0-9]{9,15}$/)
  phone: string;

  @IsString()
  @Length(4, 8)
  code: string;

  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsString()
  companyName?: string;

  @IsOptional()
  @IsString()
  province?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsArray()
  @IsEnum(CompanyRole, { each: true })
  roles?: CompanyRole[];
}

export class RefreshTokenDto {
  @IsString()
  refreshToken: string;
}
