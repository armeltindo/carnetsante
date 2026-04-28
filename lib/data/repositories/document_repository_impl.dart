import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../local/hive_database.dart';
import '../local/adapters/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final SupabaseClient _supabase;
  static const _table = 'documents';

  DocumentRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  List<MedicalDocument> _fromCache({String? familyMemberId}) {
    var models = HiveDatabase.documents.values.toList();
    if (familyMemberId != null) {
      models = models.where((m) => m.familyMemberId == familyMemberId).toList();
    }
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<MedicalDocument>> getAll({String? familyMemberId}) async {
    try {
      var query = _supabase
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null);

      if (familyMemberId != null) {
        query = query.eq('family_member_id', familyMemberId);
      }

      final data = await query.order('created_at', ascending: false);
      final models = data.map((json) => DocumentModel.fromJson(json)).toList();

      for (final m in models) {
        await HiveDatabase.documents.put(m.id, m);
      }
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return _fromCache(familyMemberId: familyMemberId);
    }
  }

  @override
  Future<MedicalDocument?> getById(String id) async {
    final cached = HiveDatabase.documents.get(id);
    return cached?.toEntity();
  }

  @override
  Future<MedicalDocument> upload({
    required File file,
    required String familyMemberId,
    required String title,
    required DocumentType documentType,
    String? description,
    DateTime? documentDate,
  }) async {
    final id = const Uuid().v4();
    final ext = p.extension(file.path);
    final fileName = '${id}$ext';
    final filePath = '$_userId/$familyMemberId/$fileName';
    final fileBytes = await file.readAsBytes();
    final fileSize = fileBytes.length;
    final mimeType = _getMimeType(ext);

    // Upload vers Supabase Storage
    await _supabase.storage
        .from(AppConstants.storageBucket)
        .uploadBinary(filePath, fileBytes, fileOptions: FileOptions(contentType: mimeType));

    final now = DateTime.now();
    final doc = MedicalDocument(
      id: id,
      userId: _userId,
      familyMemberId: familyMemberId,
      documentType: documentType,
      title: title,
      description: description,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      documentDate: documentDate,
      createdAt: now,
      updatedAt: now,
    );

    final model = DocumentModel.fromEntity(doc);
    await HiveDatabase.documents.put(model.id, model);
    await _supabase.from(_table).insert(model.toJson());

    return doc;
  }

  @override
  Future<void> delete(String id) async {
    final doc = await getById(id);
    if (doc != null) {
      try {
        await _supabase.storage
            .from(AppConstants.storageBucket)
            .remove([doc.filePath]);
        await _supabase
            .from(_table)
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id);
      } catch (_) {}
    }
    await HiveDatabase.documents.delete(id);
  }

  @override
  Future<String> getDownloadUrl(String filePath) async {
    return _supabase.storage
        .from(AppConstants.storageBucket)
        .createSignedUrl(filePath, 3600); // 1 heure
  }

  @override
  Stream<List<MedicalDocument>> watchAll({String? familyMemberId}) {
    return HiveDatabase.documents.watch().map(
      (_) => _fromCache(familyMemberId: familyMemberId),
    ).asBroadcastStream();
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      case '.pdf': return 'application/pdf';
      case '.heic': return 'image/heic';
      default: return 'application/octet-stream';
    }
  }
}
