import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import appConfig from './config/app.config';
import databaseConfig from './config/database.config';
import redisConfig from './config/redis.config';
import storageConfig from './config/storage.config';
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
import { MvpDataModule } from './modules/mvp_data/mvp-data.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig, redisConfig, storageConfig],
    }),
    MvpDataModule,
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
  ],
})
export class AppModule {}
