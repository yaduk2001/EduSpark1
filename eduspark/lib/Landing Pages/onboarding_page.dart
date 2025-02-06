// onboarding_screen.dart

import 'package:eduspark/Login%20Pages/login_role_selection.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _arrowController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _pageController.dispose(); // Dispose the PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using Stack to place bottom navigation elements above the PageView
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              buildOnboardingPage(
                image: Icons.school,
                title: 'Welcome to Edu Spark',
                description: 'Your personal assistant for smarter learning.',
              ),
              buildOnboardingPage(
                image: Icons.people,
                title: 'Collaboration Made Easy',
                description:
                    'Engage with students, teachers, and parents effortlessly.',
              ),
              buildOnboardingPage(
                image: Icons.computer,
                title: 'AI-Powered Learning',
                description:
                    'Personalized recommendations and resources for better learning.',
              ),
              LoginRoleSelection(), // Final page takes to login role selection
            ],
          ),

          // Positioned bottom navigation elements
          Positioned(
            bottom: 20, // Adjust as needed
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDotIndicator(), // Dot indicator
                  SizedBox(height: 10), // Space between dots and arrow
                  GestureDetector(
                    onTap: () {
                      if (_currentPage < 3) {
                        _pageController.animateToPage(
                          _currentPage + 1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // If on the last page, navigate to LoginRoleSelection
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => LoginRoleSelection()),
                        );
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _arrowAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _arrowAnimation.value),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable widget to build each onboarding page
  Widget buildOnboardingPage(
      {IconData? image, String? title, String? description}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: Icon(
              image,
              size: 150,
              color: Colors.white,
              key: ValueKey<int>(_currentPage), // Key for animation
            ),
          ),
          SizedBox(height: 30),
          Text(
            title!,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description!,
            style: TextStyle(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Method to build dot indicator
  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          width: 12.0, // Increased size for better visibility
          height: 12.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.white : Colors.white70,
          ),
        );
      }),
    );
  }
}
