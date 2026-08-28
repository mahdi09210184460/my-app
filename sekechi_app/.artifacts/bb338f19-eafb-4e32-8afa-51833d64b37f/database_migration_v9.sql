-- SQL Migration for Stage 9: Professional User Account System

-- 1. Add game statistics columns to profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS games_played int4 DEFAULT 0,
ADD COLUMN IF NOT EXISTS games_won int4 DEFAULT 0,
ADD COLUMN IF NOT EXISTS games_lost int4 DEFAULT 0;

-- 2. Create RPC function for incrementing game stats securely
CREATE OR REPLACE FUNCTION public.increment_game_stats(p_user_id uuid, p_is_win boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with elevated privileges to update profiles
AS $$
BEGIN
    UPDATE public.profiles
    SET
        games_played = games_played + 1,
        games_won = CASE WHEN p_is_win THEN games_won + 1 ELSE games_won END,
        games_lost = CASE WHEN NOT p_is_win THEN games_lost + 1 ELSE games_lost END
    WHERE id = p_user_id;
END;
$$;

-- 3. Security Policy: Ensure users can only update their own profile (avatar and display name)
-- This assumes standard RLS is enabled for profiles.
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
