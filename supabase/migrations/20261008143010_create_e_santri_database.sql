-- =========================================================
-- E-SANTRI
-- DATABASE FINAL
-- =========================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- =========================================================
-- ENUM
-- =========================================================

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'pengurus',
    'pengasuh'
);

CREATE TYPE public.account_status AS ENUM (
    'pending',
    'active',
    'blocked'
);

CREATE TYPE public.gender_type AS ENUM (
    'putra',
    'putri'
);

CREATE TYPE public.presence_status AS ENUM (
    'hadir',
    'izin',
    'sakit',
    'alfa'
);

CREATE TYPE public.reset_request_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'used',
    'expired'
);


-- =========================================================
-- PROFILES / MANAJEMEN AKUN
-- =========================================================

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    full_name TEXT NOT NULL,

    username TEXT NOT NULL UNIQUE,

    email TEXT UNIQUE,

    phone TEXT,

    gender public.gender_type,

    role public.user_role NOT NULL DEFAULT 'pengurus',

    status public.account_status NOT NULL DEFAULT 'pending',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- =========================================================
-- KAMAR
-- =========================================================

CREATE TABLE public.kamar (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nama_kamar TEXT NOT NULL UNIQUE,

    gender public.gender_type NOT NULL,

    kapasitas INTEGER NOT NULL DEFAULT 0
        CHECK (kapasitas >= 0),

    deskripsi TEXT,

    aktif BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- =========================================================
-- PENGURUS
-- 1 PENGURUS = 1 KAMAR TANGGUNG JAWAB
-- =========================================================

CREATE TABLE public.pengurus (
    id UUID PRIMARY KEY
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    kamar_id UUID UNIQUE
        REFERENCES public.kamar(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- =========================================================
-- SANTRI
-- =========================================================

CREATE TABLE public.santri (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nis TEXT NOT NULL UNIQUE,

    nama_lengkap TEXT NOT NULL,

    gender public.gender_type NOT NULL,

    kamar_id UUID
        REFERENCES public.kamar(id)
        ON DELETE SET NULL,

    no_hp TEXT,

    alamat TEXT,

    status_aktif BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- =========================================================
-- KEGIATAN
-- =========================================================

CREATE TABLE public.kegiatan (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    nama_kegiatan TEXT NOT NULL UNIQUE,

    deskripsi TEXT,

    aktif BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- =========================================================
-- PRESENSI
-- =========================================================

CREATE TABLE public.presensi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    santri_id UUID NOT NULL
        REFERENCES public.santri(id)
        ON DELETE CASCADE,

    kamar_id UUID
        REFERENCES public.kamar(id)
        ON DELETE SET NULL,

    kegiatan_id UUID NOT NULL
        REFERENCES public.kegiatan(id)
        ON DELETE CASCADE,

    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,

    status public.presence_status NOT NULL,

    keterangan TEXT,

    dicatat_oleh UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (
        santri_id,
        kegiatan_id,
        tanggal
    )
);


-- =========================================================
-- PASSWORD RESET REQUEST
-- =========================================================

CREATE TABLE public.password_reset_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    identifier TEXT NOT NULL,

    request_secret_hash TEXT NOT NULL,

    status public.reset_request_status NOT NULL
        DEFAULT 'pending',

    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    reviewed_at TIMESTAMPTZ,

    reviewed_by UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    expires_at TIMESTAMPTZ,

    used_at TIMESTAMPTZ
);


-- =========================================================
-- WHATSAPP
-- =========================================================

CREATE TABLE public.whatsapp_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    group_name TEXT,

    group_identifier TEXT,

    message_template TEXT,

    is_active BOOLEAN NOT NULL DEFAULT FALSE,

    updated_by UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- =========================================================
-- INDEX
-- =========================================================

CREATE INDEX idx_profiles_role
ON public.profiles(role);

CREATE INDEX idx_profiles_status
ON public.profiles(status);

CREATE INDEX idx_santri_kamar
ON public.santri(kamar_id);

CREATE INDEX idx_santri_gender
ON public.santri(gender);

CREATE INDEX idx_presensi_tanggal
ON public.presensi(tanggal);

CREATE INDEX idx_presensi_santri
ON public.presensi(santri_id);

CREATE INDEX idx_presensi_kegiatan
ON public.presensi(kegiatan_id);

CREATE INDEX idx_presensi_kamar
ON public.presensi(kamar_id);

CREATE INDEX idx_presensi_penginput
ON public.presensi(dicatat_oleh);

CREATE INDEX idx_reset_status
ON public.password_reset_requests(status);

CREATE INDEX idx_reset_user
ON public.password_reset_requests(user_id);


-- =========================================================
-- RLS
-- =========================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pengurus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kamar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.santri ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kegiatan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.presensi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_reset_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_settings ENABLE ROW LEVEL SECURITY;


-- =========================================================
-- HELPER FUNCTIONS
-- =========================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'admin'
          AND status = 'active'
    );
$$;


CREATE OR REPLACE FUNCTION public.is_pengurus()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'pengurus'
          AND status = 'active'
    );
$$;


CREATE OR REPLACE FUNCTION public.is_pengasuh()
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'pengasuh'
          AND status = 'active'
    );
