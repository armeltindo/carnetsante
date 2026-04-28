import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../local/hive_database.dart';
import '../local/adapters/treatment_model.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final SupabaseClient _supabase;
  static const _table = 'treatments';

  TreatmentRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  List<Treatment> _fromCache({String? familyMemberId}) {
    var models = HiveDatabase.treatments.values.toList();
    if (familyMemberId != null) {
      models = models.where((m) => m.familyMemberId == familyMemberId).toList();
    }
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Future<List<Treatment>> getAll({String? familyMemberId}) async {
    try {
      var query = _supabase
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null);

      if (familyMemberId != null) {
        query = query.eq('family_member_id', familyMemberId);
      }

      final data = await query.order('start_date', ascending: false);
      final models = data.map((json) => TreatmentModel.fromJson(json)).toList();

      for (final m in models) {
        m.isDirty = false;
        await HiveDatabase.treatments.put(m.id, m);
      }
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return _fromCache(familyMemberId: familyMemberId);
    }
  }

  @override
  Future<List<Treatment>> getActive({String? familyMemberId}) async {
    final all = await getAll(familyMemberId: familyMemberId);
    return all.where((t) => t.isOngoing).toList();
  }

  @override
  Future<Treatment?> getById(String id) async {
    final cached = HiveDatabase.treatments.get(id);
    if (cached != null) return cached.toEntity();
    return null;
  }

  @override
  Future<Treatment> create(Treatment treatment) async {
    final newTreatment = Treatment(
      id: treatment.id.isEmpty ? const Uuid().v4() : treatment.id,
      userId: _userId,
      familyMemberId: treatment.familyMemberId,
      medicationName: treatment.medicationName,
      dosage: treatment.dosage,
      frequency: treatment.frequency,
      frequencyHours: treatment.frequencyHours,
      startDate: treatment.startDate,
      endDate: treatment.endDate,
      instructions: treatment.instructions,
      isActive: treatment.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final model = TreatmentModel.fromEntity(newTreatment);
    model.isDirty = true;
    await HiveDatabase.treatments.put(model.id, model);

    try {
      await _supabase.from(_table).insert(model.toJson());
      model.isDirty = false;
      await HiveDatabase.treatments.put(model.id, model);
    } catch (_) {}

    return newTreatment;
  }

  @override
  Future<Treatment> update(Treatment treatment) async {
    final model = TreatmentModel.fromEntity(treatment);
    model.isDirty = true;
    await HiveDatabase.treatments.put(model.id, model);

    try {
      await _supabase
          .from(_table)
          .update(model.toJson()..remove('id')..remove('user_id'))
          .eq('id', treatment.id);
      model.isDirty = false;
      await HiveDatabase.treatments.put(model.id, model);
    } catch (_) {}

    return treatment;
  }

  @override
  Future<void> delete(String id) async {
    await HiveDatabase.treatments.delete(id);
    try {
      await _supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (_) {}
  }

  @override
  Stream<List<Treatment>> watchAll({String? familyMemberId}) {
    return HiveDatabase.treatments.watch().map(
      (_) => _fromCache(familyMemberId: familyMemberId),
    ).asBroadcastStream();
  }
}
