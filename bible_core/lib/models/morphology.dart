import 'word.dart' show MorphologyTag;

/// Parse morphology codes into human-readable MorphologyTag
class MorphologyParser {
  /// Parse a morphology code string into a MorphologyTag
  /// Format depends on source (e.g., Robinson, STEPBible, OSHB)
  static MorphologyTag? parse(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.startsWith('H') || normalized.contains('/')) {
      return _parseHebrew(normalized);
    }

    return _parseGreek(normalized);
  }

  /// Convert a MorphologyTag to human-readable description
  static String describe(MorphologyTag tag) {
    final parts = <String>[];
    
    if (tag.partOfSpeech != null) parts.add(tag.partOfSpeech!);
    if (tag.tense != null) parts.add(tag.tense!);
    if (tag.voice != null) parts.add(tag.voice!);
    if (tag.mood != null) parts.add(tag.mood!);
    if (tag.person != null) parts.add('${tag.person!} person');
    if (tag.gender != null) parts.add(tag.gender!);
    if (tag.number != null) parts.add(tag.number!);
    if (tag.case_ != null) parts.add(tag.case_!);
    if (tag.state != null) parts.add(tag.state!);

    return parts.isEmpty ? tag.rawCode : parts.join(', ');
  }

  /// Convert a MorphologyTag to a compact human-readable label for inline UI.
  static String describeCompact(MorphologyTag tag) {
    final parts = <String>[];

    if (tag.partOfSpeech != null) parts.add(tag.partOfSpeech!);
    if (tag.tense != null) parts.add(_abbreviateTense(tag.tense!));
    if (tag.voice != null) parts.add(tag.voice!);
    if (tag.mood != null) parts.add(_abbreviateMood(tag.mood!));
    if (tag.person != null) parts.add(_ordinalPerson(tag.person!));
    if (tag.gender != null) parts.add(_abbreviateGender(tag.gender!));
    if (tag.number != null) parts.add(_abbreviateNumber(tag.number!));
    if (tag.case_ != null) parts.add(_abbreviateCase(tag.case_!));
    if (tag.state != null) parts.add(_abbreviateState(tag.state!));

    return parts.isEmpty ? tag.rawCode : parts.join(' ');
  }

  static MorphologyTag _parseGreek(String code) {
    final segments = code.split('-').where((segment) => segment.isNotEmpty).toList();
    final posCode = segments.isEmpty ? code : segments.first;
    final lastSegment = segments.isEmpty ? code : segments.last;

    String? tense;
    String? voice;
    String? mood;
    String? person;
    String? gender;
    String? number;
    String? case_;

    if (segments.length >= 2 && _looksLikeGreekVerbSegment(segments[1])) {
      final verbSegment = segments[1];
      tense = _greekTenseMap[verbSegment[0]];
      voice = _greekVoiceMap[verbSegment[1]];
      mood = _greekMoodMap[verbSegment[2]];
    }

    if (_looksLikeGreekCaseNumberGender(lastSegment)) {
      case_ = _greekCaseMap[lastSegment[0]];
      number = _greekNumberMap[lastSegment[1]];
      gender = _greekGenderMap[lastSegment[2]];
    } else if (_looksLikeGreekPersonNumber(lastSegment)) {
      person = lastSegment[0];
      number = _greekNumberMap[lastSegment[1]];
    }

    return MorphologyTag(
      rawCode: code,
      partOfSpeech: _greekPartOfSpeech(posCode),
      tense: tense,
      voice: voice,
      mood: mood,
      person: person,
      gender: gender,
      number: number,
      case_: case_,
    );
  }

  static MorphologyTag _parseHebrew(String code) {
    final normalized = code.trim();
    final parts = normalized.split('/');
    final morphCode = parts.isEmpty ? normalized : parts.last;

    if (morphCode.isEmpty) {
      return MorphologyTag(rawCode: code);
    }

    String? partOfSpeech;
    String? tense;
    String? voice;
    String? mood;
    String? person;
    String? gender;
    String? number;
    String? state;

    final category = morphCode[0];
    switch (category) {
      case 'N':
        partOfSpeech = 'Noun';
        if (morphCode.length >= 5) {
          gender = _hebrewGenderMap[morphCode[2]];
          number = _hebrewNumberMap[morphCode[3]];
          state = _hebrewStateMap[morphCode[4]];
        }
        break;
      case 'A':
        partOfSpeech = 'Adjective';
        if (morphCode.length >= 5) {
          gender = _hebrewGenderMap[morphCode[2]];
          number = _hebrewNumberMap[morphCode[3]];
          state = _hebrewStateMap[morphCode[4]];
        }
        break;
      case 'P':
        partOfSpeech = 'Pronoun';
        if (morphCode.length >= 5) {
          person = morphCode[2];
          gender = _hebrewGenderMap[morphCode[3]];
          number = _hebrewNumberMap[morphCode[4]];
        }
        break;
      case 'V':
        partOfSpeech = 'Verb';
        if (morphCode.length >= 3) {
          voice = _hebrewStemMap[morphCode[1]];
          tense = _hebrewAspectMap[morphCode[2]];
        }
        if (morphCode.length >= 6) {
          person = morphCode[3];
          gender = _hebrewGenderMap[morphCode[4]];
          number = _hebrewNumberMap[morphCode[5]];
        }
        break;
      case 'T':
        partOfSpeech = 'Particle';
        mood = _hebrewParticleMap[morphCode.length > 1 ? morphCode[1] : null];
        break;
      case 'R':
        partOfSpeech = 'Preposition';
        break;
      case 'C':
        partOfSpeech = 'Conjunction';
        break;
      case 'D':
        partOfSpeech = 'Adverb';
        break;
      default:
        partOfSpeech = _hebrewPartOfSpeechMap[category];
        break;
    }

    return MorphologyTag(
      rawCode: code,
      partOfSpeech: partOfSpeech,
      tense: tense,
      voice: voice,
      mood: mood,
      person: person,
      gender: gender,
      number: number,
      state: state,
    );
  }

  static bool _looksLikeGreekVerbSegment(String segment) {
    return segment.length == 3 &&
        _greekTenseMap.containsKey(segment[0]) &&
        _greekVoiceMap.containsKey(segment[1]) &&
        _greekMoodMap.containsKey(segment[2]);
  }

  static bool _looksLikeGreekCaseNumberGender(String segment) {
    return segment.length >= 3 &&
        _greekCaseMap.containsKey(segment[0]) &&
        _greekNumberMap.containsKey(segment[1]) &&
        _greekGenderMap.containsKey(segment[2]);
  }

  static bool _looksLikeGreekPersonNumber(String segment) {
    return segment.length >= 2 &&
        _isDigit(segment[0]) &&
        _greekNumberMap.containsKey(segment[1]);
  }

  static bool _isDigit(String value) {
    return value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;
  }

  static String _ordinalPerson(String person) {
    switch (person) {
      case '1':
        return '1st';
      case '2':
        return '2nd';
      case '3':
        return '3rd';
      default:
        return person;
    }
  }

  static String _abbreviateGender(String gender) {
    switch (gender) {
      case 'Masculine':
        return 'Masc';
      case 'Feminine':
        return 'Fem';
      case 'Neuter':
        return 'Neut';
      case 'Common':
        return 'Com';
      default:
        return gender;
    }
  }

  static String _abbreviateNumber(String number) {
    switch (number) {
      case 'Singular':
        return 'Sg';
      case 'Plural':
        return 'Pl';
      case 'Dual':
        return 'Du';
      default:
        return number;
    }
  }

  static String _abbreviateCase(String value) {
    switch (value) {
      case 'Nominative':
        return 'Nom';
      case 'Genitive':
        return 'Gen';
      case 'Dative':
        return 'Dat';
      case 'Accusative':
        return 'Acc';
      case 'Vocative':
        return 'Voc';
      default:
        return value;
    }
  }

  static String _abbreviateState(String value) {
    switch (value) {
      case 'Absolute':
        return 'Abs';
      case 'Construct':
        return 'Constr';
      case 'Determined':
        return 'Det';
      default:
        return value;
    }
  }

  static String _abbreviateTense(String value) {
    switch (value) {
      case 'Present':
        return 'Pres';
      case 'Imperfect':
        return 'Imperf';
      case 'Future':
        return 'Fut';
      case 'Aorist':
        return 'Aor';
      case 'Second Aorist':
        return '2Aor';
      case 'Perfect':
        return 'Perf';
      case 'Pluperfect':
        return 'Plup';
      case 'Sequential perfect':
        return 'SeqPerf';
      case 'Sequential imperfect':
        return 'SeqImperf';
      case 'Participle active':
        return 'ActPtcp';
      case 'Participle passive':
        return 'PassPtcp';
      case 'Infinitive absolute':
        return 'InfAbs';
      case 'Infinitive construct':
        return 'InfConstr';
      default:
        return value;
    }
  }

  static String _abbreviateMood(String value) {
    switch (value) {
      case 'Indicative':
        return 'Ind';
      case 'Subjunctive':
        return 'Subj';
      case 'Optative':
        return 'Opt';
      case 'Imperative':
        return 'Imp';
      case 'Infinitive':
        return 'Inf';
      case 'Participle':
        return 'Ptcp';
      case 'Definite article':
        return 'Article';
      default:
        return value;
    }
  }

  static String? _greekPartOfSpeech(String code) {
    final normalized = code.toUpperCase();
    if (normalized.startsWith('PREP')) return 'Preposition';
    if (normalized.startsWith('ADV')) return 'Adverb';
    if (normalized.startsWith('N')) return 'Noun';
    if (normalized.startsWith('V')) return 'Verb';
    if (normalized.startsWith('A')) return 'Adjective';
    if (normalized.startsWith('T')) return 'Article';
    if (normalized.startsWith('P')) return 'Pronoun';
    if (normalized.startsWith('R')) return 'Pronoun';
    if (normalized.startsWith('D')) return 'Pronoun';
    if (normalized.startsWith('I')) return 'Pronoun';
    if (normalized.startsWith('F')) return 'Pronoun';
    if (normalized.startsWith('X')) return 'Pronoun';
    if (normalized.startsWith('Q')) return 'Pronoun';
    if (normalized.startsWith('S')) return 'Pronoun';
    if (normalized.startsWith('K')) return 'Pronoun';
    if (normalized.startsWith('C')) return 'Conjunction';
    return null;
  }

  static const Map<String, String> _greekTenseMap = {
    'P': 'Present',
    'I': 'Imperfect',
    'F': 'Future',
    'A': 'Aorist',
    '2': 'Second Aorist',
    'X': 'Perfect',
    'Y': 'Pluperfect',
    'R': 'Perfect',
    'L': 'Pluperfect',
  };

  static const Map<String, String> _greekVoiceMap = {
    'A': 'Active',
    'M': 'Middle',
    'P': 'Passive',
    'E': 'Middle or Passive',
    'D': 'Middle Deponent',
    'O': 'Passive Deponent',
    'N': 'Middle or Passive Deponent',
    'Q': 'Impersonal Active',
  };

  static const Map<String, String> _greekMoodMap = {
    'I': 'Indicative',
    'S': 'Subjunctive',
    'O': 'Optative',
    'M': 'Imperative',
    'N': 'Infinitive',
    'P': 'Participle',
  };

  static const Map<String, String> _greekCaseMap = {
    'N': 'Nominative',
    'V': 'Vocative',
    'G': 'Genitive',
    'D': 'Dative',
    'A': 'Accusative',
  };

  static const Map<String, String> _greekNumberMap = {
    'S': 'Singular',
    'P': 'Plural',
    'D': 'Dual',
  };

  static const Map<String, String> _greekGenderMap = {
    'M': 'Masculine',
    'F': 'Feminine',
    'N': 'Neuter',
    'C': 'Common',
  };

  static const Map<String, String> _hebrewPartOfSpeechMap = {
    'S': 'Suffix',
  };

  static const Map<String, String> _hebrewStemMap = {
    'q': 'Qal',
    'N': 'Niphal',
    'p': 'Piel',
    'P': 'Pual',
    'h': 'Hiphil',
    'H': 'Hophal',
    't': 'Hithpael',
    'o': 'Polel',
    'O': 'Polal',
    'r': 'Hithpolel',
    'm': 'Poel',
    'M': 'Poal',
    'k': 'Palel',
    'K': 'Pulal',
    'Q': 'Qal passive',
  };

  static const Map<String, String> _hebrewAspectMap = {
    'p': 'Perfect',
    'q': 'Sequential perfect',
    'i': 'Imperfect',
    'w': 'Sequential imperfect',
    'h': 'Cohortative',
    'j': 'Jussive',
    'v': 'Imperative',
    'r': 'Participle active',
    's': 'Participle passive',
    'a': 'Infinitive absolute',
    'c': 'Infinitive construct',
  };

  static const Map<String, String> _hebrewGenderMap = {
    'm': 'Masculine',
    'f': 'Feminine',
    'b': 'Both',
    'c': 'Common',
  };

  static const Map<String, String> _hebrewNumberMap = {
    's': 'Singular',
    'p': 'Plural',
    'd': 'Dual',
  };

  static const Map<String, String> _hebrewStateMap = {
    'a': 'Absolute',
    'c': 'Construct',
    'd': 'Determined',
  };

  static const Map<String?, String> _hebrewParticleMap = {
    'd': 'Definite article',
  };
}
