import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/patients/domain/entities/clinical_record.dart';
import '../../features/patients/domain/entities/patient.dart';
import '../../features/patients/domain/entities/tooth_state.dart';
import '../../features/reports/data/repositories/report_repository.dart';

/// Genera y descarga/imprime los PDF del sistema.
class PdfExporter {
  PdfExporter._();

  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  static const _gold = PdfColor.fromInt(0xFFD9A521);

  static pw.Widget _header(String title, String subtitle) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold),
              children: [
                const pw.TextSpan(
                    text: 'Pro', style: pw.TextStyle(color: _gold)),
                const pw.TextSpan(text: 'Dentist '),
                pw.TextSpan(
                    text: 'Peru',
                    style: pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(subtitle,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          pw.Divider(),
        ],
      );

  /// Dibuja una pieza del odontograma en el PDF.
  static pw.Widget _pdfToothBox(String tooth, ToothState? state) {
    final status = state?.status ?? ToothStatus.sano;
    final healthy = status == ToothStatus.sano;
    final fill = healthy
        ? PdfColors.white
        : PdfColor.fromInt(status.color.toARGB32());
    return pw.Container(
      width: 23,
      height: 30,
      margin: const pw.EdgeInsets.symmetric(horizontal: 1),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: fill,
        border: pw.Border.all(
            color: healthy ? PdfColors.grey400 : fill, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        status == ToothStatus.extraido ? 'X' : tooth,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: healthy ? PdfColors.grey800 : PdfColors.white,
        ),
      ),
    );
  }

  /// Fila de una arcada (16 piezas separadas por cuadrante).
  static pw.Widget _pdfArch(
      List<String> teeth, Map<String, ToothState> byTooth) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        for (var i = 0; i < teeth.length; i++) ...[
          if (i == 8)
            pw.Container(
              width: 1.2,
              height: 30,
              color: PdfColors.grey600,
              margin: const pw.EdgeInsets.symmetric(horizontal: 4),
            ),
          _pdfToothBox(teeth[i], byTooth[teeth[i]]),
        ],
      ],
    );
  }

  /// Grafico completo del odontograma con leyenda.
  static pw.Widget _pdfOdontogram(List<ToothState> teeth) {
    final byTooth = {for (final t in teeth) t.tooth: t};
    final usedStatuses =
        teeth.map((t) => t.status).toSet().toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text('Arcada superior',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          _pdfArch(kUpperTeeth, byTooth),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Divider(color: PdfColors.grey400, height: 1),
          ),
          _pdfArch(kLowerTeeth, byTooth),
          pw.SizedBox(height: 4),
          pw.Text('Arcada inferior',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
          if (usedStatuses.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: pw.WrapAlignment.center,
              children: [
                for (final s in usedStatuses)
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        width: 7,
                        height: 7,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(s.color.toARGB32()),
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 3),
                      pw.Text(s.label,
                          style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
            'Del ${_date.format(from)} al ${_date.format(to)} - '
                '${rows.length} atenciones - generado el ${_dateTime.format(DateTime.now())}',
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
            headerDecoration: const pw.BoxDecoration(color: _gold),
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
    List<ToothState> teeth = const [],
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header(
            'Historia clinica - ${patient.fullName}',
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
          pw.Text('Odontograma',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _pdfOdontogram(teeth),
          if (teeth.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Detalle de hallazgos (${teeth.length})',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Pieza (FDI)', 'Estado', 'Nota'],
              data: [
                for (final t in teeth) [t.tooth, t.status.label, t.note ?? '-'],
              ],
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: _gold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text('Registros clinicos (${records.length})',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (records.isEmpty)
            pw.Text('Sin registros.',
                style: const pw.TextStyle(fontSize: 10))
          else
            for (final r in records) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${_date.format(r.recordDate)}'
                      '${r.tooth == null || r.tooth!.isEmpty ? '' : ' - Pieza ${r.tooth}'}'
                      '${r.procedureType == null ? '' : ' - ${r.procedureType}'}',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    for (final line in [
                      ['Motivo de consulta', r.chiefComplaint],
                      ['Diagnostico', r.diagnosis],
                      ['Examen clinico', r.clinicalExam],
                      ['Tratamiento', r.treatment],
                      ['Receta / indicaciones', r.prescription],
                      ['Observaciones', r.observations],
                    ])
                      if (line[1] != null && line[1]!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.RichText(
                            text: pw.TextSpan(
                              style: const pw.TextStyle(fontSize: 9),
                              children: [
                                pw.TextSpan(
                                    text: '${line[0]}: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                                pw.TextSpan(text: line[1]),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
            ],
        ],
      ),
    );
    await _output(doc, 'historia_${patient.lastName.toLowerCase()}.pdf');
  }
}
