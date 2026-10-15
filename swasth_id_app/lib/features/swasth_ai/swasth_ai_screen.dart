import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasth_id_app/services/swasth_ai_service.dart';

class SwasthAiScreen extends StatefulWidget {
  const SwasthAiScreen({super.key});

  @override
  State<SwasthAiScreen> createState() => _SwasthAiScreenState();
}

class _SwasthAiScreenState extends State<SwasthAiScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  List<dynamic> _sessions = [];
  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  
  String? _currentSessionId;
  String? _healthId; 

  @override
  void initState() {
    super.initState();
    _loadHealthIdAndSessions();
  }

  Future<void> _loadHealthIdAndSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loadedId = prefs.getString('health_id');
      print('SWASTH AI DEBUG: Loaded health_id = $loadedId');
      
      setState(() {
        _healthId = loadedId;
      });

      if (loadedId == null || loadedId.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient profile not found'),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
      } else {
        await _loadSessions();
      }
    } catch (e) {
      print('Error loading health_id in SwasthAiScreen: $e');
    }
  }

  Future<void> _loadSessions() async {
    if (_healthId == null || _healthId!.isEmpty) return;
    final sessions = await SwasthAiService.getSessions(_healthId!);
    setState(() {
      _sessions = sessions;
    });
  }

  Future<void> _loadChat(String sessionId) async {
    setState(() => _isLoading = true);
    final messages = await SwasthAiService.getMessages(sessionId);
    setState(() {
      _currentSessionId = sessionId;
      _messages = messages.map<Map<String, dynamic>>((m) => {
        'role': m['role'],
        'text': m['content'],
        'hasImage': m['has_image'] == true
      }).toList();
      _isLoading = false;
    });
    Navigator.pop(context); // Close drawer
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _messages = [];
      _controller.clear();
      _removeImage();
    });
    Navigator.pop(context); // Close drawer
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add({
        'role': 'user', 
        'text': text,
        'hasImage': _selectedImage != null,
      });
      _isLoading = true;
    });
    
    final imageToSend = _selectedImage;
    _controller.clear();
    _removeImage(); 

    final response = await SwasthAiService.askAi(
      text, 
      image: imageToSend, 
      sessionId: _currentSessionId,
      healthId: _healthId
    );
    
    setState(() {
      _isLoading = false;
      _messages.add({'role': 'ai', 'text': response['answer'] ?? 'No response'});
      
      if (_currentSessionId == null && response['session_id'] != null) {
        _currentSessionId = response['session_id'];
        _loadSessions(); // Refresh list to show new chat title
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF6C63FF)),
              accountName: const Text("Swasth ID User"),
              accountEmail: Text("Health ID: ${_healthId ?? ''}"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF6C63FF)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF6C63FF)),
              title: const Text("New Chat", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
              onTap: _startNewChat,
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft, 
                child: Text("Your Chats", style: TextStyle(color: Colors.grey, fontSize: 12))
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _sessions.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final isSelected = session['id'] == _currentSessionId;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF6C63FF).withOpacity(0.1),
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(
                      session['title'] ?? 'Untitled Chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.black87,
                      ),
                    ),
                    onTap: () => _loadChat(session['id']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Swasth AI', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildChatList(),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  // ... _buildEmptyState, _buildChatList, _buildInputArea helper methods remain same ...
  // Re-inserting them for completeness in replace block, or assuming they exist if I don't overwrite them?
  // The tool instructions say "Rewrite State class". I must provide the full content or I'll lose the helper methods.
  // I will provide the helper methods below to ensure the file is complete and valid.

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Greetings,',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E2C),
            ),
          ),
          const Text(
            'How may I assist you today?',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          
          _buildSuggestionChip("Analyze this report 📷", "Upload a prescription or medical report"),
          _buildSuggestionChip("Symptoms of Dengue 🤒", "What are the common signs?"),
          _buildSuggestionChip("First Aid for Burns 🩹", "Immediate steps to take"),
          _buildSuggestionChip("Is low BP dangerous? ❤️", "Understand health risks"),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionChip(String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        if (title.contains("Analyze")) {
          _pickImage();
        } else {
          _controller.text = title.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim(); // Remove emojis
          _sendMessage();
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isUser 
                  ? const Color(0xFF6C63FF).withOpacity(0.9) 
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(16),
              ),
              boxShadow: isUser ? [] : [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg['hasImage'] == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white.withOpacity(0.2),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Image attached', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Text(
                  msg['text']!,
                  style: TextStyle(
                    fontSize: 16,
                    color: isUser ? Colors.white : const Color(0xFF2D3142),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_imageBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_imageBytes!, height: 40, width: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedImage!.name, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  InkWell(
                    onTap: _removeImage,
                    child: const Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _isLoading ? null : _pickImage,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.image_outlined, 
                            color: _imageBytes != null ? const Color(0xFF6C63FF) : Colors.grey[600]
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => (_healthId == null || _healthId!.isEmpty) ? null : _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6C63FF),
                child: IconButton(
                  onPressed: (_isLoading || _healthId == null || _healthId!.isEmpty) ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
