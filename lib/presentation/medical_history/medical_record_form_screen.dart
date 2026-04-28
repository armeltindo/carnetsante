import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/medical_record.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/app_widgets.dart';
import 'medical_record_provider.dart';

class MedicalRecordFormScreen extends ConsumerStatefulWidget {
  final String? recordId;
  final String? memberId;
  const MedicalRecordFormScreen({super.key, this.recordId, this.memberId});

  @override
  ConsumerState<MedicalRecordFormScreen> createState() =>
      _MedicalRecordFormScreenState();
}

class _MedicalRecordFormScreenState extends ConsumerState<MedicalRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _symptomCtrl = TextEditingController();

  DateTime _recordDate = DateTime.now();
  List<String> _symptoms = [];
  String? _selectedMemberId;
  bool _isLoading = false;
  MedicalRecord? _existing;

  bool get _isEdit => widget.recordId != null;

  @override
  void initState() {
    super.initState();
    _selectedMemberId = widget.memberId;
    if (_isEdit) _loadRecord();
  }

  Future<void> _loadRecord() async {
    final r = await ref.read(medicalRecordRepositoryProvider).getById(widget.recordId!);
    if (r != null && mounted) {
      setState(() {
        _existing = r;
        _diagnosisCtrl.text = r.diagnosis ?? '';
        _treatmentCtrl.text = r.treatment ?? '';
        _doctorCtrl.text = r.doctorName ?? '';
        _clinicCtrl.text = r.clinicName ?? '';
        _notesCtrl.text = r.notes ?? '';
        _recordDate = r.recordDate;
        _symptoms = List.from(r.symptoms);
        _selectedMemberId = r.familyMemberId;
      });
    }
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _treatmentCtrl.dispose();
    _doctorCtrl.dispose();
    _clinicCtrl.dispose();
    _notesCtrl.dispose();
    _symptomCtrl.dispose();
    super.dispose();
  }

  void _addSymptom() {
    final text = _symptomCtrl.text.trim();
    if (text.isNotEmpty && !_symptoms.contains(text)) {
      setState(() {
        _symptoms.add(text);
        _symptomCtrl.clear();
      });
    }
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
      final record = MedicalRecord(
        id: _existing?.id ?? const Uuid().v4(),
        userId: userId,
        familyMemberId: _selectedMemberId!,
        recordDate: _recordDate,
        symptoms: _symptoms,
        diagnosis: _diagnosisCtrl.text.trim().isEmpty ? null : _diagnosisCtrl.text.trim(),
        treatment: _treatmentCtrl.text.trim().isEmpty ? null : _treatmentCtrl.text.trim(),
        doctorName: _doctorCtrl.text.trim().isEmpty ? null : _doctorCtrl.text.trim(),
        clinicName: _clinicCtrl.text.trim().isEmpty ? null : _clinicCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: _existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final notifier = ref.read(medicalRecordNotifierProvider(widget.memberId).notifier);
      if (_isEdit) {
        await notifier.update(record);
      } else {
        await notifier.create(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Dossier modifié' : 'Dossier ajouté'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go(
          '/medical-history${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le dossier' : 'Nouveau dossier médical'),
        leading: BackButton(
          onPressed: () => context.go(
            '/medical-history${widget.memberId != null ? '?memberId=${widget.memberId}' : ''}',
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

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _recordDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _recordDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de consultation *',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(AppDateUtils.formatDate(_recordDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Symptômes
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _symptomCtrl,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _addSymptom(),
                      decoration: const InputDecoration(
                        labelText: 'Symptôme',
                        prefixIcon: Icon(Icons.sick_outlined),
                        hintText: 'Fièvre, toux, douleurs...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _addSymptom, icon: const Icon(Icons.add)),
                ],
              ),
              if (_symptoms.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _symptoms
                      .map((s) => Chip(
                            label: Text(s),
                            backgroundColor: AppTheme.info.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppTheme.info, fontSize: 12),
                            deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.info),
                            onDeleted: () => setState(() => _symptoms.remove(s)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _diagnosisCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Diagnostic',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _treatmentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Traitement prescrit',
                  prefixIcon: Icon(Icons.medication_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _doctorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Médecin',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _clinicCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Établissement',
                        prefixIcon: Icon(Icons.local_hospital_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes complémentaires',
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
                      : Text(_isEdit ? 'Enregistrer' : 'Ajouter le dossier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
