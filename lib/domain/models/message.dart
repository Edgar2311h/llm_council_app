import 'package:equatable/equatable.dart';
import 'stage_result.dart';

/// Represents a single message in a conversation
class Message extends Equatable {
  final int? id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  final String? content; // For user messages
  final List<ModelResponseResult>? stage1;
  final List<RankingResult>? stage2;
  final SynthesisResult? stage3;
  final CouncilMetadata? metadata;
  final DateTime createdAt;

  const Message({
    this.id,
    required this.conversationId,
    required this.role,
    this.content,
    this.stage1,
    this.stage2,
    this.stage3,
    this.metadata,
    required this.createdAt,
  });

  /// Create a user message
  factory Message.user({
    required String conversationId,
    required String content,
  }) {
    return Message(
      conversationId: conversationId,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
  }

  /// Create an assistant message from council response
  factory Message.assistant({
    required String conversationId,
    required CouncilResponse response,
  }) {
    return Message(
      conversationId: conversationId,
      role: 'assistant',
      stage1: response.stage1,
      stage2: response.stage2,
      stage3: response.stage3,
      metadata: response.metadata,
      createdAt: DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Message copyWith({
    int? id,
    String? conversationId,
    String? role,
    String? content,
    List<ModelResponseResult>? stage1,
    List<RankingResult>? stage2,
    SynthesisResult? stage3,
    CouncilMetadata? metadata,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      stage1: stage1 ?? this.stage1,
      stage2: stage2 ?? this.stage2,
      stage3: stage3 ?? this.stage3,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        role,
        content,
        stage1,
        stage2,
        stage3,
        metadata,
        createdAt
      ];
}
