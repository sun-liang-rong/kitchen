import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(24)
  nickname?: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @IsOptional()
  @IsString()
  @IsIn(['MALE', 'FEMALE', 'UNSPECIFIED'])
  gender?: 'MALE' | 'FEMALE' | 'UNSPECIFIED';
}
