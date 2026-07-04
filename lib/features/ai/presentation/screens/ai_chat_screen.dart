import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/ai/data/models/chat_message.dart';
import 'package:bizos/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:bizos/features/ai/presentation/bloc/ai_event.dart';
import 'package:bizos/features/ai/presentation/bloc/ai_state.dart';
import 'package:bizos/features/ai/presentation/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isAILoading = false;

  // Recommended ERP Prompts
  final List<Map<String, dynamic>> _quickPrompts = [
    {
      'title': 'Analyze Expenses',
      'icon': Icons.account_balance_wallet_outlined,
      'prompt': 'Show me a summary of our recent business expenses and highlight any areas we can cut costs.',
    },
    {
      'title': 'Task Overviews',
      'icon': Icons.assignment_outlined,
      'prompt': 'What are the current pending tasks for my team, and which ones are high priority?',
    },
    {
      'title': 'Staff Distribution',
      'icon': Icons.people_outline,
      'prompt': 'List active staff members and their primary assigned roles in the system.',
    },
    {
      'title': 'Profit & Loss Summary',
      'icon': Icons.analytics_outlined,
      'prompt': 'Provide a monthly profit and loss summary outline for my businesses based on active records.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Add Welcome message
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text: 'Hello! I am Voryn AI, your business intelligence assistant. Ask me anything about expenses, staff, tasks, or business performance across your enterprise.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text.trim(),
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isAILoading = true;
    });

    _textController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();

    // Trigger AI request via Bloc
    context.read<AiBloc>().add(AskAiEvent(prompt: userMessage.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voryn AI',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            Text(
              'Business Assistant',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    id: 'welcome',
                    text: 'Hello! I am Voryn AI, your business intelligence assistant. Ask me anything about expenses, staff, tasks, or business performance across your enterprise.',
                    sender: MessageSender.ai,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: BlocConsumer<AiBloc, AiState>(
        listener: (context, state) {
          if (state is AiLoaded) {
            setState(() {
              _isAILoading = false;
              _messages.add(
                ChatMessage(
                  id: const Uuid().v4(),
                  text: state.response ?? '',
                  sender: MessageSender.ai,
                  timestamp: DateTime.now(),
                ),
              );
            });
            _scrollToBottom();
          } else if (state is AiError) {
            setState(() {
              _isAILoading = false;
              _messages.add(
                ChatMessage(
                  id: const Uuid().v4(),
                  text: 'Sorry, I encountered an error: ${state.error}. Please check your connection and try again.',
                  sender: MessageSender.ai,
                  timestamp: DateTime.now(),
                ),
              );
            });
            _scrollToBottom();
          } else if (state is AiLoading) {
            setState(() {
              _isAILoading = true;
            });
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _messages.length <= 1
                      ? _buildEmptyState(theme, isDark)
                      : _buildConversationList(),
                ),
                if (_isAILoading) _buildLoadingIndicator(theme, isDark),
                _buildInputSection(theme, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Voryn AI',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Your personal SaaS ERP assistant. Ask analytical questions about your businesses, expenses, staff rosters, and tasks.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Suggestions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickPrompts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final promptItem = _quickPrompts[index];
              return InkWell(
                onTap: () {
                  _textController.text = promptItem['prompt'];
                  _focusNode.requestFocus();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          promptItem['icon'],
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      Text(
                        promptItem['title'],
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade100,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Ask about expenses, staff, tasks or business insights...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14.0,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
