-- Loyalty transaction history

-- ── Table ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount      INTEGER     NOT NULL,
  reason      TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A user can only ever receive the signup bonus once.
CREATE UNIQUE INDEX IF NOT EXISTS loyalty_transactions_signup_unique
  ON loyalty_transactions (user_id)
  WHERE reason = 'signup_bonus';

-- ── Row-Level Security ────────────────────────────────────────────────────────

ALTER TABLE loyalty_transactions ENABLE ROW LEVEL SECURITY;

-- Users may read their own history. All writes go through the SECURITY DEFINER
-- function below, so no INSERT policy is needed (and omitting one is safer).
CREATE POLICY "users_read_own_transactions" ON loyalty_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- ── Function ──────────────────────────────────────────────────────────────────

-- Replaces the original add_loyalty_points. Atomically updates the running
-- balance AND appends a history row. ON CONFLICT DO NOTHING on the insert lets
-- the partial unique index on signup_bonus silently skip duplicate awards.
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER);

CREATE OR REPLACE FUNCTION award_loyalty_points(
  p_user_id UUID,
  p_amount  INTEGER,
  p_reason  TEXT
)
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

  INSERT INTO loyalty_transactions (user_id, amount, reason)
  VALUES (p_user_id, p_amount, p_reason)
  ON CONFLICT DO NOTHING;
END;
$$;
