import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/session.dart';
import '../../data/repositories/clinical_history_repository.dart';
import '../../domain/entities/clinical_history.dart';
import '../../domain/entities/patient.dart';

/// Historia clinica odontologica formal (formato peruano, secciones I a VIII).
class ClinicalHistoryTab extends StatefulWidget {
  const ClinicalHistoryTab({super.key, required this.patient});

  final Patient patient;

  @override
  State<ClinicalHistoryTab> createState() => _ClinicalHistoryTabState();
}

class _ClinicalHistoryTabState extends State<ClinicalHistoryTab> {
  final _repo = ClinicalHistoryRepository();
  ClinicalHistory? _history;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// Un controlador por campo de texto, indexado por su clave.
  final Map<String, TextEditingController> _controllers = {};

  bool get _canEdit => Session.can('clinical.edit');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String key, String? initial) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: initial));

  String? _text(String key) {
    final v = _controllers[key]?.text.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Map<String, String> _group(String prefix, List<String> items) => {
        for (final i in items)
          if (_text('$prefix.$i') != null) i: _text('$prefix.$i')!,
      };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final h = await _repo.get(widget.patient.id!);
      if (!mounted) return;
      setState(() {
        _history = h;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final h = _history!;
    setState(() => _saving = true);

    h.hcNumber = _text('hc_number');
    h.birthPlace = _text('birth_place');
    h.origin = _text('origin');
    h.occupation = _text('occupation');
    h.tripsLastYear = _text('trips_last_year');
    h.emergencyContact = _text('emergency_contact');
    h.chiefComplaint = _text('chief_complaint');
    h.illnessTime = _text('illness_time');
    h.illnessOnset = _text('illness_onset');
    h.illnessCourse = _text('illness_course');
    h.illnessSigns = _text('illness_signs');
    h.illnessStory = _text('illness_story');
    h.risks = _text('risks');
    h.allergyDetail = _text('allergy_detail');
    h.pregnancyMonth = _text('pregnancy_month');
    h.pathologicalNotes = _text('pathological_notes');
    h.lastDentalVisit = _text('last_dental_visit');
    h.previousDentalTreatments = _text('previous_dental_treatments');
    h.anesthesiaReactionDetail = _text('anesthesia_reaction_detail');
    h.extractionComplicationDetail = _text('extraction_complication_detail');
    h.stomatologicalNotes = _text('stomatological_notes');
    h.familyHistory = _text('family_history');
    h.ectoscopy = _text('ectoscopy');
    h.vitalBloodPressure = _text('vital_blood_pressure');
    h.vitalPulse = _text('vital_pulse');
    h.vitalHeartRate = _text('vital_heart_rate');
    h.vitalRespiratoryRate = _text('vital_respiratory_rate');
    h.vitalTemperature = _text('vital_temperature');
    h.lesionMap = _text('lesion_map');
    h.presumptiveDiagnosis = _text('presumptive_diagnosis');
    h.diagnosticPlan = _text('diagnostic_plan');
    h.auxiliaryExams = _text('auxiliary_exams');
    h.definitiveDiagnosis = _text('definitive_diagnosis');
    h.treatmentPlan = _text('treatment_plan');
    h.performedTreatments = _text('performed_treatments');
    h.dentistName = _text('dentist_name');
    h.dentistCop = _text('dentist_cop');

    h.biologicalFunctions
      ..clear()
      ..addAll(_group('bio', kBiologicalFunctions));
    h.personalGeneral
      ..clear()
      ..addAll(_group('gen', kPersonalGeneralItems));
    h.personalPhysiological
      ..clear()
      ..addAll(_group('fis', kPersonalPhysiologicalItems));
    h.rasa
      ..clear()
      ..addAll(_group('rasa', kRasaSystems));
    h.generalExam
      ..clear()
      ..addAll(_group('exgen', kGeneralExamItems));
    h.extraoralExam
      ..clear()
      ..addAll(_group('extra', kExtraoralItems));
    h.intraoralExam
      ..clear()
      ..addAll(_group('intra', kIntraoralItems));

    try {
      await _repo.save(widget.patient.id!, h);
      if (!mounted) return;
      setState(() {
        _saving = false;
        h.exists = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historia clinica guardada')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final h = _history!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(h),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              _Section(
                number: 'I',
                title: 'Anamnesis - Filiacion',
                icon: Icons.badge_outlined,
                initiallyExpanded: true,
                children: [
                  _row([
                    _field('hc_number', 'N° de historia clinica', h.hcNumber),
                    _field('occupation', 'Ocupacion', h.occupation),
                  ]),
                  _row([
                    _field('birth_place', 'Lugar de nacimiento', h.birthPlace),
                    _field('origin', 'Procedencia', h.origin),
                  ]),
                  _row([
                    _field('trips_last_year', 'Viajes en el ultimo ano',
                        h.tripsLastYear),
                    _field('emergency_contact',
                        'En caso de emergencia comunicarse a',
                        h.emergencyContact),
                  ]),
                ],
              ),
              _Section(
                number: 'I',
                title: 'Motivo de consulta y enfermedad actual',
                icon: Icons.sick_outlined,
                children: [
                  _field('chief_complaint', 'Motivo de consulta',
                      h.chiefComplaint, lines: 2),
                  _row([
                    _field('illness_time', 'Tiempo de enfermedad',
                        h.illnessTime),
                    _field('illness_onset', 'Inicio', h.illnessOnset),
                    _field('illness_course', 'Curso', h.illnessCourse),
                  ]),
                  _field('illness_signs', 'Signos y sintomas principales',
                      h.illnessSigns, lines: 2),
                  _field('illness_story', 'Relato de la enfermedad',
                      h.illnessStory, lines: 4),
                  _field('risks', 'Riesgos', h.risks, lines: 2),
                ],
              ),
              _Section(
                number: 'I',
                title: 'Funciones biologicas',
                icon: Icons.monitor_heart_outlined,
                children: [
                  _grid([
                    for (final f in kBiologicalFunctions)
                      _field('bio.$f', f, h.biologicalFunctions[f]),
                  ]),
                ],
              ),
              _Section(
                number: 'I',
                title: 'Antecedentes patologicos',
                icon: Icons.warning_amber_outlined,
                highlight: h.hasAlerts,
                subtitle: h.hasAlerts
                    ? '${h.activeAlerts.length} antecedentes positivos'
                    : null,
                children: [
                  _checkGrid(h, kPathologicalItems),
                  _row([
                    _field('allergy_detail', 'Reaccion alergica a',
                        h.allergyDetail),
                    _field('pregnancy_month', 'Mes de gestacion',
                        h.pregnancyMonth),
                  ]),
                  _field('pathological_notes',
                      'Ampliacion (diagnosticos, lugar, fechas, tratamientos)',
                      h.pathologicalNotes, lines: 3),
                ],
              ),
              _Section(
                number: 'I',
                title: 'Antecedentes estomatologicos',
                icon: Icons.medical_services_outlined,
                children: [
                  _row([
                    _field('last_dental_visit', 'Ultima visita al dentista',
                        h.lastDentalVisit),
                    _field('previous_dental_treatments',
                        'Tratamientos odontologicos previos',
                        h.previousDentalTreatments),
                  ]),
                  _checkGrid(h, kStomatologicalItems),
                  _row([
                    _field('anesthesia_reaction_detail',
                        'Cual fue la reaccion a la anestesia',
                        h.anesthesiaReactionDetail),
                    _field('extraction_complication_detail',
                        'Cual fue la complicacion',
                        h.extractionComplicationDetail),
                  ]),
                  _field('stomatological_notes', 'Ampliacion',
                      h.stomatologicalNotes, lines: 2),
                ],
              ),
              _Section(
                number: 'I',
                title: 'Antecedentes personales y familiares',
                icon: Icons.family_restroom_outlined,
                children: [
                  Text('Generales',
                      style: Theme.of(context).textTheme.labelLarge),
                  _grid([
                    for (final f in kPersonalGeneralItems)
                      _field('gen.$f', f, h.personalGeneral[f]),
                  ]),
                  const SizedBox(height: 8),
                  Text('Fisiologicos y gineco-obstetricos',
                      style: Theme.of(context).textTheme.labelLarge),
                  _grid([
                    for (final f in kPersonalPhysiologicalItems)
                      _field('fis.$f', f, h.personalPhysiological[f]),
                  ]),
                  const SizedBox(height: 8),
                  _field('family_history', 'Antecedentes familiares',
                      h.familyHistory, lines: 3),
                ],
              ),
              _Section(
                number: 'I',
                title: 'R.A.S.A. - Revision por sistemas y aparatos',
                icon: Icons.checklist_outlined,
                children: [
                  _grid([
                    for (final s in kRasaSystems)
                      _field('rasa.$s', s, h.rasa[s]),
                  ]),
                ],
              ),
              _Section(
                number: 'II',
                title: 'Examen clinico general',
                icon: Icons.health_and_safety_outlined,
                children: [
                  _field('ectoscopy', 'Ectoscopia', h.ectoscopy, lines: 2),
                  Text('Funciones vitales',
                      style: Theme.of(context).textTheme.labelLarge),
                  _grid([
                    _field('vital_blood_pressure', 'Presion arterial',
                        h.vitalBloodPressure),
                    _field('vital_pulse', 'Pulso', h.vitalPulse),
                    _field('vital_heart_rate', 'Frecuencia cardiaca',
                        h.vitalHeartRate),
                    _field('vital_respiratory_rate', 'Frecuencia respiratoria',
                        h.vitalRespiratoryRate),
                    _field('vital_temperature', 'Temperatura',
                        h.vitalTemperature),
                  ], min: 200),
                  const SizedBox(height: 8),
                  _grid([
                    for (final f in kGeneralExamItems)
                      _field('exgen.$f', f, h.generalExam[f]),
                  ]),
                ],
              ),
              _Section(
                number: 'II',
                title: 'Examen estomatologico extraoral',
                icon: Icons.face_outlined,
                children: [
                  _grid([
                    for (final f in kExtraoralItems)
                      _field('extra.$f', f, h.extraoralExam[f]),
                  ]),
                ],
              ),
              _Section(
                number: 'II',
                title: 'Examen estomatologico intraoral',
                icon: Icons.co_present_outlined,
                children: [
                  _grid([
                    for (final f in kIntraoralItems)
                      _field('intra.$f', f, h.intraoralExam[f]),
                  ]),
                  const SizedBox(height: 8),
                  _field('lesion_map',
                      'Mapeo anatomico de lesiones buco-maxilofaciales',
                      h.lesionMap, lines: 3),
                ],
              ),
              _Section(
                number: 'III-VII',
                title: 'Diagnostico y plan de tratamiento',
                icon: Icons.assignment_outlined,
                children: [
                  _field('presumptive_diagnosis',
                      'III. Diagnosticos presuntivos',
                      h.presumptiveDiagnosis, lines: 3),
                  _field('diagnostic_plan',
                      'IV. Plan de trabajo para el diagnostico',
                      h.diagnosticPlan, lines: 3),
                  _field('auxiliary_exams',
                      'Resultado de los examenes auxiliares',
                      h.auxiliaryExams, lines: 3),
                  _field('definitive_diagnosis', 'V. Diagnostico definitivo',
                      h.definitiveDiagnosis, lines: 3),
                  _field('treatment_plan', 'VI. Plan de tratamiento',
                      h.treatmentPlan, lines: 3),
                  _field('performed_treatments',
                      'VII. Tratamientos realizados',
                      h.performedTreatments, lines: 4),
                ],
              ),
              _Section(
                number: 'VIII',
                title: 'Responsable',
                icon: Icons.verified_user_outlined,
                subtitle:
                    'El control y evolucion se registra en la pestana Evoluciones',
                children: [
                  _row([
                    _field('dentist_name', 'Cirujano dentista', h.dentistName),
                    _field('dentist_cop', 'COP N°', h.dentistCop),
                  ]),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ClinicalHistory h) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.exists
                        ? 'Historia clinica registrada'
                        : 'Historia clinica sin registrar',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    h.exists && h.updatedAt != null
                        ? 'Ultima actualizacion: '
                            '${DateFormat('dd/MM/yyyy HH:mm').format(h.updatedAt!)}'
                            '${h.updatedBy == null ? '' : ' por ${h.updatedBy}'}'
                        : 'Completa las secciones y guarda al final.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (h.hasAlerts) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final a in h.activeAlerts)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD03B3B)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 14, color: Color(0xFFD03B3B)),
                                const SizedBox(width: 4),
                                Text(a,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFD03B3B),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_canEdit)
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando…' : 'Guardar historia'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String key, String label, String? initial, {int lines = 1}) {
    return TextFormField(
      controller: _ctrl(key, initial),
      readOnly: !_canEdit,
      maxLines: lines,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }

  Widget _row(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 620) {
          return Column(
            children: [
              for (final w in children)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12), child: w),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _grid(List<Widget> children, {double min = 260}) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = (c.maxWidth / min).floor().clamp(1, 4);
        final width = (c.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final w in children) SizedBox(width: width, child: w),
          ],
        );
      },
    );
  }

  Widget _checkGrid(
      ClinicalHistory h, List<({String key, String label})> items) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = (c.maxWidth / 280).floor().clamp(1, 3);
        final width = (c.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(item.label,
                      style: Theme.of(context).textTheme.bodyMedium),
                  value: h.pathological[item.key] ?? false,
                  onChanged: _canEdit
                      ? (v) =>
                          setState(() => h.pathological[item.key] = v ?? false)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Seccion plegable del formulario.
class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
    this.highlight = false,
  });

  final String number;
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? subtitle;
  final bool initiallyExpanded;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ExpansionTile(
          shape: const Border(),
          initiallyExpanded: initiallyExpanded,
          leading: CircleAvatar(
            backgroundColor: highlight
                ? const Color(0xFFD03B3B).withValues(alpha: 0.14)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            child: Icon(icon,
                size: 20,
                color: highlight
                    ? const Color(0xFFD03B3B)
                    : Theme.of(context).colorScheme.primary),
          ),
          title: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(number,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          subtitle: subtitle == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 40, top: 2),
                  child: Text(subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: highlight ? const Color(0xFFD03B3B) : null)),
                ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
