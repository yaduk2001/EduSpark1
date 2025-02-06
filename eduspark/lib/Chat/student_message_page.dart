import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'dart:async';

class StudentMessagePage extends StatefulWidget {
  @override
  _StudentMessagePageState createState() => _StudentMessagePageState();
}

class _StudentMessagePageState extends State<StudentMessagePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isBlocked = false;
  Timer? _blockTimer;

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

  bool _moderateContent(String text) {
    final lowercaseText = text.toLowerCase();
    for (String word in _bannedWords) {
      if (lowercaseText.contains(word)) {
        return true;
      }
    }
    return false;
  }

  void _handleSearch(String searchText) {
    if (_moderateContent(searchText)) {
      setState(() {
        _isBlocked = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inappropriate content detected. Search blocked.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      
      _blockTimer?.cancel();
      _blockTimer = Timer(Duration(seconds: 30), () {
        setState(() {
          _isBlocked = false;
        });
      });
      
      _searchController.clear();
      return;
    }
    // Implement search functionality here
  }

  @override
  void dispose() {
    _searchController.dispose();
    _blockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Teachers'),
        backgroundColor: Color(0xFF1976D2),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              enabled: !_isBlocked,
              onChanged: _handleSearch,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'teacher')
                  .snapshots(),
              builder: (context, teacherSnapshot) {
                if (!teacherSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .where('participants', arrayContains: _auth.currentUser?.uid)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    if (!chatSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      itemCount: teacherSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var teacher = teacherSnapshot.data!.docs[index];
                        var teacherData = teacher.data() as Map<String, dynamic>;

                        // Find related chat if exists
                        var chat = chatSnapshot.data!.docs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return data['teacherId'] == teacher.id;
                        }).firstOrNull;

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF1976D2),
                              child: Text(
                                teacherData['name']?[0].toUpperCase() ?? 'T',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(teacherData['name'] ?? 'Teacher'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(teacherData['subject'] ?? 'Subject not specified'),
                                if (chat != null) ...[
                                  Text(
                                    'Last message: ${(chat.data() as Map<String, dynamic>)['lastMessage'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                            trailing: chat != null ? Icon(Icons.message) : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    isTeacher: false,
                                    studentId: _auth.currentUser!.uid,
                                    studentName: _auth.currentUser?.displayName ?? '',
                                    teacherId: teacher.id,
                                    teacherName: teacherData['name'] ?? 'Teacher',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 