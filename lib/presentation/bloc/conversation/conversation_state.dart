import 'package:equatable/equatable.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/models/message.dart';

/// Conversation state
abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {}

class ConversationsLoading extends ConversationState {}

class ConversationsLoaded extends ConversationState {
  final List<Conversation> conversations;
  final Conversation? currentConversation;
  final List<Message> messages;

  const ConversationsLoaded({
    required this.conversations,
    this.currentConversation,
    this.messages = const [],
  });

  @override
  List<Object?> get props => [conversations, currentConversation, messages];

  ConversationsLoaded copyWith({
    List<Conversation>? conversations,
    Conversation? currentConversation,
    List<Message>? messages,
    bool clearCurrentConversation = false,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      currentConversation: clearCurrentConversation
          ? null
          : (currentConversation ?? this.currentConversation),
      messages: messages ?? this.messages,
    );
  }
}

class ConversationError extends ConversationState {
  final String message;

  const ConversationError(this.message);

  @override
  List<Object?> get props => [message];
}
