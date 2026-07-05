import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { OptionalJwtAuthGuard } from '../../common/guards/optional-jwt-auth.guard';
import { JwtUser } from '../auth/jwt.strategy';
import { UpsertDishDto } from './dto/upsert-dish.dto';
import { DishesService } from './dishes.service';

@ApiTags('dishes')
@ApiBearerAuth()
@UseGuards(OptionalJwtAuthGuard)
@Controller('dishes')
export class DishesController {
  constructor(private readonly dishesService: DishesService) {}

  @Get()
  findAll(
    @Query('suitableTimeTag') suitableTimeTag?: string,
    @Query('cookOwner') cookOwner?: string,
    @Query('q') q?: string,
    @Query('difficulty') difficulty?: string,
    @Query('isFavorite') isFavorite?: string,
    @CurrentUser() user?: JwtUser | null,
  ) {
    return this.dishesService.findAll({
      suitableTimeTag,
      cookOwner,
      q,
      difficulty,
      isFavorite: isFavorite === undefined ? undefined : isFavorite === 'true',
      userId: user?.id,
    });
  }

  @Post()
  create(@Body() dto: UpsertDishDto, @CurrentUser() user?: JwtUser | null) {
    return this.dishesService.create(dto, user?.id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: Partial<UpsertDishDto>,
    @CurrentUser() user?: JwtUser | null,
  ) {
    return this.dishesService.update(id, dto, user?.id);
  }
}
