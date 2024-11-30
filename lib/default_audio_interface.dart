// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_audio/audio_interface.dart';

// Реализация AudioInterface по умолчанию.
class DefaultAudioInterface implements AudioInterface {
  static const int INPUT_FRAMES_PER_BUFFER = 4000; // 250ms @ 16kHz
  static const int OUTPUT_FRAMES_PER_BUFFER = 1000; // 62.5ms @ 16kHz

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamController<List<int>>? _outputStreamController;
  StreamSubscription? _mRecordingDataSubscription;

  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void start(void Function(List<int>) inputCallback) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    var recordingDataController = StreamController<Uint8List>();

    _mRecordingDataSubscription = recordingDataController.stream.listen((buffer) {
      inputCallback(buffer);
    });

    // Инициализируем рекордер.
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await _recorder!.startRecorder(
      toStream: recordingDataController.sink,
      // toStream: (buffer) {
      //   if (buffer != null && buffer.isNotEmpty) {
      //     inputCallback(buffer);
      //   }
      // },
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      enableVoiceProcessing: true,
    );
    _isRecording = true;

    // Инициализируем плеер.
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    _outputStreamController = StreamController<List<int>>();
    _outputStreamController!.stream.listen((audioData) {
      final buffer = Uint8List.fromList(audioData);
      _player!.startPlayer(
        fromDataBuffer: buffer,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        whenFinished: () {
          _isPlaying = false;
        },
      );
    });
  }

  @override
  void stop() async {
    _mRecordingDataSubscription?.cancel();
    // Останавливаем запись и воспроизведение.
    if (_isRecording) {
      await _recorder!.stopRecorder();
      await _recorder!.closeRecorder();
      _recorder = null;
      _isRecording = false;
    }
    if (_isPlaying) {
      await _player!.stopPlayer();
      await _player!.closePlayer();
      _player = null;
      _isPlaying = false;
    }
    _outputStreamController?.close();
  }

  @override
  void output(List<int> audio) {
    if (_isPlaying == true) {
      return;
    }
    _isPlaying = true;
    // Добавляем аудио данные в поток для воспроизведения.
    _outputStreamController?.add(audio);
  }

  @override
  void interrupt() {
    // Прерываем воспроизведение и очищаем поток.
    if (_isPlaying) {
      _player!.stopPlayer();
      _isPlaying = false;
    }
    _outputStreamController?.add([]);
  }
}
