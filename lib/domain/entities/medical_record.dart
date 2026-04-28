import 'package:equatable/equatable.dart';

class MedicalRecord extends Equatable {
  final String id;
  final String userId;
  final String familyMemberId;
  final DateTime recordDate;
  final List<String> symptoms;
  final String? diagnosis;
  final String? treatment;
  final String? doctorName;
  final String? clinicName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalRecord({
    required this.id,
    required this.userId,
    required this.familyMemberId,
    required this.recordDate,
    this.symptoms = const [],
    this.diagnosis,
    this.treatment,
    this.doctorName,
    this.clinicName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  MedicalRecord copyWith({
    DateTime? recordDate,
    List<String>? symptoms,
    String? diagnosis,
    String? treatment,
    String? doctorName,
    String? clinicName,
    String? notes,
  }) {
    return MedicalRecord(
      id: id,
      userId: userId,
      familyMemberId: familyMemberId,
      recordDate: recordDate ?? this.recordDate,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, familyMemberId, recordDate, diagnosis];
}
