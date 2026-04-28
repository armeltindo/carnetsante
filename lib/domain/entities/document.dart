import 'package:equatable/equatable.dart';

enum DocumentType { prescription, analysis, xray, report, vaccineCard, other }

class MedicalDocument extends Equatable {
  final String id;
  final String userId;
  final String familyMemberId;
  final DocumentType documentType;
  final String title;
  final String? description;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final DateTime? documentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalDocument({
    required this.id,
    required this.userId,
    required this.familyMemberId,
    required this.documentType,
    required this.title,
    this.description,
    required this.filePath,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    this.documentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isImage =>
      mimeType?.startsWith('image/') == true ||
      fileName.toLowerCase().endsWith('.jpg') ||
      fileName.toLowerCase().endsWith('.jpeg') ||
      fileName.toLowerCase().endsWith('.png');

  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  String get typeLabel {
    switch (documentType) {
      case DocumentType.prescription: return 'Ordonnance';
      case DocumentType.analysis: return 'Analyse';
      case DocumentType.xray: return 'Radiographie';
      case DocumentType.report: return 'Compte-rendu';
      case DocumentType.vaccineCard: return 'Carnet vaccinal';
      case DocumentType.other: return 'Autre';
    }
  }

  String get fileSizeLabel {
    if (fileSize == null) return '--';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  List<Object?> get props => [id, familyMemberId, title, filePath];
}
