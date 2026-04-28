import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/family_member.dart';
import '../shared/widgets/app_widgets.dart';
import 'family_provider.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Famille'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/family/new'),
          ),
        ],
      ),
      body: state.when(
        data: (members) => members.isEmpty
            ? EmptyStateWidget(
                icon: Icons.people_outline,
                title: 'Aucun membre',
                subtitle: 'Ajoutez les membres de votre famille pour commencer',
                action: ElevatedButton.icon(
                  onPressed: () => context.go('/family/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un membre'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(familyNotifierProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _FamilyMemberCard(member: members[i]),
                ),
              ),
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(familyNotifierProvider.notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/family/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FamilyMemberCard extends ConsumerWidget {
  final FamilyMember member;
  const _FamilyMemberCard({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => context.go('/family/${member.id}/edit'),
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
                title: 'Supprimer ${member.name}',
                message: 'Toutes les données associées seront supprimées. Confirmer ?',
              );
              if (confirm) {
                await ref.read(familyNotifierProvider.notifier).delete(member.id);
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
      child: InkWell(
        onTap: () => context.go('/family/${member.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              MemberAvatar(name: member.name, avatarUrl: member.avatarUrl, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (member.isMain) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (member.dateOfBirth != null) ...[
                          const Icon(Icons.cake_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            AppDateUtils.formatAge(member.dateOfBirth),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (member.bloodType != null) ...[
                          const Icon(Icons.bloodtype_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            member.bloodType!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    if (member.allergies.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: member.allergies
                            .take(3)
                            .map((a) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    a,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
