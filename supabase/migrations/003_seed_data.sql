-- ============================================================
-- DONNÉES DE TEST (seed)
-- Remplacer USER_ID_HERE par un vrai UUID d'utilisateur Supabase
-- ============================================================

-- Exemple: créer d'abord un utilisateur via Supabase Auth
-- puis utiliser son UUID ici

DO $$
DECLARE
  v_user_id UUID := 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'; -- à remplacer
  v_member1_id UUID := uuid_generate_v4();
  v_member2_id UUID := uuid_generate_v4();
  v_member3_id UUID := uuid_generate_v4();
  v_treatment1_id UUID := uuid_generate_v4();
  v_periodic1_id UUID := uuid_generate_v4();
BEGIN
  -- Membres de la famille
  INSERT INTO public.family_members (id, user_id, name, date_of_birth, blood_type, allergies, medical_notes, is_main)
  VALUES
    (v_member1_id, v_user_id, 'Jean Dupont', '1985-03-15', 'A+',
     ARRAY['Pénicilline'], 'Hypertension légère sous contrôle', TRUE),
    (v_member2_id, v_user_id, 'Marie Dupont', '1987-07-22', 'O+',
     ARRAY[]::TEXT[], 'Aucun antécédent notable', FALSE),
    (v_member3_id, v_user_id, 'Lucas Dupont', '2015-11-08', 'A+',
     ARRAY['Lactose'], 'Asthme léger. Vaccins à jour.', FALSE);

  -- Traitement ponctuel
  INSERT INTO public.treatments (id, user_id, family_member_id, medication_name, dosage, frequency, frequency_hours, start_date, end_date, instructions)
  VALUES
    (v_treatment1_id, v_user_id, v_member1_id, 'Amlodipine', '5mg', '1x/jour', 24,
     CURRENT_DATE - INTERVAL '30 days', NULL,
     'Prendre le matin avec de l''eau. Ne pas arrêter sans avis médical.'),
    (uuid_generate_v4(), v_user_id, v_member3_id, 'Ventoline', '2 bouffées', 'En cas de crise', NULL,
     CURRENT_DATE - INTERVAL '60 days', NULL,
     'Utiliser uniquement en cas de crise d''asthme.');

  -- Traitement périodique
  INSERT INTO public.periodic_treatments (id, user_id, family_member_id, treatment_type, name, frequency_days, last_date, notes)
  VALUES
    (v_periodic1_id, v_user_id, v_member1_id, 'palu', 'Traitement antipaludique préventif', 30,
     CURRENT_DATE - INTERVAL '15 days',
     'Coartem - 1 comprimé par mois'),
    (uuid_generate_v4(), v_user_id, v_member3_id, 'deworming', 'Déparasitage enfant', 90,
     CURRENT_DATE - INTERVAL '45 days',
     'Mebendazole 500mg - 1 comprimé trimestriel');

  -- Historique médical
  INSERT INTO public.medical_records (user_id, family_member_id, record_date, symptoms, diagnosis, treatment, doctor_name, clinic_name)
  VALUES
    (v_user_id, v_member3_id, CURRENT_DATE - INTERVAL '20 days',
     ARRAY['Fièvre 38.5°C', 'Toux', 'Rhinite'],
     'Infection virale des voies respiratoires supérieures',
     'Repos, hydratation, Paracétamol 250mg',
     'Dr. Koné', 'Clinique du Plateau'),
    (v_user_id, v_member1_id, CURRENT_DATE - INTERVAL '45 days',
     ARRAY['Céphalées', 'Tension élevée'],
     'Hypertension artérielle stade 1',
     'Amlodipine 5mg/j, réduction sel, exercice',
     'Dr. Touré', 'Hôpital Central');

  -- Constantes
  INSERT INTO public.vitals (user_id, family_member_id, vital_type, value, value2, unit, measured_at, notes)
  VALUES
    (v_user_id, v_member1_id, 'blood_pressure', 135, 85, 'mmHg', NOW() - INTERVAL '1 day', 'Mesure matinale'),
    (v_user_id, v_member1_id, 'blood_pressure', 128, 82, 'mmHg', NOW() - INTERVAL '3 days', NULL),
    (v_user_id, v_member1_id, 'blood_pressure', 142, 90, 'mmHg', NOW() - INTERVAL '7 days', 'Après effort'),
    (v_user_id, v_member3_id, 'temperature', 38.5, NULL, '°C', NOW() - INTERVAL '20 days', 'Fièvre lors consultation'),
    (v_user_id, v_member3_id, 'temperature', 36.8, NULL, '°C', NOW() - INTERVAL '18 days', 'Guérison'),
    (v_user_id, v_member2_id, 'weight', 65.5, NULL, 'kg', NOW() - INTERVAL '7 days', NULL);

  RAISE NOTICE 'Données de test insérées avec succès';
END $$;
