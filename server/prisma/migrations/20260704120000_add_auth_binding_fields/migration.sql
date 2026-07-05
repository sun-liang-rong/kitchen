-- AlterEnum
ALTER TYPE "InviteStatus" ADD VALUE IF NOT EXISTS 'ACCEPTED';
ALTER TYPE "InviteStatus" ADD VALUE IF NOT EXISTS 'REJECTED';

-- AlterTable
ALTER TABLE "couple_invites"
ADD COLUMN IF NOT EXISTS "invitee_id" TEXT,
ADD COLUMN IF NOT EXISTS "couple_id" TEXT,
ADD COLUMN IF NOT EXISTS "responded_at" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "couple_invites_invitee_id_idx" ON "couple_invites"("invitee_id");
CREATE INDEX IF NOT EXISTS "couple_invites_couple_id_idx" ON "couple_invites"("couple_id");