$$;


-- =========================================================
-- AUTO CREATE PROFILE SAAT REGISTER
-- =========================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    requested_role TEXT;
BEGIN

    requested_role :=
        COALESCE(
            NEW.raw_user_meta_data ->> 'role',
            'pengurus'
        );

    IF requested_role NOT IN ('admin', 'pengurus', 'pengasuh') THEN
        requested_role := 'pengurus';
    END IF;

    INSERT INTO public.profiles (
        id,
        full_name,
        username,
        email,
        phone,
        gender,
        role,
        status
    )
    VALUES (
        NEW.id,

        COALESCE(
            NEW.raw_user_meta_data ->> 'full_name',
            'Pengguna E-Santri'
        ),

        COALESCE(
            NEW.raw_user_meta_data ->> 'username',
            split_part(COALESCE(NEW.email, NEW.id::text), '@', 1)
        ),

        NEW.email,

        NEW.raw_user_meta_data ->> 'phone',

        CASE
            WHEN NEW.raw_user_meta_data ->> 'gender'
                IN ('putra', 'putri')
            THEN
                (NEW.raw_user_meta_data ->> 'gender')::public.gender_type
            ELSE NULL
        END,

        requested_role::public.user_role,

        'pending'
    );

    RETURN NEW;

END;
$$;


CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();


-- =========================================================
-- UPDATED AT
-- =========================================================

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


CREATE TRIGGER profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


CREATE TRIGGER pengurus_updated_at
BEFORE UPDATE ON public.pengurus
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


CREATE TRIGGER kamar_updated_at
BEFORE UPDATE ON public.kamar
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


CREATE TRIGGER santri_updated_at
BEFORE UPDATE ON public.santri
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


CREATE TRIGGER kegiatan_updated_at
BEFORE UPDATE ON public.kegiatan
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


CREATE TRIGGER whatsapp_settings_updated_at
BEFORE UPDATE ON public.whatsapp_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();


-- =========================================================
-- PROFILES POLICIES
-- =========================================================

CREATE POLICY "users view own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    id = auth.uid()
);


CREATE POLICY "admin view all profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    public.is_admin()
);


CREATE POLICY "admin insert profiles"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin update profiles"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin delete profiles"
ON public.profiles
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);


-- =========================================================
-- PENGURUS POLICIES
-- =========================================================

CREATE POLICY "authenticated view pengurus"
ON public.pengurus
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admin insert pengurus"
ON public.pengurus
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin update pengurus"
ON public.pengurus
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin delete pengurus"
ON public.pengurus
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);


-- =========================================================
-- KAMAR POLICIES
-- =========================================================

CREATE POLICY "authenticated view kamar"
ON public.kamar
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admin insert kamar"
ON public.kamar
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin update kamar"
ON public.kamar
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin delete kamar"
ON public.kamar
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);


-- =========================================================
-- SANTRI POLICIES
-- =========================================================

CREATE POLICY "authenticated view santri"
ON public.santri
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admin insert santri"
ON public.santri
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin update santri"
ON public.santri
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin delete santri"
ON public.santri
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);


-- =========================================================
-- KEGIATAN POLICIES
-- =========================================================

CREATE POLICY "authenticated view kegiatan"
ON public.kegiatan
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admin insert kegiatan"
ON public.kegiatan
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin update kegiatan"
ON public.kegiatan
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin delete kegiatan"
ON public.kegiatan
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);


-- =========================================================
-- PRESENSI POLICIES
-- =========================================================

CREATE POLICY "authenticated view presensi"
ON public.presensi
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "pengurus or admin insert presensi"
ON public.presensi
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_pengurus()
    OR public.is_admin()
);


CREATE POLICY "pengurus or admin update presensi"
ON public.presensi
FOR UPDATE
TO authenticated
USING (
    public.is_pengurus()
    OR public.is_admin()
)
WITH CHECK (
    public.is_pengurus()
    OR public.is_admin()
);


CREATE POLICY "admin delete presensi"
ON public.presensi
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);


