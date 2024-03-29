import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:degree/models/customer.dart';
import 'package:degree/pages/video_call_screens/Video_call_screen.dart';
import 'package:degree/service/custom_source.dart';
import 'package:degree/service/Controllers/dataController.dart';
import 'package:degree/service/data_api.dart';
import 'package:degree/service/database.dart';
import 'package:degree/service/somni_alert.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:random_string/random_string.dart';

class ListenerController extends GetxController {
  final DataController _dataController = Get.find();
  RxList<bool> usrsOnlineStats = <bool>[].obs;
  Map<String, StreamSubscription> newMessages = {};
  // ignore: non_constant_identifier_names
  Map<String, bool> exitedForEachChannel_Voice = {};
  RxMap<String, bool> channelUsrIsActive = RxMap();
  final dio = Dio();
  Set<String> processedUsernames = <String>{};
  Set<String> processedMessageIds = <String>{};

  late StreamSubscription<DocumentSnapshot> userDataSubscription;
  late StreamSubscription<DocumentSnapshot> userRequestChatSubscription;

  Set<String> get processedUsr => processedUsernames;
  StreamSubscription<DocumentSnapshot> get usrDataSubscription =>
      userDataSubscription;
  StreamSubscription<DocumentSnapshot> get usrRequestChatSubscription =>
      userRequestChatSubscription;
  Map<String, StreamSubscription> get chatRoomsSubscription => newMessages;

  void setInitProccessedValues() {
    processedUsernames = <String>{};
    processedMessageIds = <String>{};
  }

  void listenForNewMessages(
      String channel, String username, String userNativeLan) {
    final CollectionReference messagesCollection =
        FirebaseFirestore.instance.collection('chatrooms/$channel/chats');
    print('listening $channel');
    newMessages[channel] =
        messagesCollection.snapshots().listen((QuerySnapshot snapshot) {
      // ignore: avoid_function_literals_in_foreach_calls
      snapshot.docChanges.forEach((change) async {
        final messageData = change.doc.data() as Map<String, dynamic>;

        if (!processedMessageIds.contains(messageData['id'])) {
          bool exited = exitedForEachChannel_Voice[username] ?? true;
          print(
              'new message: $messageData, widget username: $username, exited: $exited');
          QuerySnapshot querySnapshot = await DatabaseMethods()
              .getUserInfo(_dataController.myUserName.toUpperCase());

          final user = querySnapshot.docs[0].data() as Map<String, dynamic>;
          String status = user['status'];
          print('status $status');
          if (messageData['type'] == 'endCall' && !messageData['read']) {
            Get.back();
            final chatPairRef = FirebaseFirestore.instance
                .collection('chatrooms')
                .doc(channel)
                .collection('chats')
                .doc(messageData["id"]);
            await chatPairRef.update({
              'read': true,
            });
          } else if (messageData["type"] == 'request' &&
              messageData["sendBy"] == username &&
              messageData["rejected"] as bool == false &&
              messageData["accept"] as bool == false &&
              messageData['missed'] as bool == false) {
            if (status == 'offline') {
              final chatPairRef = FirebaseFirestore.instance
                  .collection('chatrooms')
                  .doc(channel)
                  .collection('chats')
                  .doc(messageData["id"]);
              await chatPairRef.update({
                'missed': true,
              });
            } else if (exited) {
              await SomniAlerts.alertVideoCall(
                messageData["sendBy"],
                () async {
                  int intValue = Random().nextInt(10000);
                  String token = await Data.generateToken(channel, intValue);
                  String key = channel + _dataController.myUserName;
                  Customer? user = usersBox.get(key);
                  String from = '', to = '';
                  if (user != null) {
                    from = user.transFromVoice;
                    to = user.transToVoice;
                  } else {
                    usersBox.put(
                        channel,
                        Customer(
                          id: '1',
                          transFromVoice: _dataController.myNativeLan,
                          transToVoice: userNativeLan,
                          transFromMsg: _dataController.myNativeLan,
                          transToMsg: userNativeLan,
                        ));
                    from = 'Halh Mongolian';
                    to = userNativeLan;
                  }
                  Get.back();
                  Get.to(VideoCallScreen(channel, _dataController.myUserName,
                      username, from, to, token, intValue));
                  try {
                    final chatPairRef = FirebaseFirestore.instance
                        .collection('chatrooms')
                        .doc(channel)
                        .collection('chats')
                        .doc(messageData["id"]);
                    await chatPairRef.update({
                      'accept': true,
                    });
                  } catch (e) {
                    ('Error updating chat pair: $e');
                  }
                },
                () async {
                  try {
                    final chatPairRef = FirebaseFirestore.instance
                        .collection('chatrooms')
                        .doc(channel)
                        .collection('chats')
                        .doc(messageData["id"]);
                    await chatPairRef.update({
                      'rejected': true,
                    });
                  } catch (e) {
                    print('Error updating chat pair: $e');
                  }
                  Get.back();
                },
              );
            }
          }
          // else if (messageData["type"] == "audio" && exited) {
          //   updateChatReadState(messageData["id"], false, true, channel);
          // }
          else if (messageData["type"] == "audio" &&
              messageData["sendBy"] == username &&
              messageData["missed"] == false &&
              messageData["read"] == false &&
              !exited) {
            downloadAndPlayAudio(
                messageData["url"], messageData["id"], channel);
          }
          processedMessageIds.add(messageData['id']);
        }
      });
    });
  }

