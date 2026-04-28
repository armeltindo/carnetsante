import 'package:equatable/equatable.dart';

class Treatment extends Equatable {
  final String id;
  final String userId;
  final String familyMemberId;
  final String medicationName;
  final String? dosage;
  final String? frequency;
  final int? frequencyHours;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Treatment({
    required this.id,
    required this.userId,
    required this.familyMemberId,
    required this.medicationName,
    this.dosage,
    this.frequency,
    this.frequencyHours,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  bool get isOngoing => isActive && !isExpired;

  Treatment copyWith({
    String? medicationName,
    String? dosage,
    String? frequency,
    int? frequencyHours,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    bool? isActive,
  }) {
    return Treatment(
      id: id,
      userId: userId,
      familyMemberId: familyMemberId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      frequencyHours: frequencyHours ?? this.frequencyHours,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, familyMemberId, medicationName, startDate, isActive];
}
