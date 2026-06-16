-- Loyalty system: points, referral codes, referral uses

-- ── Tables ────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_points (
  user_id     UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  points      INTEGER     NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS referral_codes (
  user_id     UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  code        TEXT        NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- referred_id is UNIQUE so each new user can only be referred once.
CREATE TABLE IF NOT EXISTS referral_uses (
  referred_id  UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  referrer_id  UUID        NOT NULL REFERENCES auth.users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Row-Level Security ────────────────────────────────────────────────────────

ALTER TABLE user_points   ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_uses  ENABLE ROW LEVEL SECURITY;

-- Users can only read their own point balance.
CREATE POLICY "users_read_own_points" ON user_points
  FOR SELECT USING (auth.uid() = user_id);

-- New user inserts their own points row on signup (upsert with ignoreDuplicates).
CREATE POLICY "users_insert_own_points" ON user_points
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Any authenticated user may look up a referral code (needed when applying one).
CREATE POLICY "users_read_any_code" ON referral_codes
  FOR SELECT USING (auth.role() = 'authenticated');

-- Users can insert their own referral code row.
CREATE POLICY "users_insert_own_code" ON referral_codes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can view referrals they were part of.
CREATE POLICY "users_read_own_referral_uses" ON referral_uses
  FOR SELECT USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

-- The new user records that they were referred (referred_id must be themselves).
CREATE POLICY "users_insert_referral_use" ON referral_uses
  FOR INSERT WITH CHECK (auth.uid() = referred_id);

-- ── Functions ─────────────────────────────────────────────────────────────────

-- Atomically upserts a point balance, incrementing if the row already exists.
-- Used for referral rewards (both referrer and new user get +100).
CREATE OR REPLACE FUNCTION add_loyalty_points(p_user_id UUID, p_amount INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO user_points (user_id, points)
  VALUES (p_user_id, p_amount)
  ON CONFLICT (user_id)
  DO UPDATE SET points = user_points.points + EXCLUDED.points;
END;
$$;
