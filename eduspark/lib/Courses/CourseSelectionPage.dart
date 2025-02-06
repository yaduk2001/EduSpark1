import 'package:eduspark/Dashboard/StudentDashboardPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'CourseEnrollPage.dart';


// Main function that initializes Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Selection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CourseSelectionPage(),
    );
  }
}

class CourseSelectionPage extends StatefulWidget {
  @override
  _CourseSelectionPageState createState() => _CourseSelectionPageState();
}

class _CourseSelectionPageState extends State<CourseSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Firestore reference to the 'courses' collection
  final CollectionReference _coursesRef =
      FirebaseFirestore.instance.collection('courses');

  // Firebase Auth and Storage references
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? profileImageUrl;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    _fetchProfilePicture();
  }

  // Fetch the profile picture from Firebase Storage
  Future<void> _fetchProfilePicture() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Fetch the profile picture URL from Firebase Storage
        String downloadUrl = await _storage
            .ref('profile_pictures/${user.uid}.jpg') // Assuming the picture is named after the user's UID
            .getDownloadURL();
        setState(() {
          profileImageUrl = downloadUrl;
        });
      }
    } catch (e) {
      print('Error fetching profile picture: $e');
      setState(() {
        profileImageUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore Courses'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            // Handle menu action
          },
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : AssetImage('assets/profile.png') as ImageProvider, // Placeholder if no profile pic
            ),
            onPressed: () {
              // Navigate to Profile Page
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => StudentDashboardPage()));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _coursesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching courses.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs;

          // Group courses by category
          Map<String, List<DocumentSnapshot>> coursesByCategory = {};
          courses.forEach((course) {
            String category = course['category'];
            if (!coursesByCategory.containsKey(category)) {
              coursesByCategory[category] = [];
            }
            coursesByCategory[category]!.add(course);
          });

          return GridView.builder(
            padding: EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: coursesByCategory.length,
            itemBuilder: (context, index) {
              String category = coursesByCategory.keys.elementAt(index);
              int courseCount = coursesByCategory[category]!.length;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      // Navigate to Course List Page for the selected category
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseListPage(
                            category: category,
                            courses: coursesByCategory[category]!,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book, size: 40, color: Colors.blue), // Placeholder icon
                          SizedBox(height: 8.0),
                          Text(
                            category,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('$courseCount courses'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => StudentDashboardPage()));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// New page to display courses for a specific category
class CourseListPage extends StatefulWidget {
  final String category;
  final List<DocumentSnapshot> courses;

  CourseListPage({required this.category, required this.courses});

  @override
  _CourseListPageState createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: ListView.builder(
        itemCount: widget.courses.length,
        itemBuilder: (context, index) {
          DocumentSnapshot course = widget.courses[index];
          String courseTitle = course['courseName'] ?? 'No Title';
          String courseDifficulty = course['difficultyLevel'] ?? 'No Difficulty';
          String courseDuration = course['courseDuration'] ?? 'No Duration';
          double courseRating = course['rating'] ?? 0.0;
          int courseEnrolled = course['enrolled'] ?? 0;

          return GestureDetector(
            onTap: () {
              // Navigate to the CourseEnrollPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseEnrollPage(course: course),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100.0,
                    height: 100.0,
                    margin: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(course['thumbnail'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courseTitle,
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$courseDifficulty | $courseDuration',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16.0, color: Colors.yellow.shade600),
                            Text(
                              '$courseRating/5',
                              style: TextStyle(fontSize: 14.0),
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              '$courseEnrolled enrolled',
                              style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }  
}
