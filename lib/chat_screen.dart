import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Corrected import
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

import 'chat_info_screen.dart';
import 'profile_screen.dart'; // Needed for ProfileScreen navigation

class ChatScreen extends StatefulWidget {
  final String chatId;
  final bool isGroupChat;
  final String? receiverId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.isGroupChat,
    this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  late final String _currentUserId;
  List<Map<String, dynamic>> _messages = [];
  late final RealtimeChannel _messagesChannel;
  String _chatTitle = 'Loading...';
  String? _receiverPhoneNumber; // New state variable for receiver's phone number

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser!.id;
    _fetchMessages();
    _setupMessagesSubscription();
    _fetchChatTitleAndPhoneNumber(); // Fetch chat title and phone number on init
  }

  Future<void> _fetchChatTitleAndPhoneNumber() async {
    String title;
    String? phoneNumber;
    if (!widget.isGroupChat) {
      // Fetch username and phone number for direct chat
      final profile = await supabase
          .from('profiles')
          .select('username, phone_number')
          .eq('id', widget.receiverId!)
          .single()
          .maybeSingle();
      title = profile?['username'] ?? 'Unknown User';
      phoneNumber = profile?['phone_number'];
    } else {
      // Fetch group name for group chat
      final group = await supabase
          .from('groups')
          .select('name')
          .eq('id', widget.chatId)
          .single()
          .maybeSingle();
      title = group?['name'] ?? 'Unknown Group';
    }
    setState(() {
      _chatTitle = title;
      _receiverPhoneNumber = phoneNumber;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makeVideoCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel', // Using 'tel' scheme, device will prompt for video call if supported
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not initiate video call to $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchMessages() async {
    try {
      List<Map<String, dynamic>> data;
      if (!widget.isGroupChat) {
        data = await supabase
            .from('messages')
            .select('*, profiles!messages_sender_id_fkey(username)')
            .or('and(sender_id.eq.$_currentUserId,receiver_id.eq.${widget.receiverId}),and(sender_id.eq.${widget.receiverId},receiver_id.eq.$_currentUserId)')
            .order('created_at', ascending: true);
      } else {
        data = await supabase
            .from('messages')
            .select('*, profiles!messages_sender_id_fkey(username)')
            .eq('group_id', widget.chatId)
            .order('created_at', ascending: true);
      }

      setState(() {
        _messages = data;
      });
    } catch (e) {
      print('Error fetching messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupMessagesSubscription() {
    _messagesChannel = supabase.channel('public:messages');

    _messagesChannel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newMessage = payload.newRecord;
        final senderId = newMessage['sender_id'];
        final receiverId = newMessage['receiver_id'];
        final groupId = newMessage['group_id'];

        print('Realtime: Received new message: $newMessage');
        print('Realtime: Current User ID: $_currentUserId');
        print('Realtime: Widget Chat ID (other user/group): ${widget.chatId}');
        print('Realtime: Widget Receiver ID (for direct): ${widget.receiverId}');

        bool isRelevantDirectMessage = !widget.isGroupChat &&
            ((senderId == _currentUserId && receiverId == widget.receiverId) ||
                (senderId == widget.receiverId && receiverId == _currentUserId));

        bool isRelevantGroupMessage = widget.isGroupChat && (groupId == widget.chatId);

        print('Realtime: Is Relevant Direct Message: $isRelevantDirectMessage');
        print('Realtime: Is Relevant Group Message: $isRelevantGroupMessage');

        if (isRelevantDirectMessage || isRelevantGroupMessage) {
          setState(() {
            _messages.add(newMessage);
          });
          print('Realtime: Message added to list.');

          if (senderId != _currentUserId) {
            // Removed _showNotification as it should be handled globally or by a dedicated service
          }
        } else {
          print('Realtime: Message not relevant to current chat.');
        }
      },
    );

    _messagesChannel.subscribe();
    print('Realtime: Channel subscribed.');
  }

  // Removed _showNotification function as it should be handled globally or by a dedicated service

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}-${pickedFile.name}';
      const bucketName = 'chat-images';

      try {
        final String path = await supabase.storage.from(bucketName).upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        final String publicUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);

        await _sendMessage(imageUrl: publicUrl);
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage({String? content, String? imageUrl}) async {
    if ((content == null || content.isEmpty) && (imageUrl == null || imageUrl.isEmpty)) {
      return;
    }

    if (content != null && content.isNotEmpty) {
      _messageController.clear();
    }

    try {
      await supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.isGroupChat ? null : widget.receiverId,
        'group_id': widget.isGroupChat ? widget.chatId : null,
        'content': content,
        'image_url': imageUrl,
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    supabase.removeChannel(_messagesChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chatTitle),
        actions: [
          if (!widget.isGroupChat && _receiverPhoneNumber != null) ...[
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.black), // Video call icon
              onPressed: () {
                _makeVideoCall(_receiverPhoneNumber!);
              },
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.black),
              onPressed: () {
                _makePhoneCall(_receiverPhoneNumber!);
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                    MediaQuery.of(context).size.width - 100,
                    kToolbarHeight + 20,
                    0,
                    0),
                items: <PopupMenuEntry>[
                  PopupMenuItem(
                    value: 'view_info',
                    child: Text(widget.isGroupChat ? 'View Group Info' : 'View User Info'),
                  ),
                  const PopupMenuItem(
                    value: 'search_chat',
                    child: Text('Search Chat'),
                  ),
                  const PopupMenuItem(
                    value: 'mute_notifications',
                    child: Text('Mute Notifications'),
                  ),
                  const PopupMenuItem(
                    value: 'disappearing_messages',
                    child: Text('Disappearing Messages'),
                  ),
                  const PopupMenuItem(
                    value: 'clear_chat',
                    child: Text('Clear Chat'),
                  ),
                  if (widget.isGroupChat)
                    const PopupMenuItem(
                      value: 'exit_group',
                      child: Text('Exit Group'),
                    ),
                ],
              ).then((value) {
                if (value != null) {
                  switch (value) {
                    case 'view_info':
                      if (!widget.isGroupChat) {
                        // For direct chats, navigate to ProfileScreen of the receiver
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: widget.receiverId),
                          ),
                        );
                      } else {
                        // For group chats, still navigate to ChatInfoScreen (or a group-specific info screen)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatInfoScreen(
                              chatId: widget.chatId,
                              isGroupChat: widget.isGroupChat,
                              receiverId: widget.receiverId,
                            ),
                          ),
                        );
                      }
                      break;
                    case 'search_chat':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search functionality not yet implemented.')),
                      );
                      break;
                    case 'mute_notifications':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications muted (placeholder).')),
                      );
                      break;
                    case 'disappearing_messages':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Disappearing messages not yet implemented.')),
                      );
                      break;
                    case 'clear_chat':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat history cleared (placeholder).')),
                      );
                      break;
                    case 'exit_group':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exiting group (placeholder).')),
                      );
                      Navigator.pop(context);
                      break;
                  }
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSentByMe = message['sender_id'] == _currentUserId;
                final imageUrl = message['image_url'];
                final messageContent = message['content'];
                final senderUsername = (message['profiles'] as Map<String, dynamic>?)?['username'] as String?;

                Widget messageWidget;
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  messageWidget = Image.network(
                    imageUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Error loading image');
                    },
                  );
                } else {
                  // Make links clickable
                  final text = messageContent ?? '';
                  final List<TextSpan> spans = [];
                  final RegExp urlRegex = RegExp(
                      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+'); // Simple URL regex

                  text.splitMapJoin(
                    urlRegex,
                    onMatch: (Match match) {
                      final url = match.group(0)!;
                      spans.add(
                        TextSpan(
                          text: url,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              String launchUrlString = url;
                              if (!launchUrlString.startsWith('http://') && !launchUrlString.startsWith('https://')) {
                                launchUrlString = 'http://$launchUrlString';
                              }
                              final Uri launchUri = Uri.parse(launchUrlString);
                              if (await canLaunchUrl(launchUri)) {
                                await launchUrl(launchUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not launch $launchUrlString'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                        ),
                      );
                      return ''; // Return empty string to prevent default splitting
                    },
                    onNonMatch: (String nonMatch) {
                      spans.add(TextSpan(text: nonMatch));
                      return ''; // Return empty string to prevent default splitting
                    },
                  );
                  messageWidget = RichText(
                    text: TextSpan(
                      children: spans,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSentByMe ? const Color(0xFFDCF8C6) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (widget.isGroupChat && !isSentByMe && senderUsername != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              senderUsername,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        messageWidget,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, color: Theme.of(context).primaryColor),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(content: _messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
