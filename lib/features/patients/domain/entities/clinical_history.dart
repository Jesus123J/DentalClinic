/// Historia clinica odontologica formal (formato peruano, secciones I a VIII).
///
/// Los campos de texto libre se guardan tal cual; los grupos extensos
/// (funciones biologicas, RASA, examen extraoral/intraoral) viajan como
/// mapas clave-valor para no multiplicar columnas.
class ClinicalHistory {
  ClinicalHistory({
    this.exists = false,
    this.hcNumber,
    this.birthPlace,
    this.origin,
    this.occupation,
    this.tripsLastYear,
    this.emergencyContact,
    this.chiefComplaint,
    this.illnessTime,
    this.illnessOnset,
    this.illnessCourse,
    this.illnessSigns,
    this.illnessStory,
    Map<String, String>? biologicalFunctions,
    this.risks,
    Map<String, String>? personalGeneral,
    Map<String, String>? personalPhysiological,
    Map<String, bool>? pathological,
    this.allergyDetail,
    this.pregnancyMonth,
    this.pathologicalNotes,
    this.lastDentalVisit,
    this.previousDentalTreatments,
    this.anesthesiaReactionDetail,
    this.extractionComplicationDetail,
    this.stomatologicalNotes,
    this.familyHistory,
    Map<String, String>? rasa,
    this.ectoscopy,
    this.vitalBloodPressure,
    this.vitalPulse,
    this.vitalHeartRate,
    this.vitalRespiratoryRate,
    this.vitalTemperature,
    Map<String, String>? generalExam,
    Map<String, String>? extraoralExam,
    Map<String, String>? intraoralExam,
    this.lesionMap,
    this.presumptiveDiagnosis,
    this.diagnosticPlan,
    this.auxiliaryExams,
    this.definitiveDiagnosis,
    this.treatmentPlan,
    this.performedTreatments,
    this.dentistName,
    this.dentistCop,
    this.updatedAt,
    this.updatedBy,
  })  : biologicalFunctions = biologicalFunctions ?? {},
        personalGeneral = personalGeneral ?? {},
        personalPhysiological = personalPhysiological ?? {},
        pathological = pathological ?? {},
        rasa = rasa ?? {},
        generalExam = generalExam ?? {},
        extraoralExam = extraoralExam ?? {},
        intraoralExam = intraoralExam ?? {};

  bool exists;

  // I. Filiacion
  String? hcNumber;
  String? birthPlace;
  String? origin;
  String? occupation;
  String? tripsLastYear;
  String? emergencyContact;

  // I. Motivo y enfermedad actual
  String? chiefComplaint;
  String? illnessTime;
  String? illnessOnset;
  String? illnessCourse;
  String? illnessSigns;
  String? illnessStory;

  final Map<String, String> biologicalFunctions;
  String? risks;

  // I. Antecedentes
  final Map<String, String> personalGeneral;
  final Map<String, String> personalPhysiological;

  /// Antecedentes patologicos marcados (clave -> si/no).
  final Map<String, bool> pathological;
  String? allergyDetail;
  String? pregnancyMonth;
  String? pathologicalNotes;

  // I. Estomatologicos
  String? lastDentalVisit;
  String? previousDentalTreatments;
  String? anesthesiaReactionDetail;
  String? extractionComplicationDetail;
  String? stomatologicalNotes;

  String? familyHistory;
  final Map<String, String> rasa;

  // II. Examen clinico
  String? ectoscopy;
  String? vitalBloodPressure;
  String? vitalPulse;
  String? vitalHeartRate;
  String? vitalRespiratoryRate;
  String? vitalTemperature;
  final Map<String, String> generalExam;
  final Map<String, String> extraoralExam;
  final Map<String, String> intraoralExam;
  String? lesionMap;

  // III a VII
  String? presumptiveDiagnosis;
  String? diagnosticPlan;
  String? auxiliaryExams;
  String? definitiveDiagnosis;
  String? treatmentPlan;
  String? performedTreatments;

  String? dentistName;
  String? dentistCop;
  DateTime? updatedAt;
  String? updatedBy;

  bool get hasAlerts => pathological.entries.any((e) => e.value);

