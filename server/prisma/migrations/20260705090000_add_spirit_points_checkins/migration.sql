-- CreateEnum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SpiritStage') THEN
    CREATE TYPE "SpiritStage" AS ENUM ('BABY', 'GROWING', 'INTIMATE');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SpiritMood') THEN
    CREATE TYPE "SpiritMood" AS ENUM ('NORMAL', 'HAPPY', 'HUNGRY', 'EXCITED');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SpiritStyle') THEN
    CREATE TYPE "SpiritStyle" AS ENUM ('FLAME', 'SHADOW', 'CELESTIAL');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'FeedType') THEN
    CREATE TYPE "FeedType" AS ENUM ('NORMAL', 'DELICATE', 'FEAST');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'PointTransactionType') THEN
    CREATE TYPE "PointTransactionType" AS ENUM ('EARN', 'SPEND');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'PointReason') THEN
    CREATE TYPE "PointReason" AS ENUM (
      'CHECKIN',
      'CREATE_WISH',
      'RESPOND_WISH',
      'CONFIRM_RESPONSE',
      'FULFILL_WISH',
      'ADD_DISH',
      'FEED_SPIRIT'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SpiritLogType') THEN
    CREATE TYPE "SpiritLogType" AS ENUM (
      'CHECKIN',
      'FEED',
      'LEVEL_UP',
      'STAGE_CHANGED',
      'WISH_FULFILLED'
    );
  END IF;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "couple_spirits" (
  "id" TEXT NOT NULL,
  "couple_id" TEXT NOT NULL,
  "name" TEXT NOT NULL DEFAULT '饭团精灵',
  "level" INTEGER NOT NULL DEFAULT 1,
  "exp" INTEGER NOT NULL DEFAULT 0,
  "stage" "SpiritStage" NOT NULL DEFAULT 'BABY',
  "mood" "SpiritMood" NOT NULL DEFAULT 'NORMAL',
  "style" "SpiritStyle" NOT NULL DEFAULT 'FLAME',
  "appearance" TEXT NOT NULL DEFAULT 'spirit_baby',
  "last_fed_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "couple_spirits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "point_accounts" (
  "id" TEXT NOT NULL,
  "couple_id" TEXT NOT NULL,
  "balance" INTEGER NOT NULL DEFAULT 0,
  "total_earned" INTEGER NOT NULL DEFAULT 0,
  "total_spent" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "point_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "point_transactions" (
  "id" TEXT NOT NULL,
  "couple_id" TEXT NOT NULL,
  "user_id" TEXT,
  "type" "PointTransactionType" NOT NULL,
  "amount" INTEGER NOT NULL,
  "balance_after" INTEGER NOT NULL DEFAULT 0,
  "reason" "PointReason" NOT NULL,
  "related_type" TEXT,
  "related_id" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "point_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "checkins" (
  "id" TEXT NOT NULL,
  "user_id" TEXT NOT NULL,
  "couple_id" TEXT NOT NULL,
  "checkin_date" TIMESTAMP(3) NOT NULL,
  "points_earned" INTEGER NOT NULL,
  "streak_days" INTEGER NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "checkins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "spirit_growth_logs" (
  "id" TEXT NOT NULL,
  "couple_id" TEXT NOT NULL,
  "user_id" TEXT,
  "type" "SpiritLogType" NOT NULL,
  "content" TEXT NOT NULL,
  "metadata" JSONB,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "spirit_growth_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "couple_spirits_couple_id_key" ON "couple_spirits"("couple_id");
CREATE UNIQUE INDEX IF NOT EXISTS "point_accounts_couple_id_key" ON "point_accounts"("couple_id");
CREATE UNIQUE INDEX IF NOT EXISTS "point_transactions_couple_id_user_id_reason_related_id_key" ON "point_transactions"("couple_id", "user_id", "reason", "related_id");
CREATE INDEX IF NOT EXISTS "point_transactions_couple_id_created_at_idx" ON "point_transactions"("couple_id", "created_at");
CREATE INDEX IF NOT EXISTS "point_transactions_user_id_created_at_idx" ON "point_transactions"("user_id", "created_at");
CREATE UNIQUE INDEX IF NOT EXISTS "checkins_user_id_checkin_date_key" ON "checkins"("user_id", "checkin_date");
CREATE INDEX IF NOT EXISTS "checkins_couple_id_checkin_date_idx" ON "checkins"("couple_id", "checkin_date");
CREATE INDEX IF NOT EXISTS "spirit_growth_logs_couple_id_created_at_idx" ON "spirit_growth_logs"("couple_id", "created_at");

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'couple_spirits_couple_id_fkey') THEN
    ALTER TABLE "couple_spirits" ADD CONSTRAINT "couple_spirits_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "couples"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'point_accounts_couple_id_fkey') THEN
    ALTER TABLE "point_accounts" ADD CONSTRAINT "point_accounts_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "couples"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'point_transactions_couple_id_fkey') THEN
    ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "couples"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'point_transactions_user_id_fkey') THEN
    ALTER TABLE "point_transactions" ADD CONSTRAINT "point_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'checkins_user_id_fkey') THEN
    ALTER TABLE "checkins" ADD CONSTRAINT "checkins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'checkins_couple_id_fkey') THEN
    ALTER TABLE "checkins" ADD CONSTRAINT "checkins_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "couples"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'spirit_growth_logs_couple_id_fkey') THEN
    ALTER TABLE "spirit_growth_logs" ADD CONSTRAINT "spirit_growth_logs_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "couples"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'spirit_growth_logs_user_id_fkey') THEN
    ALTER TABLE "spirit_growth_logs" ADD CONSTRAINT "spirit_growth_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;
