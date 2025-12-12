import 'package:equatable/equatable.dart';

/// Conversation events
abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ConversationEvent {}

class CreateConversation extends ConversationEvent {}

class SelectConversation extends ConversationEvent {
  final String conversationId;

  const SelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class DeleteConversation extends ConversationEvent {
  final String conversationId;

  const DeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class UpdateConversationTitle extends ConversationEvent {
  final String conversationId;
  final String title;

  const UpdateConversationTitle(this.conversationId, this.title);

  @override
  List<Object?> get props => [conversationId, title];
}

class RefreshMessages extends ConversationEvent {
  final String conversationId;

  const RefreshMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class ClearAllConversations extends ConversationEvent {}
