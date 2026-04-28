import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/reminder.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/app_widgets.dart';

final _pendingRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  return ref.watch(reminderRepositoryProvider).getPending();
});

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_pendingRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rappels'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(notificationServiceProvider).cancelAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tous les rappels annulés')),
                );
              }
            },
            icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text('Tout annuler'),
          ),
        ],
      ),
      body: state.when(
        data: (reminders) => reminders.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                title: 'Aucun rappel',
                subtitle: 'Les rappels apparaissent automatiquement lors de l\'ajout de traitements',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ReminderCard(
                  reminder: reminders[i],
                  onDone: () async {
                    await ref.read(reminderRepositoryProvider).markDone(reminders[i].id);
                    if (reminders[i].localNotificationId != null) {
                      await ref.read(notificationServiceProvider).cancel(reminders[i].localNotificationId!);
                    }
                    ref.invalidate(_pendingRemindersProvider);
                  },
                  onSkip: () async {
                    await ref.read(reminderRepositoryProvider).markSkipped(reminders[i].id);
                    ref.invalidate(_pendingRemindersProvider);
                  },
                ),
              ),
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  const _ReminderCard({
    required this.reminder,
    required this.onDone,
    required this.onSkip,
  });

  Color _typeColor() {
    switch (reminder.type) {
      case ReminderType.medication: return AppTheme.primary;
      case ReminderType.periodicTreatment: return AppTheme.secondary;
      case ReminderType.appointment: return AppTheme.warning;
      case ReminderType.other: return AppTheme.textSecondary;
    }
  }

  IconData _typeIcon() {
    switch (reminder.type) {
      case ReminderType.medication: return Icons.medication_rounded;
      case ReminderType.periodicTreatment: return Icons.medication_liquid_rounded;
      case ReminderType.appointment: return Icons.calendar_today_rounded;
      case ReminderType.other: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    final isDue = reminder.isDue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDue ? color.withOpacity(0.5) : AppTheme.divider,
          width: isDue ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.title, style: Theme.of(context).textTheme.titleMedium),
                    if (reminder.body != null)
                      Text(reminder.body!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (isDue)
                StatusBadge(label: 'Maintenant', color: color)
              else
                Text(
                  AppDateUtils.formatDaysUntil(reminder.scheduledAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                AppDateUtils.formatDateTime(reminder.scheduledAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ignorer', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Fait', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
