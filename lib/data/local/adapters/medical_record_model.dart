import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/medical_record.dart';

part 'medical_record_model.g.dart';

@HiveType(typeId: AppConstants.medicalRecordTypeId)
class MedicalRecordModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String userId;
  @HiveField(2) late String familyMemberId;
  @HiveField(3) late String recordDate;
  @HiveField(4) late List<String> symptoms;
  @HiveField(5) String? diagnosis;
  @HiveField(6) String? treatment;
  @HiveField(7) String? doctorName;
  @HiveField(8) String? clinicName;
  @HiveField(9) String? notes;
  @HiveField(10) late String createdAt;
  @HiveField(11) late String updatedAt;
  @HiveField(12) bool isDirty = false;

  MedicalRecordModel();

  factory MedicalRecordModel.fromEntity(MedicalRecord e) {
    final m = MedicalRecordModel();
    m.id = e.id;
    m.userId = e.userId;
    m.familyMemberId = e.familyMemberId;
    m.recordDate = e.recordDate.toIso8601String();
    m.symptoms = List<String>.from(e.symptoms);
    m.diagnosis = e.diagnosis;
    m.treatment = e.treatment;
    m.doctorName = e.doctorName;
    m.clinicName = e.clinicName;
    m.notes = e.notes;
    m.createdAt = e.createdAt.toIso8601String();
    m.updatedAt = e.updatedAt.toIso8601String();
    return m;
  }

  MedicalRecord toEntity() => MedicalRecord(
        id: id,
        userId: userId,
        familyMemberId: familyMemberId,
        recordDate: DateTime.parse(recordDate),
        symptoms: List<String>.from(symptoms),
        diagnosis: diagnosis,
        treatment: treatment,
        doctorName: doctorName,
        clinicName: clinicName,
        notes: notes,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    final m = MedicalRecordModel();
    m.id = json['id'] as String;
    m.userId = json['user_id'] as String;
    m.familyMemberId = json['family_member_id'] as String;
    m.recordDate = json['record_date'] as String;
    m.symptoms = (json['symptoms'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    m.diagnosis = json['diagnosis'] as String?;
    m.treatment = json['treatment'] as String?;
    m.doctorName = json['doctor_name'] as String?;
    m.clinicName = json['clinic_name'] as String?;
    m.notes = json['notes'] as String?;
    m.createdAt = json['created_at'] as String;
    m.updatedAt = json['updated_at'] as String;
    return m;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'family_member_id': familyMemberId,
        'record_date': recordDate.split('T').first,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'doctor_name': doctorName,
        'clinic_name': clinicName,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
