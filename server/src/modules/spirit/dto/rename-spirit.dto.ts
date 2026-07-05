import { IsString, MaxLength } from 'class-validator';

export class RenameSpiritDto {
  @IsString()
  @MaxLength(16)
  name!: string;
}
