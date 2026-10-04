enum AiDraftType {
  appointment,
  medication,
  healthLog,
  measurement,
  question,
  reminder,
  unknown;

  static AiDraftType fromJson(String value) => switch (value) {
    'appointment' => appointment,
    'medication' => medication,
    'health_log' => healthLog,
    'measurement' => measurement,
    'question' => question,
    'reminder' => reminder,
    _ => unknown,
  };
}

class AiPlainTerm {
  const AiPlainTerm({required this.term, required this.meaning});
  final String term;
  final String meaning;
  factory AiPlainTerm.fromJson(Map<String, dynamic> json) => AiPlainTerm(
    term: _string(json, 'term'),
    meaning: _string(json, 'meaning'),
  );
}

class AiExplanation {
  const AiExplanation({
    required this.summary,
    required this.importantDetails,
    required this.plainTerms,
    required this.questionsToAsk,
    required this.uncertainties,
    required this.cautions,
  });
  final String summary;
  final List<String> importantDetails;
  final List<AiPlainTerm> plainTerms;
  final List<String> questionsToAsk;
  final List<String> uncertainties;
  final List<String> cautions;

  factory AiExplanation.fromJson(Map<String, dynamic> json) => AiExplanation(
    summary: _string(json, 'summary'),
    importantDetails: _strings(json, 'important_details'),
    plainTerms: _maps(json, 'plain_terms').map(AiPlainTerm.fromJson).toList(),
    questionsToAsk: _strings(json, 'questions_to_ask'),
    uncertainties: _strings(json, 'uncertainties'),
    cautions: _strings(json, 'cautions'),
  );
}

class AiDraftValue {
  const AiDraftValue({required this.field, required this.value});
  final String field;
  final String value;
  factory AiDraftValue.fromJson(Map<String, dynamic> json) => AiDraftValue(
    field: _string(json, 'field'),
    value: _string(json, 'value'),
  );
}

class AiDraft {
  const AiDraft({
    required this.type,
    required this.values,
    required this.evidence,
    required this.missingRequired,
  });
  final AiDraftType type;
  final List<AiDraftValue> values;
  final String evidence;
  final List<String> missingRequired;

  factory AiDraft.fromJson(Map<String, dynamic> json) => AiDraft(
    type: AiDraftType.fromJson(_string(json, 'type')),
    values: _maps(json, 'values').map(AiDraftValue.fromJson).toList(),
    evidence: _string(json, 'evidence'),
    missingRequired: _strings(json, 'missing_required'),
  );
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Expected $key to be text.');
  return value;
}

List<String> _strings(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('Expected $key to be a text list.');
  }
  return value.cast<String>();
}

List<Map<String, dynamic>> _maps(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Expected $key to be a list.');
  return value.map((item) {
    if (item is! Map) throw FormatException('Invalid item in $key.');
    return item.map((key, value) => MapEntry(key.toString(), value));
  }).toList();
}
