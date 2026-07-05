import { Body, Controller, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard';
import { JwtUser } from '../auth/jwt.strategy';
import { CreateWishResponseDto } from './dto/create-wish-response.dto';
import { WishResponsesService } from './wish-responses.service';

@ApiTags('wish-responses')
@ApiBearerAuth()
@UseGuards(OptionalJwtAuthGuard)
@Controller('wish-responses')
export class WishResponsesController {
  constructor(private readonly wishResponsesService: WishResponsesService) {}

  @Post('wishes/:wishId')
  create(
    @Param('wishId') wishId: string,
    @Body() dto: CreateWishResponseDto,
    @CurrentUser() user?: JwtUser | null,
  ) {
    return this.wishResponsesService.create(wishId, dto, user?.id);
  }

  @Patch(':responseId/confirm')
  confirm(@Param('responseId') responseId: string, @CurrentUser() user?: JwtUser | null) {
    return this.wishResponsesService.confirm(responseId, user?.id);
  }

  @Patch(':responseId/reopen')
  reopen(@Param('responseId') responseId: string, @CurrentUser() user?: JwtUser | null) {
    return this.wishResponsesService.reopen(responseId, user?.id);
  }
}
