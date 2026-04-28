import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/family_member.dart';
import 'family_provider.dart';

class FamilyMemberFormScreen extends ConsumerStatefulWidget {
  final String? memberId;
  const FamilyMemberFormScreen({super.key, this.memberId});

  @override
  ConsumerState<FamilyMemberFormScreen> createState() =>
      _FamilyMemberFormScreenState();
}

class _FamilyMemberFormScreenState extends ConsumerState<FamilyMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  String? _bloodType;
  List<String> _allergies = [];
  bool _isMain = false;
  bool _isLoading = false;
  FamilyMember? _existing;

  bool get _isEdit => widget.memberId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadMember();
  }

  Future<void> _loadMember() async {
    final member = await ref.read(familyMemberRepositoryProvider).getById(widget.memberId!);
    if (member != null && mounted) {
      setState(() {
        _existing = member;
        _nameCtrl.text = member.name;
        _notesCtrl.text = member.medicalNotes ?? '';
        _dateOfBirth = member.dateOfBirth;
        _bloodType = member.bloodType;
        _allergies = List.from(member.allergies);
        _isMain = member.isMain;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr'),
    );
    if (date != null) setState(() => _dateOfBirth = date);
  }

  void _addAllergy() {
    final text = _allergyCtrl.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() {
        _allergies.add(text);
        _allergyCtrl.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final member = FamilyMember(
        id: _existing?.id ?? const Uuid().v4(),
        userId: userId,
        name: _nameCtrl.text.trim(),
        dateOfBirth: _dateOfBirth,
        bloodType: _bloodType,
        allergies: _allergies,
        medicalNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isMain: _isMain,
        createdAt: _existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEdit) {
        await ref.read(familyNotifierProvider.notifier).update(member);
      } else {
        await ref.read(familyNotifierProvider.notifier).create(member);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Membre modifié' : 'Membre ajouté'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/family');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le membre' : 'Nouveau membre'),
        leading: BackButton(onPressed: () => context.go('/family')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar placeholder
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, size: 40, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, 'Le nom'),
              ),
              const SizedBox(height: 16),

              // Date de naissance
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(
                    _dateOfBirth != null
                        ? AppDateUtils.formatDate(_dateOfBirth)
                        : 'Sélectionner',
                    style: TextStyle(
                      color: _dateOfBirth != null
                          ? AppTheme.textPrimary
                          : AppTheme.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Groupe sanguin
              DropdownButtonFormField<String>(
                value: _bloodType,
                decoration: const InputDecoration(
                  labelText: 'Groupe sanguin',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                items: AppConstants.bloodTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v),
              ),
              const SizedBox(height: 16),

              // Allergies
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _allergyCtrl,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _addAllergy(),
                      decoration: const InputDecoration(
                        labelText: 'Allergie',
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                        hintText: 'Pénicilline, lactose...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addAllergy,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (_allergies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allergies
                      .map((a) => Chip(
                            label: Text(a),
                            backgroundColor: AppTheme.error.withOpacity(0.08),
                            labelStyle: const TextStyle(color: AppTheme.error, fontSize: 12),
                            deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.error),
                            onDeleted: () => setState(() => _allergies.remove(a)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Antécédents médicaux',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                value: _isMain,
                onChanged: (v) => setState(() => _isMain = v),
                title: const Text('Membre principal'),
                subtitle: const Text('Utilisateur principal de l\'application'),
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
                      : Text(_isEdit ? 'Enregistrer' : 'Ajouter le membre'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
