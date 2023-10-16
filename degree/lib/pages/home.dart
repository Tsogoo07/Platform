import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:degree/pages/login.dart';
import 'package:degree/service/Controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chatpage.dart';
import '../service/database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DataController _dataController = Get.find();
  bool search = false;
  String? myName, myProfilePic, myUserName, myEmail, myId;
  Stream? chatRoomsStream;
  PageController controller = PageController();
  StreamSubscription<Map<String, dynamic>>? lastMessageStream;
  FocusNode _focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();

  // void startListeningToLastMessage(String chatroomId) {
  //   lastMessageStream =
  //       listenToLastMessage(chatroomId).listen((lastMessageData) {
  //     setState(() {});
  //     print('Last message data updated in home: $lastMessageData');
  //   });
  // }

  // Map<String, dynamic>? lastMessageData;
  // Stream<Map<String, dynamic>> listenToLastMessage(String chatroomId) {
  //   FirebaseFirestore firestore = FirebaseFirestore.instance;

  //   return firestore
  //       .collection('chatrooms')
  //       .doc(chatroomId)
  //       .snapshots()
  //       .map((chatroomSnapshot) {
  //     if (chatroomSnapshot.exists) {
  //       lastMessageData = chatroomSnapshot.data() as Map<String, dynamic>;

  //       print('listening in home');
  //       //print('last listen:$lastMessageData');
  //       // Return the last message data as a stream
  //       return lastMessageData ?? {};
  //     } else {
  //       // Return an empty map if the chatroom document doesn't exist
  //       return {};
  //     }
  //   });
  // }

  @override
  void initState() {
    ontheload();
    _focusNode.addListener(_handleFocusChange);
    super.initState();
  }

  ontheload() async {
    await getthesharedpref();
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
    [Permission.microphone, Permission.camera, Permission.photos].request();
  }

  getthesharedpref() async {
    myUserName = _dataController.myusername;
    myName = _dataController.myname;
    myProfilePic = _dataController.picUrl;
    myEmail = _dataController.email;
    myId = _dataController.id;

    // print(
    //     'name ${me!.name}, usrname: ${me!.username}, pic: ${me!.picUrl}, id: ${me!.id}, box: ');
    setState(() {});
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      // TextField is currently active (has focus)

      search = true;
      print('active textfield search: $search');
      setState(() {});
    } else {
      search = false;
      print('inactive textfield search: $search');
      setState(() {});
      // TextField is currently inactive (doesn't have focus)
    }
  }

  Widget ChatRoomList() {
    return StreamBuilder(
        stream: chatRoomsStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: snapshot.data.docs.length,
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        DocumentSnapshot ds = snapshot.data.docs[index];
                        print('chatroom');

                        //   NotificationService.showNotifications(ds.id,'',);
                        //  print(
                        //    'ds send BY: ${ds["lastMessageSendBy"]}, ds msg: ${ds["lastMessage"]}');

                        return ChatRoomListTile(
                          chatRoomId: ds.id,
                          lastMessage: ds["lastMessage"],
                          myUsername: myUserName!,
                          sendBy: ds["lastMessageSendBy"],
                          time: ds["lastMessageSendTs"],
                          read: ds["read"],
                          to_msg_num: ds['to_msg_$myUserName'],
                          name: ds['sendByNameFrom'] == myName
                              ? ds['sendByNameTo']
                              : ds['sendByNameFrom'],
                        );
                      }))
              : Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  getChatRoomIdbyUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  var queryResultSet = [];
  var tempSearchStore = [];
