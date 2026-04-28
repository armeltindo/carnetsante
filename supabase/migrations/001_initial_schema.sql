-- ============================================================
-- CARNET SANTÉ FAMILIAL - Schéma initial Supabase
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: family_members
-- ============================================================
CREATE TABLE IF NOT EXISTS public.family_members (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name          VARCHAR(100) NOT NULL,
  date_of_birth DATE,
  blood_type    VARCHAR(5),
  allergies     TEXT[] DEFAULT '{}',
  medical_notes TEXT,
  avatar_url    TEXT,
  is_main       BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ
);

CREATE INDEX idx_family_members_user_id ON public.family_members(user_id);

-- ============================================================
-- TABLE: treatments
-- ============================================================
CREATE TABLE IF NOT EXISTS public.treatments (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  medication_name  VARCHAR(200) NOT NULL,
  dosage           VARCHAR(100),
  frequency        VARCHAR(100),
  frequency_hours  INTEGER,
  start_date       DATE NOT NULL,
  end_date         DATE,
  instructions     TEXT,
  is_active        BOOLEAN DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_treatments_user_id ON public.treatments(user_id);
CREATE INDEX idx_treatments_family_member_id ON public.treatments(family_member_id);

-- ============================================================
-- TABLE: periodic_treatments
-- ============================================================
CREATE TABLE IF NOT EXISTS public.periodic_treatments (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  treatment_name   VARCHAR(200) NOT NULL,
  frequency_days   INTEGER NOT NULL,
  last_date        DATE,
  next_date        DATE,
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_periodic_treatments_user_id ON public.periodic_treatments(user_id);
CREATE INDEX idx_periodic_treatments_next_date ON public.periodic_treatments(next_date);

-- ============================================================
-- TABLE: medical_records
-- ============================================================
CREATE TABLE IF NOT EXISTS public.medical_records (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  title            VARCHAR(200) NOT NULL,
  type             VARCHAR(50),  -- consultation, hospitalization, surgery, vaccination, lab_result, imaging, other
  date             DATE NOT NULL,
  description      TEXT,
  doctor           VARCHAR(200),
  facility         VARCHAR(200),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_medical_records_user_id ON public.medical_records(user_id);
CREATE INDEX idx_medical_records_date ON public.medical_records(date DESC);

-- ============================================================
-- TABLE: vitals
-- ============================================================
CREATE TABLE IF NOT EXISTS public.vitals (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  type             VARCHAR(50) NOT NULL,  -- temperature, blood_pressure, glucose, weight, height, oxygen, heart_rate, other
  value            VARCHAR(50) NOT NULL,  -- stored as text to support "120/80" for BP
  notes            TEXT,
  measured_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_vitals_user_id ON public.vitals(user_id);
CREATE INDEX idx_vitals_family_member_id ON public.vitals(family_member_id);
CREATE INDEX idx_vitals_measured_at ON public.vitals(measured_at DESC);

-- ============================================================
-- TABLE: documents
-- ============================================================
CREATE TABLE IF NOT EXISTS public.documents (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  name             VARCHAR(200) NOT NULL,
  storage_path     TEXT NOT NULL,
  mime_type        VARCHAR(100),
  size             BIGINT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_documents_user_id ON public.documents(user_id);
CREATE INDEX idx_documents_family_member_id ON public.documents(family_member_id);

-- ============================================================
-- TABLE: reminders
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reminders (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID REFERENCES public.family_members(id) ON DELETE CASCADE,
  title            VARCHAR(200) NOT NULL,
  description      TEXT,
  remind_at        TIMESTAMPTZ NOT NULL,
  is_done          BOOLEAN DEFAULT FALSE,
  recurrence       VARCHAR(20),  -- daily, weekly, monthly, or NULL
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_reminders_user_id ON public.reminders(user_id);
CREATE INDEX idx_reminders_remind_at ON public.reminders(remind_at);

-- ============================================================
-- AUTO updated_at trigger
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_family_members_updated_at BEFORE UPDATE ON public.family_members FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_treatments_updated_at BEFORE UPDATE ON public.treatments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_periodic_treatments_updated_at BEFORE UPDATE ON public.periodic_treatments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_medical_records_updated_at BEFORE UPDATE ON public.medical_records FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_vitals_updated_at BEFORE UPDATE ON public.vitals FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_documents_updated_at BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_reminders_updated_at BEFORE UPDATE ON public.reminders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- AUTO next_date for periodic_treatments
-- ============================================================
CREATE OR REPLACE FUNCTION public.calculate_next_periodic_date()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.last_date IS NOT NULL AND NEW.frequency_days IS NOT NULL THEN
    NEW.next_date = NEW.last_date + (NEW.frequency_days || ' days')::INTERVAL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_periodic_next_date
  BEFORE INSERT OR UPDATE OF last_date, frequency_days ON public.periodic_treatments
  FOR EACH ROW EXECUTE FUNCTION public.calculate_next_periodic_date();
