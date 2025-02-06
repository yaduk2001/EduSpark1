import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourseEnrollPage extends StatefulWidget {
  final DocumentSnapshot course;

  CourseEnrollPage({required this.course});

  @override
  _CourseEnrollPageState createState() => _CourseEnrollPageState();
}

class _CourseEnrollPageState extends State<CourseEnrollPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isEnrolled = false;
  List<String> courseOutlines = [];

  @override
  void initState() {
    super.initState();
    _checkEnrollmentStatus();
    _fetchCourseOutline();
  }

  Future<void> _checkEnrollmentStatus() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      List<dynamic> enrolledCourses = userDoc['enrolledCourses'] ?? [];
      setState(() {
        isEnrolled = enrolledCourses.contains(widget.course.id);
      });
    }
  }

  Future<void> _fetchCourseOutline() async {
    try {
      List<String> outlines = await fetchCourseOutline(widget.course['courseName']);
      setState(() {
        courseOutlines = outlines;
      });
    } catch (e) {
      print('Error fetching course outline: $e');
    }
  }

  Future<void> _enrollInCourse() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Check if the course is paid
      bool isPaid = widget.course['isPaid'] ?? false; // Assuming isPaid is a field in the course document

      if (isPaid) {
        // Redirect to payment page
        bool paymentSuccessful = await _redirectToPaymentPage();
        if (paymentSuccessful) {
          await _updateEnrollment(user.uid);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Enrolled successfully!'),
          ));
        }
      } else {
        // If the course is free, enroll directly
        await _updateEnrollment(user.uid);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Enrolled successfully!'),
        ));
      }
    }
  }

  Future<bool> _redirectToPaymentPage() async {
    // Navigate to the payment page and await result
    bool result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => PaymentPage()), // Assume you have a PaymentPage widget
    ) ?? false;
    return result; // Returns true if payment was successful
  }

  Future<void> _updateEnrollment(String userId) async {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    // Update user's enrolled courses
    await userRef.update({
      'enrolledCourses': FieldValue.arrayUnion([widget.course.id])
    });

    // Update the enrolled count in the course document
    DocumentReference courseRef = FirebaseFirestore.instance.collection('courses').doc(widget.course.id);
    await courseRef.update({
      'enrolled': FieldValue.increment(1) // Increment the enrolled field by 1
    });

    setState(() {
      isEnrolled = true;
    });
  }

  Future<List<String>> fetchCourseOutline(String courseName) async {
    String apiKey = '1f9eb51f009d49f0ab49551c77ae8793'; // Replace with your Bing API key
    String url = 'https://api.bing.microsoft.com/v7.0/search?q=${Uri.encodeComponent(courseName)}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Ocp-Apim-Subscription-Key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      var webPages = jsonResponse['webPages']['value'] as List;

      int resultCount = webPages.length >= 4 ? 4 : webPages.length;

      List<String> outlines = [];
      for (int i = 0; i < resultCount; i++) {
        outlines.add(webPages[i]['snippet'] ?? 'No content available');
      }

      return outlines;
    } else {
      throw Exception('Failed to fetch course outline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Add background color
      appBar: AppBar(
        title: Text('Enroll in ${course['courseName']}'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Title Section
            Text(
              course['courseName'],
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8.0),

            // Course Difficulty, Hours, Learners, Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course['difficultyLevel']} • ${course['courseDuration']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow.shade600),
                    SizedBox(width: 4.0),
                    Text('${course['rating']}/5'),
                    SizedBox(width: 16.0),
                    Text('${course['enrolled']} enrolled'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),

            // Enroll and Premium Buttons
            Center(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ElevatedButton(
                      onPressed: isEnrolled ? null : _enrollInCourse,
                      child: Text(
                        isEnrolled ? 'Already Enrolled' : 'Enroll for Free',
                        style: TextStyle(color: isEnrolled ? Colors.white : Colors.blue),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnrolled ? Colors.blue : Colors.white,
                        side: BorderSide(color: Colors.blue, width: 2),
                        padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rectangular shape
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Premium button action
                    },
                    child: Text(
                      'Go Premium',
                      style: TextStyle(color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.blue, width: 2),
                      padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.0),

            // Course Description
            Text(
              course['description'] ?? 'No description available.',
              style: TextStyle(fontSize: 16.0, color: Colors.blueGrey),
            ),
            SizedBox(height: 24.0),

            // Certificate Demo Section
            Center(
              child: Column(
                children: [
                  Text(
                    'Certificate of Completion',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Card(
                    elevation: 4,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 200, // Adjust height according to your certificate design
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/certificate_demo.png'), // Ensure you have this image in your assets
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.0),

            // Skills you'll learn section
            Text(
              'Skills you\'ll learn',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: (course['skillsEarn'] is String
                  ? (course['skillsEarn'] as String).split(',')
                  : course['skillsEarn']).map<Widget>((skill) {
                return Chip(
                  label: Text(skill.trim()),
                  backgroundColor: Colors.blue.shade100,
                );
              }).toList(),
            ),
            SizedBox(height: 24.0),

            // Course Outline section (dynamically fetched)
            Text(
              'Course Outline',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 8.0),

            courseOutlines.isNotEmpty
                ? Column(
                    children: List.generate(
                      courseOutlines.length < 4 ? courseOutlines.length : 4,
                      (index) {
                        return ExpansionTile(
                          title: Text('Topic ${index + 1}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.add), // Plus icon
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(courseOutlines[index]),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                : CircularProgressIndicator(), // Loading indicator

            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}


// ignore: must_be_immutable
class PaymentPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId; // For storing the verification ID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Page'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Amount: \$50.00',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Delivery Fee: \$5.00',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Total: \$55.00',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            _buildPaymentOption(context, 'Credit/Debit Card'),
            SizedBox(height: 16),
            _buildPaymentOption(context, 'PayPal'),
            SizedBox(height: 16),
            _buildPaymentOption(context, 'Google Pay'),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Complete Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        if (title == 'Credit/Debit Card') {
          _showCardPaymentSheet(context);
        }
      },
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18),
              ),
              Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PaymentBottomSheet(
          sendOtp: (String phoneNumber) async {
            await _sendOtp(phoneNumber, context);
          },
        );
      },
    );
  }

  Future<void> _sendOtp(String phoneNumber, BuildContext context) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-retrieval or instant verification
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed. Please try again.')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to your phone number')),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }
}

class PaymentBottomSheet extends StatelessWidget {
  final Function(String) sendOtp;
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  PaymentBottomSheet({required this.sendOtp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Card Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  sendOtp(phoneNumberController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: Text('Send OTP'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: otpController,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: Text('Submit Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
