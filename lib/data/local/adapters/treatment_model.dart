import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/treatment.dart';

part 'treatment_model.g.dart';

@HiveType(typeId: AppConstants.treatmentTypeId)
class TreatmentModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String userId;
  @HiveField(2) late String familyMemberId;
  @HiveField(3) late String medicationName;
  @HiveField(4) String? dosage;
  @HiveField(5) String? frequency;
  @HiveField(6) int? frequencyHours;
  @HiveField(7) late String startDate;
  @HiveField(8) String? endDate;
  @HiveField(9) String? instructions;
  @HiveField(10) late bool isActive;
  @HiveField(11) late String createdAt;
  @HiveField(12) late String updatedAt;
  @HiveField(13) bool isDirty = false;

  TreatmentModel();

  factory TreatmentModel.fromEntity(Treatment e) {
    final m = TreatmentModel();
    m.id = e.id;
    m.userId = e.userId;
    m.familyMemberId = e.familyMemberId;
    m.medicationName = e.medicationName;
    m.dosage = e.dosage;
    m.frequency = e.frequency;
    m.frequencyHours = e.frequencyHours;
    m.startDate = e.startDate.toIso8601String();
    m.endDate = e.endDate?.toIso8601String();
    m.instructions = e.instructions;
    m.isActive = e.isActive;
    m.createdAt = e.createdAt.toIso8601String();
    m.updatedAt = e.updatedAt.toIso8601String();
    return m;
  }

  Treatment toEntity() => Treatment(
        id: id,
        userId: userId,
        familyMemberId: familyMemberId,
        medicationName: medicationName,
        dosage: dosage,
        frequency: frequency,
        frequencyHours: frequencyHours,
        startDate: DateTime.parse(startDate),
        endDate: endDate != null ? DateTime.parse(endDate!) : null,
        instructions: instructions,
        isActive: isActive,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    final m = TreatmentModel();
    m.id = json['id'] as String;
    m.userId = json['user_id'] as String;
    m.familyMemberId = json['family_member_id'] as String;
    m.medicationName = json['medication_name'] as String;
    m.dosage = json['dosage'] as String?;
    m.frequency = json['frequency'] as String?;
    m.frequencyHours = json['frequency_hours'] as int?;
    m.startDate = json['start_date'] as String;
    m.endDate = json['end_date'] as String?;
    m.instructions = json['instructions'] as String?;
    m.isActive = json['is_active'] as bool? ?? true;
    m.createdAt = json['created_at'] as String;
    m.updatedAt = json['updated_at'] as String;
    return m;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'family_member_id': familyMemberId,
        'medication_name': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'frequency_hours': frequencyHours,
        'start_date': startDate,
        'end_date': endDate,
        'instructions': instructions,
        'is_active': isActive,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
