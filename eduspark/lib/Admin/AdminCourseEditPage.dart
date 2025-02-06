// AdminEditCoursePage.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Using FilePicker for multiple file types
import 'package:fluttertoast/fluttertoast.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:image_picker/image_picker.dart';

class AdminEditCoursePage extends StatefulWidget {
  final String courseId; // The ID of the course to edit

  // Make courseId required
  AdminEditCoursePage({required this.courseId});

  @override
  _AdminEditCoursePageState createState() => _AdminEditCoursePageState();
}

class _AdminEditCoursePageState extends State<AdminEditCoursePage>
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
  String? _skillsEarn;  // New Skills Earned Field
  bool _isCertified = false;
  bool _isPaid = false;
  double? _courseFee;
  String? _category;
  List<XFile> _courseContents = []; // For storing new course content files
  List<String> _existingContentUrls = []; // Existing content URLs

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Firestore document snapshot
  DocumentSnapshot? _courseSnapshot;

  // Map to track upload progress for each file
  Map<String, double> _uploadProgress = {};

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

    // Debugging: Print the received courseId
    print("AdminEditCoursePage initialized with courseId: '${widget.courseId}', Type: ${widget.courseId.runtimeType}");

    // Validate courseId
    if (widget.courseId.trim().isNotEmpty) {
      _fetchCourseDataById(widget.courseId.trim());
    } else {
      Fluttertoast.showToast(
        msg: "Invalid course ID",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchCourseDataById(String courseId) async {
    try {
      print("Attempting to fetch course with ID: $courseId");
      DocumentSnapshot courseDoc =
          await _firestore.collection('courses').doc(courseId).get();
      if (courseDoc.exists) {
        print("Course found. Populating fields.");
        setState(() {
          _courseSnapshot = courseDoc;
          _courseName = courseDoc.get('courseName') ?? '';
          _courseDuration = courseDoc.get('courseDuration') ?? '';
          _difficultyLevel = courseDoc.get('difficultyLevel') ?? '';
          _tutorDetails = courseDoc.get('tutorDetails') ?? '';
          _description = courseDoc.get('description') ?? ''; // Populate Description
          _skillsEarn = courseDoc.get('skillsEarn') ?? '';   // Populate Skills Earned
          _isCertified = courseDoc.get('isCertified') ?? false;
          _isPaid = courseDoc.get('isPaid') ?? false;
          _courseFee = courseDoc.get('courseFee') != null
              ? (courseDoc.get('courseFee') as num).toDouble()
              : null;
          _category = courseDoc.get('category') ?? 'General';
          _existingContentUrls =
              List<String>.from(courseDoc.get('contentUrls') ?? []);
        });
        print("Course data populated successfully.");
      } else {
        print("Course with ID $courseId does not exist.");
        Fluttertoast.showToast(
          msg: "Course with ID $courseId not found!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error fetching course: $e");
      Fluttertoast.showToast(
        msg: "Error fetching course: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      Navigator.pop(context);
    }
  }

  // Updated to use FilePicker for multiple file types
  Future<void> _pickCourseContents() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', // Images
          'mp4', 'avi', 'mov', // Videos
          'mp3', 'wav', // Audios
          'pdf', 'doc', 'docx', 'txt', // Documents
          // Add other extensions as needed
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _courseContents
              .addAll(result.files.map((e) => XFile(e.path!)).toList());
        });
        print("Picked ${result.files.length} new course content files.");
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

  Future<void> _updateCourse() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      print("Starting course update process for courseId: ${_courseSnapshot?.id}");

      try {
        // Show a loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        // Update course data in Firestore
        await _firestore.collection('courses').doc(_courseSnapshot?.id).update({
          'courseName': _courseName,
          'courseDuration': _courseDuration,
          'difficultyLevel': _difficultyLevel,
          'tutorDetails': _tutorDetails,
          'description': _description, // Update Description
          'skillsEarn': _skillsEarn,   // Update Skills Earned
          'isCertified': _isCertified,
          'isPaid': _isPaid,
          'courseFee': _isPaid ? _courseFee : null,
          'category': _category,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print("Course data updated in Firestore.");

        // Upload new course contents to Firebase Storage and update URLs
        List<String> updatedContentUrls = List<String>.from(_existingContentUrls);
        for (var file in _courseContents) {
          // Sanitize file name
          String sanitizedFileName = _sanitizeFileName(file.name);
          String uniqueFileName =
              '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
          String filePath = 'courses/${_courseSnapshot?.id}/$uniqueFileName';
          Reference storageRef = _storage.ref().child(filePath);
          UploadTask uploadTask = storageRef.putFile(File(file.path));

          // Initialize progress
          _uploadProgress[uniqueFileName] = 0.0;
          setState(() {}); // Refresh UI to show progress

          // Listen to upload progress
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            double progress =
                snapshot.bytesTransferred / snapshot.totalBytes * 100;
            setState(() {
              _uploadProgress[uniqueFileName] = progress;
            });
            print("Uploading $uniqueFileName: ${progress.toStringAsFixed(2)}%");
          });

          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          updatedContentUrls.add(downloadUrl);
          print("Uploaded $uniqueFileName to $downloadUrl");
        }

        // Update content URLs in Firestore
        await _firestore.collection('courses').doc(_courseSnapshot?.id).update({
          'contentUrls': updatedContentUrls,
        });

        print("Course content URLs updated in Firestore.");

        // Hide the loading indicator
        Navigator.pop(context);

        Fluttertoast.showToast(
          msg: "Course updated successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        // Optionally navigate back or reset the form
        Navigator.pop(context);
      } catch (e) {
        print("Error updating course: $e");
        // Hide the loading indicator
        Navigator.pop(context);

        Fluttertoast.showToast(
          msg: "Failed to update course: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  // Function to delete existing course content
  Future<void> _deleteCourseContent(String url) async {
    try {
      print("Attempting to delete content URL: $url ");
      // Delete from Firebase Storage
      Reference storageRef = _storage.refFromURL(url);
      await storageRef.delete();

      print("Deleted content from Firebase Storage.");

      // Remove from Firestore
      List<String> updatedContentUrls = List<String>.from(_existingContentUrls);
      updatedContentUrls.remove(url);
      await _firestore.collection('courses').doc(_courseSnapshot?.id).update({
        'contentUrls': updatedContentUrls,
      });

      setState(() {
        _existingContentUrls = updatedContentUrls;
      });

      Fluttertoast.showToast(
        msg: "Content deleted successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print("Error deleting content: $e");
      Fluttertoast.showToast(
        msg: "Failed to delete content: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Function to sanitize file names
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
        title: Text('Edit Course'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _courseSnapshot == null
          ? Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
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
                              'Edit Course Details',
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

                        // Course Name
                        TextFormField(
                          initialValue: _courseName,
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
                          initialValue: _courseDuration,
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
                          initialValue: _difficultyLevel,
                          decoration: _buildInputDecoration(
                              'Difficulty Level (e.g., Beginner)', Icons.trending_up),
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
                          initialValue: _tutorDetails,
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
                          initialValue: _description,
                          decoration: _buildInputDecoration('Description', Icons.description),
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
                          initialValue: _skillsEarn,
                          decoration: _buildInputDecoration('Skills Earned', Icons.star),
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
                            initialValue: _courseFee != null
                                ? _courseFee.toString()
                                : '',
                            decoration: _buildInputDecoration(
                                'Course Fee (\₹)', Icons.attach_money),
                            keyboardType: TextInputType.numberWithOptions(
                                decimal: true),
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

                        // Existing Course Contents
                        _existingContentUrls.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Existing Course Contents',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: _existingContentUrls.map((url) {
                                      // Determine the file type based on URL extension
                                      String extension = url.split('.').last.toLowerCase();
                                      IconData iconData;
                                      switch (extension) {
                                        case 'jpg':
                                        case 'jpeg':
                                        case 'png':
                                          iconData = Icons.image;
                                          break;
                                        case 'mp4':
                                        case 'avi':
                                        case 'mov':
                                          iconData = Icons.video_file;
                                          break;
                                        case 'mp3':
                                        case 'wav':
                                          iconData = Icons.audiotrack;
                                          break;
                                        case 'pdf':
                                          iconData = Icons.picture_as_pdf;
                                          break;
                                        case 'doc':
                                        case 'docx':
                                        case 'txt':
                                          iconData = Icons.description;
                                          break;
                                        default:
                                          iconData = Icons.insert_drive_file;
                                      }

                                      return Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius: BorderRadius.circular(12.0),
                                              border: Border.all(color: Colors.deepPurple),
                                            ),
                                            child: Icon(
                                              iconData,
                                              size: 50,
                                              color: Colors.deepPurple.shade700,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _deleteCourseContent(url),
                                            child: CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.red,
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(height: 16),
                                ],
                              )
                            : Container(),

                        // Upload New Course Contents
                        ElevatedButton.icon(
                          onPressed: _pickCourseContents,
                          icon: Icon(Icons.upload_file),
                          label: Text('Upload New Course Contents'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 250, 87),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
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

                        // Display Upload Progress
                        _uploadProgress.isNotEmpty
                            ? Column(
                                children: _uploadProgress.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: entry.value / 100,
                                            backgroundColor: Colors.grey.shade300,
                                            color: Colors.green,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text("${entry.value.toStringAsFixed(0)}%"),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            : Container(),

                        // Display Selected New Contents
                        _courseContents.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 16),
                                  Text(
                                    'New Course Contents',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: _courseContents.map((file) {
                                      String fileName = file.name;
                                      String extension = fileName.split('.').last.toLowerCase();

                                      IconData iconData;
                                      switch (extension) {
                                        case 'jpg':
                                        case 'jpeg':
                                        case 'png':
                                          iconData = Icons.image;
                                          break;
                                        case 'mp4':
                                        case 'avi':
                                        case 'mov':
                                          iconData = Icons.video_file;
                                          break;
                                        case 'mp3':
                                        case 'wav':
                                          iconData = Icons.audiotrack;
                                          break;
                                        case 'pdf':
                                          iconData = Icons.picture_as_pdf;
                                          break;
                                        case 'doc':
                                        case 'docx':
                                        case 'txt':
                                          iconData = Icons.description;
                                          break;
                                        default:
                                          iconData = Icons.insert_drive_file;
                                      }

                                      return Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius: BorderRadius.circular(12.0),
                                              border: Border.all(color: Colors.deepPurple),
                                            ),
                                            child: Icon(
                                              iconData,
                                              size: 50,
                                              color: Colors.deepPurple.shade700,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _courseContents.remove(file);
                                              });
                                            },
                                            child: CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Colors.red,
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 4.0, vertical: 2.0),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(12.0),
                                                  bottomRight: Radius.circular(12.0),
                                                ),
                                              ),
                                              child: Text(
                                                fileName,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              )
                            : Container(),
                        SizedBox(height: 24),

                        // Update Course Button
                        ElevatedButton(
                          onPressed: _updateCourse,
                          child: Text(
                            'Update Course',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            shadowColor: Colors.deepPurple.shade200,
                            elevation: 10,
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
