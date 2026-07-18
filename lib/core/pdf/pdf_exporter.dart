import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/patients/domain/entities/clinical_record.dart';
import '../../features/patients/domain/entities/patient.dart';
import '../../features/reports/data/repositories/report_repository.dart';

/// Genera y descarga/imprime los PDF del sistema.
class PdfExporter {
  PdfExporter._();

  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  static pw.Widget _header(String title, String subtitle) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Clinica Dental',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(subtitle,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          pw.Divider(),
        ],
      );

  static Future<void> _output(pw.Document doc, String filename) async {
    final bytes = await doc.save();
    if (kIsWeb) {
      // En web descarga el archivo directamente.
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } else {
      // En escritorio abre el dialogo de impresion (permite guardar como PDF).
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
    }
  }

  /// Reporte de atenciones por rango de fechas.
  static Future<void> appointmentsReport({
    required DateTime from,
    required DateTime to,
    required List<PatientReportRow> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header(
            'Reporte de atenciones',
            'Del ${_date.format(from)} al ${_date.format(to)} — '
                '${rows.length} atenciones — generado el ${_dateTime.format(DateTime.now())}',
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha y hora', 'Paciente', 'DNI', 'Motivo', 'Estado'],
            data: [
              for (final r in rows)
                [
                  _dateTime.format(r.dateTime),
                  r.patientName,
                  r.documentId,
                  r.reason,
                  r.status,
                ],
            ],
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.teal700),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {0: pw.Alignment.centerLeft},
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );
    await _output(doc, 'reporte_atenciones.pdf');
  }

  /// Historia clinica completa de un paciente.
  static Future<void> patientHistory({
    required Patient patient,
    required List<ClinicalRecord> records,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header(
            'Historia clinica — ${patient.fullName}',
            'Generado el ${_dateTime.format(DateTime.now())}',
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            data: [
              ['DNI', patient.documentId ?? '-'],
              ['Telefono', patient.phone ?? '-'],
              ['Correo', patient.email ?? '-'],
              [
                'Fecha de nacimiento',
                patient.birthDate == null
                    ? '-'
                    : _date.format(patient.birthDate!)
              ],
              ['Alergias', patient.allergies ?? 'Ninguna'],
              ['Notas', patient.notes ?? '-'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {0: pw.Alignment.centerLeft},
            columnWidths: {
              0: const pw.FixedColumnWidth(120),
              1: const pw.FlexColumnWidth(),
            },
          ),
          pw.SizedBox(height: 16),
          pw.Text('Registros clinicos (${records.length})',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (records.isEmpty)
            pw.Text('Sin registros.',
                style: const pw.TextStyle(fontSize: 10))
          else
            pw.TableHelper.fromTextArray(
              headers: ['Fecha', 'Diagnostico', 'Tratamiento', 'Observaciones'],
              data: [
                for (final r in records)
                  [
                    _date.format(r.recordDate),
                    r.diagnosis,
                    r.treatment ?? '-',
                    r.observations ?? '-',
                  ],
              ],
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.teal700),
              cellStyle: const pw.TextStyle(fontSize: 9),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
            ),
        ],
      ),
    );
    await _output(doc, 'historia_${patient.lastName.toLowerCase()}.pdf');
  }
}
