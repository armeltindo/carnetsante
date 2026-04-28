import '../entities/family_member.dart';

abstract class FamilyMemberRepository {
  Future<List<FamilyMember>> getAll();
  Future<FamilyMember?> getById(String id);
  Future<FamilyMember> create(FamilyMember member);
  Future<FamilyMember> update(FamilyMember member);
  Future<void> delete(String id);
  Stream<List<FamilyMember>> watchAll();
}
