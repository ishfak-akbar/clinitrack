-- CliniTrack demo seed — run ONCE in Supabase Dashboard > SQL Editor
-- AFTER schema.sql + patient_portal.sql, on a fresh DB.
--
-- Covers every data screen so you can click through both portals:
--   Doctor: dashboard, patients, appointments, prescriptions, follow-ups,
--           medicines (+ low stock), orders, reports
--   Patient: home, book-a-visit outcome, prescriptions, reminders, profile
--
-- ===== SETUP (2 min) =====
-- 1. In the app, register TWO accounts: one Doctor, one Patient.
-- 2. Dashboard > Authentication > Users > copy each UID below.
-- 3. Paste UIDs, Run. Then log in as each role in the app.

DO $seed$
DECLARE
  v_doctor  uuid := '<DOCTOR_UID>';   -- e.g. 'a1b2c3d4-1111-2222-3333-444455556666'
  v_patient uuid := '<PATIENT_UID>';  -- e.g. 'b2c3d4e5-1111-2222-3333-444455556666'
  v_linked  uuid;                      -- portal patient row (auto-created at signup)
  v_p1 uuid; v_p2 uuid; v_p3 uuid; v_p4 uuid;
  v_med1 uuid; v_med2 uuid;
  v_today date := CURRENT_DATE;
