import 'package:equatable/equatable.dart';

class FamilyMember extends Equatable {
  final String id;
  final String userId;
  final String name;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final List<String> allergies;
  final String? medicalNotes;
  final String? avatarUrl;
  final bool isMain;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    this.dateOfBirth,
    this.bloodType,
    this.allergies = const [],
    this.medicalNotes,
    this.avatarUrl,
    this.isMain = false,
    required this.createdAt,
    required this.updatedAt,
  });

  FamilyMember copyWith({
    String? name,
    DateTime? dateOfBirth,
    String? bloodType,
    List<String>? allergies,
    String? medicalNotes,
    String? avatarUrl,
    bool? isMain,
  }) {
    return FamilyMember(
      id: id,
      userId: userId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isMain: isMain ?? this.isMain,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, name, dateOfBirth, bloodType, isMain];
}
