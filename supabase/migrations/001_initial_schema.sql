-- ============================================================
-- CARNET SANTÉ FAMILIAL - Schéma initial Supabase
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TABLE: family_members
-- ============================================================
CREATE TABLE IF NOT EXISTS public.family_members (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name          VARCHAR(100) NOT NULL,
  date_of_birth DATE,
  blood_type    VARCHAR(5),    -- A+, A-, B+, B-, AB+, AB-, O+, O-
  allergies     TEXT[],
  medical_notes TEXT,
  avatar_url    TEXT,
  is_main       BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at    TIMESTAMPTZ,
  synced_at     TIMESTAMPTZ
);

CREATE INDEX idx_family_members_user_id ON public.family_members(user_id);
CREATE INDEX idx_family_members_deleted_at ON public.family_members(deleted_at);

-- ============================================================
-- TABLE: treatments (traitements ponctuels)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.treatments (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id  UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  medication_name   VARCHAR(200) NOT NULL,
  dosage            VARCHAR(100),
  frequency         VARCHAR(100),   -- ex: "2x/jour", "chaque 8h"
  frequency_hours   INTEGER,        -- intervalle en heures pour notifications
  start_date        DATE NOT NULL,
  end_date          DATE,
  instructions      TEXT,
  is_active         BOOLEAN DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ,
  synced_at         TIMESTAMPTZ
);

CREATE INDEX idx_treatments_user_id ON public.treatments(user_id);
CREATE INDEX idx_treatments_family_member_id ON public.treatments(family_member_id);
CREATE INDEX idx_treatments_is_active ON public.treatments(is_active);
CREATE INDEX idx_treatments_end_date ON public.treatments(end_date);

-- ============================================================
-- TABLE: periodic_treatments (traitements périodiques: palu, déparasitage)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.periodic_treatments (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id  UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  treatment_type    VARCHAR(100) NOT NULL,  -- 'palu', 'deworming', 'vaccine', 'other'
  name              VARCHAR(200) NOT NULL,
  frequency_days    INTEGER NOT NULL,       -- intervalle en jours (30=mensuel, 90=trimestriel)
  last_date         DATE,
  next_date         DATE,
  notes             TEXT,
  is_active         BOOLEAN DEFAULT TRUE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ,
  synced_at         TIMESTAMPTZ
);

CREATE INDEX idx_periodic_treatments_user_id ON public.periodic_treatments(user_id);
CREATE INDEX idx_periodic_treatments_family_member_id ON public.periodic_treatments(family_member_id);
CREATE INDEX idx_periodic_treatments_next_date ON public.periodic_treatments(next_date);

-- ============================================================
-- TABLE: reminders
-- ============================================================
CREATE TYPE reminder_type AS ENUM ('medication', 'periodic_treatment', 'appointment', 'other');
CREATE TYPE reminder_status AS ENUM ('pending', 'done', 'skipped', 'snoozed');

CREATE TABLE IF NOT EXISTS public.reminders (
  id                        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id          UUID REFERENCES public.family_members(id) ON DELETE CASCADE,
  treatment_id              UUID REFERENCES public.treatments(id) ON DELETE CASCADE,
  periodic_treatment_id     UUID REFERENCES public.periodic_treatments(id) ON DELETE CASCADE,
  type                      reminder_type NOT NULL DEFAULT 'medication',
  title                     VARCHAR(200) NOT NULL,
  body                      TEXT,
  scheduled_at              TIMESTAMPTZ NOT NULL,
  status                    reminder_status DEFAULT 'pending',
  local_notification_id     INTEGER,
  is_recurring              BOOLEAN DEFAULT FALSE,
  recurrence_interval_hours INTEGER,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at                TIMESTAMPTZ,
  synced_at                 TIMESTAMPTZ
);

CREATE INDEX idx_reminders_user_id ON public.reminders(user_id);
CREATE INDEX idx_reminders_family_member_id ON public.reminders(family_member_id);
CREATE INDEX idx_reminders_scheduled_at ON public.reminders(scheduled_at);
CREATE INDEX idx_reminders_status ON public.reminders(status);

-- ============================================================
-- TABLE: medical_records (historique médical)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.medical_records (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  record_date      DATE NOT NULL,
  symptoms         TEXT[],
  diagnosis        VARCHAR(500),
  treatment        TEXT,
  doctor_name      VARCHAR(200),
  clinic_name      VARCHAR(200),
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ,
  synced_at        TIMESTAMPTZ
);

CREATE INDEX idx_medical_records_user_id ON public.medical_records(user_id);
CREATE INDEX idx_medical_records_family_member_id ON public.medical_records(family_member_id);
CREATE INDEX idx_medical_records_record_date ON public.medical_records(record_date DESC);

-- ============================================================
-- TABLE: vitals (constantes)
-- ============================================================
CREATE TYPE vital_type AS ENUM ('temperature', 'blood_pressure', 'glucose', 'weight', 'height', 'oxygen', 'heart_rate', 'other');

CREATE TABLE IF NOT EXISTS public.vitals (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  vital_type       vital_type NOT NULL,
  value            DECIMAL(10, 2) NOT NULL,
  value2           DECIMAL(10, 2),  -- pour tension: valeur diastolique
  unit             VARCHAR(20) NOT NULL,
  measured_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes            TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ,
  synced_at        TIMESTAMPTZ
);

CREATE INDEX idx_vitals_user_id ON public.vitals(user_id);
CREATE INDEX idx_vitals_family_member_id ON public.vitals(family_member_id);
CREATE INDEX idx_vitals_type ON public.vitals(vital_type);
CREATE INDEX idx_vitals_measured_at ON public.vitals(measured_at DESC);

-- ============================================================
-- TABLE: documents (ordonnances, analyses)
-- ============================================================
CREATE TYPE document_type AS ENUM ('prescription', 'analysis', 'xray', 'report', 'vaccine_card', 'other');

CREATE TABLE IF NOT EXISTS public.documents (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  family_member_id UUID NOT NULL REFERENCES public.family_members(id) ON DELETE CASCADE,
  document_type    document_type NOT NULL DEFAULT 'other',
  title            VARCHAR(200) NOT NULL,
  description      TEXT,
  file_path        TEXT NOT NULL,   -- chemin dans Supabase Storage
  file_name        TEXT NOT NULL,
  file_size        BIGINT,
  mime_type        VARCHAR(100),
  document_date    DATE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at       TIMESTAMPTZ,
  synced_at        TIMESTAMPTZ
);

CREATE INDEX idx_documents_user_id ON public.documents(user_id);
CREATE INDEX idx_documents_family_member_id ON public.documents(family_member_id);
CREATE INDEX idx_documents_document_date ON public.documents(document_date DESC);

-- ============================================================
-- FONCTION: mise à jour automatique de updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers updated_at
CREATE TRIGGER trg_family_members_updated_at
  BEFORE UPDATE ON public.family_members
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_treatments_updated_at
  BEFORE UPDATE ON public.treatments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_periodic_treatments_updated_at
  BEFORE UPDATE ON public.periodic_treatments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_reminders_updated_at
  BEFORE UPDATE ON public.reminders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_medical_records_updated_at
  BEFORE UPDATE ON public.medical_records
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_vitals_updated_at
  BEFORE UPDATE ON public.vitals
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_documents_updated_at
  BEFORE UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- FONCTION: calcul automatique next_date pour traitements périodiques
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
