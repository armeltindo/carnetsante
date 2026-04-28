import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../local/hive_database.dart';

// Les rappels sont stockés principalement en local (pour les notifications offline)
class ReminderRepositoryImpl implements ReminderRepository {
  final SupabaseClient _supabase;
  static const _table = 'reminders';

  ReminderRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  Reminder _fromHiveMap(Map map) {
    return Reminder(
      id: map['id'] as String,
      userId: map['userId'] as String,
      familyMemberId: map['familyMemberId'] as String?,
      treatmentId: map['treatmentId'] as String?,
      periodicTreatmentId: map['periodicTreatmentId'] as String?,
      type: ReminderType.values.byName(map['type'] as String),
      title: map['title'] as String,
      body: map['body'] as String?,
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      status: ReminderStatus.values.byName(map['status'] as String),
      localNotificationId: map['localNotificationId'] as int?,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceIntervalHours: map['recurrenceIntervalHours'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _toHiveMap(Reminder r) => {
        'id': r.id,
        'userId': r.userId,
        'familyMemberId': r.familyMemberId,
        'treatmentId': r.treatmentId,
        'periodicTreatmentId': r.periodicTreatmentId,
        'type': r.type.name,
        'title': r.title,
        'body': r.body,
        'scheduledAt': r.scheduledAt.toIso8601String(),
        'status': r.status.name,
        'localNotificationId': r.localNotificationId,
        'isRecurring': r.isRecurring,
        'recurrenceIntervalHours': r.recurrenceIntervalHours,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  @override
  Future<List<Reminder>> getAll() async {
    return HiveDatabase.syncQueue.values
        .where((v) => v.startsWith('reminder:'))
        .map((v) {
          try {
            return null;
          } catch (_) { return null; }
        })
        .whereType<Reminder>()
        .toList();
  }

  @override
  Future<List<Reminder>> getPending() async {
    // Utiliser SharedPreferences ou Hive box dédié
    // Pour simplifier, on utilise la syncQueue box avec préfixe
    final box = HiveDatabase.syncQueue;
    final reminders = <Reminder>[];
    for (final key in box.keys) {
      final val = box.get(key.toString());
      if (val != null && key.toString().startsWith('reminder_')) {
        try {
          // Stockage simplifié comme JSON string
          final parts = val.split('||');
          if (parts.length >= 8) {
            final r = Reminder(
              id: parts[0],
              userId: parts[1],
              familyMemberId: parts[2].isEmpty ? null : parts[2],
              treatmentId: parts[3].isEmpty ? null : parts[3],
              periodicTreatmentId: parts[4].isEmpty ? null : parts[4],
              type: ReminderType.values.byName(parts[5]),
              title: parts[6],
              body: parts[7].isEmpty ? null : parts[7],
              scheduledAt: DateTime.parse(parts[8]),
              status: parts.length > 9 ? ReminderStatus.values.byName(parts[9]) : ReminderStatus.pending,
              isRecurring: parts.length > 10 ? parts[10] == 'true' : false,
              localNotificationId: parts.length > 11 ? int.tryParse(parts[11]) : null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            if (r.isPending) reminders.add(r);
          }
        } catch (_) {}
      }
    }
    return reminders..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  @override
  Future<Reminder?> getById(String id) async {
    final val = HiveDatabase.syncQueue.get('reminder_$id');
    if (val == null) return null;
    try {
      final parts = val.split('||');
      return Reminder(
        id: parts[0],
        userId: parts[1],
        familyMemberId: parts[2].isEmpty ? null : parts[2],
        treatmentId: parts[3].isEmpty ? null : parts[3],
        periodicTreatmentId: parts[4].isEmpty ? null : parts[4],
        type: ReminderType.values.byName(parts[5]),
        title: parts[6],
        body: parts[7].isEmpty ? null : parts[7],
        scheduledAt: DateTime.parse(parts[8]),
        status: parts.length > 9 ? ReminderStatus.values.byName(parts[9]) : ReminderStatus.pending,
        isRecurring: parts.length > 10 ? parts[10] == 'true' : false,
        localNotificationId: parts.length > 11 ? int.tryParse(parts[11]) : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  String _serialize(Reminder r) =>
      '${r.id}||${r.userId}||${r.familyMemberId ?? ''}||${r.treatmentId ?? ''}||${r.periodicTreatmentId ?? ''}||${r.type.name}||${r.title}||${r.body ?? ''}||${r.scheduledAt.toIso8601String()}||${r.status.name}||${r.isRecurring}||${r.localNotificationId ?? ''}';

  @override
  Future<Reminder> create(Reminder reminder) async {
    final id = reminder.id.isEmpty ? const Uuid().v4() : reminder.id;
    final newReminder = Reminder(
      id: id,
      userId: _userId,
      familyMemberId: reminder.familyMemberId,
      treatmentId: reminder.treatmentId,
      periodicTreatmentId: reminder.periodicTreatmentId,
      type: reminder.type,
      title: reminder.title,
      body: reminder.body,
      scheduledAt: reminder.scheduledAt,
      status: reminder.status,
      localNotificationId: reminder.localNotificationId,
      isRecurring: reminder.isRecurring,
      recurrenceIntervalHours: reminder.recurrenceIntervalHours,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await HiveDatabase.syncQueue.put('reminder_$id', _serialize(newReminder));
    return newReminder;
  }

  @override
  Future<Reminder> update(Reminder reminder) async {
    await HiveDatabase.syncQueue.put('reminder_${reminder.id}', _serialize(reminder));
    return reminder;
  }

  @override
  Future<Reminder> markDone(String id) async {
    final r = await getById(id);
    if (r == null) throw Exception('Rappel introuvable');
    return update(r.copyWith(status: ReminderStatus.done));
  }

  @override
  Future<Reminder> markSkipped(String id) async {
    final r = await getById(id);
    if (r == null) throw Exception('Rappel introuvable');
    return update(r.copyWith(status: ReminderStatus.skipped));
  }

  @override
  Future<void> delete(String id) async {
    await HiveDatabase.syncQueue.delete('reminder_$id');
  }

  @override
  Stream<List<Reminder>> watchPending() async* {
    yield await getPending();
    await for (final _ in HiveDatabase.syncQueue.watch()) {
      yield await getPending();
    }
  }
}
