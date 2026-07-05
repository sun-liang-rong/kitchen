import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { JwtUser } from "../auth/jwt.strategy";
import { UpsertDishDto } from "./dto/upsert-dish.dto";
import { DishesService } from "./dishes.service";

@ApiTags("dishes")
@ApiBearerAuth()
@Controller("dishes")
export class DishesController {
  constructor(private readonly dishesService: DishesService) {}

  @Get()
  findAll(
    @CurrentUser() user: JwtUser,
    @Query("suitableTimeTag") suitableTimeTag?: string,
    @Query("cookOwner") cookOwner?: string,
    @Query("q") q?: string,
    @Query("difficulty") difficulty?: string,
    @Query("isFavorite") isFavorite?: string,
  ) {
    return this.dishesService.findAll({
      suitableTimeTag,
      cookOwner,
      q,
      difficulty,
      isFavorite: isFavorite === undefined ? undefined : isFavorite === "true",
      userId: user.id,
    });
  }

  @Post()
  create(@Body() dto: UpsertDishDto, @CurrentUser() user: JwtUser) {
    return this.dishesService.create(user.id, dto);
  }

  @Patch(":id")
  update(
    @Param("id") id: string,
    @Body() dto: Partial<UpsertDishDto>,
    @CurrentUser() user: JwtUser,
  ) {
    return this.dishesService.update(user.id, id, dto);
  }

  @Delete(":id")
  remove(@Param("id") id: string, @CurrentUser() user: JwtUser) {
    return this.dishesService.remove(user.id, id);
  }
}
