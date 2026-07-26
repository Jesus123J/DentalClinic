import 'package:equatable/equatable.dart';

/// Archivo adjunto de la historia clinica (radiografia, foto, PDF...).
class Attachment extends Equatable {
  const Attachment({
    required this.id,
    required this.patientId,
    required this.name,
    required this.mime,
    required this.size,
    required this.uploadedAt,
  });

  final int id;
  final int patientId;
  final String name;
  final String mime;
  final int size;
  final DateTime uploadedAt;

  bool get isImage => mime.startsWith('image/');
  bool get isPdf => mime == 'application/pdf';

  String get sizeLabel {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024).toStringAsFixed(0)} KB';
  }

  @override
  List<Object?> get props => [id, patientId, name];
}
