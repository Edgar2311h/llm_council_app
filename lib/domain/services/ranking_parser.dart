/// Parses ranking information from model evaluation text.
class RankingParser {
  RankingParser._();

  /// Parse the FINAL RANKING section from the model's response.
  static List<String> parseRankingFromText(String rankingText) {
    // Look for "FINAL RANKING:" section
    if (rankingText.contains('FINAL RANKING:')) {
      final parts = rankingText.split('FINAL RANKING:');
      if (parts.length >= 2) {
        final rankingSection = parts[1];

        // Try to extract numbered list format (e.g., "1. Response A")
        final numberedPattern = RegExp(r'\d+\.\s*Response [A-Z]');
        final numberedMatches = numberedPattern.allMatches(rankingSection);

        if (numberedMatches.isNotEmpty) {
          // Extract just the "Response X" part
          final responsePattern = RegExp(r'Response [A-Z]');
          return numberedMatches
              .map((m) => responsePattern.firstMatch(m.group(0)!)?.group(0))
              .whereType<String>()
              .toList();
        }

        // Fallback: Extract all "Response X" patterns in order
        final matches = RegExp(r'Response [A-Z]').allMatches(rankingSection);
        return matches.map((m) => m.group(0)!).toList();
      }
    }

    // Fallback: try to find any "Response X" patterns in order
    final matches = RegExp(r'Response [A-Z]').allMatches(rankingText);
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Create label to model mapping (Response A -> model_id)
  static Map<String, String> createLabelMapping(List<String> models) {
    final mapping = <String, String>{};
    for (var i = 0; i < models.length; i++) {
      final label = 'Response ${String.fromCharCode(65 + i)}'; // A, B, C, ...
      mapping[label] = models[i];
    }
    return mapping;
  }

  /// Get alphabetic labels for responses
  static List<String> getLabels(int count) {
    return List.generate(count, (i) => String.fromCharCode(65 + i));
  }
}
