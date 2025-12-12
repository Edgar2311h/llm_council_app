import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/extensions.dart';
import '../bloc/conversation/conversation_bloc.dart';
import '../bloc/conversation/conversation_event.dart';
import '../bloc/conversation/conversation_state.dart';
import '../theme/executive_theme.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

/// Home screen with conversation list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _shouldNavigateToNew = false;

  @override
  void initState() {
    super.initState();
    context.read<ConversationBloc>().add(LoadConversations());
  }

  void _createNewConversation() {
    // Set flag to indicate we want to navigate when new conversation is created
    _shouldNavigateToNew = true;
    context.read<ConversationBloc>().add(CreateConversation());
  }

  void _openConversation(String conversationId) {
    context.read<ConversationBloc>().add(SelectConversation(conversationId));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  void _deleteConversation(String conversationId) {
    context.read<ConversationBloc>().add(DeleteConversation(conversationId));
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text(
          'Are you sure you want to delete all conversations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ConversationBloc>().add(ClearAllConversations());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All conversations cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 36,
                height: 36,
              ),
            ),
            const SizedBox(width: 12),
            const Text('LLM Council'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: () => _showClearAllDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ConversationBloc, ConversationState>(
        listener: (context, state) {
          // Only navigate on explicit new conversation creation
          // This flag is set when the FAB is pressed and cleared after navigation
          if (state is ConversationsLoaded &&
              state.currentConversation != null &&
              state.messages.isEmpty &&
              _shouldNavigateToNew) {
            _shouldNavigateToNew = false;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: state.currentConversation!.id,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ConversationsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return _buildEmptyState();
            }
            return _buildConversationList(state);
          }

          if (state is ConversationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ExecutiveTheme.errorColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading conversations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewConversation,
        icon: const Icon(Icons.add),
        label: const Text('New Council'),
      ).animate().fadeIn(duration: 300.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ExecutiveTheme.surfaceColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 48,
                color: ExecutiveTheme.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Conversations Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new council to get collective AI wisdom on any topic.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewConversation,
              icon: const Icon(Icons.add),
              label: const Text('Start New Council'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(ConversationsLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.conversations.length,
      itemBuilder: (context, index) {
        final conversation = state.conversations[index];
        return Dismissible(
          key: Key(conversation.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Conversation'),
                    content: const Text(
                        'Are you sure you want to delete this conversation?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => _deleteConversation(conversation.id),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: ExecutiveTheme.errorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(
              Icons.delete_outline,
              color: ExecutiveTheme.errorColor,
            ),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () => _openConversation(conversation.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ExecutiveTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: ExecutiveTheme.goldAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${conversation.messageCount} messages • ${conversation.updatedAt.relativeTime}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: ExecutiveTheme.textDisabled,
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: index * 50),
                duration: 300.ms,
              )
              .slideX(
                begin: 0.05,
                end: 0,
                delay: Duration(milliseconds: index * 50),
                duration: 300.ms,
              ),
        );
      },
    );
  }
}
