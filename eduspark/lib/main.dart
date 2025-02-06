import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Landing Pages/onboarding_page.dart'; // Import for Firebase

// Firebase configuration from your JSON file
const firebaseConfig = {
  "project_info": {
    "project_number": "1055251300642",
    "project_id": "eduspark-a0562",
    "storage_bucket": "eduspark-a0562.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:1055251300642:android:13ded8f371a4ba4ed3a57b",
        "android_client_info": {
          "package_name": "com.example.eduspark"
        }
      },
      "oauth_client": [
        {
          "client_id": "1055251300642-5iiuj2opilumv1i7ps6jo5jv57fbhafc.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.eduspark",
            "certificate_hash": "3d04a55bf42b52c836150ccc42561131d850dfa7"
          }
        },
        {
          "client_id": "1055251300642-nm4bmj2od9o92t9uf53ronmrjhmp587u.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyBB3vxlYAH1-btrxdtfGQTEBkx413Nnzj0"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "1055251300642-nm4bmj2od9o92t9uf53ronmrjhmp587u.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
};
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBB3vxlYAH1-btrxdtfGQTEBkx413Nnzj0',
      appId: '1:1055251300642:android:13ded8f371a4ba4ed3a57b',
      messagingSenderId: '1055251300642',
      projectId: 'eduspark-a0562',
      storageBucket: 'eduspark-a0562.appspot.com',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduSpark',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: OnboardingScreen(),
    );
  }
}


