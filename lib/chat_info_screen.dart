import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for calling functionality
import 'package:gapshap/chat_screen.dart'; // Import ChatScreen

class ChatInfoScreen extends StatefulWidget {
  final String chatId;
  final bool isGroupChat;
  final String? receiverId;

  const ChatInfoScreen({
    super.key,
    required this.chatId,
    required this.isGroupChat,
    this.receiverId,
  });

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? _info;
  List<Map<String, dynamic>> _groupMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatInfo();
  }

  Future<void> _fetchChatInfo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (!widget.isGroupChat) {
        // Fetch user profile for direct chat
        final profile = await supabase
            .from('profiles')
            .select('*')
            .eq('id', widget.receiverId!)
            .single()
            .maybeSingle();
        setState(() {
          _info = profile;
        });
      } else {
        // Fetch group info and members for group chat
        final group = await supabase
            .from('groups')
            .select('*')
            .eq('id', widget.chatId)
            .single()
            .maybeSingle();
        setState(() {
          _info = group;
        });

        if (group != null) {
          final members = await supabase
              .from('group_members')
              .select('user_id, profiles(id, username, avatar_url, phone_number)') // Fetch id and phone_number
              .eq('group_id', widget.chatId);
          setState(() {
            _groupMembers = members.map((e) => e['profiles'] as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching chat info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching chat info: $e'),
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
      appBar: AppBar(
        title: Text(widget.isGroupChat ? 'Group Info' : 'User Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _info == null
              ? const Center(child: Text('Information not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).primaryColor,
                          backgroundImage: _info!['avatar_url'] != null
                              ? NetworkImage(_info!['avatar_url'])
                              : null,
                          child: _info!['avatar_url'] == null
                              ? Icon(
                                  widget.isGroupChat ? Icons.group : Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _info!['username'] ?? _info!['name'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!widget.isGroupChat && _info!['email'] != null)
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(_info!['email']),
                        ),
                      if (widget.isGroupChat) ...[
                        const Divider(),
                        const Text(
                          'Members',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _groupMembers.isEmpty
                            ? const Text('No members found.')
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _groupMembers.length,
                                itemBuilder: (context, index) {
                                  final member = _groupMembers[index];
                                  final memberId = member['id'] as String?;
                                  final memberPhoneNumber = member['phone_number'] as String?;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      backgroundImage: member['avatar_url'] != null
                                          ? NetworkImage(member['avatar_url'])
                                          : null,
                                      child: member['avatar_url'] == null
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                    title: Text(member['username'] ?? 'Unknown Member'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (memberId != null)
                                          IconButton(
                                            icon: const Icon(Icons.chat_bubble_outline),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ChatScreen(
                                                    chatId: memberId,
                                                    isGroupChat: false,
                                                    receiverId: memberId,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        if (memberPhoneNumber != null && memberPhoneNumber.isNotEmpty) ...[
                                          IconButton(
                                            icon: const Icon(Icons.videocam), // Video call icon
                                            onPressed: () async {
                                              final Uri launchUri = Uri(
                                                scheme: 'tel', // Using 'tel' scheme, device will prompt for video call if supported
                                                path: memberPhoneNumber,
                                              );
                                              if (await canLaunchUrl(launchUri)) {
                                                await launchUrl(launchUri);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Could not initiate video call to $memberPhoneNumber'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.call),
                                            onPressed: () async {
                                              final Uri launchUri = Uri(
                                                scheme: 'tel',
                                                path: memberPhoneNumber,
                                              );
                                              if (await canLaunchUrl(launchUri)) {
                                                await launchUrl(launchUri);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Could not launch $memberPhoneNumber'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
