import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import appConfig from './config/app.config';
import databaseConfig from './config/database.config';
import redisConfig from './config/redis.config';
import storageConfig from './config/storage.config';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CouplesModule } from './modules/couples/couples.module';
import { WishesModule } from './modules/wishes/wishes.module';
import { WishResponsesModule } from './modules/wish_responses/wish-responses.module';
import { WishFulfillmentsModule } from './modules/wish_fulfillments/wish-fulfillments.module';
import { KitchenStatusModule } from './modules/kitchen_status/kitchen-status.module';
import { DishesModule } from './modules/dishes/dishes.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { UploadModule } from './modules/upload/upload.module';
import { SharedDataModule } from './modules/shared_data/shared-data.module';
import { RewardsModule } from './modules/rewards/rewards.module';
import { SpiritModule } from './modules/spirit/spirit.module';
import { PointsModule } from './modules/points/points.module';
import { CheckinsModule } from './modules/checkins/checkins.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig, redisConfig, storageConfig],
    }),
    SharedDataModule,
    RewardsModule,
    PrismaModule,
    AuthModule,
    UsersModule,
    CouplesModule,
    WishesModule,
    WishResponsesModule,
    WishFulfillmentsModule,
    KitchenStatusModule,
    DishesModule,
    NotificationsModule,
    UploadModule,
    SpiritModule,
    PointsModule,
    CheckinsModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
