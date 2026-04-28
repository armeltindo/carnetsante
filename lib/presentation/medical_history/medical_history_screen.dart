import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/medical_record.dart';
import '../shared/widgets/app_widgets.dart';
import 'medical_record_provider.dart';

class MedicalHistoryScreen extends ConsumerWidget {
  final String? memberId;
  const MedicalHistoryScreen({super.key, this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicalRecordNotifierProvider(memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique médical'),
        leading: memberId != null
            ? BackButton(onPressed: () => context.go('/family/$memberId'))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go(
              '/medical-history/new${memberId != null ? '?memberId=$memberId' : ''}',
            ),
          ),
        ],
      ),
      body: state.when(
        data: (records) => records.isEmpty
            ? EmptyStateWidget(
                icon: Icons.history_edu_outlined,
                title: 'Aucun dossier médical',
                subtitle: 'Enregistrez les consultations et diagnostics',
                action: ElevatedButton.icon(
                  onPressed: () => context.go(
                    '/medical-history/new${memberId != null ? '?memberId=$memberId' : ''}',
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(medicalRecordNotifierProvider(memberId).notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _RecordCard(record: records[i], memberId: memberId),
                ),
              ),
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(medicalRecordNotifierProvider(memberId).notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(
          '/medical-history/new${memberId != null ? '?memberId=$memberId' : ''}',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecordCard extends ConsumerWidget {
  final MedicalRecord record;
  final String? memberId;

  const _RecordCard({required this.record, this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => context.go(
              '/medical-history/${record.id}/edit${memberId != null ? '?memberId=$memberId' : ''}',
            ),
            backgroundColor: AppTheme.info,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Modifier',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          ),
          SlidableAction(
            onPressed: (_) async {
              final ok = await showConfirmDialog(
                context,
                title: 'Supprimer ce dossier',
                message: 'Cette action est irréversible',
              );
              if (ok) {
                await ref.read(medicalRecordNotifierProvider(memberId).notifier).delete(record.id);
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
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête: date + médecin
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medical_information_rounded,
                      color: AppTheme.warning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.formatShort(record.recordDate),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (record.doctorName != null || record.clinicName != null)
                        Text(
                          [record.doctorName, record.clinicName]
                              .where((s) => s != null)
                              .join(' • '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Text(
                  AppDateUtils.formatRelative(record.recordDate),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),

            if (record.diagnosis != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_hospital_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      record.diagnosis!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ],

            if (record.symptoms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: record.symptoms
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(fontSize: 11, color: AppTheme.info),
                          ),
                        ))
                    .toList(),
              ),
            ],

            if (record.treatment != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.medication_rounded, size: 14, color: AppTheme.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      record.treatment!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
