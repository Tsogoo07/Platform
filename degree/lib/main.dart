import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:degree/Data.dart';
import 'package:degree/custom_source.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';

const appId = "d565b44b98164c39b2b1855292b22dd2";
const token =
    "007eJxTYFC5N8nVytUzmE/Gd5/7LJGGY+JCJhWzE6e6zgyb33tkU48CQ4qpmWmSiUmSpYWhmUmysWWSUZKhhampkaVRkpFRSooRVyhXakMgI8Nn5mZmRgYIBPF5GEpSi0vikzMS8/JScxgYAB3uHpQ=";
const channel = "test_channel";

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  int mute = 0;
  final audioPlayer = AudioPlayer();

  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          logConfig: LogConfig(level: LogLevel.logLevelError)),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Video Call'),
      ),
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Center(
                  child: !isRecording
                      ? _localUserJoined
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: _engine,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : const CircularProgressIndicator()
                      : Text(
                          'Recording in Progress',
                          style: TextStyle(fontSize: 20),
                        )),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              child: Icon(Icons.music_note),
              foregroundColor: mute % 2 == 1 ? Colors.red : Colors.white,
              onPressed: () async {
                mute++;
                log('click $mute');
                if (mute % 2 == 0) {
                  await _engine.stopAudioRecording();
                  Directory tempDir = await getTemporaryDirectory();
                  String record = '${tempDir.absolute.path}/record.wav';

                  log('recorded file: $record');
                  Uint8List hha = await File(record).readAsBytesSync();

                  // File req = File(record);

                  var val = await Data.sendAudio(record);

                  log('res: ${val}');

                  await audioPlayer.setAudioSource(CustomSource(hha));

                  await audioPlayer.load();

                  audioPlayer.play();
                  if (this.mounted) setState(() {});
                } else {
                  Directory tempDir = await getTemporaryDirectory();
                  String record = '${tempDir.absolute.path}/record.wav';
                  await File(record).create(exclusive: false, recursive: false);

                  _engine.startAudioRecording(
                    AudioRecordingConfiguration(
                      sampleRate: 32000,
                      filePath: record,
                      fileRecordingType:
                          AudioFileRecordingType.audioFileRecordingMic,
                      recordingChannel: 1,
                      quality:
                          AudioRecordingQualityType.audioRecordingQualityMedium,
                      encode: true,
                    ),
                  );

                  setState(() {});
                }
              },
            ),
          )
        ],
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: channel),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
