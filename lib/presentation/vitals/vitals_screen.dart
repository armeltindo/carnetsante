import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/vital.dart';
import '../shared/widgets/app_widgets.dart';
import 'vital_provider.dart';

class VitalsScreen extends ConsumerStatefulWidget {
  final String? memberId;
  const VitalsScreen({super.key, this.memberId});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  VitalType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vitalNotifierProvider(widget.memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Constantes'),
        leading: widget.memberId != null
            ? BackButton(onPressed: () => context.go('/family/${widget.memberId}'))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go(
              '/vitals/new${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
            ),
          ),
        ],
      ),
      body: state.when(
        data: (vitals) {
          if (vitals.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.monitor_heart_outlined,
              title: 'Aucune mesure',
              subtitle: 'Enregistrez température, tension, glycémie...',
              action: ElevatedButton.icon(
                onPressed: () => context.go(
                  '/vitals/new${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une mesure'),
              ),
            );
          }

          // Filtrer par type
          final filtered = _selectedType == null
              ? vitals
              : vitals.where((v) => v.vitalType == _selectedType).toList();

          // Types présents
          final types = vitals.map((v) => v.vitalType).toSet().toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(vitalNotifierProvider(widget.memberId).notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Filtre par type
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _TypeChip(
                        label: 'Tout',
                        selected: _selectedType == null,
                        onTap: () => setState(() => _selectedType = null),
                        color: AppTheme.primary,
                      ),
                      ...types.map((t) => _TypeChip(
                            label: _typeName(t),
                            selected: _selectedType == t,
                            onTap: () => setState(() => _selectedType = t),
                            color: Vital(
                              id: '',
                              userId: '',
                              familyMemberId: '',
                              vitalType: t,
                              value: 0,
                              unit: '',
                              measuredAt: DateTime.now(),
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ).typeColor,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Graphique si type sélectionné et données suffisantes
                if (_selectedType != null && widget.memberId != null && filtered.length >= 2) ...[
                  _VitalChart(vitals: filtered.take(20).toList().reversed.toList()),
                  const SizedBox(height: 16),
                ],

                // Liste des mesures
                ...filtered.map((v) => _VitalCard(
                      vital: v,
                      memberId: widget.memberId,
                    )),
              ],
            ),
          );
        },
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () =>
              ref.read(vitalNotifierProvider(widget.memberId).notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(
          '/vitals/new${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _typeName(VitalType t) {
    switch (t) {
      case VitalType.temperature: return 'Température';
      case VitalType.bloodPressure: return 'Tension';
      case VitalType.glucose: return 'Glycémie';
      case VitalType.weight: return 'Poids';
      case VitalType.height: return 'Taille';
      case VitalType.oxygen: return 'Oxygène';
      case VitalType.heartRate: return 'Cardiaque';
      case VitalType.other: return 'Autre';
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
}

class _VitalChart extends StatelessWidget {
  final List<Vital> vitals;
  const _VitalChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    if (vitals.isEmpty) return const SizedBox();

    final color = vitals.first.typeColor;
    final spots = vitals
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppTheme.divider,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (vitals.length / 4).ceilToDouble(),
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx >= vitals.length) return const SizedBox();
                  return Text(
                    AppDateUtils.formatDate(vitals[idx].measuredAt).substring(0, 5),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeColor: Colors.white,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalCard extends ConsumerWidget {
  final Vital vital;
  final String? memberId;

  const _VitalCard({required this.vital, this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: vital.typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(vital.vitalType), color: vital.typeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vital.typeLabel, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    AppDateUtils.formatDateTime(vital.measuredAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  vital.displayValue,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: vital.typeColor,
                  ),
                ),
                if (vital.notes != null)
                  Text(vital.notes!, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textSecondary),
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Supprimer cette mesure',
                  message: 'Confirmer la suppression ?',
                );
                if (ok) {
                  await ref.read(vitalNotifierProvider(memberId).notifier).delete(vital.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(VitalType t) {
    switch (t) {
      case VitalType.temperature: return Icons.thermostat_rounded;
      case VitalType.bloodPressure: return Icons.favorite_rounded;
      case VitalType.glucose: return Icons.water_drop_rounded;
      case VitalType.weight: return Icons.scale_rounded;
      case VitalType.height: return Icons.height_rounded;
      case VitalType.oxygen: return Icons.air_rounded;
      case VitalType.heartRate: return Icons.monitor_heart_rounded;
      case VitalType.other: return Icons.analytics_rounded;
    }
  }
}
