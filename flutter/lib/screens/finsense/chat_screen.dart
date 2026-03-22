import 'package:flutter/material.dart';
import '../../services/setu_service.dart';
import 'package:provider/provider.dart';
import '../../auth_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0A0E2E);
  static const _darkBg = Color(0xFF050818);
  static const _cardBg = Color(0xFF0D1B4B);
  static const _blue = Color(0xFF1565C0);
  static const _red = Color(0xFFC62828);
  static const _green = Color(0xFF00C853);

  final SetuService _api = SetuService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;
  late AnimationController _pulseController;

  final List<Map<String, String>> _messages = [];

  final List<String> _suggestions = [
    "How much did I spend on food?",
    "Am I on track with my budget?",
    "Should I invest this month?",
    "What's my savings rate?",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage([String? text]) async {
    final msg = text ?? _msgCtrl.text.trim();
    if (msg.isEmpty) return;

    final userId = Provider.of<AuthProvider>(context, listen: false).serialId.toString();

    setState(() {
      _messages.add({"role": "user", "content": msg});
      _msgCtrl.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.take(_messages.length - 1).toList();
      final response = await _api.chat(userId, msg, history);
      
      setState(() {
        _messages.add({"role": "assistant", "content": response});
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "Error: ${e.toString()}"});
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.smart_toy, color: _blue),
            const SizedBox(width: 10),
            const Text("FinSense AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _green, blurRadius: 4)]),
              ),
            ),
          ],
        ),
        shape: const Border(bottom: BorderSide(color: _blue, width: 0.5)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isUser = m['role'] == 'user';
                      return _buildMessageBubble(m['content']!, isUser);
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: _blue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy_outlined, size: 64, color: _blue),
              ),
              const SizedBox(height: 24),
              const Text("Ask me anything about your finances", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("I can analyze your spending, check budgets, and give advice.", style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: _suggestions.map((s) => OutlinedButton(
                  onPressed: () => _sendMessage(s),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _blue.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13)),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 4),
            child: Text("FinSense", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              gradient: isUser 
                ? const LinearGradient(colors: [_blue, Color(0xFF0D47A1)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
              color: isUser ? null : _cardBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser ? null : Border.all(color: _blue.withOpacity(0.3), width: 0.5),
            ),
            child: Text(
              text,
              style: TextStyle(color: isUser ? Colors.white : Colors.white.withOpacity(0.9), fontSize: 14),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Text(
            TimeOfDay.now().format(context),
            style: const TextStyle(color: Colors.white24, fontSize: 9),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Row(
        children: [
          const Text("AI is thinking", style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(width: 8),
          _buildAnimatedDot(0),
          _buildAnimatedDot(1),
          _buildAnimatedDot(2),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double opacity = ((_pulseController.value - (index * 0.2)).abs() % 1.0).clamp(0.2, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4, height: 4,
          decoration: BoxDecoration(color: _blue.withOpacity(opacity), shape: BoxShape.circle),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: _navy,
        border: Border(top: BorderSide(color: _blue, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              cursorColor: _blue,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ask about your spending...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: _cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _blue, width: 1)),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_blue, Color(0xFF0D47A1)]),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
