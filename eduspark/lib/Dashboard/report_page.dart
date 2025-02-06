import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportPage extends StatelessWidget {
  final Color _primaryColor = Color(0xFF1976D2);
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Get the current user's role from the route arguments or check Firestore
    bool isTeacher = false; // Set this based on user role

    return Scaffold(
      appBar: AppBar(
        title: Text('My Submissions'),
        backgroundColor: _primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignment_submissions')
            .where('studentId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'graded')
            // Removed orderBy and other complex queries
            .snapshots(),
        builder: (context, snapshot) {
          // Debug prints
          print("Current User ID: ${currentUser?.uid}");
          print("Has Data: ${snapshot.hasData}");
          if (snapshot.hasData) {
            final allDocs = snapshot.data?.docs ?? [];
            print("All Documents: ${allDocs.length}");
            allDocs.forEach((doc) {
              print("Document Data: ${doc.data()}");
              print("StudentId in doc: ${(doc.data() as Map)['studentId']}");
            });
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final submissions = snapshot.data?.docs ?? [];

          if (submissions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No submissions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index].data() as Map<String, dynamic>;
              final submissionId = submissions[index].id;
              final status = submission['status'] ?? 'pending';
              final documentUrl = submission['documentUrl'] as String?;

              print('Submission data: ${submission.toString()}');
              print('Document URL: $documentUrl');

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Student: ${submission['studentName']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'File: ${submission['fileName']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (submission['grade'] != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Grade: ${submission['grade']}/100',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                      if (submission['feedback'] != null && submission['feedback'].isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          'Feedback: ${submission['feedback']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                      SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _viewSubmission(context, documentUrl),
                              icon: Icon(Icons.visibility),
                              label: Text('View'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            if (status != 'accepted' && status != 'rejected') ...[
                              ElevatedButton.icon(
                                onPressed: () => _updateStatus(context, submissionId, 'accepted'),
                                icon: Icon(Icons.check),
                                label: Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _updateStatus(context, submissionId, 'rejected'),
                                icon: Icon(Icons.close),
                                label: Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ],
                            if (status == 'accepted' && submission['isGraded'] != true) ...[
                              SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showAIGradingDialog(context, submissionId, submission),
                                icon: Icon(Icons.smart_toy),
                                label: Text('AI Grade'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String submissionId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('assignment_submissions')
          .doc(submissionId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission ${status.toUpperCase()}')),
      );
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _viewSubmission(BuildContext context, String? documentUrl) async {
    if (documentUrl == null || documentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No document available')),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(documentUrl);
      print('Attempting to open URL: $documentUrl'); // Debug print
      
      if (await canLaunchUrl(url)) {
        final bool launched = await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
          webViewConfiguration: WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
        
        if (!launched) {
          throw 'Could not launch URL';
        }
      } else {
        // Try opening in browser as fallback
        final browserLaunched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!browserLaunched) {
          throw 'Could not launch in browser';
        }
      }
    } catch (e) {
      print('Error opening document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the document. Please check if you have a PDF viewer installed.')),
      );
    }
  }

  Future<Map<String, dynamic>> _analyzeDocument(String? documentUrl, String assignmentType) async {
    try {
      if (documentUrl == null) return {'error': 'No document found'};
      
      // Simulated document analysis with randomized scoring
      int predictedScore = 0;
      String analysis = '';
      
      // Generate more realistic scores based on assignment type
      if (assignmentType == 'document') {
        // Random score between 70-100 for demonstration
        predictedScore = 70 + (DateTime.now().millisecond % 30);
        final contentQuality = predictedScore > 90 ? 'Excellent' : 
                             predictedScore > 80 ? 'Good' : 'Average';
        
        analysis = 'Document analysis:\n'
            '- Content quality: $contentQuality\n'
            '- Structure: ${predictedScore > 85 ? 'Well organized' : 'Needs improvement'}\n'
            '- Key points coverage: ${predictedScore > 80 ? 'Comprehensive' : 'Partial'}';
      } else if (assignmentType == 'mcq') {
        // Calculate based on correct answers (simulated)
        final correctAnswers = (DateTime.now().second % 10) + 5; // 5-14 correct answers
        final totalQuestions = 15;
        predictedScore = ((correctAnswers / totalQuestions) * 100).round();
        
        analysis = 'MCQ Analysis:\n'
            '- Correct answers: $correctAnswers/$totalQuestions\n'
            '- Accuracy: ${(predictedScore).toStringAsFixed(1)}%';
      }

      return {
        'score': predictedScore,
        'analysis': analysis,
      };
    } catch (e) {
      print('Document analysis error: $e');
      return {'error': 'Failed to analyze document'};
    }
  }

  Future<void> _showAIGradingDialog(BuildContext context, String submissionId, Map<String, dynamic> submission) async {
    bool isLoading = false;
    final feedbackController = TextEditingController();
    int suggestedGrade = 0;
    String analysisResult = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('AI-Assisted Grading'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Student: ${submission['studentName']}'),
                SizedBox(height: 16),
                if (isLoading)
                  CircularProgressIndicator()
                else
                  Column(
                    children: [
                      if (analysisResult.isNotEmpty) ...[
                        Text(
                          'Document Analysis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(analysisResult),
                        ),
                        SizedBox(height: 16),
                      ],
                      Text(
                        'Suggested Grade: $suggestedGrade/100',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: feedbackController,
                        decoration: InputDecoration(
                          labelText: 'AI-Generated Feedback',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final documentAnalysis = await _analyzeDocument(
                        submission['documentUrl'],
                        submission['assignmentType'] ?? 'document',
                      );
                      
                      if (documentAnalysis.containsKey('error')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(documentAnalysis['error'])),
                        );
                        setState(() => isLoading = false);
                        return;
                      }

                      setState(() {
                        isLoading = false;
                        suggestedGrade = documentAnalysis['score'];
                        analysisResult = documentAnalysis['analysis'];
                        feedbackController.text = 'Based on AI analysis:\n${documentAnalysis['analysis']}';
                      });
                    },
              child: Text('Analyze Document'),
            ),
            ElevatedButton(
              onPressed: isLoading || suggestedGrade == 0
                  ? null
                  : () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('assignment_submissions')
                            .doc(submissionId)
                            .update({
                          'grade': suggestedGrade,
                          'feedback': feedbackController.text,
                          'status': 'graded',
                          'gradedAt': FieldValue.serverTimestamp(),
                          'gradingMethod': 'ai-assisted',
                          'aiAnalysis': analysisResult,
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('AI-assisted grade submitted successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to submit grade: $e')),
                        );
                      }
                    },
              child: Text('Accept AI Grade'),
            ),
          ],
        ),
      ),
    );
  }
} 