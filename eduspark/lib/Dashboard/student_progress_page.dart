import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentProgressPage extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Progress'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignment_submissions')
            .where('studentId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'graded')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading progress'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final submissions = snapshot.data?.docs ?? [];
          
          // Calculate statistics
          double averageGrade = 0;
          int totalSubmissions = submissions.length;
          Map<String, int> gradeDistribution = {
            'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0
          };

          for (var submission in submissions) {
            final data = submission.data() as Map<String, dynamic>;
            final grade = data['grade'] as int;
            averageGrade += grade;

            // Update grade distribution
            if (grade >= 90) gradeDistribution['A'] = (gradeDistribution['A'] ?? 0) + 1;
            else if (grade >= 80) gradeDistribution['B'] = (gradeDistribution['B'] ?? 0) + 1;
            else if (grade >= 70) gradeDistribution['C'] = (gradeDistribution['C'] ?? 0) + 1;
            else if (grade >= 60) gradeDistribution['D'] = (gradeDistribution['D'] ?? 0) + 1;
            else gradeDistribution['F'] = (gradeDistribution['F'] ?? 0) + 1;
          }

          averageGrade = totalSubmissions > 0 ? averageGrade / totalSubmissions : 0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallProgress(averageGrade, totalSubmissions),
                SizedBox(height: 20),
                _buildGradeDistribution(gradeDistribution),
                SizedBox(height: 20),
                _buildRecentAssignments(submissions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallProgress(double averageGrade, int totalSubmissions) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Average Grade',
                  '${averageGrade.toStringAsFixed(1)}%',
                  _getGradeColor(averageGrade.round()),
                ),
                _buildStatCard(
                  'Assignments',
                  totalSubmissions.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution(Map<String, int> distribution) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grade Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: distribution.values.reduce((a, b) => a > b ? a : b).toDouble(),
                  barGroups: [
                    _buildBarGroup(0, distribution['A']?.toDouble() ?? 0, Colors.green),
                    _buildBarGroup(1, distribution['B']?.toDouble() ?? 0, Colors.lightGreen),
                    _buildBarGroup(2, distribution['C']?.toDouble() ?? 0, Colors.yellow),
                    _buildBarGroup(3, distribution['D']?.toDouble() ?? 0, Colors.orange),
                    _buildBarGroup(4, distribution['F']?.toDouble() ?? 0, Colors.red),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0: return Text('A');
                            case 1: return Text('B');
                            case 2: return Text('C');
                            case 3: return Text('D');
                            case 4: return Text('F');
                            default: return Text('');
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildRecentAssignments(List<QueryDocumentSnapshot> submissions) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Assignments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: submissions.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final submission = submissions[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(submission['assignmentTitle'] ?? 'Untitled Assignment'),
                  subtitle: Text('Grade: ${submission['grade']}%'),
                  trailing: Icon(
                    Icons.circle,
                    color: _getGradeColor(submission['grade'] as int),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(int grade) {
    if (grade >= 90) return Colors.green;
    if (grade >= 80) return Colors.lightGreen;
    if (grade >= 70) return Colors.yellow;
    if (grade >= 60) return Colors.orange;
    return Colors.red;
  }
} 