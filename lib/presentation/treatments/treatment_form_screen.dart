import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/family_member.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/app_widgets.dart';
import 'treatment_provider.dart';

class TreatmentFormScreen extends ConsumerStatefulWidget {
  final String? treatmentId;
  final String? memberId;
  const TreatmentFormScreen({super.key, this.treatmentId, this.memberId});

  @override
  ConsumerState<TreatmentFormScreen> createState() => _TreatmentFormScreenState();
}

class _TreatmentFormScreenState extends ConsumerState<TreatmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int? _freqHours;
  String? _selectedMemberId;
  bool _isLoading = false;
  bool _isActive = true;
  Treatment? _existing;

  bool get _isEdit => widget.treatmentId != null;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.memberId;
    if (_isEdit) _loadTreatment();
  }

  Future<void> _loadTreatment() async {
    final t = await ref.read(treatmentRepositoryProvider).getById(widget.treatmentId!);
    if (t != null && mounted) {
      setState(() {
        _existing = t;
        _nameCtrl.text = t.medicationName;
        _dosageCtrl.text = t.dosage ?? '';
        _freqCtrl.text = t.frequency ?? '';
        _instrCtrl.text = t.instructions ?? '';
        _startDate = t.startDate;
        _endDate = t.endDate;
        _freqHours = t.frequencyHours;
        _selectedMemberId = t.familyMemberId;
        _isActive = t.isActive;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _instrCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        if (isStart) _startDate = date;
        else _endDate = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un membre de la famille')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final treatment = Treatment(
        id: _existing?.id ?? const Uuid().v4(),
        userId: userId,
        familyMemberId: _selectedMemberId!,
        medicationName: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
        frequency: _freqCtrl.text.trim().isEmpty ? null : _freqCtrl.text.trim(),
        frequencyHours: _freqHours,
        startDate: _startDate,
        endDate: _endDate,
        instructions: _instrCtrl.text.trim().isEmpty ? null : _instrCtrl.text.trim(),
        isActive: _isActive,
        createdAt: _existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final notifier = ref.read(treatmentNotifierProvider(widget.memberId).notifier);
      if (_isEdit) {
        await notifier.update(treatment);
      } else {
        await notifier.create(treatment);
      }

      // Planifier notification si fréquence définie
      if (treatment.frequencyHours != null) {
        await ref.read(notificationServiceProvider).scheduleMedicationReminder(
          medicationName: treatment.medicationName,
          memberName: _selectedMemberId!,
          startDate: treatment.startDate,
          endDate: treatment.endDate,
          intervalHours: treatment.frequencyHours,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Traitement modifié' : 'Traitement ajouté'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/treatments${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le traitement' : 'Nouveau traitement'),
        leading: BackButton(
          onPressed: () => context.go(
            '/treatments${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
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
                    labelText: 'Membre de la famille *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: members
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Row(
                              children: [
                                MemberAvatar(name: m.name, size: 24),
                                const SizedBox(width: 8),
                                Text(m.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedMemberId = v),
                  validator: (v) => v == null ? 'Sélectionnez un membre' : null,
                ),
                loading: () => const AppLoadingWidget(),
                error: (_, __) => const Text('Erreur chargement membres'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du médicament *',
                  prefixIcon: Icon(Icons.medication_rounded),
                ),
                validator: (v) => Validators.required(v, 'Le médicament'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'Ex: 500mg, 1 comprimé',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _freqCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fréquence',
                  hintText: 'Ex: 2x/jour, matin et soir',
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Intervalle heures pour notification
              DropdownButtonFormField<int?>(
                value: _freqHours,
                decoration: const InputDecoration(
                  labelText: 'Rappel automatique',
                  prefixIcon: Icon(Icons.alarm_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Pas de rappel')),
                  DropdownMenuItem(value: 6, child: Text('Toutes les 6h')),
                  DropdownMenuItem(value: 8, child: Text('Toutes les 8h')),
                  DropdownMenuItem(value: 12, child: Text('Toutes les 12h')),
                  DropdownMenuItem(value: 24, child: Text('1 fois par jour')),
                ],
                onChanged: (v) => setState(() => _freqHours = v),
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Début *',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(AppDateUtils.formatDate(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fin',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: _endDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(() => _endDate = null),
                                )
                              : null,
                        ),
                        child: Text(
                          _endDate != null ? AppDateUtils.formatDate(_endDate) : 'Indéfinie',
                          style: TextStyle(
                            color: _endDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _instrCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'Prendre avec de l\'eau, éviter avec...',
                  prefixIcon: Icon(Icons.info_outline),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Traitement actif'),
                contentPadding: EdgeInsets.zero,
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
                      : Text(_isEdit ? 'Enregistrer' : 'Ajouter le traitement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
