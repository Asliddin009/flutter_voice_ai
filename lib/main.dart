// ignore_for_file: unused_import

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_audio/conversation.dart';
import 'package:web_socket_audio/conversation_config.dart';
import 'package:web_socket_audio/default_audio_interface.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

// Главный виджет приложения.
class MyApp extends StatelessWidget {
  final String? agentId = dotenv.env['AGENT_ID'];
  final String? apiKey = dotenv.env['XI_API_KEY'];

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (agentId == null || agentId!.isEmpty) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('AGENT_ID environment variable must be set'),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Conversation with Agent',
      debugShowCheckedModeBanner: false,
      home: ConversationPage(
        agentId: agentId!,
        apiKey: apiKey,
        requiresAuth: apiKey != null,
      ),
    );
  }
}

// Страница разговора.
class ConversationPage extends StatefulWidget {
  final String agentId;
  final String? apiKey;
  final bool requiresAuth;

  const ConversationPage({
    super.key,
    required this.agentId,
    this.apiKey,
    required this.requiresAuth,
  });

  @override
  ConversationPageState createState() => ConversationPageState();
}

class ConversationPageState extends State<ConversationPage> {
  Conversation? conversation;
  String agentResponse = '';
  String userTranscript = '';
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    // startConversation();
  }

  void startConversation() {
    conversation = Conversation(
      agentId: widget.agentId,
      apiKey: widget.apiKey,
      requiresAuth: widget.requiresAuth,
      audioInterface: DefaultAudioInterface(),
      callbackAgentResponse: (response) {
        setState(() {
          agentResponse = response;
        });
      },
      callbackUserTranscript: (transcript) {
        setState(() {
          userTranscript = transcript;
        });
      },
      config: ConversationConfig(),
    );
    conversation!.startSession();
  }

  void endConversation() {
    conversation?.endSession();
  }

  @override
  void dispose() {
    endConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation with Agent'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isRecording
                ? ElevatedButton(
                    onPressed: () {
                      endConversation();
                      setState(() {
                        isRecording = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'End Conversation',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      startConversation();
                      setState(() {
                        isRecording = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Start Conversation',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            const SizedBox(
              height: 16,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    'Agent: \n $agentResponse',
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: 1,
                  height: 200,
                  color: Colors.black,
                ),
                Expanded(
                  child: Text(
                    'User: \n $userTranscript',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
