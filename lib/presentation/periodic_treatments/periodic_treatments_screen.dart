import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/periodic_treatment.dart';
import '../shared/widgets/app_widgets.dart';
import 'periodic_treatment_provider.dart';

class PeriodicTreatmentsScreen extends ConsumerWidget {
  final String? memberId;
  const PeriodicTreatmentsScreen({super.key, this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(periodicTreatmentNotifierProvider(memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traitements périodiques'),
        leading: memberId != null
            ? BackButton(onPressed: () => context.go('/family/$memberId'))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go(
              '/periodic-treatments/new${memberId != null ? '?memberId=$memberId' : ''}',
            ),
          ),
        ],
      ),
      body: state.when(
        data: (treatments) => treatments.isEmpty
            ? EmptyStateWidget(
                icon: Icons.medication_liquid_outlined,
                title: 'Aucun traitement périodique',
                subtitle: 'Ajoutez vos traitements antipaludiques, déparasitages...',
                action: ElevatedButton.icon(
                  onPressed: () => context.go(
                    '/periodic-treatments/new${memberId != null ? '?memberId=$memberId' : ''}',
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(periodicTreatmentNotifierProvider(memberId).notifier)
                    .refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: treatments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PeriodicCard(
                    treatment: treatments[i],
                    memberId: memberId,
                  ),
                ),
              ),
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref
              .read(periodicTreatmentNotifierProvider(memberId).notifier)
              .refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(
          '/periodic-treatments/new${memberId != null ? '?memberId=$memberId' : ''}',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PeriodicCard extends ConsumerWidget {
  final PeriodicTreatment treatment;
  final String? memberId;

  const _PeriodicCard({required this.treatment, this.memberId});

  Color _getStatusColor() {
    if (treatment.isOverdue) return AppTheme.error;
    if (treatment.isDueSoon) return AppTheme.warning;
    return AppTheme.success;
  }

  String _getStatusLabel() {
    if (treatment.isOverdue) return 'En retard';
    if (treatment.isDueSoon) return 'Bientôt';
    return 'À jour';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getStatusColor();
    final nextDate = treatment.nextDate ?? treatment.calculatedNextDate;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final confirm = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (confirm != null) {
                await ref
                    .read(periodicTreatmentNotifierProvider(memberId).notifier)
                    .markTaken(treatment.id, confirm);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Traitement marqué comme pris'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              }
            },
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            icon: Icons.check_circle_rounded,
            label: 'Pris',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          ),
          SlidableAction(
            onPressed: (_) => context.go(
              '/periodic-treatments/${treatment.id}/edit${memberId != null ? '?memberId=$memberId' : ''}',
            ),
            backgroundColor: AppTheme.info,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) async {
              final ok = await showConfirmDialog(
                context,
                title: 'Supprimer',
                message: 'Supprimer "${treatment.name}" ?',
              );
              if (ok) {
                await ref
                    .read(periodicTreatmentNotifierProvider(memberId).notifier)
                    .delete(treatment.id);
              }
            },
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Supprimer',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: treatment.isOverdue ? AppTheme.error.withOpacity(0.4) : AppTheme.divider,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(treatment.treatmentType), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(treatment.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        treatment.typeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: _getStatusLabel(), color: color),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.event_repeat_rounded,
                    label: 'Fréquence',
                    value: 'Tous les ${treatment.frequencyDays}j',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.history_rounded,
                    label: 'Dernière prise',
                    value: AppDateUtils.formatDate(treatment.lastDate),
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.upcoming_rounded,
                    label: 'Prochaine',
                    value: AppDateUtils.formatDate(nextDate),
                    valueColor: color,
                  ),
                ),
              ],
            ),
            if (nextDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppDateUtils.formatDaysUntil(nextDate),
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(PeriodicTreatmentType type) {
    switch (type) {
      case PeriodicTreatmentType.palu: return Icons.bug_report_rounded;
      case PeriodicTreatmentType.deworming: return Icons.pest_control_rounded;
      case PeriodicTreatmentType.vaccine: return Icons.vaccines_rounded;
      case PeriodicTreatmentType.other: return Icons.medication_liquid_rounded;
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
}
