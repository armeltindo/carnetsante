import '../entities/vital.dart';

abstract class VitalRepository {
  Future<List<Vital>> getAll({String? familyMemberId, VitalType? type});
  Future<List<Vital>> getByType(String familyMemberId, VitalType type, {int limit = 30});
  Future<Vital?> getById(String id);
  Future<Vital> create(Vital vital);
  Future<void> delete(String id);
  Stream<List<Vital>> watchAll({String? familyMemberId});
}
