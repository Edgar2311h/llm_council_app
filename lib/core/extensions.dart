/// Utility extensions for the LLM Council app.
library;

extension StringExtensions on String {
  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - 3)}...';
  }

  /// Extract model display name from OpenRouter identifier
  String get modelDisplayName {
    final parts = split('/');
    if (parts.length >= 2) {
      return parts[1].replaceAll('-', ' ').capitalize();
    }
    return this;
  }

  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Extract provider from model ID
  String get modelProvider {
    final parts = split('/');
    return parts.isNotEmpty ? parts[0].capitalize() : 'Unknown';
  }
}

extension DateTimeExtensions on DateTime {
  /// Format as relative time string
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 7) {
      return '${day}/${month}/${year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

extension ListExtensions<T> on List<T> {
  /// Safe get with null fallback
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
}
