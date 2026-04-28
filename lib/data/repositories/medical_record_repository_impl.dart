import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../local/hive_database.dart';
import '../local/adapters/medical_record_model.dart';

class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  final SupabaseClient _supabase;
  static const _table = 'medical_records';

  MedicalRecordRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  List<MedicalRecord> _fromCache({String? familyMemberId}) {
    var models = HiveDatabase.medicalRecords.values.toList();
    if (familyMemberId != null) {
      models = models.where((m) => m.familyMemberId == familyMemberId).toList();
    }
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
  }

  @override
  Future<List<MedicalRecord>> getAll({String? familyMemberId}) async {
    try {
      var query = _supabase
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null);

      if (familyMemberId != null) {
        query = query.eq('family_member_id', familyMemberId);
      }

      final data = await query.order('record_date', ascending: false);
      final models = data.map((json) => MedicalRecordModel.fromJson(json)).toList();

      for (final m in models) {
        m.isDirty = false;
        await HiveDatabase.medicalRecords.put(m.id, m);
      }
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return _fromCache(familyMemberId: familyMemberId);
    }
  }

  @override
  Future<MedicalRecord?> getById(String id) async {
    final cached = HiveDatabase.medicalRecords.get(id);
    return cached?.toEntity();
  }

  @override
  Future<MedicalRecord> create(MedicalRecord record) async {
    final now = DateTime.now();
    final newRecord = MedicalRecord(
      id: record.id.isEmpty ? const Uuid().v4() : record.id,
      userId: _userId,
      familyMemberId: record.familyMemberId,
      recordDate: record.recordDate,
      symptoms: record.symptoms,
      diagnosis: record.diagnosis,
      treatment: record.treatment,
      doctorName: record.doctorName,
      clinicName: record.clinicName,
      notes: record.notes,
      createdAt: now,
      updatedAt: now,
    );

    final model = MedicalRecordModel.fromEntity(newRecord);
    model.isDirty = true;
    await HiveDatabase.medicalRecords.put(model.id, model);

    try {
      await _supabase.from(_table).insert(model.toJson());
      model.isDirty = false;
      await HiveDatabase.medicalRecords.put(model.id, model);
    } catch (_) {}

    return newRecord;
  }

  @override
  Future<MedicalRecord> update(MedicalRecord record) async {
    final model = MedicalRecordModel.fromEntity(record);
    model.isDirty = true;
    await HiveDatabase.medicalRecords.put(model.id, model);

    try {
      await _supabase
          .from(_table)
          .update(model.toJson()..remove('id')..remove('user_id'))
          .eq('id', record.id);
      model.isDirty = false;
      await HiveDatabase.medicalRecords.put(model.id, model);
    } catch (_) {}

    return record;
  }

  @override
  Future<void> delete(String id) async {
    await HiveDatabase.medicalRecords.delete(id);
    try {
      await _supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (_) {}
  }

  @override
  Stream<List<MedicalRecord>> watchAll({String? familyMemberId}) {
    return HiveDatabase.medicalRecords.watch().map(
      (_) => _fromCache(familyMemberId: familyMemberId),
    ).asBroadcastStream();
  }
}
