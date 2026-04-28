import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../shared/widgets/app_widgets.dart';
import 'family_provider.dart';

class FamilyMemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const FamilyMemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(familyMemberProvider(memberId));

    return memberAsync.when(
      data: (member) {
        if (member == null) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.go('/family'))),
            body: const AppErrorWidget(message: 'Membre introuvable'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(member.name),
            leading: BackButton(onPressed: () => context.go('/family')),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go('/family/${member.id}/edit'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                Center(
                  child: Column(
                    children: [
                      MemberAvatar(name: member.name, avatarUrl: member.avatarUrl, size: 80),
                      const SizedBox(height: 12),
                      Text(member.name, style: Theme.of(context).textTheme.headlineSmall),
                      if (member.dateOfBirth != null)
                        Text(
                          AppDateUtils.formatAge(member.dateOfBirth),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Infos médicales
                InfoCard(
                  icon: Icons.bloodtype_outlined,
                  label: 'Groupe sanguin',
                  value: member.bloodType ?? 'Non renseigné',
                  iconColor: AppTheme.error,
                ),
                const SizedBox(height: 10),
                InfoCard(
                  icon: Icons.cake_outlined,
                  label: 'Date de naissance',
                  value: member.dateOfBirth != null
                      ? AppDateUtils.formatDate(member.dateOfBirth)
                      : 'Non renseignée',
                  iconColor: AppTheme.secondary,
                ),

                if (member.allergies.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Allergies', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: member.allergies
                        .map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 14, color: AppTheme.error),
                                  const SizedBox(width: 6),
                                  Text(
                                    a,
                                    style: const TextStyle(
                                        color: AppTheme.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],

                if (member.medicalNotes != null && member.medicalNotes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Antécédents', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Text(member.medicalNotes!),
                  ),
                ],

                const SizedBox(height: 24),
                Text('Accès rapide', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                _ShortcutGrid(memberId: member.id),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/family'))),
        body: const AppLoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/family'))),
        body: AppErrorWidget(message: e.toString()),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  final String memberId;
  const _ShortcutGrid({required this.memberId});

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      (Icons.medication_rounded, 'Traitements', '/treatments?memberId=$memberId', AppTheme.primary),
      (Icons.medication_liquid_rounded, 'Périodiques', '/periodic-treatments?memberId=$memberId', AppTheme.secondary),
      (Icons.history_edu_rounded, 'Historique', '/medical-history?memberId=$memberId', AppTheme.warning),
      (Icons.monitor_heart_rounded, 'Constantes', '/vitals?memberId=$memberId', AppTheme.bloodPressure),
      (Icons.folder_rounded, 'Documents', '/documents?memberId=$memberId', AppTheme.info),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: shortcuts
          .map((s) => InkWell(
                onTap: () => context.go(s.$3),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: s.$4.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: s.$4.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(s.$1, color: s.$4, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        s.$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: s.$4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
