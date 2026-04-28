import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum VitalType {
  temperature,
  bloodPressure,
  glucose,
  weight,
  height,
  oxygen,
  heartRate,
  other,
}

class Vital extends Equatable {
  final String id;
  final String userId;
  final String familyMemberId;
  final VitalType vitalType;
  final double value;
  final double? value2; // Pour tension: valeur diastolique
  final String unit;
  final DateTime measuredAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vital({
    required this.id,
    required this.userId,
    required this.familyMemberId,
    required this.vitalType,
    required this.value,
    this.value2,
    required this.unit,
    required this.measuredAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get typeLabel {
    switch (vitalType) {
      case VitalType.temperature: return 'Température';
      case VitalType.bloodPressure: return 'Tension';
      case VitalType.glucose: return 'Glycémie';
      case VitalType.weight: return 'Poids';
      case VitalType.height: return 'Taille';
      case VitalType.oxygen: return 'Oxygène';
      case VitalType.heartRate: return 'Fréq. cardiaque';
      case VitalType.other: return 'Autre';
    }
  }

  String get displayValue {
    if (vitalType == VitalType.bloodPressure && value2 != null) {
      return '${value.toStringAsFixed(0)}/${value2!.toStringAsFixed(0)} $unit';
    }
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit';
  }

  Color get typeColor {
    switch (vitalType) {
      case VitalType.temperature: return AppTheme.temperature;
      case VitalType.bloodPressure: return AppTheme.bloodPressure;
      case VitalType.glucose: return AppTheme.glucose;
      case VitalType.weight: return AppTheme.weight;
      case VitalType.height: return AppTheme.secondary;
      case VitalType.oxygen: return AppTheme.info;
      case VitalType.heartRate: return AppTheme.accent;
      case VitalType.other: return AppTheme.textSecondary;
    }
  }

  @override
  List<Object?> get props => [id, familyMemberId, vitalType, value, measuredAt];
}
