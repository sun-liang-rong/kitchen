-- CreateEnum
CREATE TYPE "CoupleStatus" AS ENUM ('ACTIVE', 'UNBOUND');

-- CreateEnum
CREATE TYPE "InviteStatus" AS ENUM ('PENDING', 'USED', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "WishType" AS ENUM ('DISH', 'FEELING');

-- CreateEnum
CREATE TYPE "DesiredTime" AS ENUM ('TONIGHT', 'TOMORROW', 'THIS_WEEK', 'WEEKEND', 'SOMEDAY');

-- CreateEnum
CREATE TYPE "WishIntensity" AS ENUM ('CASUAL', 'THIS_WEEK', 'TODAY', 'VERY_TODAY', 'WEEKEND_PLAN');

-- CreateEnum
CREATE TYPE "SubstituteOption" AS ENUM ('SIMILAR_OK', 'LIGHT_VERSION_OK', 'WHAT_WE_HAVE_OK', 'NO_SUBSTITUTE');

-- CreateEnum
CREATE TYPE "WishStatus" AS ENUM ('IN_POOL', 'PENDING_CONFIRMATION', 'CLAIMED', 'ALTERNATIVE_PROPOSED', 'DEFERRED', 'TOGETHER', 'SHELVED', 'FULFILLED');

-- CreateEnum
CREATE TYPE "WishResponseType" AS ENUM ('FULFILL_TONIGHT', 'LIGHT_VERSION', 'ALTERNATIVE', 'DEFER', 'TOGETHER', 'SHELVE');

-- CreateEnum
CREATE TYPE "KitchenStatusValue" AS ENUM ('SERIOUS_COOK', 'NORMAL', 'TIRED', 'SIMPLE_ONLY', 'NO_COOKING', 'COOK_TOGETHER');

-- CreateEnum
CREATE TYPE "DishDifficulty" AS ENUM ('EASY', 'NORMAL', 'HARD');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('WISH_CREATED', 'WISH_RESPONDED', 'WISH_CLAIMED', 'WISH_DEFERRED', 'WISH_FULFILLED');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "nickname" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "password_hash" TEXT,
    "avatar_url" TEXT,
    "default_kitchen_status" "KitchenStatusValue",
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "couples" (
    "id" TEXT NOT NULL,
    "user_a_id" TEXT NOT NULL,
    "user_b_id" TEXT NOT NULL,
    "status" "CoupleStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "couples_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "couple_invites" (
    "id" TEXT NOT NULL,
    "inviter_id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "status" "InviteStatus" NOT NULL DEFAULT 'PENDING',
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "couple_invites_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "wishes" (
    "id" TEXT NOT NULL,
    "couple_id" TEXT NOT NULL,
    "creator_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "wish_type" "WishType" NOT NULL,
    "feeling_tags" TEXT[],
    "desired_time" "DesiredTime",
    "intensity" "WishIntensity" NOT NULL,
    "substitute_option" "SubstituteOption",
    "helper_tasks" TEXT[],
    "status" "WishStatus" NOT NULL DEFAULT 'IN_POOL',
    "current_response_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "wishes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "wish_responses" (
    "id" TEXT NOT NULL,
    "wish_id" TEXT NOT NULL,
    "responder_id" TEXT NOT NULL,
    "response_type" "WishResponseType" NOT NULL,
    "proposed_title" TEXT,
    "proposed_time" "DesiredTime",
    "reason_tags" TEXT[],
    "reason_text" TEXT,
    "confirmed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "wish_responses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "wish_fulfillments" (
    "id" TEXT NOT NULL,
    "wish_id" TEXT NOT NULL,
    "fulfiller_id" TEXT NOT NULL,
    "actual_dish_name" TEXT NOT NULL,
    "helper_tasks_done" TEXT[],
    "feedback_tags" TEXT[],
    "note" TEXT,
    "add_to_dishes" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "wish_fulfillments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kitchen_statuses" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "status" "KitchenStatusValue" NOT NULL,
    "note" TEXT,
    "date" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kitchen_statuses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dishes" (
    "id" TEXT NOT NULL,
    "couple_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "cook_owner" TEXT,
    "suitable_time_tags" TEXT[],
    "difficulty" "DishDifficulty",
    "taste_tags" TEXT[],
    "is_favorite" BOOLEAN NOT NULL DEFAULT false,
    "source_wish_id" TEXT,
    "last_feedback" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "dishes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "related_id" TEXT,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE INDEX "couples_user_a_id_idx" ON "couples"("user_a_id");

-- CreateIndex
CREATE INDEX "couples_user_b_id_idx" ON "couples"("user_b_id");

-- CreateIndex
CREATE UNIQUE INDEX "couple_invites_code_key" ON "couple_invites"("code");

-- CreateIndex
CREATE INDEX "couple_invites_inviter_id_idx" ON "couple_invites"("inviter_id");

-- CreateIndex
CREATE UNIQUE INDEX "wishes_current_response_id_key" ON "wishes"("current_response_id");

-- CreateIndex
CREATE INDEX "wishes_couple_id_status_idx" ON "wishes"("couple_id", "status");

-- CreateIndex
CREATE INDEX "wishes_creator_id_idx" ON "wishes"("creator_id");

-- CreateIndex
CREATE INDEX "wish_responses_wish_id_idx" ON "wish_responses"("wish_id");

-- CreateIndex
CREATE INDEX "wish_responses_responder_id_idx" ON "wish_responses"("responder_id");

-- CreateIndex
CREATE UNIQUE INDEX "wish_fulfillments_wish_id_key" ON "wish_fulfillments"("wish_id");

-- CreateIndex
CREATE INDEX "wish_fulfillments_fulfiller_id_idx" ON "wish_fulfillments"("fulfiller_id");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_statuses_user_id_date_key" ON "kitchen_statuses"("user_id", "date");

-- CreateIndex
CREATE INDEX "dishes_couple_id_idx" ON "dishes"("couple_id");

-- CreateIndex
CREATE INDEX "notifications_user_id_read_at_idx" ON "notifications"("user_id", "read_at");

-- AddForeignKey
ALTER TABLE "couples" ADD CONSTRAINT "couples_user_a_id_fkey" FOREIGN KEY ("user_a_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "couples" ADD CONSTRAINT "couples_user_b_id_fkey" FOREIGN KEY ("user_b_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "couple_invites" ADD CONSTRAINT "couple_invites_inviter_id_fkey" FOREIGN KEY ("inviter_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wishes" ADD CONSTRAINT "wishes_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "couples"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wishes" ADD CONSTRAINT "wishes_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wishes" ADD CONSTRAINT "wishes_current_response_id_fkey" FOREIGN KEY ("current_response_id") REFERENCES "wish_responses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wish_responses" ADD CONSTRAINT "wish_responses_wish_id_fkey" FOREIGN KEY ("wish_id") REFERENCES "wishes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wish_responses" ADD CONSTRAINT "wish_responses_responder_id_fkey" FOREIGN KEY ("responder_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wish_fulfillments" ADD CONSTRAINT "wish_fulfillments_wish_id_fkey" FOREIGN KEY ("wish_id") REFERENCES "wishes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wish_fulfillments" ADD CONSTRAINT "wish_fulfillments_fulfiller_id_fkey" FOREIGN KEY ("fulfiller_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kitchen_statuses" ADD CONSTRAINT "kitchen_statuses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dishes" ADD CONSTRAINT "dishes_couple_id_fkey" FOREIGN KEY ("couple_id") REFERENCES "couples"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dishes" ADD CONSTRAINT "dishes_source_wish_id_fkey" FOREIGN KEY ("source_wish_id") REFERENCES "wishes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
