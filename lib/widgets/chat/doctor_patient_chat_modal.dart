import 'package:flutter/material.dart';
import 'package:chagas_predictor/models/doctor_patient_message.dart';
import 'package:chagas_predictor/services/chat/doctor_patient_messaging_service.dart';
import 'package:chagas_predictor/services/patient/doctor_portal_service.dart';

class DoctorPatientChatModal extends StatefulWidget {
  final String patientEmail;
  final String patientName;
  final String doctorEmail;
  final String doctorName;
  final String currentUserEmail;
  final String currentUserName;
  final String currentUserRole; // 'Patient' or 'Doctor'

  const DoctorPatientChatModal({
    super.key,
    required this.patientEmail,
    required this.patientName,
    required this.doctorEmail,
    required this.doctorName,
    required this.currentUserEmail,
    required this.currentUserName,
    required this.currentUserRole,
  });

  @override
  State<DoctorPatientChatModal> createState() => _DoctorPatientChatModalState();
}

class _DoctorPatientChatModalState extends State<DoctorPatientChatModal> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messagingService = DoctorPatientMessagingService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messagingService.markMessagesAsRead(
      patientEmail: widget.patientEmail,
      doctorEmail: widget.doctorEmail,
      currentRole: widget.currentUserRole,
    );
  }

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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    await _messagingService.sendMessage(
      patientEmail: widget.patientEmail,
      doctorEmail: widget.doctorEmail,
      senderEmail: widget.currentUserEmail,
      senderName: widget.currentUserName,
      senderRole: widget.currentUserRole,
      content: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: DoctorPortalService().streamDoctorProfile(widget.doctorEmail),
      builder: (context, docSnap) {
        final currentDoctorName = (docSnap.data?['doctorName'] as String?) ?? widget.doctorName;
        final otherPartyName = widget.currentUserRole == 'Doctor'
            ? widget.patientName
            : currentDoctorName;
        final otherPartySubtitle = widget.currentUserRole == 'Doctor'
            ? 'Patient Consultation Channel • Live Database'
            : 'Chief Cardiologist • Direct Messaging Channel';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: 650,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Chat Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF006B67),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Icon(
                      widget.currentUserRole == 'Doctor' ? Icons.person : Icons.medical_services_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherPartyName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          otherPartySubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Message Stream
            Expanded(
              child: StreamBuilder<List<DoctorPatientMessage>>(
                stream: _messagingService.getMessagesStream(
                  patientEmail: widget.patientEmail,
                  doctorEmail: widget.doctorEmail,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF006B67)));
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 54,
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No previous messages with $otherPartyName.',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Send a message to start direct clinical consultation.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderEmail.trim().toLowerCase() == widget.currentUserEmail.trim().toLowerCase();

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: const BoxConstraints(maxWidth: 420),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF006B67) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMe ? 'You (${msg.senderRole})' : '${msg.senderName} (${msg.senderRole})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: widget.currentUserRole == 'Doctor'
                            ? 'Type clinical recommendation or reply to patient...'
                            : 'Ask Dr. Sathya a question about symptoms or ECG result...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFF006B67), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _handleSend,
                    backgroundColor: const Color(0xFF006B67),
                    elevation: 1,
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
