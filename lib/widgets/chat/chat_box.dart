import 'package:flutter/material.dart';

import 'package:chagas_predictor/models/chat_message.dart';
import 'package:chagas_predictor/services/ai/groq_chat_client.dart';
import 'package:chagas_predictor/services/patient/patient_service.dart';

const List<String> _quickPrompts = [
  '🩺 What are early symptoms of Chagas disease?',
  '⚡ How does LSTM predict Chagas cardiomyopathy risk?',
  '🛡️ How is Triatomine (kissing bug) infection prevented?',
  '💊 What treatment options exist for acute vs chronic Chagas?',
  '💓 Explain ECG PR interval & QRS duration biomarkers',
];

class ChatBox extends StatefulWidget {
  const ChatBox({super.key});

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatClient = GroqChatClient();

  final List<ChatMessage> _messages = [
    const ChatMessage(
      text:
          'Hello! I am Dr. Carlos Chagas AI, your Chagas Cardiomyopathy & Tropical Disease Specialist Physician.\n\nHow can I help you today regarding Chagas disease, ECG risk analysis, symptoms, or diagnostic testing?',
      isUser: false,
    ),
  ];

  bool _isWaiting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final userText = presetText ?? _messageController.text.trim();
    if (userText.isEmpty || _isWaiting) return;

    final history = List<ChatMessage>.from(_messages);
    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      if (presetText == null) {
        _messageController.clear();
      }
      _isWaiting = true;
    });
    _scrollToBottom();

    // Prepare rich patient clinical context
    final patient = PatientService().patientDetails;
    final patientContext = 'Patient Name: ${patient.fullName}, Age: ${patient.age}, Gender: ${patient.gender}, City: ${patient.city}';

    String reply;
    try {
      reply = await _chatClient.sendMessage(
        userText: userText,
        conversation: history,
        patientContext: patientContext,
      );
    } on ChatConfigurationException {
      reply =
          'Dr. Chagas AI is not configured. Please ensure GROQ_API_KEY is supplied.';
    } on ChatServiceException catch (e) {
      reply =
          'I apologize, but Dr. Chagas AI connection experienced an error (${e.statusCode}). Please check your connection and try again.';
    } catch (e) {
      reply =
          'Dr. Chagas AI encountered a temporary issue responding: $e. Please try asking again.';
    }

    if (!mounted) return;
    setState(() {
      _isWaiting = false;
      _messages.add(ChatMessage(text: reply, isUser: false));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF006B67).withValues(alpha: 0.15), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14006B67),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Profile Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF006B67),
                  const Color(0xFF004D4A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Emerald online dot
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Dr. Carlos Chagas AI',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.verified_rounded, color: Color(0xFF5EEAD4), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chagas Specialist Physician • 24/7 Consultation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reset Conversation',
                  onPressed: () {
                    setState(() {
                      _messages.clear();
                      _messages.add(
                        const ChatMessage(
                          text:
                              'Hello! I am Dr. Carlos Chagas AI. How can I assist you with Chagas disease clinical insights or ECG interpretation?',
                          isUser: false,
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Suggestion Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final prompt in _quickPrompts)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.psychology_rounded, size: 14, color: Color(0xFF006B67)),
                            label: Text(
                              prompt,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006B67),
                              ),
                            ),
                            backgroundColor: const Color(0xFF006B67).withValues(alpha: 0.08),
                            side: BorderSide(color: const Color(0xFF006B67).withValues(alpha: 0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: _isWaiting ? null : () => _sendMessage(prompt),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Chat Messages View
                Container(
                  height: 310,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length + (_isWaiting ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF006B67),
                                child: const Icon(Icons.medical_services_rounded, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF006B67),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Dr. Chagas AI is evaluating clinical records…',
                                      style: TextStyle(
                                        color: Color(0xFF006B67),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final message = _messages[index];
                      final isUser = message.isUser;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: const Color(0xFF006B67),
                                child: const Icon(Icons.medical_services_rounded, size: 15, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF006B67)
                                      : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 18),
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.6)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isUser
                                          ? const Color(0x20006B67)
                                          : const Color(0x0A000000),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'Dr. Carlos Chagas AI',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF047857),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    SelectableText(
                                      message.text,
                                      style: TextStyle(
                                        color: isUser ? Colors.white : const Color(0xFF1F2937),
                                        fontSize: 13.5,
                                        height: 1.45,
                                        fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 10),
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: const Color(0xFFE46A4A),
                                child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Text Input Field & Send Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask Dr. Chagas AI about symptoms, ECG, or risks…',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF006B67), size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF006B67), width: 1.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isWaiting ? null : () => _sendMessage(),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Ask Doctor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

