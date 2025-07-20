import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'settings_screen.dart';
import 'status_screen.dart';
import 'calls_screen.dart';
import 'chat_list_screen.dart';
// Needed for FAB navigation

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

  static const List<Widget> _widgetOptions = <Widget>[
    ChatListScreen(),
    StatusScreen(),
    CallsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed length to 2 for Chats and Groups
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _currentUser = supabase.auth.currentUser;
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _currentUser = data.session?.user;
      });
      if (data.event == AuthChangeEvent.signedIn) {
        _createProfileForNewUser(data.session!.user);
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
    return _currentUser == null
        ? LoginScreen(onLoginSuccess: () {})
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
                  icon: Icon(Icons.circle_notifications_outlined), // Changed to Status icon
                  label: 'Status',
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
            floatingActionButton: null, // Removed FloatingActionButton
          );
  }
}
