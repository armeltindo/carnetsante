export type BloodType = 'A+' | 'A-' | 'B+' | 'B-' | 'AB+' | 'AB-' | 'O+' | 'O-' | 'Inconnu'

export const BLOOD_TYPES: BloodType[] = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Inconnu']

export interface FamilyMember {
  id: string
  user_id: string
  name: string
  date_of_birth?: string | null
  blood_type?: BloodType | null
  allergies: string[]
  medical_notes?: string | null
  avatar_url?: string | null
  is_main: boolean
  created_at: string
  updated_at: string
}

export interface Treatment {
  id: string
  user_id: string
  family_member_id: string
  medication_name: string
  dosage?: string | null
  frequency?: string | null
  frequency_hours?: number | null
  start_date: string
  end_date?: string | null
  instructions?: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface PeriodicTreatment {
  id: string
  user_id: string
  family_member_id: string
  treatment_name: string
  frequency_days: number
  last_date?: string | null
  next_date?: string | null
  notes?: string | null
  created_at: string
  updated_at: string
}

export interface MedicalRecord {
  id: string
  user_id: string
  family_member_id: string
  title: string
  type?: string | null
  date: string
  description?: string | null
  doctor?: string | null
  facility?: string | null
  created_at: string
  updated_at: string
}

export type VitalType = 'temperature' | 'blood_pressure' | 'glucose' | 'weight' | 'height' | 'oxygen' | 'heart_rate' | 'other'

export interface Vital {
  id: string
  user_id: string
  family_member_id: string
  type: VitalType
  value: string
  notes?: string | null
  measured_at: string
  created_at: string
  updated_at: string
}

export interface Document {
  id: string
  user_id: string
  family_member_id: string
  name: string
  storage_path: string
  mime_type?: string | null
  size?: number | null
  created_at: string
  updated_at: string
  url?: string
}

export interface Reminder {
  id: string
  user_id: string
  family_member_id?: string | null
  title: string
  description?: string | null
  remind_at: string
  is_done: boolean
  recurrence?: string | null
  created_at: string
  updated_at: string
}

export const VITAL_UNITS: Record<VitalType, string> = {
  temperature: '°C',
  blood_pressure: 'mmHg',
  glucose: 'mg/dL',
  weight: 'kg',
  height: 'cm',
  oxygen: '%',
  heart_rate: 'bpm',
  other: '',
}

export const VITAL_COLORS: Record<VitalType, string> = {
  temperature: '#E53E3E',
  blood_pressure: '#805AD5',
  glucose: '#D69E2E',
  weight: '#3182CE',
  height: '#3BB273',
  oxygen: '#00B5D8',
  heart_rate: '#FF6B35',
  other: '#718096',
}
