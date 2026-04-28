import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/hive_database.dart';
import '../data/repositories/family_member_repository_impl.dart';
import '../data/repositories/treatment_repository_impl.dart';
import '../data/repositories/periodic_treatment_repository_impl.dart';
import '../data/repositories/medical_record_repository_impl.dart';
import '../data/repositories/vital_repository_impl.dart';

/// Service de synchronisation offline → online
/// Pousse les données locales non synchronisées vers Supabase
class SyncService {
  final SupabaseClient _supabase;
  bool _isSyncing = false;

  SyncService(this._supabase);

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult(success: false, message: 'Sync en cours...');
    _isSyncing = true;

    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      // Sync membres famille
      final familyBox = HiveDatabase.familyMembers;
      for (final model in familyBox.values.where((m) => m.isDirty)) {
        try {
          await _supabase.from('family_members').upsert(model.toJson());
          model.isDirty = false;
          await familyBox.put(model.id, model);
          synced++;
        } catch (e) {
          failed++;
          errors.add('Membre ${model.name}: $e');
        }
      }

      // Sync traitements
      final treatmentsBox = HiveDatabase.treatments;
      for (final model in treatmentsBox.values.where((m) => m.isDirty)) {
        try {
          await _supabase.from('treatments').upsert(model.toJson());
          model.isDirty = false;
          await treatmentsBox.put(model.id, model);
          synced++;
        } catch (e) {
          failed++;
          errors.add('Traitement ${model.medicationName}: $e');
        }
      }

      // Sync traitements périodiques
      final periodicBox = HiveDatabase.periodicTreatments;
      for (final model in periodicBox.values.where((m) => m.isDirty)) {
        try {
          await _supabase.from('periodic_treatments').upsert(model.toJson());
          model.isDirty = false;
          await periodicBox.put(model.id, model);
          synced++;
        } catch (e) {
          failed++;
          errors.add('Traitement périodique ${model.name}: $e');
        }
      }

      // Sync dossiers médicaux
      final recordsBox = HiveDatabase.medicalRecords;
      for (final model in recordsBox.values.where((m) => m.isDirty)) {
        try {
          await _supabase.from('medical_records').upsert(model.toJson());
          model.isDirty = false;
          await recordsBox.put(model.id, model);
          synced++;
        } catch (e) {
          failed++;
          errors.add('Dossier médical: $e');
        }
      }

      // Sync constantes
      final vitalsBox = HiveDatabase.vitals;
      for (final model in vitalsBox.values.where((m) => m.isDirty)) {
        try {
          await _supabase.from('vitals').upsert(model.toJson());
          model.isDirty = false;
          await vitalsBox.put(model.id, model);
          synced++;
        } catch (e) {
          failed++;
          errors.add('Constante: $e');
        }
      }

      return SyncResult(
        success: failed == 0,
        synced: synced,
        failed: failed,
        message: failed == 0
            ? '$synced élément(s) synchronisé(s)'
            : '$synced synchronisé(s), $failed erreur(s)',
        errors: errors,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Erreur de synchronisation: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Nombre d'éléments non synchronisés
  int get pendingCount {
    return HiveDatabase.familyMembers.values.where((m) => m.isDirty).length +
        HiveDatabase.treatments.values.where((m) => m.isDirty).length +
        HiveDatabase.periodicTreatments.values.where((m) => m.isDirty).length +
        HiveDatabase.medicalRecords.values.where((m) => m.isDirty).length +
        HiveDatabase.vitals.values.where((m) => m.isDirty).length;
  }

  /// Télécharge toutes les données depuis Supabase
  Future<void> pullAll() async {
    final familyRepo = FamilyMemberRepositoryImpl(_supabase);
    final treatmentsRepo = TreatmentRepositoryImpl(_supabase);
    final periodicRepo = PeriodicTreatmentRepositoryImpl(_supabase);
    final recordsRepo = MedicalRecordRepositoryImpl(_supabase);
    final vitalsRepo = VitalRepositoryImpl(_supabase);

    await Future.wait([
      familyRepo.getAll(),
      treatmentsRepo.getAll(),
      periodicRepo.getAll(),
      recordsRepo.getAll(),
      vitalsRepo.getAll(),
    ]);
  }
}

class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String message;
  final List<String> errors;

  SyncResult({
    required this.success,
    this.synced = 0,
    this.failed = 0,
    required this.message,
    this.errors = const [],
  });
}
