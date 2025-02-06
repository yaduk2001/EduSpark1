import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:eduspark/Courses/QuizPage.dart';
import 'package:eduspark/Courses/certificate.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'dart:convert';


class CourseContentPage extends StatefulWidget {
  final String courseName;
  final String userID;

  CourseContentPage({required this.courseName, required this.userID});

  @override
  _CourseContentPageState createState() => _CourseContentPageState();
}

class _CourseContentPageState extends State<CourseContentPage> {
  double _progress = 0.0;
  List<String> contentUrls = [];
  List<String> completedContent = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProgress();
  }

  Future<void> _initializeProgress() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        var completedData = userSnapshot.get('completedContent');

        if (completedData is List<dynamic>) {
          completedContent = List<String>.from(completedData);
        } else if (completedData is String) {
          completedContent = [completedData];
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userID)
              .update({'completedContent': FieldValue.arrayUnion([completedData])});
        } else {
          completedContent = [];
        }
      }

      // Fetch course details to get contentUrls
      Map<String, dynamic> courseDetails = await fetchCourseDetails();
      setState(() {
        contentUrls = List<String>.from(courseDetails['contentUrls'] ?? []);
        _progress = contentUrls.isNotEmpty
            ? completedContent.length / contentUrls.length
            : 0.0;
        isLoading = false;
      });
    } catch (e) {
      print('Error initializing progress: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch course details based on courseName
  Future<Map<String, dynamic>> fetchCourseDetails() async {
    try {
      QuerySnapshot courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('courseName', isEqualTo: widget.courseName)
          .get();

      if (courseSnapshot.docs.isNotEmpty) {
        return courseSnapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        throw Exception('Course not found');
      }
    } catch (e) {
      print('Error fetching course details: $e');
      throw e;
    }
  }

  // Update user's progress when a content is completed
  Future<void> updateUserProgress(String contentUrl) async {
    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userID);

      if (!completedContent.contains(contentUrl)) {
        await userRef.update({
          'completedContent': FieldValue.arrayUnion([contentUrl]),
        });

        setState(() {
          completedContent.add(contentUrl);
          _progress = contentUrls.isNotEmpty
              ? completedContent.length / contentUrls.length
              : 0.0;
        });

        if (_progress >= 1.0) {
          _showQuizUnlockedDialog();
        }
      }
    } catch (e) {
      print('Error updating user progress: $e');
    }
  }

  void _showQuizUnlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiz Unlocked'),
        content: Text('Congratulations! You\'ve unlocked the quiz for this course.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget(String contentUrl) {
    final uri = Uri.parse(contentUrl);
    final fileName = uri.pathSegments.last;
    final urlType = fileName.split('.').last.toLowerCase();

    if (['mp4', 'mov', 'avi'].contains(urlType)) {
      return VideoPlayerScreen(
        videoUrl: contentUrl,
        onComplete: () => updateUserProgress(contentUrl),
      );
    } else if (['mp3', 'wav'].contains(urlType)) {
      return AudioPlayerScreen(
        audioUrl: contentUrl,
        onComplete: () => updateUserProgress(contentUrl),
      );
    } else if (['jpg', 'jpeg', 'png', 'gif'].contains(urlType)) {
      return ImageViewerScreen(imageUrl: contentUrl);
    } else if (urlType == 'pdf') {
      return PDFViewerScreen(pdfUrl: contentUrl);
    } else {
      return _unsupportedContentWidget(urlType);
    }
  }

  Widget _unsupportedContentWidget(String urlType) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unsupported Content'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Text(
          'Unsupported content type: $urlType',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Certificate Section using FutureBuilder
  Widget _buildCertificateSection() {
    bool isUnlocked = false;

    return StatefulBuilder(builder: (context, setState) {
      return GestureDetector(
        onTap: () {
          // Show error message on single tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please complete Quiz to unlock certificate')),
          );
        },
        onDoubleTap: () {
          // Unlock the certificate on double tap
          setState(() {
            isUnlocked = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Certificate Unlocked!')),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isUnlocked ? Colors.green : Colors.blueAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Certificate',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8), // Space between certificate title and button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    isUnlocked ? Icons.lock_open : Icons.lock,
                    color: Colors.white,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (isUnlocked) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>CertificatePage(
                              courseName: widget.courseName,
                              userID: widget.userID,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Double-tap to unlock certificate')),
                        );
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Get Certificate',
                        style: TextStyle(
                            color: isUnlocked ? Colors.green : Colors.blueAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // Quiz Section
  Widget _buildQuizSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _progress >= 1.0 ? Colors.green : Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quiz',
            style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          Icon(
            _progress >= 1.0 ? Icons.lock_open : Icons.lock,
            color: Colors.white,
          ),
          GestureDetector(
            onTap: () {
              if (_progress >= 1.0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(
                      courseName: widget.courseName,
                      userID: widget.userID,
                    ),
                  ),
                ).then((_) {
                  // Refresh progress when returning from quiz
                  _initializeProgress();
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Complete all content to unlock the quiz.')),
                );
              }
            },
            child: Container(
              padding:
                  EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Take Quiz',
                style: TextStyle(
                    color: _progress >= 1.0
                        ? Colors.green
                        : Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
                _buildQuizSection(), // Quiz section
                _buildCertificateSection(), // Updated Certificate section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3 / 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: contentUrls.length,
                      itemBuilder: (context, index) {
                        final contentUrl = contentUrls[index];
                        final isCompleted =
                            completedContent.contains(contentUrl);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    _buildContentWidget(contentUrl),
                              ),
                            ).then((_) {
                              // Refresh progress when returning from content
                              _initializeProgress();
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green[100]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                                'assets/images/placeholder.png'),
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black54,
                                              Colors.black38
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_circle_fill,
                                              size: 50,
                                              color: Colors.white,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Content ${index + 1}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (isCompleted)
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.greenAccent,
                                                size: 24,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onComplete;

  VideoPlayerScreen({required this.videoUrl, required this.onComplete});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  final SpeechToText _speechToText = SpeechToText();
  String _recognizedText = '';
  
  final String _translatorEndpoint = 'https://api.cognitive.microsofttranslator.com/translate';
  final String _subscriptionKey = 'YOUR_SUBSCRIPTION_KEY';
  final String _region = 'eastus';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _processAudioStream();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    await _controller?.initialize();
    _controller?.play();
    setState(() {});
  }

  Future<void> _processAudioStream() async {
    try {
      bool available = await _speechToText.initialize();
      if (available) {
        await _speechToText.listen(
          onResult: (result) async {
            String text = result.recognizedWords;
            if (text.isNotEmpty) {
              String signLanguage = await _translateToISL(text);
              setState(() {
                _recognizedText = signLanguage;
              });
            }
          },
        );
      }
    } catch (e) {
      print('Error processing audio: $e');
    }
  }

  Future<String> _translateToISL(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_translatorEndpoint?api-version=3.0&to=isl'),
        headers: {
          'Ocp-Apim-Subscription-Key': _subscriptionKey,
          'Ocp-Apim-Subscription-Region': _region,
          'Content-Type': 'application/json',
        },
        body: jsonEncode([{'Text': text}]),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result[0]['translations'][0]['text'];
      }
    } catch (e) {
      print('Translation error: $e');
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Player')),
      body: Stack(
        children: [
          if (_controller != null)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          Positioned(
            right: 0,
            top: 0,
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    'Sign Language',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _recognizedText,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
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

  @override
  void dispose() {
    _speechToText.stop();
    _controller?.dispose();
    super.dispose();
  }
}

class AudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final VoidCallback onComplete;

  AudioPlayerScreen({required this.audioUrl, required this.onComplete});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerComplete.listen((event) {
      if (!_isCompleted) {
        _isCompleted = true;
        widget.onComplete();
        _showCompletionDialog();
      }
    });
  }

  Future<void> _playAudio() async {
    await _audioPlayer.play(UrlSource(widget.audioUrl));
    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Content Completed'),
          content: Text('You have completed listening to the audio.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog
                Navigator.of(context)
                    .pop(); // Go back to the CourseContentPage
              },
            ),
          ],
        );
      },
    );
  }

  // Manual completion (optional)
  void _completeAudio() {
    if (!_isCompleted) {
      _isCompleted = true;
      widget.onComplete();
      _stopAudio();
      _showCompletionDialog();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Audio Player'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 100,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 50,
                    onPressed: () {
                      if (_isPlaying) {
                        _pauseAudio();
                      } else {
                        _playAudio();
                      }
                    },
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.stop),
                    iconSize: 50,
                    onPressed: _stopAudio,
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _completeAudio,
                child: Text('Mark as Completed'),
              ),
            ],
          ),
        ));
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  ImageViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Viewer'),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        loadingBuilder: (context, event) =>
            Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            'Failed to load image.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;

  PDFViewerScreen({required this.pdfUrl});

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _downloadPDF();
  }

  Future<void> _downloadPDF() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final bytes = response.bodyBytes;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/temp.pdf';
      File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      setState(() {
        localPath = filePath;
        isLoading = false;
      });
    } catch (e) {
      print('Error downloading PDF: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load PDF.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('PDF Viewer'),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : localPath != null
                ? PDFView(
                    filePath: localPath,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: false,
                  )
                : Center(child: Text('Failed to load PDF.')));
  }
}

