import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard';
import { JwtUser } from '../auth/jwt.strategy';
import { CreateWishFulfillmentDto } from './dto/create-wish-fulfillment.dto';
import { WishFulfillmentsService } from './wish-fulfillments.service';

@ApiTags('wish-fulfillments')
@ApiBearerAuth()
@UseGuards(OptionalJwtAuthGuard)
@Controller('wish-fulfillments')
export class WishFulfillmentsController {
  constructor(private readonly wishFulfillmentsService: WishFulfillmentsService) {}

  @Get()
  findAll(@CurrentUser() user?: JwtUser | null) {
    return this.wishFulfillmentsService.findAll(user?.id);
  }

  @Post('wishes/:wishId')
  create(
    @Param('wishId') wishId: string,
    @Body() dto: CreateWishFulfillmentDto,
    @CurrentUser() user?: JwtUser | null,
  ) {
    return this.wishFulfillmentsService.create(wishId, dto, user?.id);
  }
}
