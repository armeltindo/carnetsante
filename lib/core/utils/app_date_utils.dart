import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _shortMonthFormat = DateFormat('dd MMM yyyy', 'fr_FR');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    return _dateTimeFormat.format(dateTime);
  }

  static String formatTime(DateTime? time) {
    if (time == null) return '--';
    return _timeFormat.format(time);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '--';
    return _shortMonthFormat.format(date);
  }

  static String formatMonthYear(DateTime? date) {
    if (date == null) return '--';
    return _monthYearFormat.format(date);
  }

  static String formatIso(DateTime? date) {
    if (date == null) return '';
    return _isoFormat.format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return '--';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} semaine(s)';
    if (diff.inDays < 365) return 'Il y a ${(diff.inDays / 30).floor()} mois';
    return 'Il y a ${(diff.inDays / 365).floor()} an(s)';
  }

  static String formatAge(DateTime? birthDate) {
    if (birthDate == null) return '--';
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (now.day < birthDate.day) months--;
    if (months < 0) { years--; months += 12; }
    if (years == 0) return '$months mois';
    if (months == 0) return '$years ans';
    return '$years ans $months mois';
  }

  static String formatDaysUntil(DateTime? date) {
    if (date == null) return '--';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff < 0) return 'Dépassé de ${diff.abs()} jour(s)';
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Demain';
    return 'Dans $diff jours';
  }

  static DateTime? parseIso(String? str) {
    if (str == null || str.isEmpty) return null;
    try { return DateTime.parse(str); } catch (_) { return null; }
  }

  static DateTime? parseDate(String? str) {
    if (str == null || str.isEmpty) return null;
    try { return _dateFormat.parse(str); } catch (_) { return null; }
  }

  static DateTime calculateNextDate(DateTime lastDate, int frequencyDays) {
    return lastDate.add(Duration(days: frequencyDays));
  }

  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  static bool isDueSoon(DateTime? date, {int daysThreshold = 7}) {
    if (date == null) return false;
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    return diff >= 0 && diff <= daysThreshold;
  }
}
