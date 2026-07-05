-- CreateEnum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'UserGender') THEN
    CREATE TYPE "UserGender" AS ENUM ('MALE', 'FEMALE', 'UNSPECIFIED');
  END IF;
END $$;

-- AlterTable
ALTER TABLE "users"
ADD COLUMN IF NOT EXISTS "gender" "UserGender" NOT NULL DEFAULT 'UNSPECIFIED';
