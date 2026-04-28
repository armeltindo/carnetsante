import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/treatment.dart';
import '../shared/providers/app_providers.dart';

final treatmentsProvider = FutureProvider.family<List<Treatment>, String?>((ref, memberId) async {
  return ref.watch(treatmentRepositoryProvider).getAll(familyMemberId: memberId);
});

class TreatmentNotifier extends StateNotifier<AsyncValue<List<Treatment>>> {
  final Ref _ref;
  final String? memberId;

  TreatmentNotifier(this._ref, this.memberId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _ref.read(treatmentRepositoryProvider).getAll(familyMemberId: memberId);
      state = AsyncValue.data(items);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() => _load();

  Future<void> create(Treatment t) async {
    await _ref.read(treatmentRepositoryProvider).create(t);
    await _load();
  }

  Future<void> update(Treatment t) async {
    await _ref.read(treatmentRepositoryProvider).update(t);
    await _load();
  }

  Future<void> delete(String id) async {
    await _ref.read(treatmentRepositoryProvider).delete(id);
    await _load();
  }
}

final treatmentNotifierProvider = StateNotifierProvider.family<TreatmentNotifier, AsyncValue<List<Treatment>>, String?>(
  (ref, memberId) => TreatmentNotifier(ref, memberId),
);
