class AppConstants {
  static const String appName = 'Carnet Santé';
  static const String appVersion = '1.0.0';

  // Supabase - à configurer dans .env ou via flutter_dotenv
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // Hive box names
  static const String familyMembersBox = 'family_members';
  static const String treatmentsBox = 'treatments';
  static const String periodicTreatmentsBox = 'periodic_treatments';
  static const String remindersBox = 'reminders';
  static const String medicalRecordsBox = 'medical_records';
  static const String vitalsBox = 'vitals';
  static const String documentsBox = 'documents';
  static const String syncQueueBox = 'sync_queue';

  // Hive type IDs
  static const int familyMemberTypeId = 1;
  static const int treatmentTypeId = 2;
  static const int periodicTreatmentTypeId = 3;
  static const int reminderTypeId = 4;
  static const int medicalRecordTypeId = 5;
  static const int vitalTypeId = 6;
  static const int documentTypeId = 7;
  static const int syncItemTypeId = 8;

  // Storage bucket
  static const String storageBucket = 'medical-documents';

  // Notification channels
  static const String medicationChannelId = 'medication_reminders';
  static const String periodicChannelId = 'periodic_treatment_reminders';
  static const String appointmentChannelId = 'appointment_reminders';

  // Groupes sanguins
  static const List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Inconnu',
  ];

  // Fréquences périodiques standard (jours)
  static const Map<String, int> periodicFrequencies = {
    'Mensuel (30j)': 30,
    'Bimensuel (60j)': 60,
    'Trimestriel (90j)': 90,
    'Semestriel (180j)': 180,
    'Annuel (365j)': 365,
  };

  // Types constantes
  static const Map<String, String> vitalUnits = {
    'temperature': '°C',
    'blood_pressure': 'mmHg',
    'glucose': 'mg/dL',
    'weight': 'kg',
    'height': 'cm',
    'oxygen': '%',
    'heart_rate': 'bpm',
    'other': '',
  };
}
