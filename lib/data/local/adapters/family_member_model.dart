import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/family_member.dart';

part 'family_member_model.g.dart';

@HiveType(typeId: AppConstants.familyMemberTypeId)
class FamilyMemberModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String userId;
  @HiveField(2) late String name;
  @HiveField(3) String? dateOfBirth;
  @HiveField(4) String? bloodType;
  @HiveField(5) late List<String> allergies;
  @HiveField(6) String? medicalNotes;
  @HiveField(7) String? avatarUrl;
  @HiveField(8) late bool isMain;
  @HiveField(9) late String createdAt;
  @HiveField(10) late String updatedAt;
  @HiveField(11) bool isDirty = false; // non synchronisé

  FamilyMemberModel();

  factory FamilyMemberModel.fromEntity(FamilyMember e) {
    final m = FamilyMemberModel();
    m.id = e.id;
    m.userId = e.userId;
    m.name = e.name;
    m.dateOfBirth = e.dateOfBirth?.toIso8601String();
    m.bloodType = e.bloodType;
    m.allergies = List<String>.from(e.allergies);
    m.medicalNotes = e.medicalNotes;
    m.avatarUrl = e.avatarUrl;
    m.isMain = e.isMain;
    m.createdAt = e.createdAt.toIso8601String();
    m.updatedAt = e.updatedAt.toIso8601String();
    return m;
  }

  FamilyMember toEntity() => FamilyMember(
        id: id,
        userId: userId,
        name: name,
        dateOfBirth: dateOfBirth != null ? DateTime.parse(dateOfBirth!) : null,
        bloodType: bloodType,
        allergies: List<String>.from(allergies),
        medicalNotes: medicalNotes,
        avatarUrl: avatarUrl,
        isMain: isMain,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    final m = FamilyMemberModel();
    m.id = json['id'] as String;
    m.userId = json['user_id'] as String;
    m.name = json['name'] as String;
    m.dateOfBirth = json['date_of_birth'] as String?;
    m.bloodType = json['blood_type'] as String?;
    m.allergies = (json['allergies'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    m.medicalNotes = json['medical_notes'] as String?;
    m.avatarUrl = json['avatar_url'] as String?;
    m.isMain = json['is_main'] as bool? ?? false;
    m.createdAt = json['created_at'] as String;
    m.updatedAt = json['updated_at'] as String;
    return m;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'date_of_birth': dateOfBirth,
        'blood_type': bloodType,
        'allergies': allergies,
        'medical_notes': medicalNotes,
        'avatar_url': avatarUrl,
        'is_main': isMain,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
