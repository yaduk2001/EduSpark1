import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../Chat/chat_page.dart';

class StudentDetailsPage extends StatefulWidget {
  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  final Stream<QuerySnapshot> _studentsStream = 
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Details'),
        backgroundColor: Color(0xFF1976D2),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _downloadStudentList(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _studentsStream,
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No students found'));
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> studentData = 
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF1976D2),
                      radius: 30,
                      child: Text(
                        studentData['name']?.substring(0, 1).toUpperCase() ?? 'S',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      studentData['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Email: ${studentData['email'] ?? 'N/A'}'),
                        Text('Phone: ${studentData['phone'] ?? 'N/A'}'),
                        Text('Created: ${_formatDate(studentData['createdAt'])}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.chat, color: Color(0xFF1976D2)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              studentId: snapshot.data!.docs[index].id,
                              studentName: studentData['name'] ?? 'Unknown', isTeacher: false, teacherId: '', teacherName: '',
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      _showStudentDetails(context, studentData);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddStudentDialog(context);
        },
        backgroundColor: Color(0xFF1976D2),
        child: Icon(Icons.add),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> studentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Student Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${studentData['name'] ?? 'N/A'}'),
              Text('Email: ${studentData['email'] ?? 'N/A'}'),
              Text('Phone: ${studentData['phone'] ?? 'N/A'}'),
              Text('Created At: ${_formatDate(studentData['createdAt'])}'),
              Text('Enrolled Courses: ${_formatCourses(studentData['enrolledCourses'])}'),
              Text('Status: ${studentData['isActive'] == true ? 'Active' : 'Inactive'}'),
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

  String _formatCourses(dynamic courses) {
    if (courses == null) return 'None';
    if (courses is List) {
      return courses.join(', ');
    }
    return 'None';
  }

  void _showAddStudentDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String name = '', email = '', phone = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Student'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => email = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Phone'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => phone = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                await FirebaseFirestore.instance.collection('users').add({
                  'name': name,
                  'email': email,
                  'phone': phone,
                  'role': 'student',
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                  'enrolledCourses': [],
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadStudentList(BuildContext context) async {
    final String? selectedFormat = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select File Format'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('PDF Format'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: Icon(Icons.document_scanner),
                title: Text('Word Format'),
                onTap: () => Navigator.pop(context, 'docx'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedFormat == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      // Get all available storage directories
      List<Directory>? directories = await getExternalStorageDirectories();
      Directory? downloadDir = directories?.first;
      
      if (downloadDir == null) {
        throw Exception('No storage directory available');
      }

      // Show directory selection dialog
      final String? selectedPath = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Download Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('Downloads'),
                  subtitle: Text('${downloadDir.path}'),
                  onTap: () => Navigator.pop(context, downloadDir.path),
                ),
                // Add more directory options if needed
              ],
            ),
          );
        },
      );

      if (selectedPath == null) {
        Navigator.pop(context); // Hide loading
        return;
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      if (selectedFormat == 'pdf') {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text('Student List', style: pw.TextStyle(fontSize: 24)),
              ),
              pw.Table.fromTextArray(
                headers: ['Name', 'Email', 'Phone', 'Status'],
                data: studentsSnapshot.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return [
                    data['name'] ?? 'N/A',
                    data['email'] ?? 'N/A',
                    data['phone'] ?? 'N/A',
                    data['isActive'] == true ? 'Active' : 'Inactive',
                  ];
                }).toList(),
              ),
            ],
          ),
        );

        final String fileName = 'students_$timestamp.pdf';
        final file = File('$selectedPath/$fileName');
        await file.writeAsBytes(await pdf.save());
        
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      } else {
        throw UnimplementedError('Word format export not yet implemented');
      }
    } catch (e) {
      Navigator.pop(context); // Hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 