import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduspark/Courses/CourseSelectionPage.dart';
import 'package:eduspark/Courses/EnrolledCourses.dart';
import 'package:eduspark/Dashboard/EditProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../Login Pages/student_login.dart';
import '../Dashboard/student_assignment_page.dart';
import '../Chat/student_message_page.dart';



class StudentDashboardPage extends StatefulWidget {
  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _currentUser;
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  XFile? _profileImage; // For storing locally picked image
  String? _profileImageUrl; // For storing image URL from Firebase Storage
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Animation controller for background

    _fetchStudentData();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller
    super.dispose();
  }

  Future<void> _fetchStudentData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      DocumentSnapshot doc =
          await _firestore.collection('students').doc(_currentUser!.uid).get();
      if (doc.exists) {
        setState(() {
          _studentData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
        await _loadProfileImage(); // Load profile image
      } else {
        _handleNoStudentData();
      }
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      String downloadUrl = await _storage
          .ref('profile_pictures/${_currentUser!.uid}')
          .getDownloadURL();
      setState(() {
        _profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print("No profile picture found.");
    }
  }

  Future<void> _handleNoStudentData() async {
    setState(() {
      _isLoading = false;
    });
    Fluttertoast.showToast(
      msg: "No student data found. Please register again.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => StudentLoginPage()),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    _navigateToLogin();
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = pickedImage;
      });
      await _uploadProfileImage(pickedImage);
    }
  }

  Future<void> _uploadProfileImage(XFile pickedImage) async {
    try {
      await _storage
          .ref('profile_pictures/${_currentUser!.uid}')
          .putFile(File(pickedImage.path));
      await _loadProfileImage(); // Reload the profile image
      Fluttertoast.showToast(
        msg: "Profile picture updated.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
        msg: "Failed to upload profile picture.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: Stack(
        children: [
          AnimatedBackground(controller: _controller), // Background animation
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _studentData != null
                  ? _buildStudentDetails()
                  : Center(
                      child: Text(
                        'No student data found.',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Drawer _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _studentData != null ? _studentData!['name'] : 'Student',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.edit, 'Edit Profile', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfilePage()),
            );
          }),
          _buildDrawerItem(Icons.message, 'Messages', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StudentMessagePage()),
            );
          }),
          _buildDrawerItem(Icons.verified, 'Certificates', () {
            // Navigate to Certificates Page
          }),
          _buildDrawerItem(Icons.support, 'Support', () {
            // Navigate to Support Page
          }),
          _buildDrawerItem(Icons.feedback, 'Feedback', () {
            // Navigate to Feedback Page
          }),
          _buildDrawerItem(Icons.card_giftcard, 'Rewards', () {
            // Navigate to Rewards Page
          }),
          _buildDrawerItem(Icons.insights, 'Progress', () {
            // Navigate to Progress Page
          }),
          _buildDrawerItem(Icons.book, 'Enrolled Courses', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EnrolledCoursesPage()), // New page for enrolled courses
            );
          }),
          _buildDrawerItem(Icons.star, 'Premium Subscription', () {
            // Navigate to Subscription Page
          }),
          _buildDrawerItem(Icons.logout, 'Logout', _logout),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _buildStudentDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : AssetImage('assets/default_profile.png') as ImageProvider,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Welcome, ${_studentData!['name']}!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildDetailRow('Student ID', _studentData!['studentID']),
                    SizedBox(height: 10),
                    _buildDetailRow('Email', _studentData!['email']),
                    SizedBox(height: 10),
                    _buildDetailRow('Phone', _studentData!['phone']),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildGradesSection(),
            SizedBox(height: 30),
            Divider(),
            _buildAnnouncementsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildGradesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Grades',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Container(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('assignment_submissions')
                .where('studentId', isEqualTo: _currentUser?.uid)
                .where('status', isEqualTo: 'graded')
                .orderBy('gradedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var submissions = snapshot.data!.docs;

              if (submissions.isEmpty) {
                return Center(
                  child: Text('No graded assignments yet'),
                );
              }

              return ListView.builder(
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  var submission = submissions[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(submission['assignmentTitle'] ?? 'Assignment'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grade: ${submission['grade']}/100'),
                          if (submission['feedback'] != null && submission['feedback'].isNotEmpty)
                            Text(
                              'Feedback: ${submission['feedback']}',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.grade,
                        color: _getGradeColor(submission['grade'] as int),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(int grade) {
    if (grade >= 90) return Colors.green;
    if (grade >= 80) return Colors.lightGreen;
    if (grade >= 70) return Colors.yellow;
    if (grade >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Announcements',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Container(
          height: 200, // Fixed height to enable scrolling
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var notifications = snapshot.data!.docs;

              if (notifications.isEmpty) {
                return Center(child: Text('No announcements available'));
              }

              return ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  var notification = notifications[index];
                  var notificationData = notification.data().toString();

                  // Assuming the timestamp field in your document is 'timestamp'
                  var timestamp = notification['timestamp'] as Timestamp;
                  var dateTime = timestamp.toDate();

                  // Manual formatting of the timestamp
                  var formattedDate = '${dateTime.day.toString().padLeft(2, '0')}-'
                                      '${dateTime.month.toString().padLeft(2, '0')}-'
                                      '${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:'
                                      '${dateTime.minute.toString().padLeft(2, '0')} '
                                      '${dateTime.hour >= 12 ? 'PM' : 'AM'}';

                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(notificationData), // Display raw notification data
                      subtitle: Text('Saved on: $formattedDate'), // Display the formatted timestamp
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Assignments',
        ),
      ],
      currentIndex: 0,
      selectedItemColor: Colors.blueAccent,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseSelectionPage()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentAssignmentPage()),
          );
        }
      },
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.5),
                Colors.lightBlue.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.3, 0.9],
              transform: GradientRotation(controller.value * 2 * 3.14),
            ),
          ),
        );
      },
    );
  }
}
