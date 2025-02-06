// CourseListPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AdminCourseEditPage.dart'; // Import the edit course page
import 'AdminCourseCreationPage.dart'; // Ensure correct import path
import 'package:fluttertoast/fluttertoast.dart';

class CourseListPage extends StatefulWidget {
  @override
  _CourseListPageState createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of categories - ensure this matches your categories in AdminCourseCreationPage
  final List<String> _categories = [
    'All',
    'General',
    'Technology',
    'Business',
    'Arts',
    'Science',
    'Health',
    'Finance',
    'Marketing',
    'Personal Development',
    'Other',
  ];

  String _selectedCategory = 'All'; // Default category

  @override
  Widget build(BuildContext context) {
    // Build Firestore query based on selected category
    Stream<QuerySnapshot> _courseStream;
    if (_selectedCategory == 'All') {
      _courseStream = _firestore
          .collection('courses')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      _courseStream = _firestore
          .collection('courses')
          .where('category', isEqualTo: _selectedCategory)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Course List'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Category Selection Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Select Category',
                prefixIcon: Icon(Icons.category, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _courseStream,
              builder: (context, snapshot) {
                // Check for loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Check if snapshot has errors
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Check if snapshot has data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No courses available'));
                }

                // Debug: Log the number of documents fetched
                print('Number of courses: ${snapshot.data!.docs.length}');

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var courseDoc = snapshot.data!.docs[index];
                    var courseId = courseDoc.id; // Get the course ID
                    var courseData = courseDoc.data() as Map<String, dynamic>;

                    // Debug: Log course data
                    print('Course ID: $courseId, Data: $courseData');

                    // Safely retrieve courseName and description
                    String courseName = courseData['courseName'] ?? 'No Name';
                    String description = courseData['description'] ?? 'No Description';
                    String category = courseData['category'] ?? 'Uncategorized';

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.book, color: Colors.deepPurple),
                        title: Text(
                          courseName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.deepPurple),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminEditCoursePage(courseId: courseId),
                              ),
                            ).then((value) {
                              // Optional: Refresh the list after editing
                              if (value != null && value is bool && value) {
                                Fluttertoast.showToast(
                                  msg: "Course updated successfully!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              }
                            });
                          },
                          tooltip: 'Edit Course',
                        ),
                        onTap: () {
                          // Optional: Navigate to a detailed course view if needed
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to course creation page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminCourseCreationPage(),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        tooltip: 'Create New Course',
      ),
    );
  }
}