BEGIN
  -- Sanity: both UIDs must exist in auth.users
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_doctor) THEN
    RAISE EXCEPTION 'DOCTOR_UID not found in auth.users — copy it from Authentication > Users';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_patient) THEN
    RAISE EXCEPTION 'PATIENT_UID not found in auth.users — copy it from Authentication > Users';
  END IF;

  -- ---------- Doctor profile (directory card + dashboard header) ----------
  UPDATE public.profiles SET
    full_name = 'Dr. Amelia Carter',
    specialty = 'General Physician',
    qualifications = 'MBBS, MD (Internal Medicine)',
    experience_years = '12',
    clinic_address = '123 Health Street, Springfield',
    phone = '+1 555-0100',
    bio = 'Caring for families for over a decade.'
  WHERE id = v_doctor;

  -- ---------- Linked portal patient row (created by signup trigger) ----------
  SELECT id INTO v_linked FROM public.patients WHERE user_id = v_patient;
  IF v_linked IS NULL THEN
    INSERT INTO public.patients (owner_id, user_id, name, age, gender, contact,
                                 blood_group, medical_history, allergies, last_visit_date)
    VALUES (v_patient, v_patient, 'Alex Morgan', 29, 'Male', '+1 555-0200',
            'O+', 'Mild asthma since childhood.', ARRAY['Penicillin'], v_today - 10)
    RETURNING id INTO v_linked;
  ELSE
    UPDATE public.patients SET
      name = 'Alex Morgan', age = 29, gender = 'Male', contact = '+1 555-0200',
      blood_group = 'O+', medical_history = 'Mild asthma since childhood.',
      allergies = ARRAY['Penicillin'], last_visit_date = v_today - 10
    WHERE id = v_linked;
  END IF;
  UPDATE public.profiles SET full_name = 'Alex Morgan', role = 'Patient'
  WHERE id = v_patient;

  -- ---------- Doctor-owned patients (varied gender + blood groups for Reports) ----------
  INSERT INTO public.patients (owner_id, name, age, gender, contact, blood_group,
                               medical_history, allergies, last_visit_date)
  VALUES
    (v_doctor, 'Sarah Johnson', 34, 'Female', '+1 555-0101', 'A+', 'Hypertension, on medication.', ARRAY['Sulfa'], v_today - 2),
    (v_doctor, 'James Wilson', 45, 'Male', '+1 555-0102', 'B+', 'Type 2 diabetes.', ARRAY[]::text[], v_today - 5),
    (v_doctor, 'Emily Davis', 26, 'Female', '+1 555-0103', 'O-', 'No major history.', ARRAY['Peanuts','Latex'], v_today - 1),
    (v_doctor, 'Michael Brown', 60, 'Male', '+1 555-0104', 'AB+', 'Heart condition, post-surgery 2023.', ARRAY['Aspirin'], v_today - 15);

  SELECT id INTO v_p1 FROM public.patients WHERE owner_id = v_doctor AND name = 'Sarah Johnson';
  SELECT id INTO v_p2 FROM public.patients WHERE owner_id = v_doctor AND name = 'James Wilson';
  SELECT id INTO v_p3 FROM public.patients WHERE owner_id = v_doctor AND name = 'Emily Davis';
  SELECT id INTO v_p4 FROM public.patients WHERE owner_id = v_doctor AND name = 'Michael Brown';

  -- ---------- Appointments: one of each status ----------
  INSERT INTO public.appointments (owner_id, patient_id, patient_name, date_iso, date_label,
                                   time_text, reason, doctor_name, status)
  VALUES
    -- today, scheduled -> shows on Doctor dashboard "today's list"
    (v_doctor, v_p1, 'Sarah Johnson', v_today, 'Today', '10:00 AM', 'Blood pressure check-up', 'Dr. Amelia Carter', 'scheduled'),
    (v_doctor, v_p3, 'Emily Davis', v_today, 'Today', '02:30 PM', 'Allergy consultation', 'Dr. Amelia Carter', 'scheduled'),
    -- completed + cancelled for filter coverage
    (v_doctor, v_p2, 'James Wilson', v_today - 3, 'Past visit', '11:00 AM', 'Diabetes follow-up', 'Dr. Amelia Carter', 'completed'),
    (v_doctor, v_p4, 'Michael Brown', v_today - 7, 'Past visit', '09:00 AM', 'Cardiac review', 'Dr. Amelia Carter', 'cancelled'),
    -- future scheduled
    (v_doctor, v_p1, 'Sarah Johnson', v_today + 7, 'Upcoming', '10:00 AM', 'BP re-check', 'Dr. Amelia Carter', 'scheduled'),
    -- patient booking request -> Doctor "Needs attention" + approve/decline flow
    (v_doctor, v_linked, 'Alex Morgan', v_today + 1, 'Tomorrow', '09:30 AM', 'Asthma review', 'Dr. Amelia Carter', 'requested');

  -- ---------- Prescriptions (doctor writes, patient reads) ----------
  INSERT INTO public.prescriptions (owner_id, patient_id, medicine_name, dosage,
                                    duration_text, frequency, notes)
  VALUES
    (v_doctor, v_p1, 'Amlodipine', '5mg', '30 days', 'Once daily', 'Take in the morning with water.'),
    (v_doctor, v_p2, 'Metformin', '500mg', '30 days', 'Twice daily', 'Take after meals.'),
    (v_doctor, v_linked, 'Salbutamol Inhaler', '100mcg', 'As needed', 'As needed', 'Use during asthma flare-ups.');

  -- ---------- Medicines: healthy + low-stock + out-of-stock ----------
  INSERT INTO public.medicines (owner_id, name, category, stock, unit)
  VALUES
    (v_doctor, 'Paracetamol', 'Pain Relief', 150, 'tablets'),
    (v_doctor, 'Amoxicillin', 'Antibiotic', 8, 'capsules'),
    (v_doctor, 'Salbutamol Inhaler', 'Respiratory', 0, 'inhalers'),
    (v_doctor, 'Metformin', 'Diabetes', 45, 'tablets'),
    (v_doctor, 'Vitamin D3', 'Supplements', 200, 'tablets')
  ON CONFLICT (owner_id, name) DO UPDATE SET
    stock = EXCLUDED.stock, category = EXCLUDED.category, unit = EXCLUDED.unit;

  SELECT id INTO v_med1 FROM public.medicines WHERE owner_id = v_doctor AND name = 'Paracetamol';
  SELECT id INTO v_med2 FROM public.medicines WHERE owner_id = v_doctor AND name = 'Amoxicillin';

  -- ---------- Medicine orders (order history) ----------
  INSERT INTO public.medicine_orders (owner_id, medicine_id, medicine_name, quantity)
  VALUES
    (v_doctor, v_med1, 'Paracetamol', 100),
    (v_doctor, v_med2, 'Amoxicillin', 50);

  -- ---------- Follow-ups: overdue + today + done ----------
  INSERT INTO public.follow_ups (owner_id, patient_id, patient_name, follow_up_date,
                                 follow_up_time, notes, is_done)
  VALUES
    (v_doctor, v_p2, 'James Wilson', v_today - 2, '10:00 AM', 'Overdue: diabetes HbA1c re-test.', false),
    (v_doctor, v_p1, 'Sarah Johnson', v_today, '04:00 PM', 'BP review call.', false),
    (v_doctor, v_p4, 'Michael Brown', v_today - 5, '09:00 AM', 'Post-surgery check completed.', true),
    (v_doctor, v_linked, 'Alex Morgan', v_today + 3, '11:00 AM', 'Asthma control review.', false);

  RAISE NOTICE 'Seed done: doctor % with 4 patients, 6 appointments, 3 prescriptions, 5 medicines, 2 orders, 4 follow-ups; patient % linked.', v_doctor, v_patient;
END
$seed$;
