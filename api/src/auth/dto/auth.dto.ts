import {
  IsArray,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
  ArrayMinSize,
} from 'class-validator';
import { CompanyRole } from '@prisma/client';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

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
