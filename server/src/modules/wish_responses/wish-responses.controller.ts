import { Body, Controller, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtUser } from '../auth/jwt.strategy';
import { CreateWishResponseDto } from './dto/create-wish-response.dto';
import { WishResponsesService } from './wish-responses.service';

@ApiTags('wish-responses')
@ApiBearerAuth()
@Controller('wish-responses')
export class WishResponsesController {
  constructor(private readonly wishResponsesService: WishResponsesService) {}

  @Post('wishes/:wishId')
  create(
    @Param('wishId') wishId: string,
    @Body() dto: CreateWishResponseDto,
    @CurrentUser() user: JwtUser,
  ) {
    return this.wishResponsesService.create(user.id, wishId, dto);
  }

  @Patch(':responseId/confirm')
  confirm(@Param('responseId') responseId: string, @CurrentUser() user: JwtUser) {
    return this.wishResponsesService.confirm(user.id, responseId);
  }

  @Patch(':responseId/reopen')
  reopen(@Param('responseId') responseId: string, @CurrentUser() user: JwtUser) {
    return this.wishResponsesService.reopen(user.id, responseId);
  }
}
