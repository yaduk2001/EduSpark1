import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityDetailsPage extends StatefulWidget {
  final String activityId;
  final Map<String, dynamic> activityData;

  ActivityDetailsPage({
    required this.activityId,
    required this.activityData,
  });

  @override
  _ActivityDetailsPageState createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityData['title'] ?? 'Activity Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivityHeader(),
              SizedBox(height: 20),
              _buildParticipantsList(),
              SizedBox(height: 20),
              _buildDiscussionSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmissionDialog(),
        label: Text('Submit Work'),
        icon: Icon(Icons.upload_file),
      ),
    );
  }

  Widget _buildActivityHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activityData['title'] ?? 'Untitled Activity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.activityData['description'] ?? 'No description available',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text(_formatDate(widget.activityData['createdAt'])),
                  ],
                ),
                Chip(
                  label: Text(
                    widget.activityData['type'] ?? 'Activity',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.person_add),
                  label: Text('Invite'),
                  onPressed: () => _showInviteDialog(),
                ),
              ],
            ),
            SizedBox(height: 10),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('collaborative_activities')
                  .doc(widget.activityId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var participants = (snapshot.data!.data() 
                    as Map<String, dynamic>)['participants'] ?? [];

                return Column(
                  children: participants.map<Widget>((participant) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          participant['name'][0].toUpperCase(),
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                      title: Text(participant['name']),
                      subtitle: Text(participant['role'] ?? 'Participant'),
                      trailing: participant['userId'] == _auth.currentUser?.uid
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discussion',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            _buildCommentsList(),
            SizedBox(height: 10),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('collaborative_activities')
          .doc(widget.activityId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var comment = snapshot.data!.docs[index];
            return _buildCommentCard(comment);
          },
        );
      },
    );
  }

  Widget _buildCommentCard(DocumentSnapshot comment) {
    Map<String, dynamic> data = comment.data() as Map<String, dynamic>;
    bool isCurrentUser = data['userId'] == _auth.currentUser?.uid;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: isCurrentUser ? Colors.blue[50] : null,
      child: ListTile(
        title: Text(data['message'] ?? ''),
        subtitle: Text('${data['userName']} • ${_formatDate(data['timestamp'])}'),
        trailing: isCurrentUser
            ? IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () => _deleteComment(comment.id),
              )
            : null,
      ),
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: _sendComment,
        ),
      ],
    );
  }

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _firestore
          .collection('collaborative_activities')
          .doc(widget.activityId)
          .collection('comments')
          .add({
        'message': _commentController.text,
        'userId': _auth.currentUser?.uid,
        'userName': _auth.currentUser?.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending comment: $e')),
      );
    }
  }

  void _deleteComment(String commentId) async {
    try {
      await _firestore
          .collection('collaborative_activities')
          .doc(widget.activityId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $e')),
      );
    }
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite Participants'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter participant\'s email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement invite logic
              Navigator.pop(context);
            },
            child: Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submit Work'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Submission Title',
                hintText: 'Enter title for your submission',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.attach_file),
              label: Text('Attach File'),
              onPressed: () {
                // Implement file attachment logic
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement submission logic
              Navigator.pop(context);
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date not available';
    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }
} 