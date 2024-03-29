import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:degree/service/Controllers/listenController.dart';
import 'package:degree/service/data_api.dart';
import 'package:degree/pages/video_call_screens/Video_call_screen.dart';
import 'package:degree/pages/chat_screens/chat_more_screen.dart';
import 'package:degree/service/Controllers/dataController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../service/database.dart';

class ChatPage extends StatefulWidget {
  final String name, profileurl, username, channel, userId, userNativeLan;
  const ChatPage(
      {super.key,
      required this.name,
      required this.profileurl,
      required this.username,
      required this.channel,
      required this.userId,
      required this.userNativeLan});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final DataController _dataController = Get.find();
  final ListenerController _listenerController = Get.find();
  TextEditingController messagecontroller = TextEditingController();
  String? myUserName, myProfilePic, myName, myEmail, messageId, chatRoomId;
  Stream? messageStream;
  int translationStatus = 1;
  var args;

  String? selectedValueFromMsg;
  String? selectedValueToMsg;
  String? selectedValueFromVoice;
  String? selectedValueToVoice;
  List<String> outLans = List.empty(growable: true);

  getthesharedpref() async {
    myUserName = _dataController.myUserName;
    myName = _dataController.myName;
    myProfilePic = _dataController.picUrl.value;
    myEmail = _dataController.email;

    // print(
    //   'name $myName, usrname: $myUserName, pic: $myProfilePic, id: $myEmail, exited:${_dataController.exitedForEachChannel[myUserName]} ');
    chatRoomId = widget.channel;
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
    _dataController.exitedForEachChannel[widget.username] = false;

    Map<String, dynamic> lastMessageInfoMap = {
      "read": true,
      "to_msg_$myUserName": 0,
    };
    DatabaseMethods().updateLastMessageSend(widget.channel, lastMessageInfoMap);

    setState(() {});
  }

  String key = '';
  @override
  void initState() {
    ontheload();
    //print('init chat page');

    super.initState();
  }

  void languageSelection() {
    outLans = List.from(args as List<String>);
    outLans.add(widget.userNativeLan);

    key = widget.channel + _dataController.myUserName;
    if (usersBox.get(key) != null) {
      //  print('users box is not null in chatpage');
      selectedValueFromVoice = usersBox.get(key)!.transFromVoice;
      selectedValueToVoice = usersBox.get(key)!.transToVoice;
      selectedValueFromMsg = usersBox.get(key)!.transFromMsg;
      selectedValueToMsg = usersBox.get(key)!.transToMsg;
    }
    // else
    //   print('users box is null in chatpage');
  }

  getChatRoomIdbyUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }

  Widget chatMessageTile(String message, bool sendByMe) {
    return Row(
      mainAxisAlignment:
          sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
            child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  bottomRight: sendByMe
                      ? const Radius.circular(0)
                      : const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: sendByMe
                      ? const Radius.circular(24)
                      : const Radius.circular(0)),
              color: sendByMe
                  ? const Color.fromARGB(255, 234, 236, 240)
                  : const Color.fromARGB(255, 211, 228, 243)),
          child: Text(
            message,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 15.0,
                fontWeight: FontWeight.w500),
          ),
        )),
      ],
    );
  }

  Widget chatMessage() {
    return StreamBuilder(
        stream: messageStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90.0, top: 130),
                  itemCount: snapshot.data.docs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    if (ds['type'] == 'text') {
                      //print('text: ${ds['message']}');
                      return chatMessageTile(
                          ds["message"], myUserName == ds["sendBy"]);
                    } else {
                      //print('audio');
                      return const Offstage();
                    }
                  })
              : const Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments;
    languageSelection();

    outLans = args as List<String>;
    print('native lan- ${widget.userNativeLan}');
    return Scaffold(
      appBar: buildAppBar(),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: chatMessage()),
          Container(
            margin:
                const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
            alignment: Alignment.bottomCenter,
            child: Material(
              elevation: 5.0,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: messagecontroller,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Type a message",
                      hintStyle: const TextStyle(color: Colors.black45),
                      suffixIcon: GestureDetector(
                          onTap: () {
                            _dataController.addMessage(
                                widget.channel,
                                messagecontroller.text,
                                selectedValueFromMsg ??
                                    _dataController.myNativeLan,
                                selectedValueToMsg ?? widget.userNativeLan,
                                widget.username,
                                widget.name);

                            messagecontroller.clear();
                          },
                          child: const Icon(
                            Icons.send_rounded,
                          ))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      elevation: 0.5,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      flexibleSpace: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      _dataController.exitedForEachChannel[widget.username] =
                          true;

                      Get.back();
                    },
                    icon: Image.asset('assets/images/ic_chevron_left.png',
                        height: 20, width: 20, color: Colors.black),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(30)),
                        //shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.black.withOpacity(0.5))),
                    width: 60,
                    height: 60,
                    child: myProfilePic != null
                        ? ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(30)),
                            child: Image.network(
                              widget.profileurl,
                              fit: BoxFit.fill,
                            ))
                        : const Offstage(),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    direction: Axis.vertical,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Visibility(
                    visible: true,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 24,
                      child: RawMaterialButton(
                        onPressed: () async {
                          //if (translation_status % 2 == 0) {
                          int intValue = Random().nextInt(10000);
                          String token = await Data.generateToken(
                              widget.channel, intValue);

                          // print('channel token $token, uid: $intValue');
                          Get.to(VideoCallScreen(
                              widget.channel,
                              myUserName!,
                              widget.username,
                              selectedValueFromVoice ??
                                  _dataController.myNativeLan,
                              selectedValueToVoice ?? widget.userNativeLan,
                              token,
                              intValue));
                          _listenerController.sendJoinRequest(widget.channel);
                        },
                        shape: const CircleBorder(),
                        child: Image.asset("assets/images/ic_chat_video.png",
                            color: Get.theme.colorScheme.secondary,
                            width: 20,
                            height: 20),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: true,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 24,
                      child: RawMaterialButton(
                        onPressed: () async {
                          await Get.to(ChatMoreScreen(
                              widget.userId,
                              widget.name,
                              widget.profileurl,
                              outLans,
                              chatRoomId,
                              widget.userNativeLan));
                          setState(() {});
                        },
                        shape: const CircleBorder(),
                        child: Image.asset("assets/images/ic_chat_more.png",
                            color: Get.theme.colorScheme.secondary,
                            width: 20,
                            height: 20),
                      ),
                    ),
                  ),
                  // const SizedBox(
                  //   width: 5,
                  // ),
                  Obx(
                    () => Visibility(
                      visible: _listenerController.channelUsrIsActive
                              .containsKey(widget.channel)
                          ? _listenerController
                                  .channelUsrIsActive[widget.channel] ??
                              false
                          : false,
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: Image.asset(
                          'assets/images/img_online.png',
                          scale: 1.7,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    //print('closing chatpage');
    _dataController
        .exitedForEachChannel[myUserName ?? _dataController.myUserName] = true;
    // lastMessageStream?.cancel();
    super.dispose();
  }
}
