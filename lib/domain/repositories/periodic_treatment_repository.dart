import '../entities/periodic_treatment.dart';

abstract class PeriodicTreatmentRepository {
  Future<List<PeriodicTreatment>> getAll({String? familyMemberId});
  Future<List<PeriodicTreatment>> getUpcoming({int daysAhead = 30});
  Future<PeriodicTreatment?> getById(String id);
  Future<PeriodicTreatment> create(PeriodicTreatment treatment);
  Future<PeriodicTreatment> update(PeriodicTreatment treatment);
  Future<PeriodicTreatment> markTaken(String id, DateTime takenDate);
  Future<void> delete(String id);
  Stream<List<PeriodicTreatment>> watchAll({String? familyMemberId});
}
