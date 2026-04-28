-- ============================================================
-- ROW LEVEL SECURITY - Politiques d'accès
-- ============================================================

ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treatments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.periodic_treatments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

-- family_members
CREATE POLICY "family_members_select" ON public.family_members
  FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "family_members_insert" ON public.family_members
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "family_members_update" ON public.family_members
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "family_members_delete" ON public.family_members
  FOR DELETE USING (auth.uid() = user_id);

-- treatments
CREATE POLICY "treatments_select" ON public.treatments
  FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "treatments_insert" ON public.treatments
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "treatments_update" ON public.treatments
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "treatments_delete" ON public.treatments
  FOR DELETE USING (auth.uid() = user_id);

-- periodic_treatments
CREATE POLICY "periodic_treatments_select" ON public.periodic_treatments
  FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "periodic_treatments_insert" ON public.periodic_treatments
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "periodic_treatments_update" ON public.periodic_treatments
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "periodic_treatments_delete" ON public.periodic_treatments
  FOR DELETE USING (auth.uid() = user_id);

-- medical_records
CREATE POLICY "medical_records_select" ON public.medical_records
  FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "medical_records_insert" ON public.medical_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "medical_records_update" ON public.medical_records
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "medical_records_delete" ON public.medical_records
  FOR DELETE USING (auth.uid() = user_id);

-- vitals
CREATE POLICY "vitals_select" ON public.vitals
  FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "vitals_insert" ON public.vitals
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "vitals_update" ON public.vitals
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "vitals_delete" ON public.vitals
  FOR DELETE USING (auth.uid() = user_id);

-- documents
CREATE POLICY "documents_select" ON public.documents
  FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "documents_insert" ON public.documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "documents_update" ON public.documents
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "documents_delete" ON public.documents
  FOR DELETE USING (auth.uid() = user_id);

-- reminders
CREATE POLICY "reminders_select" ON public.reminders
  FOR SELECT USING (auth.uid() = user_id AND deleted_at IS NULL);
CREATE POLICY "reminders_insert" ON public.reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reminders_update" ON public.reminders
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "reminders_delete" ON public.reminders
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- STORAGE: medical-documents bucket
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('medical-documents', 'medical-documents', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "storage_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'medical-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "storage_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'medical-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "storage_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'medical-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
