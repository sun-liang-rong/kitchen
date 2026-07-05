UPDATE "wishes"
SET "status" = 'PENDING_CONFIRMATION'
WHERE "status" = 'ALTERNATIVE_PROPOSED';

ALTER TYPE "WishStatus" RENAME TO "WishStatus_old";

CREATE TYPE "WishStatus" AS ENUM (
  'IN_POOL',
  'PENDING_CONFIRMATION',
  'CLAIMED',
  'DEFERRED',
  'TOGETHER',
  'SHELVED',
  'FULFILLED'
);

ALTER TABLE "wishes"
  ALTER COLUMN "status" DROP DEFAULT,
  ALTER COLUMN "status" TYPE "WishStatus"
  USING "status"::text::"WishStatus",
  ALTER COLUMN "status" SET DEFAULT 'IN_POOL';

DROP TYPE "WishStatus_old";
