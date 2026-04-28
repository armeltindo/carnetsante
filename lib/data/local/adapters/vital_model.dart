import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/vital.dart';

part 'vital_model.g.dart';

@HiveType(typeId: AppConstants.vitalTypeId)
class VitalModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String userId;
  @HiveField(2) late String familyMemberId;
  @HiveField(3) late String vitalType;
  @HiveField(4) late double value;
  @HiveField(5) double? value2;
  @HiveField(6) late String unit;
  @HiveField(7) late String measuredAt;
  @HiveField(8) String? notes;
  @HiveField(9) late String createdAt;
  @HiveField(10) late String updatedAt;
  @HiveField(11) bool isDirty = false;

  VitalModel();

  factory VitalModel.fromEntity(Vital e) {
    final m = VitalModel();
    m.id = e.id;
    m.userId = e.userId;
    m.familyMemberId = e.familyMemberId;
    m.vitalType = e.vitalType.name;
    m.value = e.value;
    m.value2 = e.value2;
    m.unit = e.unit;
    m.measuredAt = e.measuredAt.toIso8601String();
    m.notes = e.notes;
    m.createdAt = e.createdAt.toIso8601String();
    m.updatedAt = e.updatedAt.toIso8601String();
    return m;
  }

  Vital toEntity() => Vital(
        id: id,
        userId: userId,
        familyMemberId: familyMemberId,
        vitalType: VitalType.values.firstWhere(
          (t) => t.name == vitalType,
          orElse: () => VitalType.other,
        ),
        value: value,
        value2: value2,
        unit: unit,
        measuredAt: DateTime.parse(measuredAt),
        notes: notes,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory VitalModel.fromJson(Map<String, dynamic> json) {
    final m = VitalModel();
    m.id = json['id'] as String;
    m.userId = json['user_id'] as String;
    m.familyMemberId = json['family_member_id'] as String;
    m.vitalType = _mapDbType(json['vital_type'] as String);
    m.value = (json['value'] as num).toDouble();
    m.value2 = json['value2'] != null ? (json['value2'] as num).toDouble() : null;
    m.unit = json['unit'] as String;
    m.measuredAt = json['measured_at'] as String;
    m.notes = json['notes'] as String?;
    m.createdAt = json['created_at'] as String;
    m.updatedAt = json['updated_at'] as String;
    return m;
  }

  static String _mapDbType(String dbType) {
    const map = {
      'temperature': 'temperature',
      'blood_pressure': 'bloodPressure',
      'glucose': 'glucose',
      'weight': 'weight',
      'height': 'height',
      'oxygen': 'oxygen',
      'heart_rate': 'heartRate',
      'other': 'other',
    };
    return map[dbType] ?? 'other';
  }

  static String _mapEntityType(String entityType) {
    const map = {
      'temperature': 'temperature',
      'bloodPressure': 'blood_pressure',
      'glucose': 'glucose',
      'weight': 'weight',
      'height': 'height',
      'oxygen': 'oxygen',
      'heartRate': 'heart_rate',
      'other': 'other',
    };
    return map[entityType] ?? 'other';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'family_member_id': familyMemberId,
        'vital_type': _mapEntityType(vitalType),
        'value': value,
        'value2': value2,
        'unit': unit,
        'measured_at': measuredAt,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
