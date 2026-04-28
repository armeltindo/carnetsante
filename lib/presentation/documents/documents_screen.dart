import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_date_utils.dart';
import '../../domain/entities/document.dart';
import '../shared/providers/app_providers.dart';
import '../shared/widgets/app_widgets.dart';

final _documentsProvider = FutureProvider.family<List<MedicalDocument>, String?>((ref, memberId) async {
  return ref.watch(documentRepositoryProvider).getAll(familyMemberId: memberId);
});

class DocumentsScreen extends ConsumerStatefulWidget {
  final String? memberId;
  const DocumentsScreen({super.key, this.memberId});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  bool _isUploading = false;

  Future<void> _uploadFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) _showUploadDialog(File(image.path));
  }

  Future<void> _uploadFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) _showUploadDialog(File(image.path));
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      _showUploadDialog(File(result.files.single.path!));
    }
  }

  Future<void> _showUploadDialog(File file) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DocumentType type = DocumentType.prescription;
    DateTime? docDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Informations du document'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DocumentType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: DocumentType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_typeLabel(t)),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v ?? DocumentType.other),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setDialogState(() => docDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date du document'),
                    child: Text(
                      docDate != null ? AppDateUtils.formatDate(docDate) : 'Sélectionner',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Uploader'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && titleCtrl.text.trim().isNotEmpty) {
      setState(() => _isUploading = true);
      try {
        final memberId = widget.memberId ?? '';
        await ref.read(documentRepositoryProvider).upload(
              file: file,
              familyMemberId: memberId,
              title: titleCtrl.text.trim(),
              documentType: type,
              description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              documentDate: docDate,
            );
        ref.invalidate(_documentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document ajouté'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(ctx); _uploadFromCamera(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.secondary),
              title: const Text('Choisir dans la galerie'),
              onTap: () { Navigator.pop(ctx); _uploadFromGallery(); },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded, color: AppTheme.info),
              title: const Text('Importer un fichier (PDF)'),
              onTap: () { Navigator.pop(ctx); _uploadFile(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_documentsProvider(widget.memberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents médicaux'),
        leading: widget.memberId != null
            ? BackButton(onPressed: () => context.go('/family/${widget.memberId}'))
            : null,
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _isUploading ? null : _showAddOptions,
          ),
        ],
      ),
      body: state.when(
        data: (docs) => docs.isEmpty
            ? EmptyStateWidget(
                icon: Icons.folder_open_outlined,
                title: 'Aucun document',
                subtitle: 'Ajoutez ordonnances, analyses, rapports médicaux...',
                action: ElevatedButton.icon(
                  onPressed: _showAddOptions,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un document'),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: docs.length,
                itemBuilder: (_, i) => _DocumentCard(
                  doc: docs[i],
                  memberId: widget.memberId,
                ),
              ),
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _typeLabel(DocumentType t) {
    switch (t) {
      case DocumentType.prescription: return 'Ordonnance';
      case DocumentType.analysis: return 'Analyse';
      case DocumentType.xray: return 'Radiographie';
      case DocumentType.report: return 'Compte-rendu';
      case DocumentType.vaccineCard: return 'Carnet vaccinal';
      case DocumentType.other: return 'Autre';
    }
  }
}

class _DocumentCard extends ConsumerWidget {
  final MedicalDocument doc;
  final String? memberId;

  const _DocumentCard({required this.doc, this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _typeColor(doc.documentType);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Icon(
                  doc.isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                  size: 48,
                  color: color,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(label: doc.typeLabel, color: color),
                    Text(doc.fileSizeLabel, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                if (doc.documentDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.formatDate(doc.documentDate),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                      onPressed: () async {
                        final ok = await showConfirmDialog(
                          context,
                          title: 'Supprimer "${doc.title}"',
                          message: 'Ce document sera définitivement supprimé.',
                        );
                        if (ok) {
                          await ref.read(documentRepositoryProvider).delete(doc.id);
                          ref.invalidate(_documentsProvider);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(DocumentType t) {
    switch (t) {
      case DocumentType.prescription: return AppTheme.primary;
      case DocumentType.analysis: return AppTheme.secondary;
      case DocumentType.xray: return AppTheme.bloodPressure;
      case DocumentType.report: return AppTheme.warning;
      case DocumentType.vaccineCard: return AppTheme.info;
      case DocumentType.other: return AppTheme.textSecondary;
    }
  }
}
