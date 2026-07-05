import { IsString } from 'class-validator';

export class ApplyByCodeDto {
  @IsString()
  code!: string;
}
