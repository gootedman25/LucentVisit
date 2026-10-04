enum AiDraftType {
    appointment,
    medication,
    healthLog,
    measurement,
    question,
    reminder,
    unknown;


    static AiDraftType fromJson(string value) {
        return switch (value) {
            'appointment' => AiDraftType.appointment,
            'medication' => AiDraftType.medication,
            'healthLog' => AiDraftType.healthLog,
            'measurement' => AiDraftType.measurement,
            'question' => AiDraftType.question,
            'reminder' => AiDraftType.reminder,
            _ => AiDraftType.unknown,

        };
    }
}

class AiPlainTerm {
    const AiPlainTerm({
        required this.term,
        required this.meaning,
    });

    final String term;
    final String meaning;

    factory AiPlainTerm.fromJson(Map<String, dynamic> json) {
        return AiPlainTerm(
            term: _requiredString(json, 'term'),
            meaning: _requiredString(json, 'meaning')
        );
    }
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

    factory AiExplanation.fromJson(Map<String, dynamic> json) {
        return AiExplanation(
            summary: _requiredString(json, 'summary'),
            importantDetails: _stringList(json, 'importantDetails'),
            plainTerms: _mapList(json, 'plainTerms')
                .map(AiPlainTerm.fromJson)
                .toList(growable: false),
            questionsToAsk: _stringList(json, 'questionsToAsk'),
            uncertainties: _stringList(json, 'uncertainties'),
            cautions: _stringList(json, 'cautions')
        );
    }
}

class AiDraftValue {
    const AiDraftValue({
        required this.field,
        required this.value,
    });

    final String field;
    final String value;

    factory AiDraftValue.fromJson(Map<String, dynamic> json) {
        return AiDraftValue(
            field: _requiredString(json, 'field'),
            value: _requiredString(json, 'value')
        );
    }
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

    bool get isComplete => missingRequired.isEmpty;

    String? valueFor(String field) {
        for (final item in values) {
            if (item.field == field) {
                return item.value;
            }
        }
        return null;
    }

    factory AiDraft.fromJson(Map<String, dynamic> json) {
        return AiDraft(
            type: AiDraftType.fromJson(_requiredString(json, 'type')),
            values: _mapList(json, 'values')
                .map(AiDraftValue.fromJson)
                .toList(growable: false),
            evidence: _requiredString(json, 'evidence'),
            missingRequired: _stringList(json, 'missingRequired')
        );
    }
}

class AiDraftResponse {
    const AiDraftResponse({
        required this.drafts,
    });

    final List<AiDraft> drafts;

    factory AiDraftResponse.fromJson(Map<String, dynamic> json) {
        return AiDraftResponse(
            drafts: _mapList(json, 'drafts')
                .map(AiDraft.fromJson)
                .toList(growable: false)
        );
    }
}

String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
        throw Exception('Expected a string for key "$key"');
    }
    return value;
}

List<String> _stringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
        throw Exception('Expected a list for key "$key"');
    }
    return value.map((item) {
        if (item is! String) {
            throw Exception('Expected a string in the list for key "$key"');
        }
        return item;
    }).toList(growable: false);
}

List<Map<String, dynamic>> _mapList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
        throw Exception('Expected a list for key "$key"');
    }
    return value.map((item) {
        if (item is! Map<String, dynamic>) {
            throw Exception('Expected a map in the list for key "$key"');
        }
        return item;
    }).toList(growable: false);
}
