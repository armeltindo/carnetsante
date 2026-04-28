import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/periodic_treatment.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/app_widgets.dart';
import 'periodic_treatment_provider.dart';

class PeriodicTreatmentFormScreen extends ConsumerStatefulWidget {
  final String? treatmentId;
  final String? memberId;
  const PeriodicTreatmentFormScreen({super.key, this.treatmentId, this.memberId});

  @override
  ConsumerState<PeriodicTreatmentFormScreen> createState() =>
      _PeriodicTreatmentFormScreenState();
}

class _PeriodicTreatmentFormScreenState
    extends ConsumerState<PeriodicTreatmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  PeriodicTreatmentType _type = PeriodicTreatmentType.palu;
  int _frequencyDays = 30;
  DateTime? _lastDate;
  String? _selectedMemberId;
  bool _isLoading = false;
  PeriodicTreatment? _existing;

  bool get _isEdit => widget.treatmentId != null;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.memberId;
    if (_isEdit) _loadTreatment();
  }

  Future<void> _loadTreatment() async {
    final t = await ref.read(periodicTreatmentRepositoryProvider).getById(widget.treatmentId!);
    if (t != null && mounted) {
      setState(() {
        _existing = t;
        _nameCtrl.text = t.name;
        _notesCtrl.text = t.notes ?? '';
        _type = t.treatmentType;
        _frequencyDays = t.frequencyDays;
        _lastDate = t.lastDate;
        _selectedMemberId = t.familyMemberId;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLastDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lastDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _lastDate = date);
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
      final nextDate = _lastDate != null
          ? _lastDate!.add(Duration(days: _frequencyDays))
          : null;

      final treatment = PeriodicTreatment(
        id: _existing?.id ?? const Uuid().v4(),
        userId: userId,
        familyMemberId: _selectedMemberId!,
        treatmentType: _type,
        name: _nameCtrl.text.trim(),
        frequencyDays: _frequencyDays,
        lastDate: _lastDate,
        nextDate: nextDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isActive: true,
        createdAt: _existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final notifier = ref.read(periodicTreatmentNotifierProvider(widget.memberId).notifier);
      if (_isEdit) {
        await notifier.update(treatment);
      } else {
        await notifier.create(treatment);
      }

      // Planifier notification si prochaine date dans le futur
      if (nextDate != null && nextDate.isAfter(DateTime.now())) {
        await ref.read(notificationServiceProvider).schedulePeriodicReminder(
          treatmentName: treatment.name,
          memberName: _selectedMemberId!,
          nextDate: nextDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Traitement modifié' : 'Traitement ajouté'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go(
          '/periodic-treatments${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
        );
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
    final nextDate = _lastDate != null
        ? _lastDate!.add(Duration(days: _frequencyDays))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier' : 'Traitement périodique'),
        leading: BackButton(
          onPressed: () => context.go(
            '/periodic-treatments${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
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
              // Membre
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

              // Type
              DropdownButtonFormField<PeriodicTreatmentType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Type de traitement *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: PeriodicTreatmentType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _type = v;
                      if (_nameCtrl.text.isEmpty) {
                        _nameCtrl.text = _typeLabel(v);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du traitement *',
                  prefixIcon: Icon(Icons.medication_liquid_rounded),
                ),
                validator: (v) => Validators.required(v, 'Le nom'),
              ),
              const SizedBox(height: 16),

              // Fréquence
              DropdownButtonFormField<int>(
                value: _frequencyDays,
                decoration: const InputDecoration(
                  labelText: 'Fréquence *',
                  prefixIcon: Icon(Icons.event_repeat_rounded),
                ),
                items: AppConstants.periodicFrequencies.entries
                    .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                    .toList(),
                onChanged: (v) => setState(() => _frequencyDays = v ?? 30),
              ),
              const SizedBox(height: 16),

              // Dernière prise
              InkWell(
                onTap: _pickLastDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Dernière prise',
                    prefixIcon: const Icon(Icons.history_rounded),
                    suffixIcon: _lastDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _lastDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _lastDate != null
                        ? AppDateUtils.formatDate(_lastDate)
                        : 'Jamais effectué',
                    style: TextStyle(
                      color: _lastDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                    ),
                  ),
                ),
              ),

              // Prochaine date calculée
              if (nextDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upcoming_rounded, color: AppTheme.secondary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Prochaine: ${AppDateUtils.formatDate(nextDate)} (${AppDateUtils.formatDaysUntil(nextDate)})',
                        style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
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
                      : Text(_isEdit ? 'Enregistrer' : 'Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(PeriodicTreatmentType t) {
    switch (t) {
      case PeriodicTreatmentType.palu: return 'Antipaludique';
      case PeriodicTreatmentType.deworming: return 'Déparasitage';
      case PeriodicTreatmentType.vaccine: return 'Vaccin';
      case PeriodicTreatmentType.other: return 'Autre';
    }
  }
}
