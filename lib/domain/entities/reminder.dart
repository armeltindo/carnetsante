import 'package:equatable/equatable.dart';

enum ReminderType { medication, periodicTreatment, appointment, other }

enum ReminderStatus { pending, done, skipped, snoozed }

class Reminder extends Equatable {
  final String id;
  final String userId;
  final String? familyMemberId;
  final String? treatmentId;
  final String? periodicTreatmentId;
  final ReminderType type;
  final String title;
  final String? body;
  final DateTime scheduledAt;
  final ReminderStatus status;
  final int? localNotificationId;
  final bool isRecurring;
  final int? recurrenceIntervalHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.userId,
    this.familyMemberId,
    this.treatmentId,
    this.periodicTreatmentId,
    required this.type,
    required this.title,
    this.body,
    required this.scheduledAt,
    this.status = ReminderStatus.pending,
    this.localNotificationId,
    this.isRecurring = false,
    this.recurrenceIntervalHours,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == ReminderStatus.pending;
  bool get isDue => isPending && scheduledAt.isBefore(DateTime.now());

  Reminder copyWith({
    ReminderType? type,
    String? title,
    String? body,
    DateTime? scheduledAt,
    ReminderStatus? status,
    int? localNotificationId,
    bool? isRecurring,
    int? recurrenceIntervalHours,
  }) {
    return Reminder(
      id: id,
      userId: userId,
      familyMemberId: familyMemberId,
      treatmentId: treatmentId,
      periodicTreatmentId: periodicTreatmentId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      localNotificationId: localNotificationId ?? this.localNotificationId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceIntervalHours: recurrenceIntervalHours ?? this.recurrenceIntervalHours,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, userId, title, scheduledAt, status];
}
