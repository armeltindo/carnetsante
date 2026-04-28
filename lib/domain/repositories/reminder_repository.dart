import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Future<List<Reminder>> getPending();
  Future<Reminder?> getById(String id);
  Future<Reminder> create(Reminder reminder);
  Future<Reminder> update(Reminder reminder);
  Future<Reminder> markDone(String id);
  Future<Reminder> markSkipped(String id);
  Future<void> delete(String id);
  Stream<List<Reminder>> watchPending();
}
