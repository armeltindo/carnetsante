import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/entities/periodic_treatment.dart';
import '../auth/auth_provider.dart';
import '../family/family_provider.dart';
import '../periodic_treatments/periodic_treatment_provider.dart';
import '../shared/widgets/app_widgets.dart';
import '../shared/providers/app_providers.dart';
import '../../services/sync_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final membersAsync = ref.watch(familyMembersProvider);
    final periodicAsync = ref.watch(periodicTreatmentsProvider(null));
    final syncService = ref.watch(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour ${user?.userMetadata?['name'] ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              AppDateUtils.formatShort(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Synchroniser',
            onPressed: () async {
              final result = await syncService.syncAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? AppTheme.success : AppTheme.error,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Déconnexion',
                message: 'Voulez-vous vous déconnecter ?',
                confirmLabel: 'Déconnecter',
                confirmColor: AppTheme.primary,
              );
              if (confirm && context.mounted) {
                await ref.read(authProvider.notifier).signOut();
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats rapides
            _QuickStats(membersAsync: membersAsync, periodicAsync: periodicAsync),
            const SizedBox(height: 24),

            // Actions rapides
            Text('Actions rapides', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            _QuickActions(),
            const SizedBox(height: 24),

            // Famille
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ma Famille', style: Theme.of(context).textTheme.headlineSmall),
                TextButton(
                  onPressed: () => context.go('/family'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            membersAsync.when(
              data: (members) => members.isEmpty
                  ? const _AddFamilyCard()
                  : SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: members.length > 5 ? 5 : members.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => _MemberChip(member: members[i]),
                      ),
                    ),
              loading: () => const AppLoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
            const SizedBox(height: 24),

            // Traitements périodiques à venir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('À venir', style: Theme.of(context).textTheme.headlineSmall),
                TextButton(
                  onPressed: () => context.go('/periodic-treatments'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            periodicAsync.when(
              data: (treatments) {
                final upcoming = treatments
                    .where((t) => t.isOverdue || t.isDueSoon)
                    .take(3)
                    .toList();
                if (upcoming.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Aucun traitement imminent', style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }
                return Column(
                  children: upcoming
                      .map((t) => _PeriodicTreatmentCard(treatment: t))
                      .toList(),
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final AsyncValue membersAsync;
  final AsyncValue periodicAsync;

  const _QuickStats({required this.membersAsync, required this.periodicAsync});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            label: 'Membres',
            value: membersAsync.when(
              data: (m) => '${(m as List).length}',
              loading: () => '--',
              error: (_, __) => '--',
            ),
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_rounded,
            label: 'En retard',
            value: periodicAsync.when(
              data: (t) => '${(t as List<PeriodicTreatment>).where((x) => x.isOverdue).length}',
              loading: () => '--',
              error: (_, __) => '--',
            ),
            color: AppTheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.notifications_rounded,
            label: 'À venir',
            value: periodicAsync.when(
              data: (t) => '${(t as List<PeriodicTreatment>).where((x) => x.isDueSoon).length}',
              loading: () => '--',
              error: (_, __) => '--',
            ),
            color: AppTheme.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.medication_rounded, 'Traitement', '/treatments/new', AppTheme.primary),
      (Icons.healing_rounded, 'Périodique', '/periodic-treatments/new', AppTheme.secondary),
      (Icons.monitor_heart_rounded, 'Constante', '/vitals/new', AppTheme.bloodPressure),
      (Icons.history_edu_rounded, 'Dossier', '/medical-history/new', AppTheme.warning),
      (Icons.folder_open_rounded, 'Document', '/documents', AppTheme.accent),
      (Icons.alarm_rounded, 'Rappel', '/reminders', AppTheme.info),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actions.map((a) => _ActionButton(
        icon: a.$1,
        label: a.$2,
        path: a.$3,
        color: a.$4,
      )).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.path,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AddFamilyCard extends StatelessWidget {
  const _AddFamilyCard();

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.go('/family/new'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3), style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter un membre',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Commencez par ajouter votre famille',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _MemberChip extends StatelessWidget {
  final FamilyMember member;
  const _MemberChip({required this.member});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go('/family/${member.id}'),
        child: Column(
          children: [
            MemberAvatar(name: member.name, avatarUrl: member.avatarUrl, size: 56),
            const SizedBox(height: 6),
            Text(
              member.name.split(' ').first,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

class _PeriodicTreatmentCard extends StatelessWidget {
  final PeriodicTreatment treatment;
  const _PeriodicTreatmentCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    final nextDate = treatment.nextDate ?? treatment.calculatedNextDate;
    final isOverdue = treatment.isOverdue;
    final color = isOverdue ? AppTheme.error : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medication_liquid_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(treatment.name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  treatment.typeLabel,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                label: isOverdue ? 'En retard' : 'Bientôt',
                color: color,
              ),
              if (nextDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppDateUtils.formatDate(nextDate),
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
