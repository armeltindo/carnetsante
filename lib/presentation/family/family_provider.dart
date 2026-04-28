import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/family_member.dart';
import '../shared/providers/app_providers.dart';

final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  return ref.watch(familyMemberRepositoryProvider).getAll();
});

final familyMemberProvider = FutureProvider.family<FamilyMember?, String>((ref, id) async {
  return ref.watch(familyMemberRepositoryProvider).getById(id);
});

class FamilyNotifier extends StateNotifier<AsyncValue<List<FamilyMember>>> {
  final Ref _ref;

  FamilyNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await _ref.read(familyMemberRepositoryProvider).getAll();
      state = AsyncValue.data(members);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() => _load();

  Future<void> create(FamilyMember member) async {
    await _ref.read(familyMemberRepositoryProvider).create(member);
    await _load();
  }

  Future<void> update(FamilyMember member) async {
    await _ref.read(familyMemberRepositoryProvider).update(member);
    await _load();
  }

  Future<void> delete(String id) async {
    await _ref.read(familyMemberRepositoryProvider).delete(id);
    await _load();
  }
}

final familyNotifierProvider =
    StateNotifierProvider<FamilyNotifier, AsyncValue<List<FamilyMember>>>(
  (ref) => FamilyNotifier(ref),
);
