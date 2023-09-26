import 'package:get/get.dart';

import 'chatpage.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF553370),
      body: <Widget>[
        Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 50.0, bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ChatUp",
                      style: TextStyle(
                          color: Color(0Xffc199cd),
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Color(0xFF3a2144),
                            borderRadius: BorderRadius.circular(20)),
                        child: Icon(
                          Icons.search,
                          color: Color(0Xffc199cd),
                        ))
                  ],
                ),
              ),
              Expanded(
                  child: Container(
                padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                // height: MediaQuery.of(context).size.height / 1.15,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(ChatPage());
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                "assets/images/boy1.jpg",
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              )),
                          SizedBox(
                            width: 10.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 10.0,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Shivam Gupta",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 17.0,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Text(
                                "Hello, What are you doing?",
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Spacer(),
                          Text(
                            "04:30 PM",
                            style: TextStyle(
                                color: Colors.black45,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.asset(
                              "assets/images/boy1.jpg",
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            )),
                        SizedBox(
                          width: 10.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              "Ayush Sharma",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "Hy, What is going on?",
                              style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          "05:30 PM",
                          style: TextStyle(
                              color: Colors.black45,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.asset(
                              "assets/images/boy1.jpg",
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            )),
                        SizedBox(
                          width: 10.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              "Pooja Sharma",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "Hello, How was your day?",
                              style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          "10:30 AM",
                          style: TextStyle(
                              color: Colors.black45,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.asset(
                              "assets/images/boy1.jpg",
                              height: 60,
                              width: 60,
                              fit: BoxFit.fill,
                            )),
                        SizedBox(
                          width: 10.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              "Diya Singh",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "Hello, Shivam!",
                              style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Spacer(),
                        Text(
                          "12:30 AM",
                          style: TextStyle(
                              color: Colors.black45,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ))
            ],
          ),
        ),
        Container(
          color: Colors.green,
          alignment: Alignment.center,
          child: const Text('Page 2'),
        ),
        Container(
          color: Colors.blue,
          alignment: Alignment.center,
          child: const Text('Page 3'),
        ),
      ][currentPageIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber[800],
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.school),
            icon: Icon(Icons.school_outlined),
            label: 'School',
          ),
        ],
      ),
    );
  }
}