-- =========================================================
-- PASSWORD RESET POLICIES
-- =========================================================
-- User TIDAK INSERT langsung.
-- Permintaan reset dibuat melalui function
-- request_password_reset().
-- =========================================================

CREATE POLICY "admin view reset requests"
ON public.password_reset_requests
FOR SELECT
TO authenticated
USING (
    public.is_admin()
);


CREATE POLICY "admin update reset requests"
ON public.password_reset_requests
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);


-- =========================================================
-- REQUEST PASSWORD RESET
-- =========================================================
-- Dipanggil dari halaman "Lupa Password".
-- Bisa dipanggil walaupun user BELUM LOGIN.
--
-- User memberikan:
-- username / email
-- + secret acak yang dibuat aplikasi.
--
-- Secret disimpan dalam bentuk HASH.
-- =========================================================

CREATE OR REPLACE FUNCTION public.request_password_reset(
    p_identifier TEXT,
    p_secret_hash TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
    v_request_id UUID;
BEGIN

    SELECT id
    INTO v_user_id
    FROM public.profiles
    WHERE
        LOWER(username) = LOWER(TRIM(p_identifier))
        OR LOWER(COALESCE(email, '')) = LOWER(TRIM(p_identifier))
    LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akun tidak ditemukan';
    END IF;


    INSERT INTO public.password_reset_requests (
        user_id,
        identifier,
        request_secret_hash,
        status,
        expires_at
    )
    VALUES (
        v_user_id,
        TRIM(p_identifier),
        p_secret_hash,
        'pending',
        NOW() + INTERVAL '30 minutes'
    )
    RETURNING id INTO v_request_id;


    RETURN v_request_id;

END;
$$;


GRANT EXECUTE
ON FUNCTION public.request_password_reset(TEXT, TEXT)
TO anon;


-- =========================================================
-- CEK STATUS RESET REQUEST
-- =========================================================
-- Dipakai aplikasi untuk mengetahui apakah Admin
-- sudah approve.
-- =========================================================

CREATE OR REPLACE FUNCTION public.check_password_reset_status(
    p_request_id UUID,
    p_secret_hash TEXT
)
RETURNS TABLE (
    request_id UUID,
    status public.reset_request_status,
    expires_at TIMESTAMPTZ
)
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT
        r.id,
        r.status,
        r.expires_at
    FROM public.password_reset_requests r
    WHERE r.id = p_request_id
      AND r.request_secret_hash = p_secret_hash
      AND r.expires_at > NOW()
    LIMIT 1;
$$;


GRANT EXECUTE
ON FUNCTION public.check_password_reset_status(UUID, TEXT)
TO anon;


-- =========================================================
-- WHATSAPP POLICIES
-- =========================================================

CREATE POLICY "authenticated view whatsapp"
ON public.whatsapp_settings
FOR SELECT
TO authenticated
USING (TRUE);


CREATE POLICY "admin insert whatsapp"
ON public.whatsapp_settings
FOR INSERT
TO authenticated
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin update whatsapp"
ON public.whatsapp_settings
FOR UPDATE
TO authenticated
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);


CREATE POLICY "admin delete whatsapp"
ON public.whatsapp_settings
FOR DELETE
TO authenticated
USING (
    public.is_admin()
);


-- =========================================================
-- DEFAULT PRIVILEGES / FUNCTION SECURITY
-- =========================================================

REVOKE EXECUTE
ON FUNCTION public.request_password_reset(TEXT, TEXT)
FROM PUBLIC;


GRANT EXECUTE
ON FUNCTION public.request_password_reset(TEXT, TEXT)
TO anon;


REVOKE EXECUTE
ON FUNCTION public.check_password_reset_status(UUID, TEXT)
FROM PUBLIC;


GRANT EXECUTE
ON FUNCTION public.check_password_reset_status(UUID, TEXT)
TO anon;


-- =========================================================
-- SEED KEGIATAN AWAL
-- =========================================================

INSERT INTO public.kegiatan (
    nama_kegiatan,
    deskripsi
)
VALUES
    ('Sholat waktu', 'Presensi sholat waktu'),
    ('Piket sore', 'Presensi piket sore'),
    ('Piket pagi', 'Presensi piket pagi'),
    ('Ngaji rutinan malam Selasa', 'Presensi ngaji rutinan malam Selasa'),
    ('Ngaji subuh', 'Presensi ngaji subuh'),
    ('Ngaji malam', 'Presensi ngaji malam'),
    ('Ngaji sore', 'Presensi ngaji sore')
ON CONFLICT (nama_kegiatan)
DO NOTHING;