  /// Antecedentes marcados como positivos, con su etiqueta legible.
  List<String> get activeAlerts => [
        for (final e in kPathologicalItems)
          if (pathological[e.key] == true) e.label,
      ];
}

/// Items de antecedentes patologicos del formato oficial.
const kPathologicalItems = <({String key, String label})>[
  (key: 'path_hypertension', label: 'Hipertension arterial'),
  (key: 'path_cardiovascular', label: 'Otra enfermedad cardiovascular'),
  (key: 'path_diabetes', label: 'Diabetes'),
  (key: 'path_endocrine', label: 'Otra enfermedad endocrinologica'),
  (key: 'path_asthma', label: 'Asma'),
  (key: 'path_hepatitis', label: 'Hepatitis'),
  (key: 'path_liver', label: 'Enfermedad hepatica'),
  (key: 'path_kidney', label: 'Enfermedad renal'),
  (key: 'path_tbc', label: 'TBC'),
  (key: 'path_infectious', label: 'Otra enfermedad infecciosa'),
  (key: 'path_bleeding', label: 'Enfermedad hemorragica'),
  (key: 'path_other', label: 'Otras enfermedades'),
  (key: 'path_medication', label: 'Ingesta de medicamentos'),
  (key: 'allergy_drugs', label: 'Alergia a farmacos'),
  (key: 'allergy_food', label: 'Alergia a alimentos'),
  (key: 'previous_surgeries', label: 'Cirugias previas'),
  (key: 'previous_hospitalizations', label: 'Hospitalizaciones previas'),
  (key: 'habit_tobacco', label: 'Tabaco'),
  (key: 'habit_alcohol', label: 'Alcohol'),
  (key: 'habit_drugs', label: 'Drogas'),
  (key: 'is_pregnant', label: 'Gestando'),
];

/// Antecedentes estomatologicos con respuesta si/no.
const kStomatologicalItems = <({String key, String label})>[
  (key: 'previous_anesthesia', label: 'Infiltraciones de anestesia previas'),
  (key: 'anesthesia_reaction', label: 'Reacciones adversas a la anestesia'),
  (key: 'previous_extractions', label: 'Exodoncias o cirugias bucales previas'),
  (key: 'extraction_complications',
      label: 'Complicaciones despues de la exodoncia'),
];

const kBiologicalFunctions = [
  'Apetito', 'Sed', 'Sueno', 'Sudor', 'Peso', 'Orina', 'Deposiciones',
  'Estado de animo',
];

const kPersonalGeneralItems = [
  'Residencias anteriores', 'Ocupaciones anteriores', 'Vivienda',
  'Crianza de animales', 'Ventilacion', 'Vestido e higiene', 'Alimentacion',
];

const kPersonalPhysiologicalItems = [
  'Parto', 'Desarrollo fisico', 'Desarrollo psiquico', 'Menarquia',
  'Regimen catamenial', 'Gestaciones / partos', 'Lactancia',
  'Metodo anticonceptivo', 'PAP',
];

const kRasaSystems = [
  'Cabeza', 'Ojos', 'Oidos', 'Nariz', 'Boca', 'Faringe y laringe', 'Cuello',
  'Aparato respiratorio', 'Aparato cardiovascular', 'Aparato gastrointestinal',
  'Aparato urinario', 'Neuropsiquiatrico', 'Aparato locomotor', 'Piel y anexos',
];

const kGeneralExamItems = [
  'Piel y anexos', 'Tejido celular subcutaneo', 'Sistema oseomioarticular',
  'Sistema linfatico',
];

const kExtraoralItems = [
  'Craneo', 'Cara', 'Piel facial', 'Ojos', 'Nariz', 'Oidos', 'ATM', 'Cuello',
  'Ganglios linfaticos', 'Glandulas salivales',
];

const kIntraoralItems = [
  'Apertura bucal', 'Labios', 'Mucosa yugal', 'Paladar duro y blando',
  'Istmo de las fauces', 'Orofaringe', 'Lengua', 'Piso de boca', 'Encias',
  'Relacion molar', 'Relacion canina', 'Movilidad dental', 'Saliva',
];
