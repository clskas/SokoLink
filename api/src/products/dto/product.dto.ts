import {
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
  IsNumber,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ProductType } from '@prisma/client';

export class CreateProductDto {
  @IsOptional()
  @IsEnum(ProductType)
  type?: ProductType;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsString()
  @MinLength(2)
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  unit?: string;

  @IsOptional()
  @Transform(({ value, obj }) =>
    value ?? (obj.price != null ? String(obj.price) : undefined),
  )
  @IsString()
  indicativePrice?: string;

  @IsOptional()
  @IsNumber()
  price?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  moq?: string;

  @IsOptional()
  @IsString()
  capacityPerMonth?: string;

  @IsOptional()
  @IsString()
  originProvince?: string;
}

export class UpdateProductDto {
  @IsOptional()
  @IsEnum(ProductType)
  type?: ProductType;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  unit?: string;

  @IsOptional()
  @Transform(({ value, obj }) =>
    value ?? (obj.price != null ? String(obj.price) : undefined),
  )
  @IsString()
  indicativePrice?: string;

  @IsOptional()
  @IsNumber()
  price?: number;

  @IsOptional()
  @IsString()
  moq?: string;

  @IsOptional()
  @IsString()
  capacityPerMonth?: string;

  @IsOptional()
  @IsString()
  originProvince?: string;

  @IsOptional()
  isArchived?: boolean;
}
