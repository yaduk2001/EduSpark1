import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ContentAccessPage.dart'; // Ensure the correct path

class EnrolledCoursesPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch enrolled course IDs and then fetch course details from 'courses' collection
  Future<List<Map<String, dynamic>>> fetchEnrolledCourses() async {
    final user = _auth.currentUser;
    final uid = user!.uid;

    try {
      // Fetch the user document from Firestore to get the enrolledCourses list
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Cast userDoc.data() to a Map<String, dynamic>
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      // Check if 'enrolledCourses' exists and is a list of course IDs
      if (userData != null && userData.containsKey('enrolledCourses')) {
        List<dynamic> courseIds = userData['enrolledCourses'];
        List<Map<String, dynamic>> courseDetails = [];

        // For each course ID, fetch the course details from the 'courses' collection
        for (var courseId in courseIds) {
          DocumentSnapshot courseDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .get();

          // If the course exists, add its details to the list
          if (courseDoc.exists) {
            courseDetails.add(courseDoc.data() as Map<String, dynamic>);
          }
        }
        return courseDetails; // Return list of course details
      } else {
        return []; // No courses enrolled
      }
    } catch (e) {
      print('Error fetching courses: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Courses'),
      ),
      body: FutureBuilder(
        future: fetchEnrolledCourses(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading courses: ${snapshot.error}'));
          }
          final courses = snapshot.data!;

          if (courses.isEmpty) {
            return Center(child: Text('No courses enrolled yet.'));
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseTile(
                title: course['courseName'] ?? 'No Title', // Fetch title from course details
                duration: course['courseDuration']?.toString() ?? 'Unknown',  // Fetch duration
                level: course['difficultylevel'] ?? 'Unknown', // Fetch level
                imageUrl: course['thumbnail'] ?? 'https://via.placeholder.com/150', // Fetch image URL
                onTap: () {
                  // Navigate to Course Content Page, passing both courseName and userID
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseContentPage(
                        courseName: course['courseName'],
                        userID: _auth.currentUser!.uid, // Pass the user ID here
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class CourseTile extends StatelessWidget {
  final String title;
  final String duration;
  final String level;
  final String imageUrl;
  final VoidCallback onTap;

  CourseTile({
    required this.title,
    required this.duration,
    required this.level,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Show a placeholder image if the thumbnail fails to load
              return Image.asset(
                'assets/placeholder.png', // Ensure you have a placeholder image in your assets folder
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              '$duration hours',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap, // Handle tap event
      ),
    );
  }
}
