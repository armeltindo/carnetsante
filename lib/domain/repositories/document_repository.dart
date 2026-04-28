import 'dart:io';
import '../entities/document.dart';

abstract class DocumentRepository {
  Future<List<MedicalDocument>> getAll({String? familyMemberId});
  Future<MedicalDocument?> getById(String id);
  Future<MedicalDocument> upload({
    required File file,
    required String familyMemberId,
    required String title,
    required DocumentType documentType,
    String? description,
    DateTime? documentDate,
  });
  Future<void> delete(String id);
  Future<String> getDownloadUrl(String filePath);
  Stream<List<MedicalDocument>> watchAll({String? familyMemberId});
}
