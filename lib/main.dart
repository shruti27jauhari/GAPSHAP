import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart'; // New import for Provider
import 'package:url_launcher/url_launcher.dart'; // Import for calling functionality
import 'package:flutter/gestures.dart'; // Import for TapGestureRecognizer
import 'package:flutter/services.dart'; // Import for Clipboard

import 'login_screen.dart';
import 'signup_screen.dart';
import 'profile_screen.dart';
import 'new_chat_screen.dart'; // Import new_chat_screen.dart
import 'chat_info_screen.dart';
import 'status_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';
import 'theme_mode_notifier.dart';
import 'user_profile_notifier.dart'; // New import for UserProfileNotifier
import 'chat_screen.dart'; // Import chat_screen.dart
import 'updates_screen.dart'; // Import updates_screen.dart

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Add network connectivity check
Future<bool> _checkNetworkConnectivity() async {
  try {
    // Try multiple hosts to ensure connectivity
    final googleResult = await InternetAddress.lookup('google.com');
    final supabaseResult = await InternetAddress.lookup('supabase.co');
    return (googleResult.isNotEmpty && googleResult[0].rawAddress.isNotEmpty) ||
           (supabaseResult.isNotEmpty && supabaseResult[0].rawAddress.isNotEmpty);
  } on SocketException catch (_) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Checking network connectivity...');
    bool isConnected = await _checkNetworkConnectivity();
    if (!isConnected) {
      throw Exception('No internet connection available');
    }
    print('Network connectivity: OK');

    print('Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://zywlpzbfcnianiiptgnz.supabase.co', // Replace with your Supabase URL
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5d2xwemJmY25pYW5paXB0Z256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5NjkxMzUsImV4cCI6MjA2NTU0NTEzNX0.cayA4mS4XarYwPKZrFw_7rTB6NOBlvazqXmkdce6pkY', // Replace with your Supabase Anon Key
    );
    print('Supabase initialized successfully');

    // Test Supabase connection with retry
    bool supabaseConnected = false;
    for (int i = 0; i < 3; i++) {
      try {
        await Supabase.instance.client.from('profiles').select('count').limit(1);
        print('Supabase connection test: OK (attempt ${i + 1})');
        supabaseConnected = true;
        break;
      } catch (e) {
        print('Supabase connection test failed (attempt ${i + 1}): $e');
        if (i < 2) {
          await Future.delayed(Duration(seconds: 2)); // Wait before retry
        }
      }
    }
    
    if (!supabaseConnected) {
      print('Warning: Supabase database connection failed after 3 attempts, but app will continue');
    }

    // Initialize flutter_local_notifications
    print('Initializing notifications...');
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/app_icon'); // Use default launcher icon

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: DarwinInitializationSettings(), // For iOS, uncomment and configure if needed
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('Notifications initialized successfully');

    // Request notification permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    print('Starting app...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeModeNotifier()),
          ChangeNotifierProvider(create: (_) => UserProfileNotifier()), // Provide UserProfileNotifier
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Error during initialization: $e');
    // Show error screen instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Connection Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to connect to the server.\n\nError: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please check:\n• Your Supabase project is active\n• API keys are correct\n• Internet connection is stable',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Restart the app
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      // Test network connectivity
                      bool isConnected = await _checkNetworkConnectivity();
                      // Show result in a simple way
                      print('Network connectivity check: ${isConnected ? "Connected" : "Not connected"}');
                    },
                    child: const Text('Check Internet Connection'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModeNotifier>(
      builder: (context, themeModeNotifier, child) {
        return MaterialApp(
          title: 'GapShap',
          themeMode: themeModeNotifier.themeMode,
          theme: ThemeData(
            primaryColor: const Color(0xFF4285F4), // Google Blue
            hintColor: Colors.grey,
            scaffoldBackgroundColor: const Color(0xFFF0F2F5), // Light grey background
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontSize: 16),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4), // Google Blue
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white, // White app bar
              elevation: 0, // No shadow
              titleTextStyle: TextStyle(
                color: Colors.black, // Black title text
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.black), // Black icons
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF4285F4), // Google Blue
              foregroundColor: Colors.white,
            ),
            cardTheme: const CardThemeData( // Corrected from CardTheme to CardThemeData
              elevation: 0,
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)), // Rounded corners for cards
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF1A73E8), // Darker Google Blue
            hintColor: Colors.grey.shade700,
            scaffoldBackgroundColor: const Color(0xFF202124), // Dark grey background
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8), // Darker Google Blue
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF202124), // Dark grey app bar
              elevation: 0, // No shadow
              titleTextStyle: TextStyle(
                color: Colors.white, // White title text
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.white), // White icons
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF1A73E8), // Darker Google Blue
              foregroundColor: Colors.white,
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient supabase = Supabase.instance.client;
  User? _currentUser;
  int _selectedIndex = 0; // New state for bottom navigation index
  bool _isLoading = true; // Add loading state

  static final List<Widget> _widgetOptions = <Widget>[
    // This will be the "Chats" screen, which is the current MainScreen content
    const _ChatScreenContent(), // A new widget to encapsulate the existing chat screen content
    const UpdatesScreen(), // Replaced StatusScreen with UpdatesScreen
    const CallsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed length to 2 for Chats and Groups
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _currentUser = supabase.auth.currentUser;
    print('Initial auth state - User: ${_currentUser?.email ?? "null"}');
    
    supabase.auth.onAuthStateChange.listen((data) {
      print('Auth state changed: ${data.event} - User: ${data.session?.user?.email ?? "null"}');
      setState(() {
        _currentUser = data.session?.user;
        _isLoading = false; // Stop loading when auth state is determined
      });
      if (data.event == AuthChangeEvent.signedIn) {
        _createProfileForNewUser(data.session!.user);
      }
    });
    
    // If no auth state change happens, stop loading after a timeout
    Future.delayed(const Duration(seconds: 3), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _createProfileForNewUser(User user) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .single()
          .maybeSingle();

      if (response == null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'username': user.userMetadata?['name'] ?? user.email,
          'avatar_url': user.userMetadata?['avatar_url'],
          'phone_number': user.phone, // Save phone number from user object
        });
      }
    } catch (e) {
      print('Error creating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating user profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onLogout() async {
    try {
      await supabase.auth.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('MainScreen build - Current user: ${_currentUser?.email ?? "null"}, Loading: $_isLoading');
    
    // Show loading screen while determining auth state
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return _currentUser == null
        ? LoginScreen(onLoginSuccess: () {
            print('Login success callback called');
            setState(() {
              _currentUser = supabase.auth.currentUser;
            });
          })
        : Scaffold(
            body: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed, // Ensures all items are visible
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info_outline), // Changed to Updates icon
                  label: 'Updates',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.call_outlined), // Changed to Calls icon
                  label: 'Calls',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined), // Changed to Settings icon
                  label: 'Settings',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
  }
}

