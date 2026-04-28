import 'package:equatable/equatable.dart';

enum PeriodicTreatmentType { palu, deworming, vaccine, other }

class PeriodicTreatment extends Equatable {
  final String id;
  final String userId;
  final String familyMemberId;
  final PeriodicTreatmentType treatmentType;
  final String name;
  final int frequencyDays;
  final DateTime? lastDate;
  final DateTime? nextDate;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PeriodicTreatment({
    required this.id,
    required this.userId,
    required this.familyMemberId,
    required this.treatmentType,
    required this.name,
    required this.frequencyDays,
    this.lastDate,
    this.nextDate,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime? get calculatedNextDate {
    if (lastDate == null) return null;
    return lastDate!.add(Duration(days: frequencyDays));
  }

  bool get isOverdue {
    final next = nextDate ?? calculatedNextDate;
    if (next == null) return false;
    return next.isBefore(DateTime.now());
  }

  bool get isDueSoon {
    final next = nextDate ?? calculatedNextDate;
    if (next == null) return false;
    final diff = next.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  String get typeLabel {
    switch (treatmentType) {
      case PeriodicTreatmentType.palu: return 'Antipaludique';
      case PeriodicTreatmentType.deworming: return 'Déparasitage';
      case PeriodicTreatmentType.vaccine: return 'Vaccin';
      case PeriodicTreatmentType.other: return 'Autre';
    }
  }

  PeriodicTreatment copyWith({
    PeriodicTreatmentType? treatmentType,
    String? name,
    int? frequencyDays,
    DateTime? lastDate,
    DateTime? nextDate,
    String? notes,
    bool? isActive,
  }) {
    return PeriodicTreatment(
      id: id,
      userId: userId,
      familyMemberId: familyMemberId,
      treatmentType: treatmentType ?? this.treatmentType,
      name: name ?? this.name,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      lastDate: lastDate ?? this.lastDate,
      nextDate: nextDate ?? this.nextDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, familyMemberId, name, treatmentType, frequencyDays];
}
