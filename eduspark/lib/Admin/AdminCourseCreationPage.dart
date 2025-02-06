// AdminCourseCreationPage.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduspark/Admin/AdminCourseEditPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // For file uploads
import 'package:fluttertoast/fluttertoast.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:image_picker/image_picker.dart';

class AdminCourseCreationPage extends StatefulWidget {
  @override
  _AdminCourseCreationPageState createState() =>
      _AdminCourseCreationPageState();
}

class _AdminCourseCreationPageState extends State<AdminCourseCreationPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();
  String? _courseName;
  String? _courseDuration;
  String? _difficultyLevel;
  String? _tutorDetails;
  String? _description; // New Description Field
  String? _skillsEarn; // New Skills Earned Field
  bool _isCertified = false;
  bool _isPaid = false;
  double? _courseFee;
  String? _category;
  List<XFile> _courseContents = []; // For storing course content files
  List<String> _uploadedContentUrls = []; // URLs of uploaded contents

  // Thumbnail variables
  XFile? _thumbnail;
  String? _thumbnailUrl;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Progress tracking
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Categories list - you can fetch this dynamically from Firestore if needed
  final List<String> _categories = [
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

  String? _courseCode;

  @override
  void initState() {
    super.initState();
    // Initialize Animation Controller for 3D effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Define Scale Animation for 3D effect
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to pick course content files
  Future<void> _pickCourseContents() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png', // Images
          'mp4',
          'avi',
          'mov', // Videos
          'mp3',
          'wav', // Audios
          'pdf',
          'doc',
          'docx',
          'txt', // Documents
          // Add other extensions as needed
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _courseContents
              .addAll(result.files.map((e) => XFile(e.path!)).toList());
        });
        print("Picked ${result.files.length} course content files.");
      } else {
        print("No files selected.");
      }
    } catch (e) {
      print("Error picking course contents: $e");
      Fluttertoast.showToast(
        msg: "Error picking files: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Function to pick thumbnail image
  Future<void> _pickThumbnail() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (image != null) {
        setState(() {
          _thumbnail = image;
        });
        print("Thumbnail selected: ${image.name}");
      } else {
        print("No thumbnail selected.");
      }
    } catch (e) {
      print("Error picking thumbnail: $e");
      Fluttertoast.showToast(
        msg: "Error picking thumbnail: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Function to sanitize file names
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
  }

  // Function to upload thumbnail to Firebase Storage
  Future<void> _uploadThumbnail(String courseId) async {
    try {
      if (_thumbnail == null) return;

      String sanitizedFileName = _sanitizeFileName(_thumbnail!.name);
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      String filePath = 'courses/$courseId/thumbnail/$uniqueFileName';
      Reference storageRef = _storage.ref().child(filePath);
      UploadTask uploadTask = storageRef.putFile(File(_thumbnail!.path));

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            snapshot.bytesTransferred / snapshot.totalBytes * 100;
        setState(() {
          _uploadProgress = progress;
        });
        print("Uploading thumbnail: ${progress.toStringAsFixed(2)}%");
      });

      // Await completion
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      _thumbnailUrl = downloadUrl;
      print("Thumbnail uploaded to $downloadUrl");
    } catch (e) {
      print("Error uploading thumbnail: $e");
      Fluttertoast.showToast(
        msg: "Error uploading thumbnail: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      throw e; // Rethrow to handle in calling function
    }
  }

  // Function to upload course contents to Firebase Storage
  Future<void> _uploadCourseContents(String courseId) async {
    try {
      if (_courseContents.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      int totalFiles = _courseContents.length;
      int uploadedFiles = 0;

      for (var file in _courseContents) {
        String sanitizedFileName = _sanitizeFileName(file.name);
        String uniqueFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
        String filePath = 'courses/$courseId/contents/$uniqueFileName';
        Reference storageRef = _storage.ref().child(filePath);
        UploadTask uploadTask = storageRef.putFile(File(file.path));

        // Listen to upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress =
              snapshot.bytesTransferred / snapshot.totalBytes * 100;
          setState(() {
            _uploadProgress =
                ((uploadedFiles + (progress / 100)) / totalFiles) * 100;
          });
          print("Uploading $uniqueFileName: ${progress.toStringAsFixed(2)}%");
        });

        // Await completion
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        _uploadedContentUrls.add(downloadUrl);
        print("Uploaded $uniqueFileName to $downloadUrl");

        uploadedFiles++;
        setState(() {
          _uploadProgress = (uploadedFiles / totalFiles) * 100;
        });
      }

      setState(() {
        _isUploading = false;
      });

      Fluttertoast.showToast(
        msg: "All files uploaded successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print("Error uploading course contents: $e");
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(
        msg: "Error uploading files: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Function to create a new course
  Future<void> _createCourse() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Validate course fee if course is paid
      if (_isPaid && (_courseFee == null || _courseFee! <= 0)) {
        Fluttertoast.showToast(
          msg: "Please enter a valid course fee.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      try {
        // Show a loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        // Create a new document with auto-generated ID
        DocumentReference courseRef = _firestore.collection('courses').doc();
        String courseId = courseRef.id; // Firestore's auto-generated string ID

        // Set course data with initial fields
        await courseRef.set({
          'courseCode': _courseCode,
          'courseName': _courseName,
          'courseDuration': _courseDuration,
          'difficultyLevel': _difficultyLevel,
          'tutorDetails': _tutorDetails,
          'description': _description, // New Description Field
          'skillsEarn': _skillsEarn, // New Skills Earned Field
          'isCertified': _isCertified,
          'isPaid': _isPaid,
          'courseFee': _isPaid ? _courseFee : null,
          'category': _category,
          'createdBy': _auth.currentUser?.uid,
          'teacherId': _auth.currentUser?.uid, // Add teacher ID
          'createdAt': FieldValue.serverTimestamp(),
          'contentUrls': [], // Initialize as empty, will be updated after uploads
          'thumbnail': null, // Placeholder for thumbnail URL
          'rating': null, // New Rating Field
          'enrolled': 0, // New Enrolled Field
        });

        print("Course created with ID: $courseId");

        // Upload thumbnail if selected
        if (_thumbnail != null) {
          await _uploadThumbnail(courseId);

          // Update course document with thumbnail URL
          await _firestore.collection('courses').doc(courseId).update({
            'thumbnailUrl': _thumbnailUrl,
          });

          print("Thumbnail uploaded and URL updated.");
        }

        // Upload course contents if any
        if (_courseContents.isNotEmpty) {
          await _uploadCourseContents(courseId);

          // Update course document with content URLs
          await _firestore.collection('courses').doc(courseId).update({
            'contentUrls': _uploadedContentUrls,
          });

          print("Course contents uploaded and URLs updated.");
        }

        // Hide the loading indicator
        Navigator.pop(context);

        Fluttertoast.showToast(
          msg: "Course created successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        // Navigate to course list or reset the form
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminCourseListPage(),
          ),
        );
      } catch (e) {
        print("Error creating course: $e");
        // Hide the loading indicator
        Navigator.pop(context);

        Fluttertoast.showToast(
          msg: "Failed to create course: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  // Custom Input Decoration for consistency
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Course'),
        backgroundColor: Colors.deepPurple,
      ),
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..scale(_scaleAnimation.value, _scaleAnimation.value),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Animated Header
                  AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'Create New Course',
                        textStyle: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                        speed: Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                  SizedBox(height: 16),

                  // Course Code
                  TextFormField(
                    decoration: _buildInputDecoration('Course Code', Icons.code),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter course code';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _courseCode = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Course Name
                  TextFormField(
                    decoration:
                        _buildInputDecoration('Course Name', Icons.book),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter course name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _courseName = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Course Duration
                  TextFormField(
                    decoration: _buildInputDecoration(
                        'Course Duration (e.g., 4 weeks)', Icons.timer),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter course duration';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _courseDuration = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Difficulty Level
                  TextFormField(
                    decoration: _buildInputDecoration('Difficulty Level (e.g., Beginner)', Icons.trending_up),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter difficulty level';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _difficultyLevel = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Tutor Details
                  TextFormField(
                    decoration:
                        _buildInputDecoration('Tutor Details', Icons.person),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter tutor details';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _tutorDetails = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    decoration:
                        _buildInputDecoration('Description', Icons.description),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _description = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Skills Earn Field
                  TextFormField(
                    decoration:
                        _buildInputDecoration('Skills Earned', Icons.star),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the skills earned';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _skillsEarn = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration:
                        _buildInputDecoration('Category', Icons.category),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _category = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Is Certified
                  CheckboxListTile(
                    title: Text(
                      "Is Certified",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                    value: _isCertified,
                    activeColor: Colors.deepPurple,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCertified = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 10),

                  // Is Paid
                  CheckboxListTile(
                    title: Text(
                      "Is Paid",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                    value: _isPaid,
                    activeColor: Colors.deepPurple,
                    onChanged: (bool? value) {
                      setState(() {
                        _isPaid = value ?? false;
                        if (!_isPaid) _courseFee = null;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  SizedBox(height: 10),

                  // Course Fee (only if isPaid is true)
                  if (_isPaid)
                    TextFormField(
                      decoration: _buildInputDecoration(
                          'Course Fee (\₹)', Icons.attach_money),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (_isPaid && (value == null || value.isEmpty)) {
                          return 'Please enter course fee';
                        }
                        if (_isPaid && double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _courseFee = double.tryParse(value!);
                      },
                    ),
                  SizedBox(height: 16),

                  // Upload Thumbnail
                  ElevatedButton.icon(
                    onPressed: _pickThumbnail,
                    icon: Icon(Icons.image),
                    label: Text('Select Thumbnail Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Display Selected Thumbnail
                  _thumbnail != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            Text(
                              'Selected Thumbnail:',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple),
                            ),
                            SizedBox(height: 10),
                            Image.file(
                              File(_thumbnail!.path),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(height: 16),
                          ],
                        )
                      : Container(),

                  // Upload Course Contents
                  ElevatedButton.icon(
                    onPressed: _pickCourseContents,
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Course Contents'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 250, 87),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Display Selected Course Contents
                  _courseContents.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            Text(
                              'Selected Course Contents',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _courseContents.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Chip(
                                      label: Text(
                                        _courseContents[index].name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      deleteIcon: Icon(Icons.cancel),
                                      onDeleted: () {
                                        setState(() {
                                          _courseContents.removeAt(index);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Container(),

                  SizedBox(height: 20),

                  // Upload Progress Indicator
                  _isUploading
                      ? Column(
                          children: [
                            LinearProgressIndicator(
                              value: _uploadProgress / 100,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Uploading... ${_uploadProgress.toStringAsFixed(2)}%",
                              style: TextStyle(color: Colors.deepPurple),
                            ),
                          ],
                        )
                      : Container(),

                  SizedBox(height: 20),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isUploading ? null : _createCourse,
                    child: Text(
                      'Create Course',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for AdminCourseListPage
class AdminCourseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Implement your course list page here
    return Scaffold(
      appBar: AppBar(
        title: Text('Course List'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Text(
          'Course List Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
