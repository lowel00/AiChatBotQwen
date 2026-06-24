import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// YENİ EKLENEN MATEMATİK KÜTÜPHANELERİ
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

import 'database_helper.dart';

void main() {
  runApp(const MathAIApp());
}

class ChatMessage {
  int? id;
  final bool isUser;
  String content;
  String thinking;
  final String? imagePath;

  ChatMessage({
    this.id,
    required this.isUser,
    required this.content,
    this.thinking = "",
    this.imagePath,
  });
}

class MathAIApp extends StatelessWidget {
  const MathAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qwen AI Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _sessions =[];
  int? _currentSessionId;
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _autoScroll = true; 

  final String _apiUrl = "https://vocal-yeti-solely.ngrok-free.app/solve-math";

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await DatabaseHelper.getSessions();
    setState(() {
      _sessions = sessions;
    });
  }

  Future<void> _loadChatHistory(int sessionId) async {
    final messagesData = await DatabaseHelper.getMessages(sessionId);
    List<ChatMessage> loadedMessages = messagesData.map((m) {
      return ChatMessage(
        id: m['id'],
        isUser: m['is_user'] == 1,
        content: m['content'],
        thinking: m['thinking'],
        imagePath: m['image_path'],
      );
    }).toList();

    setState(() {
      _currentSessionId = sessionId;
      _messages = loadedMessages;
      _selectedImage = null;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _startNewSession() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
      _selectedImage = null;
    });
  }

  void _scrollToBottom() {
    if (!_autoScroll) return; 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = p.join(directory.path, fileName);
      final File localImage = await image.copy(localPath);
      return localImage.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendMessage() async {
    String text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    File? imageToSend = _selectedImage;
    String? localImagePath;

    setState(() {
      _isLoading = true;
      _autoScroll = true; 
      _selectedImage = null;
      _textController.clear();
    });

    if (_currentSessionId == null) {
      String title = text.isEmpty ? "Fotoğraflı Soru" : (text.length > 25 ? "${text.substring(0, 25)}..." : text);
      _currentSessionId = await DatabaseHelper.createSession(title);
      await _loadSessions();
    }

    if (imageToSend != null) {
      localImagePath = await _saveImageLocally(imageToSend);
    }

    String userContent = text.isEmpty ? "Bu fotoğrafa bak." : text;
    int userId = await DatabaseHelper.insertMessage(_currentSessionId!, true, userContent, imagePath: localImagePath);

    setState(() {
      _messages.add(ChatMessage(id: userId, isUser: true, content: userContent, imagePath: localImagePath));
    });
    
    int aiMessageId = await DatabaseHelper.insertMessage(_currentSessionId!, false, "", thinking: "");
    
    setState(() {
      _messages.add(ChatMessage(id: aiMessageId, isUser: false, content: ""));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });

    try {
      List<Map<String, dynamic>> apiMessages =[];
      for (int i = 0; i < _messages.length - 1; i++) {
        var m = _messages[i];
        apiMessages.add({"role": m.isUser ? "user" : "assistant", "content": m.content});
      }

      if (imageToSend != null) {
        final bytes = await imageToSend.readAsBytes();
        apiMessages.last["images"] = [base64Encode(bytes)];
      }

      var request = http.Request('POST', Uri.parse(_apiUrl));
      request.headers['Content-Type'] = 'application/json';
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.body = jsonEncode({"messages": apiMessages});

      var response = await http.Client().send(request);

      if (response.statusCode == 200) {
        response.stream.transform(utf8.decoder).listen((value) {
          var lines = value.split('\n');
          for (var line in lines) {
            if (line.trim().isNotEmpty) {
              try {
                var jsonResponse = jsonDecode(line);
                if (jsonResponse['message'] != null) {
                  var message = jsonResponse['message'];
                  setState(() {
                    var lastMessage = _messages.last;
                    if (message['thinking'] != null) lastMessage.thinking += message['thinking'];
                    if (message['content'] != null) lastMessage.content += message['content'];
                  });
                  _scrollToBottom(); 
                }

                if (jsonResponse['done'] == true) {
                  DatabaseHelper.updateMessage(aiMessageId, _messages.last.content, _messages.last.thinking);
                  setState(() { _isLoading = false; });
                }
              } catch (e) {}
            }
          }
        }, onDone: () {
          setState(() { _isLoading = false; });
        });
      } else {
        setState(() {
          _messages.last.content = "Hata: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.last.content = "Bağlantı koptu. Python sunucusunu kontrol et.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        child: Column(
          children:[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: SizedBox(
                width: double.infinity,
                child: Text('Sohbet Geçmişi', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
              title: const Text('Yeni Sohbet Başlat', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                _startNewSession();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final isSelected = session['id'] == _currentSessionId;
                  
                  // YENİ EKLENEN: Sola Kaydırarak Silme (Swipe to Delete) Widget'ı
                  return Dismissible(
                    key: Key(session['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await DatabaseHelper.deleteSession(session['id']); // Veritabanından uçur
                      if (isSelected) {
                        _startNewSession(); // Eğer sildiğimiz sohbet o an açıksa, ekranı temizle
                      }
                      _loadSessions(); // Listeyi yenile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sohbet silindi!')),
                      );
                    },
                    child: ListTile(
                      tileColor: isSelected ? Colors.deepPurple.shade50 : null,
                      leading: Icon(Icons.chat_bubble_outline, color: isSelected ? Colors.deepPurple : Colors.grey),
                      title: Text(session['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.pop(context);
                        if (!isSelected) _loadChatHistory(session['id']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Qwen AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children:[
            Column(
              children:[
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is UserScrollNotification) {
                        if (notification.direction == ScrollDirection.forward) setState(() { _autoScroll = false; });
                      }
                      if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 10) {
                        if (!_autoScroll) setState(() { _autoScroll = true; });
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), 
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
                  ),
                ),

                if (_selectedImage != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade200),
                    ),
                    child: Row(
                      children:[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, width: 60, height: 60, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Text("Fotoğraf eklendi", style: TextStyle(fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _selectedImage = null),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children:[
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo, color: Colors.deepPurple),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Bir şeyler yaz...",
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: IconButton(
                          icon: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!_autoScroll && _messages.isNotEmpty)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    setState(() { _autoScroll = true; });
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: const[BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              if (msg.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(msg.imagePath!), fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
              ],
              
              if (!msg.isUser && msg.thinking.isNotEmpty) ...[
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.psychology, color: Colors.orange),
                    title: Text(
                      _isLoading && _messages.last == msg ? "Düşünüyor..." : "Düşünce Süreci",
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    children:[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(msg.thinking, style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
                const Divider(), 
              ],

              // YENİ EKLENEN: MATEMATİKSEL FORMÜL RENDER SİSTEMİ (LATEX)
              if (msg.content.isNotEmpty)
                msg.isUser 
                  ? Text(
                      msg.content,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    )
                  : MarkdownBody( 
                      data: msg.content,
                      selectable: true, 
                      // Latex inşasını ve okumasını sağlıyoruz
                      builders: {
                        'latex': LatexElementBuilder(
                          textStyle: const TextStyle(color: Colors.black),
                        ),
                      },
                      extensionSet: md.ExtensionSet([...md.ExtensionSet.gitHubFlavored.blockSyntaxes, LatexBlockSyntax()],[...md.ExtensionSet.gitHubFlavored.inlineSyntaxes, LatexInlineSyntax()],
                      ),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15, color: Colors.black87),
                        strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        em: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                      ),
                    ),
                
              if (!msg.isUser && msg.content.isEmpty && msg.thinking.isEmpty)
                const SizedBox(
                  width: 40,
                  height: 20,
                  child: Center(child: LinearProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}