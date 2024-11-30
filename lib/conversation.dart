import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_audio/audio_interface.dart';
import 'package:web_socket_audio/conversation_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

// Класс для управления разговором с агентом.
class Conversation {
  final String agentId;
  final String? apiKey;
  final bool requiresAuth;
  final ConversationConfig config;
  final AudioInterface audioInterface;
  final void Function(String)? callbackAgentResponse;
  final void Function(String, String)? callbackAgentResponseCorrection;
  final void Function(String)? callbackUserTranscript;
  final void Function(int)? callbackLatencyMeasurement;

  WebSocketChannel? _webSocket;
  int _lastInterruptId = 0;
  bool _shouldStop = false;

  Conversation({
    required this.agentId,
    this.apiKey,
    required this.requiresAuth,
    required this.audioInterface,
    required this.config,
    this.callbackAgentResponse,
    this.callbackAgentResponseCorrection,
    this.callbackUserTranscript,
    this.callbackLatencyMeasurement,
  });

  // Метод для начала сессии разговора.
  Future<void> startSession() async {
    String wsUrl = requiresAuth ? await _getSignedUrl() : _getWssUrl();
    _webSocket = WebSocketChannel.connect(Uri.parse(wsUrl));

    // Отправляем инициализационные данные.
    _webSocket!.sink.add(jsonEncode({
      "type": "conversation_initiation_client_data",
      "custom_llm_extra_body": config.extraBody,
      "conversation_config_override": config.conversationConfigOverride,
    }));

    // Запускаем аудио интерфейс.
    audioInterface.start((audioData) {
      _webSocket!.sink.add(jsonEncode({
        "user_audio_chunk": base64Encode(audioData),
      }));
    });

    // Слушаем входящие сообщения.
    _webSocket!.stream.listen((message) {
      if (_shouldStop) return;
      _handleMessage(jsonDecode(message));
    }, onDone: () {
      // Обработка завершения соединения.
    }, onError: (error) {
      // Обработка ошибок.
    });
  }

  // Метод для завершения сессии разговора.
  void endSession() {
    _shouldStop = true;
    audioInterface.stop();
    _webSocket?.sink.close();
  }

  // Метод для обработки входящих сообщений.
  void _handleMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'conversation_initiation_metadata':
        break;
      case 'audio':
        var event = message['audio_event'];
        // if ((int.tryParse(event['event_id']) ?? 10000) <= _lastInterruptId) {
        //   return;
        // }
        var audio = base64Decode(event['audio_base_64']);
        audioInterface.output(audio);
        break;
      case 'agent_response':
        if (callbackAgentResponse != null) {
          var event = message['agent_response_event'];
          callbackAgentResponse!(event['agent_response'].trim());
        }
        break;
      case 'user_transcript':
        if (callbackUserTranscript != null) {
          var event = message['user_transcription_event'];
          callbackUserTranscript!(event['user_transcript'].trim());
        }
        break;
      case 'interruption':
        var event = message['interruption_event'];
        _lastInterruptId = int.parse(event['event_id']);
        audioInterface.interrupt();
        break;
      default:
        // Игнорируем другие типы сообщений.
        break;
    }
  }

  // Метод для получения WebSocket URL без аутентификации.
  String _getWssUrl() {
    String baseUrl = 'https://api.elevenlabs.io';
    String baseWsUrl = baseUrl.replaceFirst('http', 'ws');
    return '$baseWsUrl/v1/convai/conversation?agent_id=$agentId';
  }

  // Метод для получения подписанного URL с аутентификацией.
  Future<String> _getSignedUrl() async {
    final response = await http.get(
      Uri.parse('https://api.elevenlabs.io/v1/convai/conversation/get_signed_url?agent_id=$agentId'),
      headers: {
        'xi-api-key': apiKey ?? '',
      },
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['signed_url'];
    } else {
      throw Exception('Failed to get signed URL');
    }
  }
}
