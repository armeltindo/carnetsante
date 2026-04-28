import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/repositories/family_member_repository.dart';
import '../local/hive_database.dart';
import '../local/adapters/family_member_model.dart';

class FamilyMemberRepositoryImpl implements FamilyMemberRepository {
  final SupabaseClient _supabase;
  static const _table = 'family_members';

  FamilyMemberRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<FamilyMember>> getAll() async {
    // Essayer Supabase d'abord, fallback sur Hive
    try {
      final data = await _supabase
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .order('created_at');

      final models = data.map((json) => FamilyMemberModel.fromJson(json)).toList();
      // Mettre à jour le cache local
      final box = HiveDatabase.familyMembers;
      for (final m in models) {
        m.isDirty = false;
        await box.put(m.id, m);
      }
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      // Offline: utiliser Hive
      return _fromCache();
    }
  }

  List<FamilyMember> _fromCache() {
    return HiveDatabase.familyMembers.values
        .where((m) => !m.isDirty || true)
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<FamilyMember?> getById(String id) async {
    final cached = HiveDatabase.familyMembers.get(id);
    if (cached != null) return cached.toEntity();
    try {
      final data = await _supabase.from(_table).select().eq('id', id).single();
      final model = FamilyMemberModel.fromJson(data);
      await HiveDatabase.familyMembers.put(model.id, model);
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FamilyMember> create(FamilyMember member) async {
    final newMember = FamilyMember(
      id: member.id.isEmpty ? const Uuid().v4() : member.id,
      userId: _userId,
      name: member.name,
      dateOfBirth: member.dateOfBirth,
      bloodType: member.bloodType,
      allergies: member.allergies,
      medicalNotes: member.medicalNotes,
      avatarUrl: member.avatarUrl,
      isMain: member.isMain,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final model = FamilyMemberModel.fromEntity(newMember);
    model.isDirty = true;
    await HiveDatabase.familyMembers.put(model.id, model);

    try {
      await _supabase.from(_table).insert(model.toJson());
      model.isDirty = false;
      await HiveDatabase.familyMembers.put(model.id, model);
    } catch (_) {
      // Sauvegardé localement, sera synchronisé plus tard
    }

    return newMember;
  }

  @override
  Future<FamilyMember> update(FamilyMember member) async {
    final model = FamilyMemberModel.fromEntity(member);
    model.isDirty = true;
    await HiveDatabase.familyMembers.put(model.id, model);

    try {
      await _supabase
          .from(_table)
          .update(model.toJson()..remove('id')..remove('user_id'))
          .eq('id', member.id);
      model.isDirty = false;
      await HiveDatabase.familyMembers.put(model.id, model);
    } catch (_) {}

    return member;
  }

  @override
  Future<void> delete(String id) async {
    await HiveDatabase.familyMembers.delete(id);
    try {
      await _supabase
          .from(_table)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (_) {}
  }

  @override
  Stream<List<FamilyMember>> watchAll() {
    return HiveDatabase.familyMembers.watch().map((_) => _fromCache()).asBroadcastStream();
  }
}
