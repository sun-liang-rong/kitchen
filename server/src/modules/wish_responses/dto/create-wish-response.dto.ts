import { IsArray, IsIn, IsOptional, IsString } from 'class-validator';
import { WishResponseType } from '../../mvp_data/mvp-data.service';

export class CreateWishResponseDto {
  @IsOptional()
  @IsString()
  responderId?: string;

  @IsIn(['FULFILL_TONIGHT', 'LIGHT_VERSION', 'ALTERNATIVE', 'DEFER', 'TOGETHER', 'SHELVE'])
  responseType!: WishResponseType;

  @IsOptional()
  @IsString()
  proposedTitle?: string;

  @IsOptional()
  @IsString()
  proposedTime?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  reasonTags?: string[];

  @IsOptional()
  @IsString()
  reasonText?: string;
}
