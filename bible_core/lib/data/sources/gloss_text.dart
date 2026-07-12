String normalizeGlossToken(String gloss) {
  var normalized = gloss.trim();
  if (normalized.isEmpty) {
    return '';
  }

  normalized = normalized.replaceAll(RegExp(r'<[^>]+>'), ' ');
  normalized = normalized.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]'),
    (match) => match.group(1) ?? '',
  );
  normalized = normalized.replaceAll('/', ' ');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

String composeGlossText(Iterable<String> glosses) {
  var result = '';

  for (final rawGloss in glosses) {
    final gloss = normalizeGlossToken(rawGloss);
    if (gloss.isEmpty) {
      continue;
    }

    if (result.isEmpty) {
      result = gloss.startsWith('-') ? gloss.substring(1) : gloss;
      continue;
    }

    if (_isStandalonePunctuation(gloss)) {
      result += gloss;
      continue;
    }

    if (result.endsWith('-')) {
      result = result.substring(0, result.length - 1);
      result += gloss.startsWith('-') ? gloss.substring(1) : gloss;
      continue;
    }

    if (gloss.startsWith('-')) {
      result += gloss.substring(1);
      continue;
    }

    result += ' $gloss';
  }

  return result;
}

bool _isStandalonePunctuation(String token) {
  return const {
    '.', ',', ';', ':', '!', '?', ')', ']', '}',
  }.contains(token);
}