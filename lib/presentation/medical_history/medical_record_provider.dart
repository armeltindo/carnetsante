import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/medical_record.dart';
import '../shared/providers/app_providers.dart';

class MedicalRecordNotifier extends StateNotifier<AsyncValue<List<MedicalRecord>>> {
  final Ref _ref;
  final String? memberId;

  MedicalRecordNotifier(this._ref, this.memberId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _ref.read(medicalRecordRepositoryProvider).getAll(familyMemberId: memberId);
      state = AsyncValue.data(items);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() => _load();

  Future<void> create(MedicalRecord record) async {
    await _ref.read(medicalRecordRepositoryProvider).create(record);
    await _load();
  }

  Future<void> update(MedicalRecord record) async {
    await _ref.read(medicalRecordRepositoryProvider).update(record);
    await _load();
  }

  Future<void> delete(String id) async {
    await _ref.read(medicalRecordRepositoryProvider).delete(id);
    await _load();
  }
}

final medicalRecordNotifierProvider = StateNotifierProvider.family<
    MedicalRecordNotifier,
    AsyncValue<List<MedicalRecord>>,
    String?>(
  (ref, memberId) => MedicalRecordNotifier(ref, memberId),
);
