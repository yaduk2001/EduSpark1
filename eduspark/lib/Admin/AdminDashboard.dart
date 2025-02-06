// AdminDashboardPage.dart

import 'package:eduspark/Admin/AdminCourseCreationPage.dart';
import 'package:eduspark/Admin/AdminCourseEditPage.dart';
import 'package:eduspark/Courses/CourseSelectionPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // Import the admin registration page

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Theme management
  bool _isDarkTheme = false;

  // User profile data
  String? _profileImageUrl;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Widget> _pages = [
    DashboardHome(),
    ManageUsers(),
    SettingsPage(),
    // AdminCourseCreationPage(), // Remove if not needed
  ];

  @override
  void initState() {
    super.initState();
    // Initialize Animation Controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Define Animation
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the animation
    _animationController.forward();

    // Fetch profile picture and theme
    _fetchProfilePictureAndTheme();
  }

  Future<void> _fetchProfilePictureAndTheme() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc.get('profilePicture');
          _isDarkTheme = userDoc.get('isDarkTheme') ?? false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Handle Bottom Navigation Tap
  void _onItemTapped(int index) {
    if (index == 3) { // 'Add Courses' index
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminCourseCreationPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
        // Restart animation on page change
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  // Handle Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  // Handle Profile Picture Upload
  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      String fileName = 'profile_pictures/${_auth.currentUser!.uid}.png';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore with the new profile picture URL
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'profilePicture': downloadUrl,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully!')),
      );
    }
  }

  // Toggle Theme
  Future<void> _toggleTheme(bool isDark) async {
    setState(() {
      _isDarkTheme = isDark;
    });
    // Update in Firestore
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isDarkTheme': isDark,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provide theme to the app using Provider
    return ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(_isDarkTheme ? ThemeData.dark() : ThemeData.light()),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return Scaffold(
            appBar: AppBar(
              title: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Admin Dashboard',
                    textStyle: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                    speed: Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              backgroundColor: Colors.deepPurple,
              actions: [
                GestureDetector(
                  onTap: _uploadProfilePicture,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                  ),
                ),
              ],
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                    ),
                    accountName: Text('Admin'),
                    accountEmail: Text(_auth.currentUser?.email ?? ''),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text('Home'),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(0);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.manage_accounts),
                    title: Text('Manage Users'),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(1);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.add_box),
                    title: Text('Add Courses'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdminCourseCreationPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Courses'),
                    onTap: () {
                     Navigator.pop(context); // Close the drawer
                     Navigator.push(
                      context,
                       MaterialPageRoute(
                        builder: (context) => CourseListPage(category: '', courses: []),
                     ),
                     );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      _onItemTapped(2);
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                ],
              ),
            ),
            body: FadeTransition(
              opacity: _animation,
              child: _pages[_selectedIndex],
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.manage_accounts),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.deepPurple,
              onTap: _onItemTapped,
            ),
          );
        },
      ),
    );
  }
}
// Theme Notifier using Provider
class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier(this._themeData);

  ThemeData getTheme() => _themeData;

  void setTheme(ThemeData theme) {
    _themeData = theme;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    if (isDark) {
      _themeData = ThemeData.dark();
    } else {
      _themeData = ThemeData.light();
    }
    notifyListeners();
  }
}

// Sample Home Page with text animations
class DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 30.0,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
        child: AnimatedTextKit(
          animatedTexts: [
            FadeAnimatedText('Welcome to the Admin Dashboard!'),
            FadeAnimatedText('Manage your application with ease.'),
            FadeAnimatedText('Stay organized and efficient.'),
          ],
          isRepeatingAnimation: true,
          repeatForever: true,
        ),
      ),
    );
  }
}

// Manage Users Page
class ManageUsers extends StatefulWidget {
  @override
  _ManageUsersState createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Initialize Firebase Storage

  // Fetch users by role
  Stream<QuerySnapshot> _getUsersByRole(String role) {
    return _firestore.collection('users').where('role', isEqualTo: role).snapshots();
  }

  // Toggle user active status
  Future<void> _toggleUserStatus(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({'isActive': isActive});
  }

