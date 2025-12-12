import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/database/database_helper.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/models/message.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final DatabaseHelper _database;

  ConversationBloc({
    DatabaseHelper? database,
  })  : _database = database ?? DatabaseHelper.instance,
        super(ConversationInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<CreateConversation>(_onCreateConversation);
    on<SelectConversation>(_onSelectConversation);
    on<DeleteConversation>(_onDeleteConversation);
    on<UpdateConversationTitle>(_onUpdateConversationTitle);
    on<RefreshMessages>(_onRefreshMessages);
    on<ClearAllConversations>(_onClearAllConversations);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationState> emit,
  ) async {
    emit(ConversationsLoading());

    try {
      final conversations = await _database.listConversations();
      emit(ConversationsLoaded(conversations: conversations));
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final conversation = await _database.createConversation();

      if (state is ConversationsLoaded) {
        final currentState = state as ConversationsLoaded;
        emit(ConversationsLoaded(
          conversations: [conversation, ...currentState.conversations],
          currentConversation: conversation,
          messages: [],
        ));
      } else {
        emit(ConversationsLoaded(
          conversations: [conversation],
          currentConversation: conversation,
          messages: [],
        ));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onSelectConversation(
    SelectConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final conversation =
          await _database.getConversation(event.conversationId);
      final messages = await _database.getMessages(event.conversationId);

      if (state is ConversationsLoaded && conversation != null) {
        final currentState = state as ConversationsLoaded;
        emit(currentState.copyWith(
          currentConversation: conversation,
          messages: messages,
        ));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _database.deleteConversation(event.conversationId);

      if (state is ConversationsLoaded) {
        final currentState = state as ConversationsLoaded;
        final updatedConversations = currentState.conversations
            .where((c) => c.id != event.conversationId)
            .toList();

        final shouldClearCurrent =
            currentState.currentConversation?.id == event.conversationId;

        emit(currentState.copyWith(
          conversations: updatedConversations,
          clearCurrentConversation: shouldClearCurrent,
          messages: shouldClearCurrent ? [] : null,
        ));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onUpdateConversationTitle(
    UpdateConversationTitle event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _database.updateConversationTitle(
          event.conversationId, event.title);

      if (state is ConversationsLoaded) {
        final currentState = state as ConversationsLoaded;
        final updatedConversations = currentState.conversations.map((c) {
          if (c.id == event.conversationId) {
            return c.copyWith(title: event.title);
          }
          return c;
        }).toList();

        Conversation? updatedCurrent = currentState.currentConversation;
        if (updatedCurrent?.id == event.conversationId) {
          updatedCurrent = updatedCurrent!.copyWith(title: event.title);
        }

        emit(currentState.copyWith(
          conversations: updatedConversations,
          currentConversation: updatedCurrent,
        ));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  Future<void> _onRefreshMessages(
    RefreshMessages event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final messages = await _database.getMessages(event.conversationId);
      final conversation =
          await _database.getConversation(event.conversationId);

      if (state is ConversationsLoaded) {
        final currentState = state as ConversationsLoaded;

        // Update current conversation with latest data (including title)
        // and update in the conversations list
        List<Conversation> updatedConversations = currentState.conversations;
        if (conversation != null) {
          updatedConversations = currentState.conversations.map((c) {
            if (c.id == event.conversationId) {
              return conversation;
            }
            return c;
          }).toList();
        }

        emit(currentState.copyWith(
          messages: messages,
          currentConversation: conversation,
          conversations: updatedConversations,
        ));
      }
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }

  /// Add a message to the current conversation (used by CouncilBloc)
  Future<void> addMessage(Message message) async {
    if (state is ConversationsLoaded) {
      final currentState = state as ConversationsLoaded;
      // ignore: invalid_use_of_visible_for_testing_member
      emit(currentState.copyWith(
        messages: [...currentState.messages, message],
      ));
    }
  }

  /// Update the last message (used for progressive loading)
  Future<void> updateLastMessage(Message Function(Message) updater) async {
    if (state is ConversationsLoaded) {
      final currentState = state as ConversationsLoaded;
      if (currentState.messages.isNotEmpty) {
        final messages = List<Message>.from(currentState.messages);
        messages[messages.length - 1] = updater(messages.last);
        // ignore: invalid_use_of_visible_for_testing_member
        emit(currentState.copyWith(messages: messages));
      }
    }
  }

  Future<void> _onClearAllConversations(
    ClearAllConversations event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await _database.clearAllConversations();
      emit(ConversationsLoaded(
        conversations: [],
        messages: [],
      ));
    } catch (e) {
      emit(ConversationError(e.toString()));
    }
  }
}
