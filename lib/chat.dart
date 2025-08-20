import 'dart:developer';

import 'package:agora/main.dart';
import 'package:flutter/material.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String get appKey => dotenv.env['AppKey'] ?? '';
  static const String userId = "adebayo"; // your user ID
  String get token => dotenv.env['adebayoToken'] ?? '';

  late ChatClient agoraChatClient;
  bool isJoined = false;

  ScrollController scrollController = ScrollController();
  TextEditingController messageBoxController = TextEditingController();
  String messageContent = "", recipientId = "";
  final List<Widget> messageList = [];

  // MARK: JOIN / LEAVE
  void joinLeave() async {
    if (!isJoined) {
      // Log in
      try {
        await agoraChatClient.loginWithToken(userId, token);
        showLog("Logged in successfully as $userId");
        setState(() {
          isJoined = true;
        });
      } on ChatError catch (e) {
        if (e.code == 200) {
          // Already logged in
          setState(() {
            isJoined = true;
          });
        } else {
          showLog("Login failed, code: ${e.code}, desc: ${e.description}");
        }
      }
    } else {
      // Log out
      try {
        await agoraChatClient.logout(true);
        showLog("Logged out successfully");
        setState(() {
          isJoined = false;
        });
      } on ChatError catch (e) {
        showLog("Logout failed, code: ${e.code}, desc: ${e.description}");
      }
    }
  }

  // MARK: SEND MESSAGE
  void sendMessage() async {
    log("clicked me");
    if (recipientId.isEmpty || messageContent.isEmpty) {
      showLog("Enter recipient user ID and type a message");
      return;
    }
    log("message content $messageContent recipientId $recipientId");
    var msg = ChatMessage.createTxtSendMessage(
      targetId: recipientId,
      content: messageContent,
    );
    ChatClient.getInstance.chatManager.addMessageEvent(
      "UNIQUE_HANDLER_ID",
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          showLog("on message succeed");
          log("message succeed");
          displayMessage(messageContent, true);
          messageBoxController.clear();
          messageContent = "";
        },
        onProgress: (msgId, progress) {
          showLog("on message progress");
        },
        onError: (msgId, msg, error) {
          showLog(
            "on message failed, code: ${error.code}, desc: ${error.description}",
          );
        },
      ),
    );
    ChatClient.getInstance.chatManager.removeMessageEvent("UNIQUE_HANDLER_ID");
    agoraChatClient.chatManager.sendMessage(msg);
  }

  
  
  // MARK: LOG SNACKBAR
  showLog(String message, {bool showSnackbar = false}) {
    if (showSnackbar) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    log(message, name: "AgoraChat");
  }

  @override
  void initState() {
    super.initState();
    setupChatClient();
    setupListeners();
  }

  void setupChatClient() async {
    try {
      if (appKey.isEmpty) {
        showLog("ERROR: Cannot initialize Chat SDK - AppKey is empty");
        return;
      }
      
      log("Initializing Chat SDK with AppKey: $appKey", name: "AgoraChat");
      
      ChatOptions options = ChatOptions(appKey: appKey, autoLogin: false);
      agoraChatClient = ChatClient.getInstance;
      await agoraChatClient.init(options);
      
      // Notify SDK that UI is ready
      await ChatClient.getInstance.startCallback();
      
      showLog("Chat SDK initialized successfully");
      log("Chat SDK initialized successfully", name: "AgoraChat");
      
    } catch (e) {
      showLog("Failed to initialize Chat SDK: $e");
      log("Chat SDK initialization error: $e", name: "AgoraChat");
    }
  }

  void setupListeners() {
    agoraChatClient.addConnectionEventHandler(
      "CONNECTION_HANDLER",
      ConnectionEventHandler(
        onConnected: onConnected,
        onDisconnected: onDisconnected,
        onTokenWillExpire: onTokenWillExpire,
        onTokenDidExpire: onTokenDidExpire,
      ),
    );

    agoraChatClient.chatManager.addEventHandler(
      "MESSAGE_HANDLER",
      ChatEventHandler(onMessagesReceived: onMessagesReceived),
    );
    
    // Add message acknowledgment listener
    agoraChatClient.chatManager.addMessageEvent(
      "MESSAGE_ACK_HANDLER",
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          log("=== MESSAGE ACKNOWLEDGMENT RECEIVED ===", name: "AgoraChat");
          log("Message ID: $msgId", name: "AgoraChat");
          log("Recipient: ${msg.to}", name: "AgoraChat");
          log("Status: ${msg.status}", name: "AgoraChat");
          log("✓ Message was successfully delivered to recipient", name: "AgoraChat");
          log("=========================================", name: "AgoraChat");
          showLog("✓ Message delivered to ${msg.to}", showSnackbar: true);
        },
        onProgress: (msgId, progress) {
          log("Message delivery progress: $progress%", name: "AgoraChat");
        },
        onError: (msgId, msg, error) {
          log("=== MESSAGE DELIVERY FAILED ===", name: "AgoraChat");
          log("Message ID: $msgId", name: "AgoraChat");
          log("Recipient: ${msg.to}", name: "AgoraChat");
          log("Error Code: ${error.code}", name: "AgoraChat");
          log("Error Description: ${error.description}", name: "AgoraChat");
          log("✗ Message failed to deliver - recipient may not exist", name: "AgoraChat");
          log("=================================", name: "AgoraChat");
          showLog("✗ Message failed to deliver to ${msg.to}", showSnackbar: true);
        },
      ),
    );
  }

  // MARK: EVENT HANDLERS
  void onMessagesReceived(List<ChatMessage> messages) {
    log("=== MESSAGES RECEIVED ===", name: "AgoraChat");
    log("Number of messages received: ${messages.length}", name: "AgoraChat");
    
    for (var msg in messages) {
      log("--- MESSAGE DETAILS ---", name: "AgoraChat");
      log("Message ID: ${msg.msgId}", name: "AgoraChat");
      log("From: ${msg.from}", name: "AgoraChat");
      log("To: ${msg.to}", name: "AgoraChat");
      log("Message Type: ${msg.body.type}", name: "AgoraChat");
      log("Direction: ${msg.direction}", name: "AgoraChat");
      log("Status: ${msg.status}", name: "AgoraChat");
      log("Timestamp: ${msg.serverTime}", name: "AgoraChat");
      log("Local Time: ${msg.localTime}", name: "AgoraChat");
      
      if (msg.body.type == MessageType.TXT) {
        ChatTextMessageBody body = msg.body as ChatTextMessageBody;
        log("Content: ${body.content}", name: "AgoraChat");
        log("Message received from Agora servers!", name: "AgoraChat");
        
        displayMessage(body.content, false);
        showLog("Message from ${msg.from}");
      } else {
        String msgType = msg.body.type.name;
        log("Received $msgType message", name: "AgoraChat");
        showLog("Received $msgType message, from ${msg.from}");
      }
      log("----------------------", name: "AgoraChat");
    }
    log("=========================", name: "AgoraChat");
  }
  

  
  // Send delivery acknowledgment
  void _sendDeliveryAck(ChatMessage message) async {
    try {
      await agoraChatClient.chatManager.sendMessageReadAck(message);
      log("Delivery acknowledgment sent for message: ${message.msgId}", name: "AgoraChat");
    } catch (e) {
      log("Failed to send delivery ack: $e", name: "AgoraChat");
    }
  }
  


  void onTokenWillExpire() {
    // The token is about to expire. Fetch a new token from your server.
  }

  void onTokenDidExpire() {
    // The token has expired.
  }

  void onDisconnected() {
    // Disconnected from the Chat server
  }

  void onConnected() {
    showLog("Connected");
  }

  // MARK: DISPLAY MESSAGES
  void displayMessage(String text, bool isSentMessage) {
    messageList.add(
      Row(
        children: [
          Expanded(
            child: Align(
              alignment: isSentMessage
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: EdgeInsets.fromLTRB(
                  (isSentMessage ? 50 : 0),
                  5,
                  (isSentMessage ? 0 : 50),
                  5,
                ),
                decoration: BoxDecoration(
                  color: isSentMessage
                      ? const Color(0xFFDCF8C6)
                      : const Color(0xFFFFFFFF),
                ),
                child: Text(text),
              ),
            ),
          ),
        ],
      ),
    );

    setState(() {
      scrollController.jumpTo(scrollController.position.maxScrollExtent + 50);
    });
  }

  @override
  void dispose() {
    agoraChatClient.chatManager.removeEventHandler("MESSAGE_HANDLER");
    agoraChatClient.chatManager.removeMessageEvent("MESSAGE_ACK_HANDLER");
    agoraChatClient.removeConnectionEventHandler("CONNECTION_HANDLER");
    super.dispose();
  }

  // MARK: UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Enter recipient's userId",
                      ),
                      onChanged: (chatUserId) => recipientId = chatUserId,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: joinLeave,
                    child: Text(isJoined ? "Leave" : "Join"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemBuilder: (_, index) {
                  print(messageList[index]);
                  print(messageList.length);
                  return messageList[index];
                },
                itemCount: messageList.length,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: messageBoxController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Message",
                      ),
                      onChanged: (msg) => messageContent = msg,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: sendMessage,
                    child: const Text(">>"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
