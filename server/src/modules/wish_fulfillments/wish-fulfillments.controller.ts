import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtUser } from '../auth/jwt.strategy';
import { CreateWishFulfillmentDto } from './dto/create-wish-fulfillment.dto';
import { WishFulfillmentsService } from './wish-fulfillments.service';

@ApiTags('wish-fulfillments')
@ApiBearerAuth()
@Controller('wish-fulfillments')
export class WishFulfillmentsController {
  constructor(private readonly wishFulfillmentsService: WishFulfillmentsService) {}

  @Get()
  findAll(@CurrentUser() user: JwtUser) {
    return this.wishFulfillmentsService.findAll(user.id);
  }

  @Post('wishes/:wishId')
  create(
    @Param('wishId') wishId: string,
    @Body() dto: CreateWishFulfillmentDto,
    @CurrentUser() user: JwtUser,
  ) {
    return this.wishFulfillmentsService.create(user.id, wishId, dto);
  }
}
