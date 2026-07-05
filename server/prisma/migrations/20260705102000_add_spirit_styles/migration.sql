DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SpiritStyle') THEN
    CREATE TYPE "SpiritStyle" AS ENUM ('FLAME', 'SHADOW', 'CELESTIAL');
  END IF;
END $$;

ALTER TABLE "couple_spirits"
ADD COLUMN IF NOT EXISTS "style" "SpiritStyle" NOT NULL DEFAULT 'FLAME';

UPDATE "couple_spirits"
SET "appearance" = CASE
  WHEN "stage" = 'INTIMATE' THEN 'flame_intimate'
  WHEN "stage" = 'GROWING' THEN 'flame_growing'
  ELSE 'flame_baby'
END
WHERE "appearance" IN ('spirit_baby', 'spirit_growing', 'spirit_intimate');
