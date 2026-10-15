import 'package:flutter/material.dart';
import 'package:swasth_id_app/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:swasth_id_app/core/constants/api_constants.dart';

class HealthBotScreen extends StatefulWidget {
  const HealthBotScreen({super.key});

  @override
  State<HealthBotScreen> createState() => _HealthBotScreenState();
}

class _HealthBotScreenState extends State<HealthBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial Greeting
    _addMessage("bot", "Hi! I am Swasth AI. I can help you assess your symptoms. How are you feeling today?");
  }

  void _addMessage(String sender, String text) {
    if (!mounted) return;
    setState(() {
      _messages.add({"sender": sender, "text": text});
    });
    Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
            _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
            );
        }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _addMessage("user", text);
    setState(() => _isTyping = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final healthId = prefs.getString('health_id') ?? "guest";
      
      // Use the existing RAG chat endpoint: /swasth-ai/ask
      // It expects Form Data (x-www-form-urlencoded), NOT JSON.
      final uri = Uri.parse('${ApiConstants.baseUrl}/swasth-ai/ask');
      
      final response = await http.post(
          uri, 
          // No JSON headers for form data
          body: {
              "health_id": healthId,
              "question": text
          }
      );

      if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // Backend returns keys like "answer" or "response"
          // In main.py: return {"assistant": "...", "answer": "..."}
          _addMessage("bot", data['answer'] ?? "I didn't understand that.");
      } else {
           _addMessage("bot", "Sorry, I'm having trouble connecting to the server. (${response.statusCode})");
      }
    } catch (e) {
       _addMessage("bot", "Network error. Please try again.");
    } finally {
        if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Self Assessment Bot", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Typ indicator
          if (_isTyping)
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
               child: Align(child: Text("Swasth AI is thinking...", style: TextStyle(color: Colors.grey, fontSize: 12))),
             ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-4))]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your symptoms...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: AppColors.primaryColor,
                  child: const Icon(Icons.send, color: Colors.white),
                  mini: true,
                  elevation: 0,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
