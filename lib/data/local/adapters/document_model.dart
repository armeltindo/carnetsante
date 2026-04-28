import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/document.dart';

part 'document_model.g.dart';

@HiveType(typeId: AppConstants.documentTypeId)
class DocumentModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String userId;
  @HiveField(2) late String familyMemberId;
  @HiveField(3) late String documentType;
  @HiveField(4) late String title;
  @HiveField(5) String? description;
  @HiveField(6) late String filePath;
  @HiveField(7) late String fileName;
  @HiveField(8) int? fileSize;
  @HiveField(9) String? mimeType;
  @HiveField(10) String? documentDate;
  @HiveField(11) late String createdAt;
  @HiveField(12) late String updatedAt;

  DocumentModel();

  factory DocumentModel.fromEntity(MedicalDocument e) {
    final m = DocumentModel();
    m.id = e.id;
    m.userId = e.userId;
    m.familyMemberId = e.familyMemberId;
    m.documentType = e.documentType.name;
    m.title = e.title;
    m.description = e.description;
    m.filePath = e.filePath;
    m.fileName = e.fileName;
    m.fileSize = e.fileSize;
    m.mimeType = e.mimeType;
    m.documentDate = e.documentDate?.toIso8601String();
    m.createdAt = e.createdAt.toIso8601String();
    m.updatedAt = e.updatedAt.toIso8601String();
    return m;
  }

  MedicalDocument toEntity() => MedicalDocument(
        id: id,
        userId: userId,
        familyMemberId: familyMemberId,
        documentType: DocumentType.values.firstWhere(
          (t) => t.name == documentType,
          orElse: () => DocumentType.other,
        ),
        title: title,
        description: description,
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        documentDate: documentDate != null ? DateTime.parse(documentDate!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final m = DocumentModel();
    m.id = json['id'] as String;
    m.userId = json['user_id'] as String;
    m.familyMemberId = json['family_member_id'] as String;
    m.documentType = _mapDbType(json['document_type'] as String);
    m.title = json['title'] as String;
    m.description = json['description'] as String?;
    m.filePath = json['file_path'] as String;
    m.fileName = json['file_name'] as String;
    m.fileSize = json['file_size'] as int?;
    m.mimeType = json['mime_type'] as String?;
    m.documentDate = json['document_date'] as String?;
    m.createdAt = json['created_at'] as String;
    m.updatedAt = json['updated_at'] as String;
    return m;
  }

  static String _mapDbType(String dbType) {
    const map = {
      'prescription': 'prescription',
      'analysis': 'analysis',
      'xray': 'xray',
      'report': 'report',
      'vaccine_card': 'vaccineCard',
      'other': 'other',
    };
    return map[dbType] ?? 'other';
  }

  Map<String, dynamic> toJson() {
    const typeMap = {
      'prescription': 'prescription',
      'analysis': 'analysis',
      'xray': 'xray',
      'report': 'report',
      'vaccineCard': 'vaccine_card',
      'other': 'other',
    };
    return {
      'id': id,
      'user_id': userId,
      'family_member_id': familyMemberId,
      'document_type': typeMap[documentType] ?? 'other',
      'title': title,
      'description': description,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'document_date': documentDate?.split('T').first,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
