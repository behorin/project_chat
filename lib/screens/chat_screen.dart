import 'package:flutter/material.dart';
import 'package:project_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late User loggedInUser;
  late String messageText;

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  // void getMessages() async {
  //   final messages = await _firestore.collection('messages').get();
  //   for (var message in messages.docs) {
  //     print(message.data());
  //   }
  // }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: () {
              messagesStream();
              // _auth.signOut();
              // Navigator.pop(context);
            },
            icon: Icon(Icons.close),
          ),
        ],
        title: Text('Chat'),
        backgroundColor: Colors.black45,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Container(
                height: 540,
                child: SingleChildScrollView(
                  physics: ScrollPhysics(),
                  reverse: true,
                  child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('messages')
                          .orderBy('time')
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        return Expanded(
                          child: ListView.builder(
                            physics: ScrollPhysics(),
                            reverse: false,
                            itemCount: snapshot.data!.docs.length,
                            shrinkWrap: true,
                            primary: true,
                            itemBuilder: (context, index) {
                              QueryDocumentSnapshot x =
                                  snapshot.data!.docs[index];
                              return ListTile(
                                title: Column(
                                  crossAxisAlignment:
                                      loggedInUser.email == x['sender']
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color:
                                              loggedInUser.email == x['sender']
                                                  ? Colors.blue
                                                  : Colors.black12,
                                          borderRadius:
                                              loggedInUser.email == x['sender']
                                                  ? BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(30.0),
                                                      bottomLeft:
                                                          Radius.circular(30.0),
                                                      bottomRight:
                                                          Radius.circular(30.0))
                                                  : BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(30.0),
                                                      bottomRight:
                                                          Radius.circular(30.0),
                                                      topRight:
                                                          Radius.circular(30.0),
                                                    ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              x['text'],
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            Text(
                                              x['sender'],
                                              style: TextStyle(fontSize: 15),
                                            )
                                          ],
                                        )),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }),
                ),
              ),
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                        //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'time': DateTime.now(),
                      });
                      //Implement send functionality.
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
