import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'user_profile_notifier.dart';
import 'chat_screen.dart'; // Import ChatScreen
// Needed for FAB navigation

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;
  late UserProfileNotifier _userProfileNotifier; // Declare notifier

  @override
  void initState() {
    super.initState();
    _userProfileNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
    _userProfileNotifier.addListener(_onUserProfileChanged); // Listen for profile changes
    _fetchConversations();
  }

  @override
  void dispose() {
    _userProfileNotifier.removeListener(_onUserProfileChanged); // Remove listener
    super.dispose();
  }

  void _onUserProfileChanged() {
    // Re-fetch conversations when user profile changes (e.g., after login/logout)
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUserId = _userProfileNotifier.userProfile?['id'] ?? supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        _conversations = []; // Clear conversations if no user is logged in
        return;
      }

      final List<Map<String, dynamic>> sentMessages = await supabase
          .from('messages')
          .select('receiver_id, group_id')
          .eq('sender_id', currentUserId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> receivedMessages = await supabase
          .from('messages')
          .select('sender_id, group_id')
          .eq('receiver_id', currentUserId)
          .order('created_at', ascending: false);

      Set<String> uniqueChatIds = {};
      List<Map<String, dynamic>> conversations = [];

      for (var msg in sentMessages) {
        if (msg['receiver_id'] != null && !uniqueChatIds.contains(msg['receiver_id'])) {
          uniqueChatIds.add(msg['receiver_id']);
          conversations.add({'id': msg['receiver_id'], 'type': 'direct'});
        }
      }

      for (var msg in receivedMessages) {
        if (msg['sender_id'] != null && !uniqueChatIds.contains(msg['sender_id'])) {
          uniqueChatIds.add(msg['sender_id']);
          conversations.add({'id': msg['sender_id'], 'type': 'direct'});
        }
      }

      // Fetch names for direct chats and group names
      for (var conv in conversations) {
        if (conv['type'] == 'direct') {
          final profile = await supabase
              .from('profiles')
              .select('username')
              .eq('id', conv['id'])
              .single()
              .maybeSingle();
          conv['name'] = profile?['username'] ?? 'Unknown User';
        } else if (conv['type'] == 'group') {
          final group = await supabase
              .from('groups')
              .select('name')
              .eq('id', conv['id'])
              .single()
              .maybeSingle();
          conv['name'] = group?['name'] ?? 'Unknown Group';
        }
      }

      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      print('Error fetching conversations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching conversations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed floatingActionButton
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                final isGroupChat = conversation['type'] == 'group';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: conversation['id'],
                            isGroupChat: isGroupChat,
                            receiverId: isGroupChat ? null : conversation['id'],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Icon(isGroupChat ? Icons.group : Icons.person, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conversation['name'] ?? 'Unknown Chat',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Last message preview...', // TODO: Fetch last message
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                '10:30 AM', // TODO: Fetch last message timestamp
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  '3', // TODO: Fetch unread count
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