// New widget to encapsulate the original _buildChatScreen content
class _ChatScreenContent extends StatefulWidget {
  const _ChatScreenContent();

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = Provider.of<UserProfileNotifier>(context);
    final currentUserProfile = userProfileNotifier.userProfile;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: currentUserProfile?['avatar_url'] != null
                  ? NetworkImage(currentUserProfile!['avatar_url'])
                  : null,
              child: currentUserProfile?['avatar_url'] == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
        ),
        title: null,
        flexibleSpace: Align(
          alignment: Alignment.center,
          child: Container(
            width: 200,
            height: 40,
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 0,
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              tabs: const [
                Tab(text: 'Message'),
                Tab(text: 'Group'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // TODO: Implement notification logic
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Chat App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).primaryColor),
              title: const Text('Logout'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatListScreen(),
          GroupListScreen(),
        ],
      ),
      floatingActionButton: null, // Removed FloatingActionButton
    );
  }
}

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
    _markMessagesAsRead(); // Mark messages as read when chat is opened
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
            _showNotification(newMessage['content'], senderId);
          }
        } else {
          print('Realtime: Message not relevant to current chat.');
        }
      },
    );

    _messagesChannel.subscribe();
    print('Realtime: Channel subscribed.');
  }

  Future<void> _showNotification(String message, String senderId) async {
    String senderUsername = 'Unknown User';
    try {
      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', senderId)
          .single()
          .maybeSingle();
      senderUsername = profile?['username'] ?? 'Unknown User';
    } catch (e) {
      print('Error fetching sender profile for notification: $e');
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_app_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New message from $senderUsername',
      message,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

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

  Future<void> _scheduleMessage() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message cannot be empty to schedule!')),
      );
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled time cannot be in the past!')),
      );
      return;
    }

    try {
      await supabase.from('scheduled_messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.isGroupChat ? null : widget.receiverId,
        'group_id': widget.isGroupChat ? widget.chatId : null,
        'content': _messageController.text,
        'scheduled_at': scheduledDateTime.toIso8601String(),
        'status': 'pending',
      });

      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message scheduled for ${scheduledDateTime.toLocal()}')),
      );
    } catch (e) {
      print('Error scheduling message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      if (!mounted) return; // Check if widget is still mounted

      if (!widget.isGroupChat) {
        // For direct messages, mark messages sent by the other user to me as read
        await supabase
            .from('messages')
            .update({'read': true})
            .eq('sender_id', widget.receiverId!) // Use null-assertion operator
            .eq('receiver_id', _currentUserId)
            .eq('read', false);
      } else {
        // For group messages, mark all messages in this group as read for the current user
        // (assuming 'read' status is per-message, not per-user-per-message)
        // If 'read' needs to be per-user, a separate join table or more complex RLS is needed.
        // For now, we mark messages in the group as read if they were sent by others.
        await supabase
            .from('messages')
            .update({'read': true})
            .eq('group_id', widget.chatId)
            .neq('sender_id', _currentUserId) // Only mark messages sent by others as read
            .eq('read', false);
      }
    } catch (e) {
      print('Error marking messages as read: $e');
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
                // For video call, typically use a different scheme or a specific app's deep link
                // For simplicity, we'll use tel: for now, but a real app would integrate with a video call service
                _makePhoneCall(_receiverPhoneNumber!); // Using tel: for video call as well
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
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Clear Chat History?'),
                            content: const Text('Are you sure you want to clear all messages in this chat? This action cannot be undone.'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Clear'),
                                onPressed: () async {
                                  Navigator.of(dialogContext).pop(); // Close dialog
                                  try {
                                    if (!widget.isGroupChat) {
                                      // For direct chat
                                      await supabase
                                          .from('messages')
                                          .delete()
                                          .or('and(sender_id.eq.$_currentUserId,receiver_id.eq.${widget.receiverId}),and(sender_id.eq.${widget.receiverId},receiver_id.eq.$_currentUserId)');
                                    } else {
                                      // For group chat
                                      await supabase
                                          .from('messages')
                                          .delete()
                                          .eq('group_id', widget.chatId);
                                    }
                                    setState(() {
                                      _messages.clear(); // Clear messages from UI
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Chat history cleared!')),
                                    );
                                  } catch (e) {
                                    print('Error clearing chat: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error clearing chat: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
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
                  child: GestureDetector(
                    onLongPress: () {
                      if (isSentByMe) {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext bc) {
                            return SafeArea(
                              child: Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.copy),
                                    title: const Text('Copy Text'),
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: messageContent ?? ''));
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Message copied to clipboard!')),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: const Text('Delete Message'),
                                    onTap: () async {
                                      Navigator.pop(context); // Close bottom sheet
                                      final bool? confirmDelete = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return AlertDialog(
                                            title: const Text('Delete Message?'),
                                            content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Cancel'),
                                                onPressed: () {
                                                  Navigator.of(dialogContext).pop(false);
                                                },
                                              ),
                                              TextButton(
                                                child: const Text('Delete'),
                                                onPressed: () {
                                                  Navigator.of(dialogContext).pop(true);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmDelete == true) {
                                        try {
                                          await supabase
                                              .from('messages')
                                              .delete()
                                              .eq('id', message['id']);
                                          setState(() {
                                            _messages.removeWhere((msg) => msg['id'] == message['id']);
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Message deleted!')),
                                          );
                                        } catch (e) {
                                          print('Error deleting message: $e');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error deleting message: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
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
                    onLongPress: _scheduleMessage, // Added onLongPress
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

          // Fetch unread count for direct messages
          final unreadCount = await supabase
              .from('messages')
              .select('count')
              .eq('receiver_id', currentUserId)
              .eq('sender_id', conv['id'])
              .eq('read', false)
              .single();
          conv['unread_count'] = unreadCount['count'] ?? 0;

        } else if (conv['type'] == 'group') {
          final group = await supabase
              .from('groups')
              .select('name')
              .eq('id', conv['id'])
              .single()
              .maybeSingle();
          conv['name'] = group?['name'] ?? 'Unknown Group';

          // Fetch unread count for group messages
          final unreadCount = await supabase
              .from('messages')
              .select('count')
              .eq('group_id', conv['id'])
              .neq('sender_id', currentUserId) // Exclude messages sent by current user
              .eq('read', false)
              .single();
          conv['unread_count'] = unreadCount['count'] ?? 0;
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatListFab', // Unique tag for ChatListScreen FAB
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewChatScreen()),
          );
        },
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        child: const Icon(Icons.chat),
      ),
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
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: conversation['id'],
                            isGroupChat: isGroupChat,
                            receiverId: isGroupChat ? null : conversation['id'],
                          ),
                        ),
                      );
                      _fetchConversations(); // Refresh conversations when returning from chat
                    },
                    onLongPress: () async {
                      // Long press to delete chat
                      final bool? confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Delete Chat?'),
                            content: const Text('Are you sure you want to delete this chat and all its messages? This action cannot be undone.'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(false);
                                },
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        try {
                          final currentUserId = _userProfileNotifier.userProfile?['id'] ?? supabase.auth.currentUser?.id;
                          if (currentUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error: User not logged in.')),
                            );
                            return;
                          }

                          if (!isGroupChat) {
                            // Delete messages for direct chat
                            await supabase
                                .from('messages')
                                .delete()
                                .or('and(sender_id.eq.$currentUserId,receiver_id.eq.${conversation['id']}),and(sender_id.eq.${conversation['id']},receiver_id.eq.$currentUserId)');
                          } else {
                            // Delete messages for group chat
                            await supabase
                                .from('messages')
                                .delete()
                                .eq('group_id', conversation['id']);
                            // Optionally, remove user from group_members or delete group if empty
                          }

                          setState(() {
                            _conversations.removeAt(index); // Remove from UI list
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat deleted successfully!')),
                          );
                        } catch (e) {
                          print('Error deleting chat: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting chat: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
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
                              const SizedBox(height: 5),
                              if (conversation['unread_count'] > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    conversation['unread_count'].toString(),
                                    style: const TextStyle(
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

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  late UserProfileNotifier _userProfileNotifier; // Declare notifier

  @override
  void initState() {
    super.initState();
    _userProfileNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
    _userProfileNotifier.addListener(_onUserProfileChanged); // Listen for profile changes
    _fetchGroups();
  }

  @override
  void dispose() {
    _userProfileNotifier.removeListener(_onUserProfileChanged); // Remove listener
    super.dispose();
  }

  void _onUserProfileChanged() {
    // Re-fetch groups when user profile changes (e.g., after login/logout)
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUserId = _userProfileNotifier.userProfile?['id'] ?? supabase.auth.currentUser!.id; // Get current user ID from notifier or fallback
      final List<Map<String, dynamic>> data = await supabase
          .from('group_members')
          .select('group_id, groups(name)')
          .eq('user_id', currentUserId);

      List<Map<String, dynamic>> fetchedGroups = [];
      for (var row in data) {
        if (row['groups'] != null) {
          fetchedGroups.add({
            'id': row['group_id'],
            'name': row['groups']['name'],
          });
        }
      }

      setState(() {
        _groups = fetchedGroups;
      });
    } catch (e) {
      print('Error fetching groups: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching groups: $e'),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'groupListFab', // Unique tag for GroupListScreen FAB
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewChatScreen()),
          );
        },
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        child: const Icon(Icons.group_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.group, color: Colors.white),
                    ),
                    title: Text(group['name'] ?? 'Unknown Group'),
                    subtitle: const Text('Group chat'),
                    trailing: const Text(''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: group['id'],
                            isGroupChat: true,
                            receiverId: null,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
