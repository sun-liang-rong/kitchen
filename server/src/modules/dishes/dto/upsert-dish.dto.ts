import { IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpsertDishDto {
  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  cookOwner?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  suitableTimeTags?: string[];

  @IsOptional()
  @IsString()
  difficulty?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tasteTags?: string[];

  @IsOptional()
  @IsBoolean()
  isFavorite?: boolean;

  @IsOptional()
  @IsString()
  sourceWishId?: string;

  @IsOptional()
  @IsString()
  lastFeedback?: string;
}
