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
  String get appKey {
    final key = dotenv.env['AppKey'] ?? '';
    if (key.isEmpty) {
      showLog("ERROR: AppKey not found in .env file");
    }
    return key;
  }
  
  // User management
  static const List<String> availableUsers = ["adebayo", "adesayo"];
  String currentUserId = "adebayo";
  
  String get token {
    // Get token for current user
    final userToken = dotenv.env['${currentUserId}Token'] ?? '';
    if (userToken.isEmpty) {
      showLog("ERROR: Token not found for user $currentUserId in .env file");
    }
    return userToken;
  }

  late ChatClient agoraChatClient;
  bool isJoined = false;

  ScrollController scrollController = ScrollController();
  TextEditingController messageBoxController = TextEditingController();
  String messageContent = "", recipientId = "";
  final List<Widget> messageList = [];
  
  // Conversation management
  final Map<String, List<Widget>> conversationMessages = {};
  String currentConversationId = "";

  // MARK: JOIN / LEAVE
  void joinLeave() async {
    if (!isJoined) {
      // Log in
      if (token.isEmpty) {
        showLog("ERROR: Cannot login - User token is empty");
        return;
      }
      
      try {
        await agoraChatClient.loginWithToken(currentUserId, token);
        showLog("Logged in successfully as $currentUserId");
        setState(() {
          isJoined = true;
        });
      } on ChatError catch (e) {
        if (e.code == 200) {
          // Already logged in
                showLog("Already logged in as $currentUserId");
          setState(() {
            isJoined = true;
          });
        } else {
          showLog("Login failed: ${e.description}");
        }
      } catch (e) {
        showLog("Unexpected login error: $e");
      }
    } else {
      try {
        await agoraChatClient.logout(true);
        showLog("Logged out successfully");
        setState(() {
          isJoined = false;
        });
              } on ChatError catch (e) {
          showLog("Logout failed: ${e.description}");
        }
    }
  }

  // MARK: SEND MESSAGE
  void sendMessage() async {
    log("clicked me");
    
    // Check if user is logged in
    if (!isJoined) {
      showLog("Please login first before sending messages", showSnackbar: true);
      return;
    }
    
    if (currentConversationId.isEmpty) {
      showLog("Please start a conversation first", showSnackbar: true);
      return;
    }
    
    if (messageContent.isEmpty) {
      showLog("Please type a message", showSnackbar: true);
      return;
    }
    
    log("message content $messageContent recipientId $currentConversationId");
    
    try {
      var msg = ChatMessage.createTxtSendMessage(
        targetId: currentConversationId,
        content: messageContent,
      );
      
      await agoraChatClient.chatManager.sendMessage(msg);
      
      if (msg.status == MessageStatus.SUCCESS) {
        showLog("Message delivered successfully to $currentConversationId", showSnackbar: true);
      } else {
        showLog("Message sent but delivery status unclear", showSnackbar: true);
      }
      
      displayMessage(messageContent, true);
      messageBoxController.clear();
      messageContent = "";
      
    } on ChatError catch (e) {
      showLog("Failed to send message: ${e.description}", showSnackbar: true);
    } catch (e) {
      showLog("Unexpected error sending message: $e", showSnackbar: true);
    }
  }

  // MARK: USER MANAGEMENT
  void switchUser(String newUserId) async {
    if (isJoined) {
      // Logout current user first
      await agoraChatClient.logout(true);
      setState(() {
        isJoined = false;
      });
    }
    
    setState(() {
      currentUserId = newUserId;
      currentConversationId = "";
      messageList.clear();
    });
    
          showLog("Switched to user: $currentUserId", showSnackbar: true);
  }
  
  void startConversation(String otherUserId) {
    if (otherUserId == currentUserId) {
      showLog("Cannot start conversation with yourself", showSnackbar: true);
      return;
    }
    
    setState(() {
      currentConversationId = otherUserId;
      // Load existing messages for this conversation
      messageList.clear();
      if (conversationMessages.containsKey(otherUserId)) {
        messageList.addAll(conversationMessages[otherUserId]!);
      }
    });
    
          showLog("Started conversation with: $otherUserId", showSnackbar: true);
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
      
      ChatOptions options = ChatOptions(appKey: appKey, autoLogin: false);
      agoraChatClient = ChatClient.getInstance;
      await agoraChatClient.init(options);
      
      // Notify SDK that UI is ready
      await ChatClient.getInstance.startCallback();
      
      showLog("Chat SDK initialized successfully");
      
    } catch (e) {
      showLog("Failed to initialize Chat SDK: $e");
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
          showLog("✓ Message delivered to ${msg.to}", showSnackbar: true);
        },
        onProgress: (msgId, progress) {
          // Progress tracking (silent)
        },
        onError: (msgId, msg, error) {
          showLog("✗ Message failed to deliver to ${msg.to}", showSnackbar: true);
        },
      ),
    );
  }

  // MARK: EVENT HANDLERS
  void onMessagesReceived(List<ChatMessage> messages) {
    for (var msg in messages) {
      if (msg.body.type == MessageType.TXT) {
        ChatTextMessageBody body = msg.body as ChatTextMessageBody;
        
        // Add message to the appropriate conversation
        displayMessage(body.content, false, conversationId: msg.from);
        showLog("Message received from ${msg.from}: ${body.content}");
        
        // Send delivery acknowledgment
        _sendDeliveryAck(msg);
      } else {
        String msgType = msg.body.type.name;
        showLog("Received $msgType message, from ${msg.from}");
      }
    }
  }
  

  
  // Send delivery acknowledgment
  void _sendDeliveryAck(ChatMessage message) async {
    try {
      await agoraChatClient.chatManager.sendMessageReadAck(message);
    } catch (e) {
      // Silent fail for delivery ack
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
    // Connection established (silent)
  }

  // MARK: DISPLAY MESSAGES
  void displayMessage(String text, bool isSentMessage, {String? conversationId}) {
    final targetConversationId = conversationId ?? currentConversationId;
    
    if (targetConversationId.isEmpty) {
      showLog("No active conversation", showSnackbar: true);
      return;
    }
    
    final messageWidget = Row(
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSentMessage ? "You" : currentConversationId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(text),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    
    // Add to current conversation
    messageList.add(messageWidget);
    
    // Store in conversation history
    if (!conversationMessages.containsKey(targetConversationId)) {
      conversationMessages[targetConversationId] = [];
    }
    conversationMessages[targetConversationId]!.add(messageWidget);
    
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
      appBar: AppBar(
        title: Text("Chat - $currentUserId"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // User Selection Section
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    "Current User: $currentUserId",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: availableUsers.map((user) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: () => switchUser(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentUserId == user 
                                  ? Colors.blue 
                                  : Colors.grey[300],
                              foregroundColor: currentUserId == user 
                                  ? Colors.white 
                                  : Colors.black,
                            ),
                            child: Text(user),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: joinLeave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isJoined ? "Logout" : "Login"),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Conversation Selection Section
            if (isJoined) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      "Conversations",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: availableUsers
                          .where((user) => user != currentUserId)
                          .map((user) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: () => startConversation(user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentConversationId == user 
                                    ? Colors.blue 
                                    : Colors.white,
                                foregroundColor: currentConversationId == user 
                                    ? Colors.white 
                                    : Colors.blue,
                              ),
                              child: Text(user),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            
            // Current Conversation Header
            if (currentConversationId.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      "Chatting with: $currentConversationId",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            
            // Messages Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: currentConversationId.isEmpty
                    ? const Center(
                        child: Text(
                          "Select a conversation to start chatting",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemBuilder: (_, index) {
                          return messageList[index];
                        },
                        itemCount: messageList.length,
                      ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Message Input Section
            if (currentConversationId.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageBoxController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (msg) => messageContent = msg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: sendMessage,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}