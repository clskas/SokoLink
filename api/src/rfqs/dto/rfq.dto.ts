import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { ProductType } from '@prisma/client';

export class CreateRfqDto {
  @IsString()
  @MinLength(3)
  title: string;

  @IsOptional()
  @IsEnum(ProductType)
  type?: ProductType;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  quantity?: string;

  @IsOptional()
  @IsString()
  unit?: string;

  @IsOptional()
  @IsString()
  budgetHint?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetProvinces?: string[];

  @IsOptional()
  @IsString()
  deadline?: string;

  @IsOptional()
  @IsString()
  details?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsBoolean()
  isOpen?: boolean;
}

export class RespondRfqDto {
  @IsOptional()
  @IsString()
  price?: string;

  @IsOptional()
  @IsString()
  leadTime?: string;

  @IsOptional()
  @IsString()
  comment?: string;

  @IsOptional()
  @IsString()
  message?: string;
}

export class UpdateRfqDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  dealStatus?: string;
}
