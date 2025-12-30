import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humini_ai/providers/chat_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  Uint8List? _webImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // تقليل الجودة لتجنب خطأ الحجم
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _webImage = bytes);
    }
  }

  void _send() {
    if (_controller.text.isNotEmpty || _webImage != null) {
      ref.read(chatProvider.notifier).sendMessage(_controller.text, imageBytes: _webImage);
      _controller.clear();
      setState(() => _webImage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isLoading = ref.watch(chatProvider.notifier).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Humini AI", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => ref.read(chatProvider.notifier).clearChat())
        ],
      ),
      body: Column(
        children: [
          Expanded(child: messages.isEmpty ? _buildWelcome() : _buildChatList(messages)),
          if (isLoading) _buildLoading(),
          if (_webImage != null) _buildPreview(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildWelcome() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.forum_outlined, size: 80, color: Colors.deepPurple),
    const SizedBox(height: 16),
    Text("مرحباً بك في هوميني!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
    const Text("اسألني أي شيء أو أرسل صورة لتحليلها", style: TextStyle(color: Colors.grey)),
  ]));

  Widget _buildChatList(List<ChatMessage> messages) => ListView.builder(
    padding: const EdgeInsets.all(15),
    itemCount: messages.length,
    itemBuilder: (context, i) {
      final m = messages[i];
      return Align(
        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(crossAxisAlignment: m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          if (m.base64Image != null) 
            Container(
              margin: const EdgeInsets.only(bottom: 5), 
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(m.base64Image!), width: 220))
            ),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 15),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: m.isUser ? Colors.deepPurple : Colors.white,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomRight: m.isUser ? Radius.zero : const Radius.circular(18),
                bottomLeft: m.isUser ? const Radius.circular(18) : Radius.zero,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: MarkdownBody(
              data: m.text, 
              styleSheet: MarkdownStyleSheet(p: TextStyle(color: m.isUser ? Colors.white : Colors.black87, fontSize: 16))
            ),
          )
        ]),
      );
    }
  );

  Widget _buildLoading() => Padding(padding: const EdgeInsets.all(12), child: Row(children: [
    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple)),
    const SizedBox(width: 12),
    Text("جاري معالجة طلبك...", style: TextStyle(color: Colors.grey.shade600))
  ]));

  Widget _buildPreview() => Container(padding: const EdgeInsets.all(12), color: Colors.white, child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(_webImage!, width: 45, height: 45, fit: BoxFit.cover)),
    const SizedBox(width: 12),
    const Text("صورة جاهزة للإرسال"),
    const Spacer(),
    IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() => _webImage = null))
  ]));

  Widget _buildInput() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
    child: SafeArea(child: Row(children: [
      IconButton(icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.deepPurple, size: 28), onPressed: _pickImage),
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
        child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "اسأل هوميني...", border: InputBorder.none), onSubmitted: (_) => _send()),
      )),
      const SizedBox(width: 8),
      CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _send),
      ),
    ])),
  );
}