  // Function to get download URL from Firebase Storage
  Future<String> _getProfilePictureUrl(String userId) async {
    String imageUrl;
    try {
      // Construct the reference to the image
      final ref = _storage.ref().child('profile_pictures/$userId.jpg'); // Adjust the path accordingly
      imageUrl = await ref.getDownloadURL(); // Get the download URL
    } catch (e) {
      // Handle error (e.g., if the image doesn't exist)
      imageUrl = ''; // Return an empty string or a default image URL
    }
    return imageUrl;
  }

  Widget _buildUserList(String role, Stream<QuerySnapshot> stream) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error fetching $role');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            final users = snapshot.data!.docs;

            if (users.isEmpty) {
              return Text('No $role registered.');
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index];

                // Fetch profile picture URL asynchronously
                return FutureBuilder<String>(
                  future: _getProfilePictureUrl(user.id), // Fetch the URL for the user
                  builder: (context, snapshot) {
                    // Handle loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text(user['email'] ?? 'No Email'),
                        subtitle: Text('UID: ${user.id}'),
                        leading: CircularProgressIndicator(), // Show a loader while fetching
                      );
                    }

                    // If there's an error fetching the URL
                    if (snapshot.hasError) {
                      return ListTile(
                        title: Text(user['email'] ?? 'No Email'),
                        subtitle: Text('UID: ${user.id}'),
                        leading: Icon(Icons.error), // Show an error icon
                      );
                    }

                    // Use the fetched URL
                    final profilePictureUrl = snapshot.data ?? ''; // Default to an empty string

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePictureUrl.isNotEmpty
                              ? NetworkImage(profilePictureUrl)
                              : AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                        title: Text(user['email'] ?? 'No Email'),
                        subtitle: Text('UID: ${user.id}'),
                        trailing: Switch(
                          value: user['isActive'] ?? true,
                          onChanged: (value) {
                            _toggleUserStatus(user.id, value);
                          },
                        ),
                        onTap: () {
                          // Optionally handle user edit
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserList('Students', _getUsersByRole('student')),
          _buildUserList('Teachers', _getUsersByRole('teacher')),
          _buildUserList('Parents', _getUsersByRole('parent')),
        ],
      ),
    );
  }
}


 

// Settings Page
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _notificationController = TextEditingController();

  // Fetch notifications
  Stream<QuerySnapshot> _getNotifications() {
    return _firestore.collection('notifications').orderBy('timestamp', descending: true).snapshots();
  }

  // Create a new notification
  Future<void> _createNotification(String message) async {
    await _firestore.collection('notifications').add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Delete a notification
  Future<void> _deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  Widget _buildNotificationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _getNotifications(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error fetching notifications');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            final notifications = snapshot.data!.docs;

            if (notifications.isEmpty) {
              return Text('No notifications.');
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];
                return Card(
                  child: ListTile(
                    title: Text(notification['message'] ?? ''),
                    subtitle: Text(notification['timestamp'] != null
                        ? notification['timestamp'].toDate().toString()
                        : ''),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteNotification(notification.id);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        SizedBox(height: 20),
        TextField(
          controller: _notificationController,
          decoration: InputDecoration(
            labelText: 'New Notification',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[200],
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            String message = _notificationController.text.trim();
            if (message.isNotEmpty) {
              _createNotification(message);
              _notificationController.clear();
            }
          },
          child: Text('Add Notification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access ThemeNotifier from Provider
    ThemeNotifier themeNotifier = Provider.of<ThemeNotifier>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationList(),
          SizedBox(height: 20),
          Text(
            'Theme',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: Text('Dark Theme'),
            value: themeNotifier.getTheme() == ThemeData.dark(),
            onChanged: (bool value) {
              themeNotifier.toggleTheme(value);
              // Optionally, save theme preference to Firestore
              User? user = _auth.currentUser;
              if (user != null) {
                _firestore.collection('users').doc(user.uid).update({
                  'isDarkTheme': value,
                });
              }
            },
            secondary: Icon(Icons.brightness_6),
          ),
        ],
      ),
    );
  }
}
