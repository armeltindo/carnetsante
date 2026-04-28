import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 1;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    const androidPlugin = AndroidFlutterLocalNotificationsPlugin();

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.medicationChannelId,
        'Médicaments',
        description: 'Rappels de prise de médicaments',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.periodicChannelId,
        'Traitements périodiques',
        description: 'Rappels de traitements périodiques (palu, déparasitage)',
        importance: Importance.high,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.appointmentChannelId,
        'Rendez-vous',
        description: 'Rappels de rendez-vous médicaux',
        importance: Importance.max,
      ),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation gérée par l'app via payload
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  int _nextNotificationId() {
    return _nextId++;
  }

  /// Planifie une notification à une heure précise
  Future<int> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledAt,
    String channelId = AppConstants.medicationChannelId,
    String? payload,
  }) async {
    final id = _nextNotificationId();
    final tzScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledAt,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName(channelId),
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    return id;
  }

  /// Planifie une notification récurrente (ex: chaque jour à heure fixe)
  Future<int> scheduleRepeatingNotification({
    required String title,
    required String body,
    required DateTime firstScheduledAt,
    required RepeatInterval interval,
    String channelId = AppConstants.medicationChannelId,
  }) async {
    final id = _nextNotificationId();

    await _plugin.periodicallyShow(
      id,
      title,
      body,
      interval,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName(channelId),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    return id;
  }

  /// Affiche une notification immédiate
  Future<void> showImmediate({
    required String title,
    required String body,
    String channelId = AppConstants.medicationChannelId,
  }) async {
    final id = _nextNotificationId();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName(channelId),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Planifie automatiquement les rappels pour un traitement
  Future<int?> scheduleMedicationReminder({
    required String medicationName,
    required String memberName,
    required DateTime startDate,
    DateTime? endDate,
    int? intervalHours,
  }) async {
    if (intervalHours == null) return null;

    // Planifier la prochaine prise depuis maintenant
    var nextDate = startDate;
    final now = DateTime.now();
    while (nextDate.isBefore(now)) {
      nextDate = nextDate.add(Duration(hours: intervalHours));
    }

    if (endDate != null && nextDate.isAfter(endDate)) return null;

    return scheduleNotification(
      title: 'Médicament: $medicationName',
      body: 'Heure de prise pour $memberName',
      scheduledAt: nextDate,
      channelId: AppConstants.medicationChannelId,
      payload: 'medication:$medicationName',
    );
  }

  /// Planifie un rappel pour traitement périodique
  Future<int?> schedulePeriodicReminder({
    required String treatmentName,
    required String memberName,
    required DateTime nextDate,
  }) async {
    if (nextDate.isBefore(DateTime.now())) return null;

    return scheduleNotification(
      title: 'Traitement périodique: $treatmentName',
      body: 'Date de traitement pour $memberName - Aujourd\'hui',
      scheduledAt: DateTime(nextDate.year, nextDate.month, nextDate.day, 8, 0),
      channelId: AppConstants.periodicChannelId,
      payload: 'periodic:$treatmentName',
    );
  }

  String _channelName(String id) {
    switch (id) {
      case AppConstants.medicationChannelId: return 'Médicaments';
      case AppConstants.periodicChannelId: return 'Traitements périodiques';
      case AppConstants.appointmentChannelId: return 'Rendez-vous';
      default: return 'Rappels';
    }
  }
}
