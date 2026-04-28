import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/vital.dart';
import '../../domain/repositories/vital_repository.dart';
import '../local/hive_database.dart';
import '../local/adapters/vital_model.dart';

class VitalRepositoryImpl implements VitalRepository {
  final SupabaseClient _supabase;
  static const _table = 'vitals';

  VitalRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  List<Vital> _fromCache({String? familyMemberId, VitalType? type}) {
    var models = HiveDatabase.vitals.values.toList();
    if (familyMemberId != null) {
      models = models.where((m) => m.familyMemberId == familyMemberId).toList();
    }
    if (type != null) {
      models = models.where((m) => m.vitalType == type.name).toList();
    }
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
  }

  @override
  Future<List<Vital>> getAll({String? familyMemberId, VitalType? type}) async {
    try {
      var query = _supabase
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null);

      if (familyMemberId != null) {
        query = query.eq('family_member_id', familyMemberId);
      }

      final data = await query.order('measured_at', ascending: false);
      final models = data.map((json) => VitalModel.fromJson(json)).toList();

      for (final m in models) {
        m.isDirty = false;
        await HiveDatabase.vitals.put(m.id, m);
      }

      var entities = models.map((m) => m.toEntity()).toList();
      if (type != null) entities = entities.where((v) => v.vitalType == type).toList();
      return entities;
    } catch (_) {
      return _fromCache(familyMemberId: familyMemberId, type: type);
    }
  }

  @override
  Future<List<Vital>> getByType(String familyMemberId, VitalType type, {int limit = 30}) async {
    final all = await getAll(familyMemberId: familyMemberId, type: type);
    return all.take(limit).toList();
  }

  @override
  Future<Vital?> getById(String id) async {
    final cached = HiveDatabase.vitals.get(id);
    return cached?.toEntity();
  }

  @override
  Future<Vital> create(Vital vital) async {
    final now = DateTime.now();
    final newVital = Vital(
      id: vital.id.isEmpty ? const Uuid().v4() : vital.id,
      userId: _userId,
      familyMemberId: vital.familyMemberId,
      vitalType: vital.vitalType,
      value: vital.value,
      value2: vital.value2,
      unit: vital.unit,
      measuredAt: vital.measuredAt,
      notes: vital.notes,
      createdAt: now,
      updatedAt: now,
    );

    final model = VitalModel.fromEntity(newVital);
    model.isDirty = true;
    await HiveDatabase.vitals.put(model.id, model);

    try {
      await _supabase.from(_table).insert(model.toJson());
      model.isDirty = false;
      await HiveDatabase.vitals.put(model.id, model);
    } catch (_) {}

    return newVital;
  }

  @override
  Future<void> delete(String id) async {
    await HiveDatabase.vitals.delete(id);
    try {
      await _supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (_) {}
  }

  @override
  Stream<List<Vital>> watchAll({String? familyMemberId}) {
    return HiveDatabase.vitals.watch().map(
      (_) => _fromCache(familyMemberId: familyMemberId),
    ).asBroadcastStream();
  }
}
