import { IsArray, IsIn, IsOptional, IsString } from 'class-validator';

export class CreateWishDto {
  @IsOptional()
  @IsString()
  creatorId?: string;

  @IsString()
  title!: string;

  @IsOptional()
  @IsIn(['DISH', 'FEELING'])
  wishType?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  feelingTags?: string[];

  @IsOptional()
  @IsString()
  desiredTime?: string;

  @IsOptional()
  @IsString()
  intensity?: string;

  @IsOptional()
  @IsString()
  substituteOption?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  helperTasks?: string[];
}
