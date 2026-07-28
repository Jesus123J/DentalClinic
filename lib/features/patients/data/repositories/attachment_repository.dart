import '../../../../core/api/api_client.dart';
import '../../../../core/auth/session.dart';
import '../../domain/entities/attachment.dart';

/// Archivos adjuntos de la historia clinica por paciente.
class AttachmentRepository {
  AttachmentRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Attachment _fromJson(Map<String, dynamic> json) => Attachment(
        id: int.parse(json['id'].toString()),
        patientId: int.parse(json['patient_id'].toString()),
        name: json['original_name'] ?? '',
        mime: json['mime'] ?? '',
        size: int.tryParse(json['size'].toString()) ?? 0,
        uploadedAt:
            DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
      );

  Future<List<Attachment>> getByPatient(int patientId) async {
    final data =
        await _api.get('/attachments', {'patientId': '$patientId'}) as List;
    return data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> upload({
    required int patientId,
    required String filename,
    required List<int> bytes,
  }) async {
    await _api.uploadFile(
      '/attachments',
      fields: {'patient_id': '$patientId'},
      bytes: bytes,
      filename: filename,
    );
  }

  Future<void> delete(int id, {String? reason}) async {
    await _api.delete('/attachments/$id', reason: reason);
  }

  /// Descarga el contenido del archivo para verlo dentro de la app.
  Future<List<int>> download(int id) async {
    return _api.getBytes('/attachments/$id/download');
  }

  /// URL para abrir/descargar el archivo en el navegador (incluye el token).
  String viewUrl(int id) {
    // En produccion baseUrl es relativa (/api): se completa con el origen.
    final base = ApiClient.baseUrl.startsWith('http')
        ? ApiClient.baseUrl
        : '${Uri.base.origin}${ApiClient.baseUrl}';
    return '$base/attachments/$id/download?token=${Session.token}';
  }
}
