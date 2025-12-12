import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/message.dart';
import '../bloc/conversation/conversation_bloc.dart';
import '../bloc/conversation/conversation_event.dart';
import '../bloc/conversation/conversation_state.dart';
import '../bloc/council/council_bloc.dart';
import '../bloc/council/council_event.dart';
import '../bloc/council/council_state.dart';
import '../theme/executive_theme.dart';
import '../widgets/stage_tabs.dart';

/// Chat interface with stage visualization.
class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    context.read<CouncilBloc>().add(SubmitQuery(
          conversationId: widget.conversationId,
          query: content,
        ));

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEditTitleDialog(String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new title',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != currentTitle) {
                context.read<ConversationBloc>().add(
                      UpdateConversationTitle(
                        widget.conversationId,
                        newTitle,
                      ),
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ConversationBloc, ConversationState>(
          builder: (context, state) {
            if (state is ConversationsLoaded &&
                state.currentConversation != null) {
              return GestureDetector(
                onTap: () =>
                    _showEditTitleDialog(state.currentConversation!.title),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        state.currentConversation!.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: ExecutiveTheme.textDisabled,
                    ),
                  ],
                ),
              );
            }
            return const Text('Council');
          },
        ),
      ),
      body: BlocListener<CouncilBloc, CouncilState>(
        listener: (context, state) {
          if (state is CouncilError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ExecutiveTheme.errorColor,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ConversationBloc, ConversationState>(
                builder: (context, state) {
                  if (state is ConversationsLoaded) {
                    return _buildMessageList(state.messages);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages) {
    return BlocBuilder<CouncilBloc, CouncilState>(
      builder: (context, councilState) {
        final isProcessing = councilState is CouncilProcessing;

        // If no messages and not processing, show welcome
        if (messages.isEmpty && !isProcessing) {
          return _buildWelcomeMessage();
        }

        // Build list with processing state at the end
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length + (isProcessing ? 1 : 0),
          itemBuilder: (context, index) {
            // Show processing widget at the end
            if (index == messages.length && isProcessing) {
              return _buildProcessingStages(councilState);
            }

            final message = messages[index];
            return _buildMessageBubble(message, index);
          },
        );
      },
    );
  }

  Widget _buildProcessingStages(CouncilProcessing state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: ExecutiveTheme.goldAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ExecutiveTheme.goldAccent.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ExecutiveTheme.goldAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _getProcessingStatus(state),
                  style: TextStyle(
                    color: ExecutiveTheme.goldAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Progressive StageTabsWidget
          StageTabsWidget(
            stage1: state.stage1Results,
            stage2: state.stage2Results,
            stage3: state.stage3Result != null ? state.stage3Result : null,
            metadata: state.metadata,
            isLoading: true,
            stage1Loading: state.stage1Loading,
            stage2Loading: state.stage2Loading,
            stage3Loading: state.stage3Loading,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  String _getProcessingStatus(CouncilProcessing state) {
    if (state.stage3Loading) return 'Stage 3: Chairman synthesizing...';
    if (state.stage3Result != null) return 'Finishing up...';
    if (state.stage2Loading) return 'Stage 2: Models ranking each other...';
    if (state.stage2Results != null) return 'Stage 2 complete';
    if (state.stage1Loading) return 'Stage 1: Gathering opinions...';
    if (state.stage1Results != null) return 'Stage 1 complete';
    return 'Starting council deliberation...';
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ask the Council',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your question will be sent to multiple AI models.\nThey\'ll evaluate each other\'s responses and provide\na synthesized answer.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, int index) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 48),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ExecutiveTheme.goldAccent.withOpacity(0.2),
                  ExecutiveTheme.goldAccent.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(
                color: ExecutiveTheme.goldAccent.withOpacity(0.3),
              ),
            ),
            child: Text(
              message.content ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(
            begin: 0.1,
            end: 0,
            duration: 200.ms,
          );
    }

    // Assistant message with stage tabs
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 16),
      child: StageTabsWidget(
        stage1: message.stage1,
        stage2: message.stage2,
        stage3: message.stage3,
        metadata: message.metadata,
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: index * 100),
          duration: 300.ms,
        );
  }

  Widget _buildInputArea() {
    return BlocBuilder<CouncilBloc, CouncilState>(
      builder: (context, state) {
        final isProcessing = state is CouncilProcessing;

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: ExecutiveTheme.cardBackground,
            border: Border(
              top: BorderSide(
                color: ExecutiveTheme.dividerColor.withOpacity(0.5),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !isProcessing,
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: isProcessing
                        ? 'Council is deliberating...'
                        : 'Ask the council...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: ExecutiveTheme.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: const BoxDecoration(
                  gradient: ExecutiveTheme.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: isProcessing ? null : _sendMessage,
                  icon: Icon(
                    Icons.arrow_upward,
                    color: isProcessing
                        ? ExecutiveTheme.textDisabled
                        : ExecutiveTheme.primaryBackground,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