//should search via mail
  initiateSearch(value) {
    if (value.length == 0) {
      setState(() {
        log('null');
        queryResultSet = [];
        tempSearchStore = [];
      });
      return;
    }
    setState(() {
      search = true;
    });
    print('qset: $queryResultSet');
    var capitalizedValue = value.substring(0, 1).toUpperCase();
    if (queryResultSet.isEmpty && value.length == 1) {
      print('search in DataStore');
      DatabaseMethods().Search(value).then((QuerySnapshot docs) {
        for (int i = 0; i < docs.docs.length; ++i) {
          queryResultSet.add(docs.docs[i].data());
        }
      });
    } else {
      tempSearchStore = [];
      queryResultSet.forEach((element) {
        print('search in local');
        if (element['username'].startsWith(capitalizedValue)) {
          setState(() {
            tempSearchStore.add(element);
          });
        }
      });
    }
  }

  void selectedImage() async {
    final ImagePicker _imagePicker = ImagePicker();
    XFile? _file = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (_file == null) return;
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImages = referenceRoot.child('images');
    Reference referenceImageToUpload = referenceDirImages.child(myUserName!);
    File img = File(_file.path);

    try {
      referenceImageToUpload.putFile(img);
      referenceImageToUpload.getDownloadURL();
    } catch (e) {
      print('upload image to firebase exception: $e');
    }

    myProfilePic = await referenceImageToUpload.getDownloadURL();
    _dataController.picUrl = myProfilePic!;
    // await DefaultCacheManager().emptyCache();
    print('uploaded its url :$myProfilePic, userid: $myId');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myId ?? _dataController.id)
        .update({"Photo": myProfilePic});
    setState(() {});
    // updateUser();
  }

  // updateUser() async {
  //   Map<String, dynamic> userInfoMap = {
  //     "Name": myName,
  //     "E-mail": myEmail,
  //     "username": myUserName,
  //     "SearchKey": myUserName!.substring(0, 1).toUpperCase(),
  //     "Photo": myProfilePic,
  //     "Id": myId,
  //   };
  //   await DatabaseMethods().addUserDetails(userInfoMap, myId!);
  // }

  Widget DrawerBuilder(String name) {
    print('my profile in drawer: $myProfilePic');
    return Drawer(
      width: 330,
      elevation: 30,
      backgroundColor: Color(0xFfFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(35))),
      child: Container(
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(35)),
            boxShadow: [
              BoxShadow(
                  color: Color(0xFfFFFFFF), spreadRadius: 30, blurRadius: 20)
            ]),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Settings",
                          style: const TextStyle(
                            fontFamily: "Gilroy",
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff2675ec),
                            height: 27 / 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Color(0xff2675ec),
                            size: 30,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                              border: Border.all(
                                  color: Colors.black.withOpacity(0.5))),
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Stack(
                            children: [
                              myProfilePic == null
                                  ? CircularProgressIndicator()
                                  : GestureDetector(
                                      onDoubleTap: selectedImage,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image(
                                          image: NetworkImage(
                                            myProfilePic!,
                                          ),
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                              // Positioned.fill(
                              //   bottom: -80,
                              //   right: -90,
                              //   child: IconButton(
                              //       onPressed: () {},
                              //       icon: Icon(
                              //         Icons.add_a_photo,
                              //         size: 40,
                              //       )),
                              // ),
                            ],
                          ),
                        ),

                        // if (myProfilePic != null) ...[
                        //   GestureDetector(
                        //     onDoubleTap: selectedImage,
                        //     child: CircleAvatar(
                        //       radius: 64,
                        //       backgroundImage: MemoryImage(myProfilePic!),
                        //     ),
                        //   ),
                        // ] else ...[
                        //   GestureDetector(
                        //     onDoubleTap: selectedImage,
                        //     child: CircleAvatar(
                        //       radius: 64,
                        //       backgroundImage: NetworkImage(myProfilePic!),
                        //     ),
                        //   ),
                        // ],
                        SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: "Gilroy",
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff2675ec),
                              height: 30 / 23,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 35,
                    ),
                    DrawerItem(
                      title: 'Account',
                      icon: Icons.key,
                      myFunction: () {},
                    ),
                    DrawerItem(
                      title: 'Chats',
                      icon: Icons.chat_bubble_outline_outlined,
                      myFunction: () {},
                    ),
                    DrawerItem(
                      title: 'Notifications',
                      icon: Icons.notifications_none_outlined,
                      myFunction: () {},
                    ),
                    DrawerItem(
                      title: 'Data and Storage',
                      icon: Icons.storage,
                      myFunction: () {},
                    ),
                    DrawerItem(
                      title: 'Help',
                      icon: Icons.help_outline,
                      myFunction: () {},
                    ),
                    const Divider(
                      height: 35,
                      color: Colors.green,
                    ),
                    DrawerItem(
                      title: 'Invite a friend',
                      icon: Icons.people_outline,
                      myFunction: () {},
                    ),
                  ],
                ),
                DrawerItem(
                  title: 'Log out',
                  icon: Icons.logout,
                  myFunction: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LogIn()),
                        (Route<dynamic> route) => false);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();

  PreferredSizeWidget HomeAppbar() {
    return AppBar(
      elevation: 0.5,
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      backgroundColor: Colors.white,
      flexibleSpace: SafeArea(
        child: Container(
          decoration: BoxDecoration(
              // border: Border(
              //     bottom: BorderSide(
              //   color: Colors.black,
              // )),
              ),
          padding: const EdgeInsets.only(
              left: 20.0, right: 20.0, top: 20.0, bottom: 10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                        color: Color.fromARGB(255, 218, 216, 215)
                            .withOpacity(0.3)),
                    child: IconButton(
                        onPressed: () {
                          _globalKey.currentState!.openDrawer();
                        },
                        icon: Icon(
                          Icons.menu,
                          size: 40,
                          color: Colors.black.withOpacity(0.8),
                        )),
                  ),
                  Text(
                    "ChatUp",
                    style: TextStyle(
                        color: Color(0Xff2675EC),
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold),
                  ),
                  Image.asset(
                    'assets/images/img_new_chat.png',
                    scale: 1.5,
                  )
                ],
              ),

              //Expanded(child: SingleChildScrollView(child: Column(ch),))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build home page');

    return Scaffold(
      key: _globalKey,
      appBar: HomeAppbar(),
      drawer: DrawerBuilder(myName ?? _dataController.myname),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          elevation: 0,
          floating: true,
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          title: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.fromLTRB(10, 0, 0, 2),
            height: 40,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 205, 205, 206),
              borderRadius: BorderRadius.circular(8.0), // Border radius
            ),
            child: TextField(
              controller: textEditingController,
              focusNode: _focusNode,
              textAlign: search ? TextAlign.start : TextAlign.center,
              autocorrect: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                initiateSearch(value.toUpperCase());
              },
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: search
                      ? GestureDetector(
                          onTap: () {
                            textEditingController.clear();
                            FocusScope.of(context).requestFocus(FocusNode());

                            search = false;
                            //  queryResultSet = [];
                            tempSearchStore = [];
                            print('search');

                            setState(() {});
                          },
                          child: Icon(
                            size: 25,
                            Icons.close,
                            color: Color(0Xff2675EC),
                          ))
                      : GestureDetector(
                          onTap: () {
                            search = true;
                            _focusNode.requestFocus();
                            print('not search');
                            setState(() {});
                          },
                          child: Icon(
                            size: 30,
                            Icons.search,
                            color: Color(0Xff2675EC),
                          ),
                        ),
                  onPressed: () {
                    search = true;
                    setState(() {});
                  },
                ),
                border: InputBorder.none,
                hintText: 'Search User',
                hintStyle: const TextStyle(
                  fontFamily: "SF Pro Text",
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff3c3c43),
                  height: 22 / 17,
                ),
              ),
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              // Build the list of items
              return search
                  ? ListView(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0),
                      primary: false,
                      shrinkWrap: true,
                      children: [...tempSearchStore].map((element) {
                        return buildResultCard(element);
                      }).toList())
                  : ChatRoomList();
            },
            childCount: 1, // Number of items in the list
          ),
        ),
      ]),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              onTap: () {},
              child: Image.asset(
                'assets/images/ic_call.png',
                width: 80,
                height: 80,
              ),
            ),
            InkWell(
              onTap: () {},
              child: Image.asset(
                'assets/images/ic_chat.png',
                width: 80,
                height: 80,
                color: Color(0xff007AFF),
              ),
            ),
            InkWell(
              onTap: () {},
              child: Image.asset(
                'assets/images/ic_setting.png',
                width: 70,
                height: 70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget PageViewItem() {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onTap: () {
          if (_focusNode.hasFocus) {
            FocusScope.of(context).requestFocus(FocusNode());
            textEditingController.clear();
            search = false;
            setState(() {});
          }
        },
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
                // border: Border(
                //     bottom: BorderSide(
                //   color: Colors.black,
                // )),
                ),
            padding: const EdgeInsets.only(
                left: 20.0, right: 20.0, top: 30.0, bottom: 10.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          color: Color.fromARGB(255, 218, 216, 215)
                              .withOpacity(0.3)),
                      child: IconButton(
                          onPressed: () {
                            _globalKey.currentState!.openDrawer();
                          },
                          icon: Icon(
                            Icons.menu,
                            size: 40,
                            color: Colors.black.withOpacity(0.8),
                          )),
                    ),
                    Text(
                      "ChatUp",
                      style: TextStyle(
                          color: Color(0Xff2675EC),
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Image.asset(
                      'assets/images/img_new_chat.png',
                      scale: 1.5,
                    )
                  ],
                ),

                //Expanded(child: SingleChildScrollView(child: Column(ch),))
              ],
            ),
          ),

          // ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 0, 0, 2),
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 205, 205, 206),

                      borderRadius: BorderRadius.circular(8.0), // Border radius
                    ),
                    child: TextField(
                      controller: textEditingController,
                      focusNode: _focusNode,
                      textAlign: search ? TextAlign.start : TextAlign.center,
                      autocorrect: true,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) {
                        initiateSearch(value.toUpperCase());
                      },
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: search
                              ? GestureDetector(
                                  onTap: () {
                                    textEditingController.clear();
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());

                                    search = false;
                                    //  queryResultSet = [];
                                    tempSearchStore = [];
                                    print('search');

                                    setState(() {});
                                  },
                                  child: Icon(
                                    size: 25,
                                    Icons.close,
                                    color: Color(0Xff2675EC),
                                  ))
                              : GestureDetector(
                                  onTap: () {
                                    search = true;
                                    _focusNode.requestFocus();
                                    print('not search');
                                    setState(() {});
                                  },
                                  child: Icon(
                                    size: 30,
                                    Icons.search,
                                    color: Color(0Xff2675EC),
                                  ),
                                ),
                          onPressed: () {
                            search = true;
                            setState(() {});
                          },
                        ),
                        border: InputBorder.none,
                        hintText: 'Search User',
                        hintStyle: const TextStyle(
                          fontFamily: "SF Pro Text",
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff3c3c43),
                          height: 22 / 17,
                        ),
                      ),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  search
                      ? Flexible(
                          child: ListView(
                              padding: EdgeInsets.only(left: 10.0, right: 10.0),
                              primary: false,
                              shrinkWrap: true,
                              children: tempSearchStore.map((element) {
                                return buildResultCard(element);
                              }).toList()),
                        )
                      : ChatRoomList(),
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }

  Widget buildResultCard(data) {
    return GestureDetector(
      onTap: () async {
        search = false;

        var chatRoomId = getChatRoomIdbyUsername(myUserName!, data["username"]);
        Map<String, dynamic> chatRoomInfoMap = {
          "users": [myUserName, data["username"]],
        };
        print('created channel: $chatRoomId');
        await DatabaseMethods().createChatRoom(chatRoomId, chatRoomInfoMap);

        await Get.to(ChatPage(
          name: data["Name"],
          profileurl: data["Photo"],
          username: data["username"],
          channel: chatRoomId,
        ));
        setState(() {});
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.network(
                      data["Photo"],
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    )),
                SizedBox(
                  width: 20.0,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["Name"],
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      data["username"],
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername, time, sendBy, name;
  final int to_msg_num;
  final bool read;
  ChatRoomListTile(
      {required this.chatRoomId,
      required this.lastMessage,
      required this.myUsername,
      required this.time,
      required this.sendBy,
      required this.name,
      required this.read,
      required this.to_msg_num});

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "", id = "";
  List<String> native_lans = [];
  getthisUserInfo() async {
    log('message');
    username =
        widget.chatRoomId.replaceAll("_", "").replaceAll(widget.myUsername, "");
    QuerySnapshot querySnapshot =
        await DatabaseMethods().getUserInfo(username.toUpperCase());
    name = "${querySnapshot.docs[0]["Name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["Photo"]}";
    id = "${querySnapshot.docs[0]["Id"]}";
    native_lans = List<String>.from(querySnapshot.docs[0]["native_lans"]);

    print('native lans: ${native_lans} ');
  }

  @override
  void initState() {
    getthisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getthisUserInfo(),
        builder: (context, snapshot) {
          return GestureDetector(
            onTap: () async {
              log('to ${widget.chatRoomId}');
              await Get.to(
                  ChatPage(
                    name: name,
                    profileurl: profilePicUrl,
                    username: username,
                    channel: widget.chatRoomId,
                  ),
                  arguments: native_lans);

              setState(() {});
            },
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  profilePicUrl == ""
                      ? CircularProgressIndicator()
                      : Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.black.withOpacity(0.5)),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            // child: CachedNetworkImage(imageUrl: profilePicUrl,width: 70,height: 70,
                            // errorWidget: (context, url, error) => const CircularProgressIndicator(),
                            // ),
                            child: Image.network(
                              profilePicUrl,
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          widget.name,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 17.0,
                              fontWeight: FontWeight.w500),
                        ),
                        // const SizedBox(
                        //   height: 5,
                        // ),
                        Container(
                          child: Text(
                            widget.sendBy == widget.myUsername
                                ? "you: " + widget.lastMessage
                                : widget.lastMessage,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              //  color: true ? Color(0xff848484) : Color(0xff2675EC),
                              color: widget.sendBy == widget.myUsername
                                  ? Color(0xff848484)
                                  : widget.read
                                      ? Color(0xff848484)
                                      : Color(0xff2675ec),
                              fontFamily: "Gilroy",
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.time,
                        style: TextStyle(
                            color: Colors.black45,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (widget.to_msg_num != 0) ...[
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                          decoration: BoxDecoration(
                              color: Color(0xff2675EC),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                          child: Text(
                            '${widget.to_msg_num}',
                            style: const TextStyle(
                              fontFamily: "Gilroy",
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 13 / 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ] else if (widget.read &&
                          widget.sendBy == widget.myUsername)
                        Image.asset(
                          'assets/images/img_viewed.png',
                          scale: 1.9,
                        ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }
}

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function() myFunction;
  DrawerItem(
      {super.key,
      required this.title,
      required this.icon,
      required this.myFunction});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: myFunction,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Row(
          children: [
            Icon(
              icon,
              color: Color(0xff2675ec),
              size: 40,
            ),
            const SizedBox(
              width: 40,
            ),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                    fontFamily: "Gilroy",
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff2675ec),
                    height: 23 / 19,
                  ),
                  textAlign: TextAlign.left),
            ),
          ],
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String filename;
  UserAvatar({
    super.key,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    if (filename != '')
      return CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 29,
          backgroundImage: Image.network(filename).image,
        ),
      );
    else
      return CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 29,
          backgroundImage: Image.asset('assets/images/boy1.jpg').image,
        ),
      );
  }
}

class Pages extends StatelessWidget {
  final text;
  final color;
  Pages({this.text, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                text,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
              ),
            ]),
      ),
    );
  }
}
