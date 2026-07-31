import '../../../../core/api/api_client.dart';
import '../../domain/entities/clinical_history.dart';

/// Historia clinica formal del paciente (una por paciente).
class ClinicalHistoryRepository {
  ClinicalHistoryRepository({ApiClient? api})
      : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static Map<String, String> _strMap(dynamic v) {
    if (v is! Map) return {};
    return {
      for (final e in v.entries)
        e.key.toString(): e.value?.toString() ?? '',
    };
  }

  static bool _flag(dynamic v) => v == 1 || v == '1' || v == true;

  Future<ClinicalHistory> get(int patientId) async {
    final j = await _api.get('/patients/$patientId/history')
        as Map<String, dynamic>;
    if (j['exists'] != true) return ClinicalHistory();

    return ClinicalHistory(
      exists: true,
      hcNumber: j['hc_number'],
      birthPlace: j['birth_place'],
      origin: j['origin'],
      occupation: j['occupation'],
      tripsLastYear: j['trips_last_year'],
      emergencyContact: j['emergency_contact'],
      chiefComplaint: j['chief_complaint'],
      illnessTime: j['illness_time'],
      illnessOnset: j['illness_onset'],
      illnessCourse: j['illness_course'],
      illnessSigns: j['illness_signs'],
      illnessStory: j['illness_story'],
      biologicalFunctions: _strMap(j['biological_functions']),
      risks: j['risks'],
      personalGeneral: _strMap(j['personal_general']),
      personalPhysiological: _strMap(j['personal_physiological']),
      pathological: {
        for (final item in kPathologicalItems) item.key: _flag(j[item.key]),
        for (final item in kStomatologicalItems) item.key: _flag(j[item.key]),
      },
      allergyDetail: j['allergy_detail'],
      pregnancyMonth: j['pregnancy_month'],
      pathologicalNotes: j['pathological_notes'],
      lastDentalVisit: j['last_dental_visit'],
      previousDentalTreatments: j['previous_dental_treatments'],
      anesthesiaReactionDetail: j['anesthesia_reaction_detail'],
      extractionComplicationDetail: j['extraction_complication_detail'],
      stomatologicalNotes: j['stomatological_notes'],
      familyHistory: j['family_history'],
      rasa: _strMap(j['rasa']),
      ectoscopy: j['ectoscopy'],
      vitalBloodPressure: j['vital_blood_pressure'],
      vitalPulse: j['vital_pulse'],
      vitalHeartRate: j['vital_heart_rate'],
      vitalRespiratoryRate: j['vital_respiratory_rate'],
      vitalTemperature: j['vital_temperature'],
      generalExam: _strMap(j['general_exam']),
      extraoralExam: _strMap(j['extraoral_exam']),
      intraoralExam: _strMap(j['intraoral_exam']),
      lesionMap: j['lesion_map'],
      presumptiveDiagnosis: j['presumptive_diagnosis'],
      diagnosticPlan: j['diagnostic_plan'],
      auxiliaryExams: j['auxiliary_exams'],
      definitiveDiagnosis: j['definitive_diagnosis'],
      treatmentPlan: j['treatment_plan'],
      performedTreatments: j['performed_treatments'],
      dentistName: j['dentist_name'],
      dentistCop: j['dentist_cop'],
      updatedAt: DateTime.tryParse(j['updated_at'] ?? ''),
      updatedBy: j['updated_by'],
    );
  }

  Future<void> save(int patientId, ClinicalHistory h) async {
    await _api.put('/patients/$patientId/history', {
      'hc_number': h.hcNumber,
      'birth_place': h.birthPlace,
      'origin': h.origin,
      'occupation': h.occupation,
      'trips_last_year': h.tripsLastYear,
      'emergency_contact': h.emergencyContact,
      'chief_complaint': h.chiefComplaint,
      'illness_time': h.illnessTime,
      'illness_onset': h.illnessOnset,
      'illness_course': h.illnessCourse,
      'illness_signs': h.illnessSigns,
      'illness_story': h.illnessStory,
      'biological_functions': h.biologicalFunctions,
      'risks': h.risks,
      'personal_general': h.personalGeneral,
      'personal_physiological': h.personalPhysiological,
      for (final item in kPathologicalItems)
        item.key: h.pathological[item.key] ?? false,
      for (final item in kStomatologicalItems)
        item.key: h.pathological[item.key] ?? false,
      'allergy_detail': h.allergyDetail,
      'pregnancy_month': h.pregnancyMonth,
      'pathological_notes': h.pathologicalNotes,
      'last_dental_visit': h.lastDentalVisit,
      'previous_dental_treatments': h.previousDentalTreatments,
      'anesthesia_reaction_detail': h.anesthesiaReactionDetail,
      'extraction_complication_detail': h.extractionComplicationDetail,
      'stomatological_notes': h.stomatologicalNotes,
      'family_history': h.familyHistory,
      'rasa': h.rasa,
      'ectoscopy': h.ectoscopy,
      'vital_blood_pressure': h.vitalBloodPressure,
      'vital_pulse': h.vitalPulse,
      'vital_heart_rate': h.vitalHeartRate,
      'vital_respiratory_rate': h.vitalRespiratoryRate,
      'vital_temperature': h.vitalTemperature,
      'general_exam': h.generalExam,
      'extraoral_exam': h.extraoralExam,
      'intraoral_exam': h.intraoralExam,
      'lesion_map': h.lesionMap,
      'presumptive_diagnosis': h.presumptiveDiagnosis,
      'diagnostic_plan': h.diagnosticPlan,
      'auxiliary_exams': h.auxiliaryExams,
      'definitive_diagnosis': h.definitiveDiagnosis,
      'treatment_plan': h.treatmentPlan,
      'performed_treatments': h.performedTreatments,
      'dentist_name': h.dentistName,
      'dentist_cop': h.dentistCop,
    });
  }
}
