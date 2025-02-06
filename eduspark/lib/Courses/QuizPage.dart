import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ContentAccessPage.dart';

class QuizPage extends StatefulWidget {
  final String courseName;
  final String userID;

  QuizPage({required this.courseName, required this.userID});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  List<Question> questions = [];
  int score = 0;
  int totalQuestions = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    questions = generateSampleQuestions();
    totalQuestions = questions.length;

    // Set up animation
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  List<Question> generateSampleQuestions() {
    return [
      Question(
        question: 'What is 5 + 3?',
        options: ['6', '7', '8', '9'],
        correctAnswer: '8',
      ),
      Question(
        question: 'What is 10 - 4?',
        options: ['5', '6', '7', '4'],
        correctAnswer: '6',
      ),
      Question(
        question: 'What is the capital of France?',
        options: ['Paris', 'London', 'Berlin', 'Madrid'],
        correctAnswer: 'Paris',
      ),
      Question(
        question: 'What is 9 * 6?',
        options: ['54', '56', '60', '62'],
        correctAnswer: '54',
      ),
    ];
  }

  void submitQuiz() {
    double percentage = (score / totalQuestions) * 100;
    if (percentage >= 70) {
      FirebaseFirestore.instance.collection('quizzes').add({
        'courseName': widget.courseName,
        'userID': widget.userID,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _controller.forward().then((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.lightGreen.shade50,
              title: Text(
                'Congratulations!',
                style: TextStyle(color: Colors.green),
              ),
              content: FadeTransition(
                opacity: _animation,
                child: Text(
                  'You have passed the quiz with a score of ${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _controller.reverse().then((_) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseContentPage(courseName: widget.courseName, userID: widget.userID),
                        ),
                      );
                    });
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.red.shade50,
            title: Text(
              'Failed',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              'You need at least 70% to pass.',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Try Again',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz for ${widget.courseName}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return Card(
                color: Colors.white70,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questions[index].question,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      ...questions[index].options.map((option) => RadioListTile(
                            activeColor: Colors.deepPurple,
                            title: Text(option),
                            value: option,
                            groupValue: questions[index].selectedAnswer,
                            onChanged: (value) {
                              setState(() {
                                questions[index].selectedAnswer = value as String?;
                                if (questions[index].correctAnswer == value) {
                                  score++;
                                }
                              });
                            },
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitQuiz,
        backgroundColor: Colors.deepPurple,
        label: Text('Submit'),
        icon: Icon(Icons.check),
      ),
    );
  }
}

class Question {
  String question;
  List<String> options;
  String correctAnswer;
  String? selectedAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}
