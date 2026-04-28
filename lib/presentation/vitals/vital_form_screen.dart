import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/vital.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/app_widgets.dart';
import 'vital_provider.dart';

class VitalFormScreen extends ConsumerStatefulWidget {
  final String? memberId;
  const VitalFormScreen({super.key, this.memberId});

  @override
  ConsumerState<VitalFormScreen> createState() => _VitalFormScreenState();
}

class _VitalFormScreenState extends ConsumerState<VitalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueCtrl = TextEditingController();
  final _value2Ctrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  VitalType _vitalType = VitalType.temperature;
  DateTime _measuredAt = DateTime.now();
  String? _selectedMemberId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.memberId;
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _value2Ctrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un membre')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final unit = AppConstants.vitalUnits[_vitalType.name] ?? '';

      final vital = Vital(
        id: const Uuid().v4(),
        userId: userId,
        familyMemberId: _selectedMemberId!,
        vitalType: _vitalType,
        value: double.parse(_valueCtrl.text.replaceAll(',', '.')),
        value2: _vitalType == VitalType.bloodPressure && _value2Ctrl.text.isNotEmpty
            ? double.tryParse(_value2Ctrl.text.replaceAll(',', '.'))
            : null,
        unit: unit,
        measuredAt: _measuredAt,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(vitalNotifierProvider(widget.memberId).notifier).create(vital);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesure enregistrée'), backgroundColor: AppTheme.success),
        );
        context.go('/vitals${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);
    final unit = AppConstants.vitalUnits[_vitalType.name] ?? '';
    final isBloodPressure = _vitalType == VitalType.bloodPressure;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle mesure'),
        leading: BackButton(
          onPressed: () => context.go(
            '/vitals${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              membersAsync.when(
                data: (members) => DropdownButtonFormField<String>(
                  value: _selectedMemberId,
                  decoration: const InputDecoration(
                    labelText: 'Membre *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: members
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Row(children: [
                              MemberAvatar(name: m.name, size: 24),
                              const SizedBox(width: 8),
                              Text(m.name),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMemberId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                loading: () => const AppLoadingWidget(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),

              // Type de constante
              DropdownButtonFormField<VitalType>(
                value: _vitalType,
                decoration: const InputDecoration(
                  labelText: 'Type de mesure *',
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
                items: VitalType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeName(t)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _vitalType = v);
                },
              ),
              const SizedBox(height: 16),

              // Valeur
              if (isBloodPressure) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valueCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Systolique *',
                          hintText: 'Ex: 120',
                          suffixText: 'mmHg',
                        ),
                        validator: Validators.positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _value2Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Diastolique',
                          hintText: 'Ex: 80',
                          suffixText: 'mmHg',
                        ),
                        validator: Validators.positiveNumber,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valeur *',
                    hintText: _getHint(),
                    suffixText: unit,
                    prefixIcon: const Icon(Icons.analytics_outlined),
                  ),
                  validator: Validators.positiveNumber,
                ),
              ],
              const SizedBox(height: 16),

              // Date et heure
              InkWell(
                onTap: () async {
                  final date = await showDateTimePicker(context, _measuredAt);
                  if (date != null) setState(() => _measuredAt = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date et heure de mesure',
                    prefixIcon: Icon(Icons.access_time_rounded),
                  ),
                  child: Text(AppDateUtils.formatDateTime(_measuredAt)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Mesure à jeun, après effort...',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Enregistrer la mesure'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _typeName(VitalType t) {
    switch (t) {
      case VitalType.temperature: return 'Température';
      case VitalType.bloodPressure: return 'Tension artérielle';
      case VitalType.glucose: return 'Glycémie';
      case VitalType.weight: return 'Poids';
      case VitalType.height: return 'Taille';
      case VitalType.oxygen: return 'Saturation oxygène';
      case VitalType.heartRate: return 'Fréquence cardiaque';
      case VitalType.other: return 'Autre';
    }
  }

  String _getHint() {
    switch (_vitalType) {
      case VitalType.temperature: return 'Ex: 37.5';
      case VitalType.glucose: return 'Ex: 1.2';
      case VitalType.weight: return 'Ex: 70';
      case VitalType.height: return 'Ex: 175';
      case VitalType.oxygen: return 'Ex: 98';
      case VitalType.heartRate: return 'Ex: 72';
      default: return '';
    }
  }
}
