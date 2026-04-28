import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import 'adapters/family_member_model.dart';
import 'adapters/treatment_model.dart';
import 'adapters/periodic_treatment_model.dart';
import 'adapters/vital_model.dart';
import 'adapters/medical_record_model.dart';
import 'adapters/document_model.dart';

class HiveDatabase {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Enregistrer les adapters générés par hive_generator
    Hive.registerAdapter(FamilyMemberModelAdapter());
    Hive.registerAdapter(TreatmentModelAdapter());
    Hive.registerAdapter(PeriodicTreatmentModelAdapter());
    Hive.registerAdapter(VitalModelAdapter());
    Hive.registerAdapter(MedicalRecordModelAdapter());
    Hive.registerAdapter(DocumentModelAdapter());

    // Ouvrir toutes les boîtes
    await Future.wait([
      Hive.openBox<FamilyMemberModel>(AppConstants.familyMembersBox),
      Hive.openBox<TreatmentModel>(AppConstants.treatmentsBox),
      Hive.openBox<PeriodicTreatmentModel>(AppConstants.periodicTreatmentsBox),
      Hive.openBox<VitalModel>(AppConstants.vitalsBox),
      Hive.openBox<MedicalRecordModel>(AppConstants.medicalRecordsBox),
      Hive.openBox<DocumentModel>(AppConstants.documentsBox),
      Hive.openBox<String>(AppConstants.syncQueueBox),
    ]);
  }

  static Box<FamilyMemberModel> get familyMembers =>
      Hive.box<FamilyMemberModel>(AppConstants.familyMembersBox);

  static Box<TreatmentModel> get treatments =>
      Hive.box<TreatmentModel>(AppConstants.treatmentsBox);

  static Box<PeriodicTreatmentModel> get periodicTreatments =>
      Hive.box<PeriodicTreatmentModel>(AppConstants.periodicTreatmentsBox);

  static Box<VitalModel> get vitals =>
      Hive.box<VitalModel>(AppConstants.vitalsBox);

  static Box<MedicalRecordModel> get medicalRecords =>
      Hive.box<MedicalRecordModel>(AppConstants.medicalRecordsBox);

  static Box<DocumentModel> get documents =>
      Hive.box<DocumentModel>(AppConstants.documentsBox);

  static Box<String> get syncQueue =>
      Hive.box<String>(AppConstants.syncQueueBox);

  static Future<void> clearAll() async {
    await Future.wait([
      familyMembers.clear(),
      treatments.clear(),
      periodicTreatments.clear(),
      vitals.clear(),
      medicalRecords.clear(),
      documents.clear(),
      syncQueue.clear(),
    ]);
  }
}