  void listenToChat(String chatId, String channel) {
    if (!processedMessageIds.contains(chatId)) {
      userRequestChatSubscription = FirebaseFirestore.instance
          .collection(
              'chatrooms/$channel/chats') // Replace with the name of your chats collection
          .doc(chatId) // Provide the specific chat document ID
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic> chatData =
              snapshot.data() as Map<String, dynamic>;
          String sendBy = chatData['sendBy'];
          if (sendBy == _dataController.myUserName &&
              chatData['missed'] as bool) {
            Get.back();
          } else if (sendBy == _dataController.myUserName &&
              chatData['rejected'] as bool) {
            Get.back();
          }
          print("Chat data: $chatData");
        } else {
          // Chat document doesn't exist
          print("Chat document does not exist");
        }
      });
      processedMessageIds.add(chatId);
    }
  }

  void sendJoinRequest(String channel) {
    String messageId = randomAlphaNumeric(10);
    DateTime now = DateTime.now();
    String formattedDate = DateFormat.yMd().format(now);
    String hour = DateFormat.Hm().format(now);

    listenToChat(messageId, channel);

    Map<String, dynamic> messageInfoMap = {
      "id": messageId,
      "type": "request",
      "message": "video call invitation",
      "sendBy": _dataController.myUserName,
      "time": FieldValue.serverTimestamp(),
      "ts": "$hour , $formattedDate",
      "rejected": false,
      "accept": false,
      "missed": false,
      "read": false
    };

    DatabaseMethods().addMessage(channel, messageId, messageInfoMap);
  }

  void sendEndCall(String channel) {
    String messageId = randomAlphaNumeric(10);
    DateTime now = DateTime.now();
    String formattedDate = DateFormat.yMd().format(now);
    String hour = DateFormat.Hm().format(now);

    Map<String, dynamic> messageInfoMap = {
      "id": messageId,
      "type": "endCall",
      "message": "video call invitation",
      "sendBy": _dataController.myUserName,
      "time": FieldValue.serverTimestamp(),
      "ts": "$hour , $formattedDate",
      "read": false
    };

    DatabaseMethods().addMessage(channel, messageId, messageInfoMap);
  }

  downloadAndPlayAudio(String url, String chatId, String channel) async {
    final res =
        await dio.get(url, options: Options(responseType: ResponseType.bytes));
    print('download: ${res.data}');

    final audioPlayer = AudioPlayer();

    await audioPlayer.setAudioSource(CustomSource(res.data));

    await audioPlayer.load();

    await audioPlayer.play();

    updateChatReadState(chatId, true, false, channel);
  }

  updateChatReadState(
      String chatId, bool read, bool missed, String channel) async {
    //print('update data: id-$chatId, read- $read, miss- $missed');
    try {
      final chatPairRef = FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(channel)
          .collection('chats')
          .doc(chatId);
      await chatPairRef.update({
        'read': read,
        'missed': missed,
      });
    } catch (e) {
      print('Error updating chat pair: $e');
    }
  }

  void listenToUserData(String userId, String channel) {
    userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        // User data has changed
        // Access the data using snapshot.data()
        Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
        print('user status : ${userData['status']}');
        if (userData['status'] == 'online') {
          //    channelUsrIsActive.putIfAbsent(channel, () => true);

          channelUsrIsActive[channel] = true;
        } else {
          // channelUsrIsActive.putIfAbsent(channel, () => false);
          channelUsrIsActive[channel] = false;
        }
        print('usr: ${channelUsrIsActive[channel]}');
        print("Listening user data: $userData");
      } else {
        // User document doesn't exist
        print("Listening user document does not exist");
      }
    });
  }

  @override
  void dispose() {
    print('listen controller is disposed');
    // TODO: implement dispose
    super.dispose();
  }
}
