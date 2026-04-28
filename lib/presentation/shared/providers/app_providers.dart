import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/family_member_repository_impl.dart';
import '../../../data/repositories/treatment_repository_impl.dart';
import '../../../data/repositories/periodic_treatment_repository_impl.dart';
import '../../../data/repositories/medical_record_repository_impl.dart';
import '../../../data/repositories/vital_repository_impl.dart';
import '../../../data/repositories/document_repository_impl.dart';
import '../../../data/repositories/reminder_repository_impl.dart';
import '../../../domain/repositories/family_member_repository.dart';
import '../../../domain/repositories/treatment_repository.dart';
import '../../../domain/repositories/periodic_treatment_repository.dart';
import '../../../domain/repositories/medical_record_repository.dart';
import '../../../domain/repositories/vital_repository.dart';
import '../../../domain/repositories/document_repository.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../../../services/notification_service.dart';
import '../../../services/sync_service.dart';

// Client Supabase
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// Repositories
final familyMemberRepositoryProvider = Provider<FamilyMemberRepository>((ref) {
  return FamilyMemberRepositoryImpl(ref.watch(supabaseClientProvider));
});

final treatmentRepositoryProvider = Provider<TreatmentRepository>((ref) {
  return TreatmentRepositoryImpl(ref.watch(supabaseClientProvider));
});

final periodicTreatmentRepositoryProvider = Provider<PeriodicTreatmentRepository>((ref) {
  return PeriodicTreatmentRepositoryImpl(ref.watch(supabaseClientProvider));
});

final medicalRecordRepositoryProvider = Provider<MedicalRecordRepository>((ref) {
  return MedicalRecordRepositoryImpl(ref.watch(supabaseClientProvider));
});

final vitalRepositoryProvider = Provider<VitalRepository>((ref) {
  return VitalRepositoryImpl(ref.watch(supabaseClientProvider));
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(ref.watch(supabaseClientProvider));
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(ref.watch(supabaseClientProvider));
});

// Services
final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(supabaseClientProvider));
});

// Theme mode
final themeModeProvider = StateProvider<bool>((ref) => false); // false = light
