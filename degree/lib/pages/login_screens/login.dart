import 'dart:developer';

import 'package:degree/pages/home.dart';
import 'package:degree/pages/login_screens/onboard_screen.dart';
import 'package:degree/service/Controllers/dataController.dart';
import 'package:degree/service/database.dart';
import 'package:degree/service/somni_alert.dart';
import 'package:degree/util/firebase.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:degree/pages/forgotpassword.dart';
import 'package:email_validator/email_validator.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "",
      password = "",
      name = "",
      pic = "",
      username = "",
      id = "",
      userNativeLan = '';
  TextEditingController usermailcontroller = TextEditingController();
  TextEditingController userpasswordcontroller = TextEditingController();
  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  final DataController _dataController = Get.find();
  bool _isEmptyMail = false;
  bool _isEmptyPass = false;
  bool isValidMail = false;
  bool isValidPass = false;
  final _formkey = GlobalKey<FormState>();

  validator() {
    if (usermailcontroller.text.isEmpty) {
      _isEmptyMail = true;
      setState(() {});
    } else {
      _isEmptyMail = false;
    }
    if (userpasswordcontroller.text.isEmpty) {
      _isEmptyPass = true;
      setState(() {});
    } else {
      _isEmptyPass = false;
    }

    if (_isEmptyMail && _isEmptyPass) {
      SomniAlerts.showMyDialog(context, 'Та майл болон нууц үгээ оруулна уу!');
    } else if (_isEmptyMail) {
      SomniAlerts.showMyDialog(context, 'Та майл-ээ оруулна уу!');
    } else if (_isEmptyPass) {
      SomniAlerts.showMyDialog(context, 'Та нууц үгээ оруулна уу!');
    }
    //print('validation mail: $_isEmptyMail, pass: $_isEmptyPass');
  }

  userLogin() async {
    try {
      // print('1');

      email = email.toLowerCase();
      //print('email $email, pass: $password');
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      QuerySnapshot querySnapshot =
          await DatabaseMethods().getUserbyemail(email);

      name = "${querySnapshot.docs[0]["Name"]}";

      username = "${querySnapshot.docs[0]["username"]}";
      pic = "${querySnapshot.docs[0]["Photo"]}";
      id = querySnapshot.docs[0].id;
      userNativeLan = '${querySnapshot.docs[0]["myNativeLanguage"]}';

      _dataController.saveUser(id, name, username, pic,
          "${querySnapshot.docs[0]["SearchKey"]}", email, userNativeLan);

      //print('object: ${FirebaseAuth.instance.currentUser}');
      //print('name $name, usrname: $username, pic: $pic, id: $id');

      Get.to(const Home());
      FirebaseUtils.main();
      _dataController.fetchCallHistories();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // ignore: use_build_context_synchronously
        SomniAlerts.showMyDialog(
            context, 'Таны оруулсан бүтгэлтэй хэрэглэгч байхгүй байна!');
      } else if (e.code == 'wrong-password') {
        // ignore: use_build_context_synchronously
        SomniAlerts.showMyDialog(context, 'Таны оруулсан нууц үг буруу байна!');
      } else if (e.code == 'invalid-email') {
        // ignore: use_build_context_synchronously
        SomniAlerts.showMyDialog(
            context, 'Таны оруулсан имэйл хаяг буруу байна!');
      } else if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        // ignore: use_build_context_synchronously
        SomniAlerts.showMyDialog(context,
            'Та өөрийн оруулсан нууц үг болон мэйлээ зөв эсэхийг шалгана уу!');
      } else if (e.code == 'network-request-failed') {
        // ignore: use_build_context_synchronously
        SomniAlerts.showMyDialog(
            context, 'Та интернетэд холбогдсон эсэхээ шалгана уу!');
      }

      log('sign in exception: ${e.toString()}, code: ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
            onPressed: () {
              Get.to(const OnboardScreen());
            },
            icon: const Icon(Icons.arrow_back)),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          if (focusNode1.hasFocus) {
            FocusScope.of(context).requestFocus(FocusNode());
          }
          if (focusNode2.hasFocus) {
            FocusScope.of(context).requestFocus(FocusNode());
          }
        },
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          height: double.infinity,
          //  decoration: BoxDecoration(border: Border.all()),
          //  child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ic_splash.png',
                scale: 1.5,
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: double.infinity,
                child: Form(
                  key: _formkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextFormField(
                          onChanged: (value) {
                            setState(() {
                              //   Validator();
                              isValidMail = EmailValidator.validate(value);
                              // print('valid: $isValidMail ');
                            });
                          },
                          focusNode: focusNode1,
                          textAlignVertical: TextAlignVertical.center,
                          controller: usermailcontroller,
                          decoration: InputDecoration(
                            suffixIcon: isValidMail
                                ? const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(
                                      0xff48D68A,
                                    ),
                                    size: 23,
                                  )
                                : Image.asset(
                                    'assets/images/img_login_exclamation.png',
                                    scale: 1.9,
                                  ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.black38),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                width: 1,
                                color: Color(0xff434347),
                              ),
                            ),
                            hintText: 'Имэйл',
                            hintStyle: const TextStyle(
                                color: Color(0xff434347),
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: TextFormField(
                          onChanged: (value) {},
                          focusNode: focusNode2,
                          textAlignVertical: TextAlignVertical.center,
                          controller: userpasswordcontroller,
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.black38),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                width: 1.5,
                                color: Color(0xff434347),
                              ),
                            ),
                            border: InputBorder.none,
                            hintText: 'Нууц үг',
                            hintStyle: TextStyle(
                                color: Color(0xff434347),
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                          ),
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 35),
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                        child: ElevatedButton(
                          onPressed: () {
                            validator();
                            if (!_isEmptyMail && !_isEmptyPass) {
                              if (_formkey.currentState!.validate()) {
                                setState(() {
                                  email = usermailcontroller.text;
                                  password = userpasswordcontroller.text;
                                  //log('email: $email, pass: $password');
                                });
                              }
                              userLogin();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: const Color(0xff0057ff),
                          ),
                          child: const Text(
                            'Нэвтрэх',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.normal,
                                fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 35,
                          ),
                          GestureDetector(
                            onTap: () => Get.to(const ForgotPassword()),
                            child: Container(
                              alignment: Alignment.bottomRight,
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                    color: Color(0xff434347),
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
          // ),
        ),
      ),
    );
  }
}
