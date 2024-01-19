// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:intl/intl.dart';

final _store = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance.ref();
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = '/chat';

  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final messageController = TextEditingController();
  bool showSpinner = false;
  late String messageText;
  late File? _selectedImage;
  late ScrollController _scrollController;

  @override
  void initState() {
    getCurrentUser();
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage(ImageSource imageSource) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: imageSource);

    // if (pickedFile != null) {
    //   File imageFile = File(pickedFile.path);

    // // Upload the image to Firebase Storage
    // String imageName = DateTime.now().millisecondsSinceEpoch.toString();
    // Reference storageReference = _storage.child('images/$imageName');
    // UploadTask uploadTask = storageReference.putFile(imageFile);

    // await uploadTask.whenComplete(() {
    //   // Get the download URL for the image
    //   storageReference.getDownloadURL().then((imageUrl) {
    //     // Add a message with the image URL to the Firestore collection
    //     _store.collection('messages2').add({
    //       'sender': loggedInUser.email,
    //       'imageUrl': imageUrl,
    //       'text': '',
    //       'timestamp': FieldValue.serverTimestamp(),
    //     });
    //   });
    // });

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _showImagePreviewBottomSheet(context);
    }
  }

  void _showImagePreviewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 50, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _selectedImage != null
                  ? Flexible(
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: kMessageTextFieldDecoration,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        //Implement send functionality.
                        Navigator.pop(context); // Close the bottom sheet
                        _sendMessage(messageController.text);
                        messageController.clear();
                      },
                      child: const Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(String? message) async {
    if (_selectedImage != null) {
      // Upload the image to your API and get the imageUrl
      // Upload the image to Firebase Storage
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = _storage.child('images/$imageName');
      UploadTask uploadTask = storageReference.putFile(_selectedImage!);

      setState(() {
        showSpinner = true;
      });

      await uploadTask.whenComplete(() {
        // Get the download URL for the image
        storageReference.getDownloadURL().then((imageUrl) {
          // Add a message with the image URL to the Firestore collection
          _store.collection('messages2').add({
            'sender': loggedInUser.email,
            'imageUrl': imageUrl,
            'text': message,
            'timestamp': FieldValue.serverTimestamp(),
          });
        });
      });

      setState(() {
        _selectedImage = null;
        showSpinner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessagesStream(scrollController: _scrollController),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: messageController,
                        decoration: kMessageTextFieldDecoration,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: () async {
                        final result = await showDialog<ImageSource>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Pick Image From:'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, ImageSource.gallery);
                                  },
                                  child: const Text('Gallery'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, ImageSource.camera);
                                  },
                                  child: const Text('Camera'),
                                ),
                              ],
                            );
                          },
                        );

                        if (result != null) {
                          _pickImage(result);
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        //Implement send functionality.
                        _store.collection('messages2').add({
                          'sender': loggedInUser.email,
                          'text': messageController.text,
                          'imageUrl': '',
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                        messageController.clear();
                      },
                      child: const Text(
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
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final ScrollController scrollController; // Add scrollController parameter

  const MessagesStream({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _store.collection("messages2").orderBy('timestamp').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent),
          );
        }
        final messages = snapshot.data!.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageBubble = MessageBubble(
            key: ValueKey(message.id),
            sender: message['sender'],
            text: message['text'] ?? '',
            imageUrl: message['imageUrl'] ?? '',
            timeStamp: message['timestamp'] ?? Timestamp.now(),
            isMe: loggedInUser.email == message['sender'],
            onLongPress: () => showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        _store.collection('messages2').doc(message.id).delete();
                        Navigator.pop(context);
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                );
              },
            ),
          );
          messageBubbles.add(messageBubble);
        }

        // Scroll to the bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollController.animateTo(
            scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });

        return Expanded(
          child: ListView(
              controller: scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: messageBubbles),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {super.key,
      required this.sender,
      required this.text,
      required this.isMe,
      required this.imageUrl,
      required this.timeStamp,
      required this.onLongPress});

  final String sender;
  final String text;
  final String imageUrl;
  final bool isMe;
  final Timestamp timeStamp;
  final Function() onLongPress;

  void showLargeImagePreviewBottomSheet(BuildContext context, String imageUrl,
      {String? text}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 16.0, bottom: 16.0),
          child: imageUrl.isNotEmpty && text != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                CircularProgressIndicator(
                                    value: downloadProgress.progress),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      CircularProgressIndicator(
                          value: downloadProgress.progress),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      timeStamp.seconds * 1000 + timeStamp.nanoseconds ~/ 1000000,
      isUtc: true,
    );
    DateTime now = DateTime.now();
    String formattedTime;

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      formattedTime = 'Today, ${DateFormat.Hm().format(dateTime.toLocal())}';
    } else {
      formattedTime = DateFormat('E, HH:mm').format(dateTime.toLocal());
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
            Padding(
              padding: isMe
                  ? const EdgeInsets.only(left: 35.0)
                  : const EdgeInsets.only(right: 35.0),
              child: Material(
                borderRadius: isMe
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      )
                    : const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                color: isMe ? Colors.lightBlueAccent : Colors.black,
                elevation: 5.0,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 10, horizontal: imageUrl.isNotEmpty ? 8 : 20),
                  child: imageUrl.isNotEmpty && text.isNotEmpty
                      ? Column(
                          children: [
                            GestureDetector(
                              onTap: () => showLargeImagePreviewBottomSheet(
                                  context, imageUrl,
                                  text: text),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder:
                                      (context, url, downloadProgress) =>
                                          CircularProgressIndicator(
                                              value: downloadProgress.progress),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isMe ? Colors.white : Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        )
                      : imageUrl.isNotEmpty && text.isEmpty
                          ? GestureDetector(
                              onTap: () => showLargeImagePreviewBottomSheet(
                                  context, imageUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder:
                                      (context, url, downloadProgress) =>
                                          CircularProgressIndicator(
                                              value: downloadProgress.progress),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            )
                          : Text(
                              text,
                              style: TextStyle(
                                fontSize: 15,
                                color: isMe ? Colors.white : Colors.white54,
                              ),
                            ),
                ),
              ),
            ),
            const SizedBox(
              height: 2.0,
            ),
            Text(
              formattedTime,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
