-- SQL Migration for Stage 10: Secure Payment Infrastructure

-- 1. Create payment_packages table
CREATE TABLE IF NOT EXISTS public.payment_packages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    coins_amount int4 NOT NULL,
    price_irr int8 NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);

-- 2. Create payments table with snapshot fields
CREATE TABLE IF NOT EXISTS public.payments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) NOT NULL,
    package_id uuid REFERENCES public.payment_packages(id),
    package_title_snapshot text NOT NULL,
    coins_amount_snapshot int4 NOT NULL,
    price_at_purchase int8 NOT NULL,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed')),
    transaction_id text UNIQUE,
    authority_code text,
    created_at timestamp with time zone DEFAULT now()
);

-- 3. Secure RPC: confirm_payment_and_add_coins
-- This function verifies the payment and adds coins in a single atomic transaction.
CREATE OR REPLACE FUNCTION public.confirm_payment_and_add_coins(
    p_payment_id uuid,
    p_transaction_id text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- Essential for bypassing RLS to update profiles/transactions
AS $$
DECLARE
    v_user_id uuid;
    v_coins int4;
    v_package_title text;
BEGIN
    -- Only process if payment exists, is pending, and transaction_id is not already used
    SELECT user_id, coins_amount_snapshot, package_title_snapshot
    INTO v_user_id, v_coins, v_package_title
    FROM public.payments
    WHERE id = p_payment_id AND status = 'pending'
    FOR UPDATE; -- Lock the row to prevent concurrent races

    IF FOUND THEN
        -- 1. Check if transaction_id is already used by another payment
        IF EXISTS (SELECT 1 FROM public.payments WHERE transaction_id = p_transaction_id) THEN
            RAISE EXCEPTION 'این شناسه تراکنش قبلاً ثبت شده است.';
        END IF;

        -- 2. Update payment record
        UPDATE public.payments
        SET status = 'success', transaction_id = p_transaction_id
        WHERE id = p_payment_id;

        -- 3. Update user points in profiles (field name is 'points')
        UPDATE public.profiles
        SET points = points + v_coins
        WHERE id = v_user_id;

        -- 4. Log in coin_transactions
        INSERT INTO public.coin_transactions (user_id, amount, type, description)
        VALUES (v_user_id, v_coins, 'purchase', 'خرید بسته: ' || v_package_title);

        RETURN true;
    END IF;

    RETURN false;
EXCEPTION
    WHEN OTHERS THEN
        -- If any error occurs, transaction will roll back
        RAISE NOTICE 'خطا در تایید پرداخت: %', SQLERRM;
        RETURN false;
END;
$$;

-- 4. Enable RLS
ALTER TABLE public.payment_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Policies for packages
CREATE POLICY "Anyone can view active packages" ON public.payment_packages
    FOR SELECT USING (is_active = true);

-- Policies for payments
CREATE POLICY "Users can view their own payments" ON public.payments
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create a payment request" ON public.payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);
