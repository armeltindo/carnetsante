import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/periodic_treatment.dart';
import '../../domain/repositories/periodic_treatment_repository.dart';
import '../local/hive_database.dart';
import '../local/adapters/periodic_treatment_model.dart';

class PeriodicTreatmentRepositoryImpl implements PeriodicTreatmentRepository {
  final SupabaseClient _supabase;
  static const _table = 'periodic_treatments';

  PeriodicTreatmentRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  List<PeriodicTreatment> _fromCache({String? familyMemberId}) {
    var models = HiveDatabase.periodicTreatments.values.toList();
    if (familyMemberId != null) {
      models = models.where((m) => m.familyMemberId == familyMemberId).toList();
    }
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) {
        final aNext = a.nextDate ?? a.calculatedNextDate;
        final bNext = b.nextDate ?? b.calculatedNextDate;
        if (aNext == null && bNext == null) return 0;
        if (aNext == null) return 1;
        if (bNext == null) return -1;
        return aNext.compareTo(bNext);
      });
  }

  @override
  Future<List<PeriodicTreatment>> getAll({String? familyMemberId}) async {
    try {
      var query = _supabase
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null);

      if (familyMemberId != null) {
        query = query.eq('family_member_id', familyMemberId);
      }

      final data = await query.order('next_date');
      final models = data.map((json) => PeriodicTreatmentModel.fromJson(json)).toList();

      for (final m in models) {
        m.isDirty = false;
        await HiveDatabase.periodicTreatments.put(m.id, m);
      }
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return _fromCache(familyMemberId: familyMemberId);
    }
  }

  @override
  Future<List<PeriodicTreatment>> getUpcoming({int daysAhead = 30}) async {
    final all = await getAll();
    final threshold = DateTime.now().add(Duration(days: daysAhead));
    return all.where((t) {
      final next = t.nextDate ?? t.calculatedNextDate;
      return next != null && next.isBefore(threshold);
    }).toList();
  }

  @override
  Future<PeriodicTreatment?> getById(String id) async {
    final cached = HiveDatabase.periodicTreatments.get(id);
    return cached?.toEntity();
  }

  @override
  Future<PeriodicTreatment> create(PeriodicTreatment treatment) async {
    final now = DateTime.now();
    final nextDate = treatment.lastDate != null
        ? treatment.lastDate!.add(Duration(days: treatment.frequencyDays))
        : null;

    final newTreatment = PeriodicTreatment(
      id: treatment.id.isEmpty ? const Uuid().v4() : treatment.id,
      userId: _userId,
      familyMemberId: treatment.familyMemberId,
      treatmentType: treatment.treatmentType,
      name: treatment.name,
      frequencyDays: treatment.frequencyDays,
      lastDate: treatment.lastDate,
      nextDate: nextDate,
      notes: treatment.notes,
      isActive: treatment.isActive,
      createdAt: now,
      updatedAt: now,
    );

    final model = PeriodicTreatmentModel.fromEntity(newTreatment);
    model.isDirty = true;
    await HiveDatabase.periodicTreatments.put(model.id, model);

    try {
      await _supabase.from(_table).insert(model.toJson());
      model.isDirty = false;
      await HiveDatabase.periodicTreatments.put(model.id, model);
    } catch (_) {}

    return newTreatment;
  }

  @override
  Future<PeriodicTreatment> update(PeriodicTreatment treatment) async {
    final model = PeriodicTreatmentModel.fromEntity(treatment);
    model.isDirty = true;
    await HiveDatabase.periodicTreatments.put(model.id, model);

    try {
      await _supabase
          .from(_table)
          .update(model.toJson()..remove('id')..remove('user_id'))
          .eq('id', treatment.id);
      model.isDirty = false;
      await HiveDatabase.periodicTreatments.put(model.id, model);
    } catch (_) {}

    return treatment;
  }

  @override
  Future<PeriodicTreatment> markTaken(String id, DateTime takenDate) async {
    final existing = await getById(id);
    if (existing == null) throw Exception('Traitement introuvable');

    final nextDate = takenDate.add(Duration(days: existing.frequencyDays));
    final updated = existing.copyWith(lastDate: takenDate, nextDate: nextDate);
    return update(updated);
  }

  @override
  Future<void> delete(String id) async {
    await HiveDatabase.periodicTreatments.delete(id);
    try {
      await _supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (_) {}
  }

  @override
  Stream<List<PeriodicTreatment>> watchAll({String? familyMemberId}) {
    return HiveDatabase.periodicTreatments.watch().map(
      (_) => _fromCache(familyMemberId: familyMemberId),
    ).asBroadcastStream();
  }
}
