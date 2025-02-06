
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Registration Pages/AdminLoginPage.dart';
import 'student_login.dart';
import 'teacher_login.dart';

class LoginRoleSelection extends StatefulWidget {
  @override
  _LoginRoleSelectionState createState() => _LoginRoleSelectionState();
}

class _LoginRoleSelectionState extends State<LoginRoleSelection>
    with SingleTickerProviderStateMixin {
  String _selectedRole = 'Student'; // Default value
  TextEditingController _secretKeyController = TextEditingController();
  late AnimationController _shapeController;
  late Animation<double> _shapeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for floating shapes
    _shapeController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _shapeAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _shapeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shapeController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background with floating shapes
          _buildAnimatedBackground(),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Login to Edu Spark',
                    style: GoogleFonts.raleway(
                      textStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30), // Spacing

                  // Dropdown to select role
                  _buildRoleDropdown(),
                  SizedBox(height: 20),

                  // Button to navigate to selected role's login page
                  _buildContinueButton(),

                  // Show "Restricted" message if Admin is selected
                  if (_selectedRole == 'Admin') ...[
                    SizedBox(height: 20),
                    Text(
                      'Restricted',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Floating shapes
        _buildFloatingShapes(),
      ],
    );
  }

  Widget _buildFloatingShapes() {
    return AnimatedBuilder(
      animation: _shapeAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(10, (index) {
            double size = 30 + (index % 5) * 20;
            double left = (index * 50) % MediaQuery.of(context).size.width;
            double top = (index * 30) % MediaQuery.of(context).size.height;

            return Positioned(
              left: left,
              top: top,
              child: Transform.scale(
                scale: _shapeAnimation.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.primaries[index % Colors.primaries.length]
                        .withOpacity(0.7),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Role',
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
      ),
      items: ['Student', 'Parent', 'Teacher', 'Admin']
          .map((role) => DropdownMenuItem<String>(
                value: role,
                child: Text(role),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedRole = value!;
        });
      },
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue, backgroundColor: Colors.white,
      ),
      onPressed: () {
        if (_selectedRole == 'Admin') {
          // Admin secret key handling
          _showSecretKeyDialog();
        } else if (_selectedRole == 'Student') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentLoginPage(),
            ),
          );
        } else if (_selectedRole == 'Teacher') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherLoginPage(),
          ),
        );
      }
        
        
         else {
          Fluttertoast.showToast(
            msg: 'Role not implemented yet.',
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      },
      child: Text('Continue'),
    );
  }

  void _showSecretKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Secret Key'),
          content: TextField(
            controller: _secretKeyController,
            decoration: InputDecoration(hintText: 'Secret Key'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_secretKeyController.text == 'admin_secret_key') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminLoginPage(),
                    ),
                  );
                } else {
                  Fluttertoast.showToast(
                    msg: 'Invalid secret key!',
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}
