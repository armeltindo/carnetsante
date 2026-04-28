import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/treatment.dart';
import '../shared/widgets/app_widgets.dart';
import 'treatment_provider.dart';

class TreatmentsScreen extends ConsumerWidget {
  final String? memberId;
  const TreatmentsScreen({super.key, this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(treatmentNotifierProvider(memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traitements'),
        leading: memberId != null
            ? BackButton(onPressed: () => context.go('/family/$memberId'))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go(
              '/treatments/new${memberId != null ? '?memberId=$memberId' : ''}',
            ),
          ),
        ],
      ),
      body: state.when(
        data: (treatments) {
          if (treatments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.medication_outlined,
              title: 'Aucun traitement',
              subtitle: 'Ajoutez les traitements en cours',
              action: ElevatedButton.icon(
                onPressed: () => context.go(
                  '/treatments/new${memberId != null ? '?memberId=$memberId' : ''}',
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            );
          }

          final active = treatments.where((t) => t.isOngoing).toList();
          final inactive = treatments.where((t) => !t.isOngoing).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(treatmentNotifierProvider(memberId).notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  SectionHeader(title: 'EN COURS (${active.length})'),
                  const SizedBox(height: 8),
                  ...active.map((t) => _TreatmentCard(treatment: t, memberId: memberId)),
                ],
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionHeader(title: 'TERMINÉS / INACTIFS (${inactive.length})'),
                  const SizedBox(height: 8),
                  ...inactive.map((t) => _TreatmentCard(treatment: t, memberId: memberId, dimmed: true)),
                ],
              ],
            ),
          );
        },
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(treatmentNotifierProvider(memberId).notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(
          '/treatments/new${memberId != null ? '?memberId=$memberId' : ''}',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TreatmentCard extends ConsumerWidget {
  final Treatment treatment;
  final String? memberId;
  final bool dimmed;

  const _TreatmentCard({
    required this.treatment,
    this.memberId,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => context.go(
                '/treatments/${treatment.id}/edit${memberId != null ? '?memberId=$memberId' : ''}',
              ),
              backgroundColor: AppTheme.info,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Modifier',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
            SlidableAction(
              onPressed: (_) async {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Supprimer ce traitement',
                  message: 'Confirmer la suppression de "${treatment.medicationName}" ?',
                );
                if (confirm) {
                  await ref.read(treatmentNotifierProvider(memberId).notifier).delete(treatment.id);
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
        child: Opacity(
          opacity: dimmed ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medication_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            treatment.medicationName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (treatment.dosage != null)
                            Text(
                              treatment.dosage!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: treatment.isOngoing ? 'Actif' : 'Terminé',
                      color: treatment.isOngoing ? AppTheme.success : AppTheme.textSecondary,
                    ),
                  ],
                ),
                if (treatment.frequency != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(treatment.frequency!, style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${AppDateUtils.formatDate(treatment.startDate)} → ${treatment.endDate != null ? AppDateUtils.formatDate(treatment.endDate) : "En cours"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
