import '../entities/treatment.dart';

abstract class TreatmentRepository {
  Future<List<Treatment>> getAll({String? familyMemberId});
  Future<List<Treatment>> getActive({String? familyMemberId});
  Future<Treatment?> getById(String id);
  Future<Treatment> create(Treatment treatment);
  Future<Treatment> update(Treatment treatment);
  Future<void> delete(String id);
  Stream<List<Treatment>> watchAll({String? familyMemberId});
}
