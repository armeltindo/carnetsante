import '../entities/medical_record.dart';

abstract class MedicalRecordRepository {
  Future<List<MedicalRecord>> getAll({String? familyMemberId});
  Future<MedicalRecord?> getById(String id);
  Future<MedicalRecord> create(MedicalRecord record);
  Future<MedicalRecord> update(MedicalRecord record);
  Future<void> delete(String id);
  Stream<List<MedicalRecord>> watchAll({String? familyMemberId});
}
