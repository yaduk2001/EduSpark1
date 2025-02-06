import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_assignment_page.dart';
import 'student_details_page.dart';
import 'report_page.dart';
import 'package:eduspark/Admin/AdminCourseCreationPage.dart';
import 'package:eduspark/Admin/AdminCourseEditPage.dart';
import 'package:eduspark/Chat/chat_page.dart';



class TeacherDashboard extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? profileImageUrl;
  String? teacherName;
  String? teacherEmail;

  // Add new properties for analytics
  Map<String, dynamic> dashboardStats = {
    'totalStudents': 0,
    'averagePerformance': 0.0,
    'pendingAssignments': 0,
  };

  List<Map<String, dynamic>> assignmentReports = [];

  @override
  void initState() {
    super.initState();
    loadTeacherData();
    loadAssignmentReports();
  }

  Future<void> loadTeacherData() async {
    if (currentUser != null) {
      print("Current User ID: ${currentUser!.uid}"); // Debug print
      
      try {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(currentUser!.uid)
            .get();
            
        print("Teacher Doc exists: ${teacherDoc.exists}"); // Debug print
        print("Teacher Data: ${teacherDoc.data()}"); // Debug print
        
        if (teacherDoc.exists) {
          setState(() {
            profileImageUrl = teacherDoc.data()?['profileImage'];
            teacherName = teacherDoc.data()?['name'] ?? 'Teacher';
            teacherEmail = teacherDoc.data()?['email'] ?? currentUser!.email;
          });
        } else {
          print("No teacher document found for this user ID");
        }
      } catch (e) {
        print("Error loading teacher data: $e"); // Debug print
      }
    } else {
      print("No current user found"); // Debug print
    }
  }

  Future<void> loadAssignmentReports() async {
    if (currentUser != null) {
      try {
        print("Loading assignment reports..."); // Debug print
        final reportsSnapshot = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(currentUser!.uid)
            .collection('assignments')
            .orderBy('dueDate', descending: true)
            .get();

        print("Reports snapshot: ${reportsSnapshot.docs.length}"); // Debug print
        
        setState(() {
          assignmentReports = reportsSnapshot.docs
              .map((doc) {
                print("Processing doc: ${doc.id}"); // Debug print
                return {
                  ...doc.data(),
                  'id': doc.id,
                };
              })
              .toList();
        });
        print("Loaded ${assignmentReports.length} reports"); // Debug print
      } catch (e) {
        print("Error loading assignment reports: $e");
      }
    }
  }

  Future<void> _viewDocument(String documentUrl) async {
    if (await canLaunch(documentUrl)) {
      await launch(documentUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open document')),
      );
    }
  }

  void _showAssignmentDetails(BuildContext context, Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment['title'] ?? 'Assignment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Due Date: ${_formatDate(assignment['dueDate'])}'),
              SizedBox(height: 8),
              Text('Status: ${assignment['status'] ?? 'Pending'}'),
              SizedBox(height: 8),
              if (assignment['documentUrl'] != null)
                ElevatedButton.icon(
                  icon: Icon(Icons.remove_red_eye),
                  label: Text('View Document'),
                  onPressed: () => _viewDocument(assignment['documentUrl']),
                ),
              if (assignment['submissions'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'Submissions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...(assignment['submissions'] as List).map((submission) =>
                        ListTile(
                          title: Text(submission['studentName'] ?? 'Unknown Student'),
                          subtitle: Text('Submitted: ${_formatDate(submission['submittedAt'])}'),
                          trailing: submission['documentUrl'] != null
                              ? IconButton(
                                  icon: Icon(Icons.file_present),
                                  onPressed: () =>
                                      _viewDocument(submission['documentUrl']),
                                )
                              : null,
                        )),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    if (date is Timestamp) {
      return date.toDate().toString().split(' ')[0];
    }
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Color(0xFF1976D2), // Rich blue color
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Add notifications functionality
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(teacherName ?? 'Loading...'),
              accountEmail: Text(teacherEmail ?? 'Loading...'),
              currentAccountPicture: GestureDetector(
                onTap: () {
                  // Add profile picture update functionality
                },
                child: CircleAvatar(
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF1976D2), // Primary blue
                    Color(0xFF2196F3), // Lighter blue
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                // Navigate to profile page
              },
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Student Details'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsPage(),
                  ),
                );
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Schedule'),
              onTap: () {
                // Navigate to schedule page
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment),
              title: Text('Reports'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Assignment Reports'),
                    content: Container(
                      width: double.maxFinite,
                      child: assignmentReports.isEmpty
                          ? Center(child: Text('No assignments found'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: assignmentReports.length,
                              itemBuilder: (context, index) {
                                final assignment = assignmentReports[index];
                                return ListTile(
                                  title: Text(assignment['title'] ?? 'Untitled Assignment'),
                                  subtitle: Text('Due: ${_formatDate(assignment['dueDate'])}'),
                                  trailing: Icon(Icons.arrow_forward_ios),
                                  onTap: () => _showAssignmentDetails(context, assignment),
                                );
                              },
                            ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings page
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // Very light blue
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF1976D2).withOpacity(0.9),
                          Color(0xFF2196F3).withOpacity(0.9),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null,
                            child: profileImageUrl == null
                                ? Icon(Icons.person, size: 40, color: Color(0xFF1976D2))
                                : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacherName ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  teacherEmail ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Add Analytics Summary
                _buildAnalyticsSummary(),
                
                SizedBox(height: 20),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      'Students',
                      Icons.group,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailsPage(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      'Schedule',
                      Icons.calendar_today,
                      () {},
                    ),
                    _buildDashboardCard(
                      'Reports',
                      Icons.assessment,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportPage(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      'Assignments',
                      Icons.assignment,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAssignmentPage(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      'Create Course',
                      Icons.add_box,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminCourseCreationPage(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      'My Courses',
                      Icons.library_books,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminCourseListPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.white,
                Color(0xFFE3F2FD), // Very light blue
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Color(0xFF1976D2)),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportPage(),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignment_submissions')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error loading stats'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // Calculate stats from submissions
            Set<String> uniqueStudents = {};
            int pendingCount = 0;
            double totalGrades = 0;
            int gradedAssignments = 0;

            for (var doc in snapshot.data?.docs ?? []) {
              final submission = doc.data() as Map<String, dynamic>;
              
              if (submission['studentId'] != null) {
                uniqueStudents.add(submission['studentId'].toString());
              }

              if (submission['status'] == 'pending') {
                pendingCount++;
              }

              if (submission['grade'] != null) {
                totalGrades += (submission['grade'] as num).toDouble();
                gradedAssignments++;
              }
            }

            double averagePerformance = gradedAssignments > 0 
                ? (totalGrades / gradedAssignments) 
                : 0.0;

            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Stats',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF1976D2),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Students',
                        uniqueStudents.length.toString(),
                        Icons.group,
                        'Total active students',
                      ),
                      _buildStatItem(
                        'Performance',
                        averagePerformance.toStringAsFixed(1),
                        Icons.trending_up,
                        'Average grade',
                      ),
                      _buildStatItem(
                        'Pending',
                        pendingCount.toString(),
                        Icons.assignment_late,
                        'Assignments to review',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF1976D2), size: 24),
          SizedBox(height: 8),
          Text(
            label == 'Performance' ? '$value%' : value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 