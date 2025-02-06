import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StudentAssignmentPage extends StatefulWidget {
  @override
  _StudentAssignmentPageState createState() => _StudentAssignmentPageState();
}

class _StudentAssignmentPageState extends State<StudentAssignmentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final Color _primaryColor = Color(0xFF1976D2);
  final double _borderRadius = 12.0;

  FilePickerResult? _result;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Assignments'),
          backgroundColor: _primaryColor,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAssignmentList(false),
            _buildAssignmentList(true),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentList(bool isCompleted) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('assignments')
          .where('isForAllStudents', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var assignments = snapshot.data!.docs;

        if (assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No ${isCompleted ? 'completed' : 'pending'} assignments',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            var assignment = assignments[index].data() as Map<String, dynamic>;
            DateTime dueDate = (assignment['dueDate'] as Timestamp).toDate();
            bool isOverdue = dueDate.isBefore(DateTime.now());

            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: InkWell(
                onTap: () => _showAssignmentDetails(assignment),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getAssignmentTypeIcon(assignment['assignmentType']),
                            color: _primaryColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              assignment['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(isOverdue),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        assignment['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Due: ${dueDate.year}-${dueDate.month}-${dueDate.day}',
                            style: TextStyle(
                              color: isOverdue ? Colors.red : Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAssignmentDetails(assignment),
                            child: Text('View Details'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getAssignmentTypeIcon(String type) {
    switch (type) {
      case 'mcq':
        return Icons.check_circle_outline;
      case 'document':
        return Icons.file_present;
      case 'question':
        return Icons.question_answer;
      default:
        return Icons.assignment;
    }
  }

  Widget _buildStatusChip(bool isOverdue) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOverdue ? 'Overdue' : 'Active',
        style: TextStyle(
          color: isOverdue ? Colors.red : Colors.green,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showAssignmentDetails(Map<String, dynamic> assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment['title'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    assignment['description'],
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  _buildSubmissionSection(assignment),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmissionSection(Map<String, dynamic> assignment) {
    switch (assignment['assignmentType']) {
      case 'mcq':
        return Column(
          children: [
            _buildMCQQuestions(assignment['mcqQuestions']),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _submitMCQAssignment(assignment),
              child: Text('Submit MCQ Answers'),
              style: _submitButtonStyle(),
            ),
          ],
        );
      case 'document':
        return Column(
          children: [
            _buildDocumentUpload(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _submitDocumentAssignment(assignment),
              child: Text('Upload & Submit Document'),
              style: _submitButtonStyle(),
            ),
          ],
        );
      case 'handwritten':
        return Column(
          children: [
            _buildHandwrittenUpload(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _submitHandwrittenAssignment(assignment),
              child: Text('Upload & Submit Image'),
              style: _submitButtonStyle(),
            ),
          ],
        );
      default:
        return Text('Unknown assignment type');
    }
  }

  ButtonStyle _submitButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _primaryColor,
      minimumSize: Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
    );
  }

  Widget _buildDocumentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Document (PDF, DOC, DOCX)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickDocument,
          icon: Icon(Icons.upload_file),
          label: Text('Select Document'),
        ),
        // Add a preview of selected document here
      ],
    );
  }

  Widget _buildHandwrittenUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Image of Handwritten Work',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: Icon(Icons.camera_alt),
                label: Text('Take Photo'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library),
                label: Text('Choose from Gallery'),
              ),
            ),
          ],
        ),
        // Add image preview here
      ],
    );
  }

  Future<void> _pickDocument() async {
    try {
      _result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (_result != null) {
        setState(() {
          // Store the selected file path
          _selectedFile = _result?.files.first;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected file: ${_selectedFile!.name}')),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Implement image picking logic
  }

  Future<void> _submitMCQAssignment(Map<String, dynamic> assignment) async {
    // Submit MCQ answers to Firestore
  }

  Future<void> _submitDocumentAssignment(Map<String, dynamic> assignment) async {
    try {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a document first')),
        );
        return;
      }

      setState(() => _isUploading = true);

      // Upload file to Firebase Storage
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + _selectedFile!.name;
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('assignments/${assignment['id']}/$fileName');
      
      final UploadTask uploadTask = storageRef.putFile(File(_selectedFile!.path!));
      
      // Get download URL after upload completes
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Save submission details to Firestore
      await FirebaseFirestore.instance
          .collection('assignment_submissions')
          .add({
        'assignmentId': assignment['id'],
        'studentId': _auth.currentUser?.uid,
        'studentName': _auth.currentUser?.displayName,
        'submissionDate': FieldValue.serverTimestamp(),
        'documentUrl': downloadUrl,
        'fileName': fileName,
        'status': 'submitted'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting assignment: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submitHandwrittenAssignment(Map<String, dynamic> assignment) async {
    // Upload image to Firebase Storage and submit reference to Firestore
  }

  Widget _buildMCQQuestions(List<dynamic> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> question = entry.value;
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${index + 1}. ${question['question']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ...List.generate(
                  question['options'].length,
                  (optionIndex) => RadioListTile<int>(
                    title: Text(question['options'][optionIndex]),
                    value: optionIndex,
                    groupValue: null, // You'll need to track selected answers
                    onChanged: (value) {
                      // Handle answer selection
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
} 