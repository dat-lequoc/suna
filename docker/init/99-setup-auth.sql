-- Docker Local Supabase Auth Setup
-- This runs AFTER the supabase/postgres image initializes its schema (named 99- to run last)

-- Create auth schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS auth;

-- Create all enum types required by GoTrue MFA migrations (in public schema where GoTrue expects them)
DO $$ BEGIN
    CREATE TYPE factor_type AS ENUM ('totp', 'webauthn');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE factor_status AS ENUM ('unverified', 'verified');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE aal_level AS ENUM ('aal1', 'aal2', 'aal3');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Also create in auth schema for compatibility
DO $$ BEGIN
    CREATE TYPE auth.factor_type AS ENUM ('totp', 'webauthn');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Fix search path for postgres user to include auth schema
ALTER ROLE postgres SET search_path TO auth, public;

-- Ensure postgres user has full access to auth schema
GRANT ALL ON SCHEMA auth TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO postgres;

-- Fix identities table id column type if needed (GoTrue migration compatibility)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'identities') THEN
        ALTER TABLE auth.identities ALTER COLUMN id TYPE text;
    END IF;
EXCEPTION
    WHEN others THEN NULL;
END $$;

