import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/periodic_treatment.dart';
import '../shared/providers/app_providers.dart';

final periodicTreatmentsProvider =
    FutureProvider.family<List<PeriodicTreatment>, String?>((ref, memberId) async {
  return ref.watch(periodicTreatmentRepositoryProvider).getAll(familyMemberId: memberId);
});

class PeriodicTreatmentNotifier
    extends StateNotifier<AsyncValue<List<PeriodicTreatment>>> {
  final Ref _ref;
  final String? memberId;

  PeriodicTreatmentNotifier(this._ref, this.memberId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _ref
          .read(periodicTreatmentRepositoryProvider)
          .getAll(familyMemberId: memberId);
      state = AsyncValue.data(items);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() => _load();

  Future<void> create(PeriodicTreatment t) async {
    await _ref.read(periodicTreatmentRepositoryProvider).create(t);
    await _load();
  }

  Future<void> update(PeriodicTreatment t) async {
    await _ref.read(periodicTreatmentRepositoryProvider).update(t);
    await _load();
  }

  Future<void> markTaken(String id, DateTime date) async {
    await _ref.read(periodicTreatmentRepositoryProvider).markTaken(id, date);
    await _load();
  }

  Future<void> delete(String id) async {
    await _ref.read(periodicTreatmentRepositoryProvider).delete(id);
    await _load();
  }
}

final periodicTreatmentNotifierProvider = StateNotifierProvider.family<
    PeriodicTreatmentNotifier,
    AsyncValue<List<PeriodicTreatment>>,
    String?>(
  (ref, memberId) => PeriodicTreatmentNotifier(ref, memberId),
);
