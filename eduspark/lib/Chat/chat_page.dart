import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool isTeacher;
  final String teacherId;
  final String teacherName;

  ChatPage({
    required this.studentId,
    required this.studentName,
    required this.isTeacher,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;
  final audioPlayer = AudioPlayer();
  final recorder = AudioRecorder();
  
  bool _isRecording = false;
  Map<String, bool> _playingMessages = {};
  Map<String, VideoPlayerController> _videoControllers = {};
  late AnimationController _recordingAnimationController;
  final List<double> _audioLevels = List.filled(30, 0.0);
  Timer? _recordingTimer;
  bool _showEmojiPicker = false;
  final List<String> _bannedWords = [
    // Profanity
    'fuck', 'shit', 'ass', 'bitch', 'damn', 'crap', 'piss', 'dick', 'cock', 'pussy', 
    'whore', 'slut', 'bastard', 'cunt', 'hell',
    
    // Racial/Ethnic Slurs
    'nigger', 'nigga', 'chink', 'spic', 'wetback', 'kike', 'gook', 'paki',
    
    // Sexual Content
    'porn', 'sex', 'penis', 'vagina', 'boobs', 'nude', 'naked',
    
    // Violence
    'kill', 'murder', 'rape', 'suicide', 'die', 'death',
    
    // Hate Speech
    'nazi', 'terrorist', 'faggot', 'dyke', 'retard',
    
    // Drug References
    'cocaine', 'heroin', 'weed', 'crack', 'meth',
    
    // Common Variants
    'fck', 'fuk', 'sh1t', 'b1tch', 'ass', '@ss', 'f*ck', 's*it'
  ];
  bool _isMessageBlocked = false;
  Timer? _blockTimer;


  @override
  void initState() {
    super.initState();
    _recordingAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Mark messages as read when chat is opened
    if (widget.isTeacher) {
      _markMessagesAsRead();
    }
  }

  Future<void> _markMessagesAsRead() async {
    final chatId = getChatId();
    final batch = FirebaseFirestore.instance.batch();
    
    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.studentId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        backgroundColor: Color(0xFF1976D2),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(getChatId())
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var message = snapshot.data!.docs[index];
                      bool isMe = message['senderId'] == currentUser?.uid;

                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot message, bool isMe) {
    return GestureDetector(
      onLongPress: isMe ? () => _showMessageOptions(message) : null,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFF1976D2) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: _buildMessageContent(message),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(DocumentSnapshot message) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(message);
              },
            ),
            // Add more options here if needed
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(DocumentSnapshot message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteMessage(message);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(DocumentSnapshot message) async {
    try {
      // Delete the message document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(getChatId())
          .collection('messages')
          .doc(message.id)
          .delete();

      // If message has media, delete from storage
      if (message['type'] != 'text') {
        try {
          await FirebaseStorage.instance
              .refFromURL(message['content'])
              .delete();
        } catch (e) {
          print('Error deleting media file: $e');
        }
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  Widget _buildMessageContent(DocumentSnapshot message) {
    switch (message['type']) {
      case 'text':
        return Text(
          message['content'],
          style: TextStyle(
            color: message['senderId'] == currentUser?.uid 
                ? Colors.white 
                : Colors.black,
          ),
        );
      case 'image':
        return Image.network(
          message['content'],
          height: 200,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
        );
      case 'video':
        return _buildVideoMessage(message);
      case 'audio':
        return _buildAudioMessage(message);
      case 'document':
        return _buildDocumentMessage(message);
      default:
        return Text('Unsupported message type');
    }
  }

  Widget _buildVideoMessage(DocumentSnapshot message) {
    if (!_videoControllers.containsKey(message.id)) {
      final controller = VideoPlayerController.network(message['content'])
        ..initialize().then((_) {
          setState(() {});
        });
      _videoControllers[message.id] = controller;
    }

    final controller = _videoControllers[message.id]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          child: controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                )
              : Center(child: CircularProgressIndicator()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: message['senderId'] == currentUser?.uid 
                    ? Colors.white 
                    : Colors.black,
              ),
              onPressed: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioMessage(DocumentSnapshot message) {
    bool isPlaying = _playingMessages[message.id] ?? false;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? Icons.stop : Icons.play_arrow,
            color: message['senderId'] == currentUser?.uid 
                ? Colors.white 
                : Colors.black,
          ),
          onPressed: () => _playAudio(message),
        ),
        Text(
          'Voice Message',
          style: TextStyle(
            color: message['senderId'] == currentUser?.uid 
                ? Colors.white 
                : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _playAudio(DocumentSnapshot message) async {
    final messageId = message.id;
    final audioUrl = message['content'];

    if (_playingMessages[messageId] ?? false) {
      await audioPlayer.stop();
      setState(() {
        _playingMessages[messageId] = false;
      });
    } else {
      setState(() {
        _playingMessages.forEach((key, value) {
          _playingMessages[key] = false;
        });
        _playingMessages[messageId] = true;
      });

      await audioPlayer.play(UrlSource(audioUrl));
      audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _playingMessages[messageId] = false;
        });
      });
    }
  }

  Widget _buildMessageInput() {
    return Column(
      children: [
        if (_isMessageBlocked)
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            color: Colors.red[100],
            child: Text(
              'Messaging temporarily blocked due to inappropriate content',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, -2),
                blurRadius: 4,
                color: Colors.black12,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: _isRecording ? null : _showAttachmentOptions,
              ),
              IconButton(
                icon: Icon(Icons.emoji_emotions),
                onPressed: _isRecording ? null : _toggleEmojiPicker,
              ),
              IconButton(
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                onPressed: _handleVoiceRecord,
              ),
              Expanded(
                child: _isRecording
                    ? _buildRecordingVisualizer()
                    : TextField(
                        controller: _messageController,
                        enabled: !_isMessageBlocked,
                        decoration: InputDecoration(
                          hintText: _isMessageBlocked 
                              ? 'Temporarily blocked...' 
                              : 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                      ),
              ),
              IconButton(
                icon: Icon(_isRecording ? Icons.send : Icons.send),
                color: _isMessageBlocked ? Colors.grey : Color(0xFF1976D2),
                onPressed: _isMessageBlocked 
                    ? null 
                    : (_isRecording ? _handleVoiceRecord : _sendTextMessage),
              ),
            ],
          ),
        ),
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _messageController.text += emoji.emoji;
              },
              config: Config(),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordingVisualizer() {
    return Container(
      height: 50,
      child: Row(
        children: [
          Icon(Icons.mic, color: Colors.red),
          SizedBox(width: 8),
          Text('Recording...'),
          Expanded(
            child: AnimatedBuilder(
              animation: _recordingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    15,
                    (index) => Container(
                      width: 3,
                      height: 32 * _audioLevels[index],
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 200,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam),
              title: Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _uploadAndSendFile(File(image.path), 'image');
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      await _uploadAndSendFile(File(video.path), 'video');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        await _uploadAndSendFile(file, 'document');
      }
    } catch (e) {
      print('Error picking document: $e');
    }
  }

  Future<void> _handleVoiceRecord() async {
    if (_isRecording) {
      _recordingTimer?.cancel();
      _recordingAnimationController.stop();
      final path = await recorder.stop();
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        await _uploadAndSendAudio(File(path));
      }
    } else {
      if (await recorder.hasPermission()) {
        await recorder.start(
          RecordConfig(),
          path: path.join((await getTemporaryDirectory()).path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a'),
        );
        setState(() {
          _isRecording = true;
        });
        
        _recordingAnimationController.repeat(reverse: true);
        _recordingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
          setState(() {
            // Simulate audio levels with random values
            for (int i = 0; i < _audioLevels.length - 1; i++) {
              _audioLevels[i] = _audioLevels[i + 1];
            }
            _audioLevels[_audioLevels.length - 1] = 0.1 + Random().nextDouble() * 0.9;
          });
        });
      }
    }
  }

  Future<void> _uploadAndSendAudio(File audioFile) async {
    try {
      String fileName = path.basename(audioFile.path);
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_files')
          .child(getChatId())
          .child('audio')
          .child(fileName);

      await ref.putFile(audioFile);
      String downloadUrl = await ref.getDownloadURL();

      await _sendMessage(downloadUrl, 'audio');
    } catch (e) {
      print('Error uploading audio: $e');
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    if (_moderateContent(_messageController.text)) {
      setState(() {
        _isMessageBlocked = true;
      });
      
      // Show warning message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message contains inappropriate content. Please revise.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Block sending messages for 30 seconds
      _blockTimer?.cancel();
      _blockTimer = Timer(Duration(seconds: 30), () {
        setState(() {
          _isMessageBlocked = false;
        });
      });
      
      return;
    }

    await _sendMessage(_messageController.text.trim(), 'text');
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendMessage(
    String content, 
    String type, 
    {Map<String, dynamic>? additionalData}
  ) async {
    if (currentUser == null) return;

    Map<String, dynamic> messageData = {
      'content': content,
      'type': type,
      'senderId': currentUser!.uid,
      'senderName': widget.isTeacher ? widget.teacherName : widget.studentName,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,  // Add read status
    };

    if (additionalData != null) {
      messageData.addAll(additionalData);
    }

    // Get chat document reference
    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId());

    // Create or update chat metadata
    await chatDocRef.set({
      'lastMessage': content,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'participants': [widget.studentId, widget.teacherId],
      'studentName': widget.studentName,
      'teacherName': widget.teacherName,
      'studentId': widget.studentId,
      'teacherId': widget.teacherId,
    }, SetOptions(merge: true));

    // Add message to subcollection
    await chatDocRef
        .collection('messages')
        .add(messageData);
  }

  Future<void> _uploadAndSendFile(File file, String type) async {
    try {
      String fileName = path.basename(file.path);
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('chat_files')
          .child(getChatId())
          .child(type)
          .child(fileName);

      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      await _sendMessage(
        downloadUrl, 
        type,
        additionalData: {'fileName': fileName},
      );
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  String getChatId() {
    // Create a unique chat ID combining teacher and student IDs
    List<String> ids = [widget.teacherId, widget.studentId];
    ids.sort(); // Sort to ensure consistent ID regardless of who initiates
    return ids.join('_');
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _moderateContent(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Check for banned words
    for (String word in _bannedWords) {
      if (lowercaseText.contains(word)) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _recordingAnimationController.dispose();
    _recordingTimer?.cancel();
    // Dispose video controllers
    _videoControllers.forEach((_, controller) => controller.dispose());
    _messageController.dispose();
    _scrollController.dispose();
    audioPlayer.dispose();
    recorder.dispose();
    _blockTimer?.cancel();
    super.dispose();
  }

  Widget _buildDocumentMessage(DocumentSnapshot message) {
    String fileName = message['fileName'] ?? 'Document';
    return GestureDetector(
      onTap: () => _openDocument(message['content']),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: message['senderId'] == currentUser?.uid ? Colors.white : Colors.black,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(
                  color: message['senderId'] == currentUser?.uid ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    try {
      // Launch URL in browser or default document viewer
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 