import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app/constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/media_service.dart';
import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/verified_badge.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ApiService _api = Get.find<ApiService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;
  String? _lastMessageId;
  File? _pickedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollNow();
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollNow());
  }

  Future<void> _pollNow() async {
    if (!mounted) return;
    try {
      final response = await _api.get('/messages/${widget.conversation.user.id}');
      if (response['success'] && mounted) {
        final newMessages = (response['data']['messages'] as List)
            .map((item) => Message.fromJson(item))
            .toList();
        if (newMessages.isNotEmpty && newMessages.last.id != _lastMessageId) {
          final wasAtBottom = _scrollController.hasClients &&
              _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 100;
          setState(() {
            _messages = newMessages;
            _lastMessageId = newMessages.last.id;
          });
          if (wasAtBottom) _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/messages/${widget.conversation.user.id}');
      if (response['success']) {
        setState(() {
          _messages = (response['data']['messages'] as List)
              .map((item) => Message.fromJson(item))
              .toList();
          if (_messages.isNotEmpty) _lastMessageId = _messages.last.id;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
    setState(() => _isLoading = false);
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choisir une source', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppConstants.primaryColor),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppConstants.primaryColor),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _pickedImage = File(picked.path));
    _sendImageMessage();
  }

  Future<void> _sendImageMessage() async {
    if (_pickedImage == null || _isUploadingImage) return;
    setState(() => _isUploadingImage = true);

    try {
      final fileName = _pickedImage!.path.split('/').last;
      final formData = FormData.fromMap({
        'receiver_id': widget.conversation.user.id,
        'media': await MultipartFile.fromFile(_pickedImage!.path, filename: fileName),
        if (_messageController.text.trim().isNotEmpty)
          'content': _messageController.text.trim(),
      });

      final response = await _api.multipart('/messages', formData);

      if (response['success']) {
        final message = Message.fromJson(response['data']['data']);
        setState(() {
          _messages.add(message);
          _lastMessageId = message.id;
          _pickedImage = null;
          _messageController.clear();
        });
        _scrollToBottom();
      } else {
        Get.snackbar('Erreur', ApiService.extractErrorMessage(response['error'], fallback: 'Échec de l\'envoi.'));
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau lors de l\'envoi de l\'image.');
    }

    setState(() => _isUploadingImage = false);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final response = await _api.post('/messages', data: {
        'receiver_id': widget.conversation.user.id,
        'content': content,
      });

      if (response['success']) {
        final message = Message.fromJson(response['data']['data']);
        setState(() {
          _messages.add(message);
          _lastMessageId = message.id;
        });
        _scrollToBottom();
      } else {
        Get.snackbar('Erreur', 'Impossible d\'envoyer le message.');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur réseau.');
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0B0B) : const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.conversation.user.profilePhoto != null
                  ? CachedNetworkImageProvider(widget.conversation.user.profilePhoto!)
                  : null,
              backgroundColor: Colors.grey[300],
              child: widget.conversation.user.profilePhoto == null
                  ? Text(
                      widget.conversation.user.name.isNotEmpty
                          ? widget.conversation.user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.conversation.user.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.conversation.user.isPremium) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  const Text(
                    'En ligne',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Aucun message', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(
                              'Envoyez un message à ${widget.conversation.user.name}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isOwnMessage = message.isSentByUser;
                          return MessageBubble(
                            message: message,
                            isOwnMessage: isOwnMessage,
                          );
                        },
                      ),
          ),

          if (_pickedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_pickedImage!, height: 60, width: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image sélectionnée',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _pickedImage = null),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  onPressed: _isUploadingImage ? null : _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  backgroundColor: _messageController.text.trim().isNotEmpty
                      ? AppConstants.primaryColor
                      : Colors.grey[400],
                  child: _isSending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Bloquer'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archiver'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer la conversation'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
