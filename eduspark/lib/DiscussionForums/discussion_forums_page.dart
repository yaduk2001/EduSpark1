import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscussionForumsPage extends StatefulWidget {
  @override
  _DiscussionForumsPageState createState() => _DiscussionForumsPageState();
}

class _DiscussionForumsPageState extends State<DiscussionForumsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discussion Forums'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('discussion_forums')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    return _buildMessageCard(message);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewTopicDialog(),
        child: Icon(Icons.add),
        tooltip: 'New Topic',
      ),
    );
  }

  Widget _buildMessageCard(DocumentSnapshot message) {
    Map<String, dynamic> data = message.data() as Map<String, dynamic>;
    bool isCurrentUser = data['userId'] == _auth.currentUser?.uid;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isCurrentUser ? Colors.blue[100] : null,
      child: ListTile(
        title: Text(data['message'] ?? ''),
        subtitle: Text('${data['userName'] ?? 'Anonymous'} • ${_formatTimestamp(data['timestamp'])}'),
        trailing: isCurrentUser
            ? IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteMessage(message.id),
              )
            : null,
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _firestore.collection('discussion_forums').add({
        'message': _messageController.text,
        'userId': _auth.currentUser?.uid,
        'userName': _auth.currentUser?.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  void _deleteMessage(String messageId) async {
    try {
      await _firestore.collection('discussion_forums').doc(messageId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  void _showNewTopicDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Discussion Topic'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Topic Title',
            hintText: 'Enter your discussion topic',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement new topic creation
              Navigator.pop(context);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
} 