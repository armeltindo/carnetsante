import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vital.dart';
import '../shared/providers/app_providers.dart';

class VitalNotifier extends StateNotifier<AsyncValue<List<Vital>>> {
  final Ref _ref;
  final String? memberId;

  VitalNotifier(this._ref, this.memberId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _ref
          .read(vitalRepositoryProvider)
          .getAll(familyMemberId: memberId);
      state = AsyncValue.data(items);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() => _load();

  Future<void> create(Vital vital) async {
    await _ref.read(vitalRepositoryProvider).create(vital);
    await _load();
  }

  Future<void> delete(String id) async {
    await _ref.read(vitalRepositoryProvider).delete(id);
    await _load();
  }
}

final vitalNotifierProvider = StateNotifierProvider.family<
    VitalNotifier, AsyncValue<List<Vital>>, String?>(
  (ref, memberId) => VitalNotifier(ref, memberId),
);

final vitalsByTypeProvider = FutureProvider.family<List<Vital>, ({String memberId, VitalType type})>(
  (ref, params) async {
    return ref.watch(vitalRepositoryProvider).getByType(params.memberId, params.type, limit: 30);
  },
);
