import { Body, Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtUser } from '../auth/jwt.strategy';
import { WishStatus } from '../shared_data/shared-data.service';
import { CreateWishDto } from './dto/create-wish.dto';
import { WishesService } from './wishes.service';

@ApiTags('wishes')
@ApiBearerAuth()
@Controller('wishes')
export class WishesController {
  constructor(private readonly wishesService: WishesService) {}

  @Get()
  findAll(
    @CurrentUser() user: JwtUser,
    @Query('status') status?: WishStatus,
    @Query('creator') creator?: 'me' | 'partner',
  ) {
    return this.wishesService.findAll(user.id, status, creator);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() user: JwtUser) {
    return this.wishesService.findOne(user.id, id);
  }

  @Post()
  create(@Body() dto: CreateWishDto, @CurrentUser() user: JwtUser) {
    return this.wishesService.create(user.id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user: JwtUser) {
    return this.wishesService.remove(user.id, id);
  }
}
