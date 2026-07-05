import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard';
import { JwtUser } from '../auth/jwt.strategy';
import { WishStatus } from '../mvp_data/mvp-data.service';
import { CreateWishDto } from './dto/create-wish.dto';
import { WishesService } from './wishes.service';

@ApiTags('wishes')
@ApiBearerAuth()
@UseGuards(OptionalJwtAuthGuard)
@Controller('wishes')
export class WishesController {
  constructor(private readonly wishesService: WishesService) {}

  @Get()
  findAll(
    @Query('status') status?: WishStatus,
    @Query('creator') creator?: 'me' | 'partner',
    @CurrentUser() user?: JwtUser | null,
  ) {
    return this.wishesService.findAll(status, user?.id, creator);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() user?: JwtUser | null) {
    return this.wishesService.findOne(id, user?.id);
  }

  @Post()
  create(@Body() dto: CreateWishDto, @CurrentUser() user?: JwtUser | null) {
    return this.wishesService.create(dto, user?.id);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user?: JwtUser | null) {
    return this.wishesService.remove(id, user?.id);
  }
}
