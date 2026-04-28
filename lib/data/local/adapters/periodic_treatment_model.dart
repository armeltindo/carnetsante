import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/periodic_treatment.dart';

part 'periodic_treatment_model.g.dart';

@HiveType(typeId: AppConstants.periodicTreatmentTypeId)
class PeriodicTreatmentModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String userId;
  @HiveField(2) late String familyMemberId;
  @HiveField(3) late String treatmentType;
  @HiveField(4) late String name;
  @HiveField(5) late int frequencyDays;
  @HiveField(6) String? lastDate;
  @HiveField(7) String? nextDate;
  @HiveField(8) String? notes;
  @HiveField(9) late bool isActive;
  @HiveField(10) late String createdAt;
  @HiveField(11) late String updatedAt;
  @HiveField(12) bool isDirty = false;

  PeriodicTreatmentModel();

  factory PeriodicTreatmentModel.fromEntity(PeriodicTreatment e) {
    final m = PeriodicTreatmentModel();
    m.id = e.id;
    m.userId = e.userId;
    m.familyMemberId = e.familyMemberId;
    m.treatmentType = e.treatmentType.name;
    m.name = e.name;
    m.frequencyDays = e.frequencyDays;
    m.lastDate = e.lastDate?.toIso8601String();
    m.nextDate = e.nextDate?.toIso8601String();
    m.notes = e.notes;
    m.isActive = e.isActive;
    m.createdAt = e.createdAt.toIso8601String();
    m.updatedAt = e.updatedAt.toIso8601String();
    return m;
  }

  PeriodicTreatment toEntity() => PeriodicTreatment(
        id: id,
        userId: userId,
        familyMemberId: familyMemberId,
        treatmentType: PeriodicTreatmentType.values.firstWhere(
          (t) => t.name == treatmentType,
          orElse: () => PeriodicTreatmentType.other,
        ),
        name: name,
        frequencyDays: frequencyDays,
        lastDate: lastDate != null ? DateTime.parse(lastDate!) : null,
        nextDate: nextDate != null ? DateTime.parse(nextDate!) : null,
        notes: notes,
        isActive: isActive,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory PeriodicTreatmentModel.fromJson(Map<String, dynamic> json) {
    final m = PeriodicTreatmentModel();
    m.id = json['id'] as String;
    m.userId = json['user_id'] as String;
    m.familyMemberId = json['family_member_id'] as String;
    m.treatmentType = json['treatment_type'] as String;
    m.name = json['name'] as String;
    m.frequencyDays = json['frequency_days'] as int;
    m.lastDate = json['last_date'] as String?;
    m.nextDate = json['next_date'] as String?;
    m.notes = json['notes'] as String?;
    m.isActive = json['is_active'] as bool? ?? true;
    m.createdAt = json['created_at'] as String;
    m.updatedAt = json['updated_at'] as String;
    return m;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'family_member_id': familyMemberId,
        'treatment_type': treatmentType,
        'name': name,
        'frequency_days': frequencyDays,
        'last_date': lastDate,
        'next_date': nextDate,
        'notes': notes,
        'is_active': isActive,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
