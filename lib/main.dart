import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final SupabaseClient supabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pdoariwimzobawluvskl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBkb2FyaXdpbXpvYmF3bHV2c2tsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzNzUzOTgsImV4cCI6MjA5NTk1MTM5OH0.RietFXlfyBk0PkLP8i5DBwTr7NNy3DJs52uLg9cvNR4',
  );
  supabase = Supabase.instance.client;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await supabase.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (e) {
      // Если обычный логин не работает, используем anonymous
      try {
        await supabase.auth.signInAnonymously();
      } catch (anonError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auth error: $e\nAnonymous: $anonError')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      // Skip auth for now - use direct access
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anonymous auth disabled. Using direct access.')),
        );
        // Force show HomeScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event, size: 80, color: Colors.deepPurple),
                Text('Event Management', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Invalid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _authenticate,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isLogin ? 'Login' : 'Register'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Create Account' : 'Have Account? Login'),
                ),
                const Divider(),
                TextButton(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Event> _myEvents = [];
  List<Event> _availableEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('events').select().order('created_at', ascending: false);
      if (mounted && response is List) {
        final events = response.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          _availableEvents = events;
          _myEvents = events.where((e) => e.creatorId == userId).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _availableEvents.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'My Events' : 'Available Events'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => supabase.auth.signOut()),
        ],
      ),
      body: _currentIndex == 0 ? _buildMyEvents() : _buildAvailableEvents(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          _loadEvents();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'My Events'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Available Events'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateEventScreen(onCreated: _loadEvents)),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMyEvents() {
    return _myEvents.isEmpty
        ? const Center(child: Text('No events. Create one!'))
        : ListView.builder(
            itemCount: _myEvents.length,
            itemBuilder: (_, i) => EventCard(event: _myEvents[i], isCreator: true, onRefresh: _loadEvents),
          );
  }

  Widget _buildAvailableEvents() {
    return _availableEvents.isEmpty
        ? const Center(child: Text('No available events'))
        : ListView.builder(
            itemCount: _availableEvents.length,
            itemBuilder: (_, i) => EventCard(event: _availableEvents[i], isCreator: false, onRefresh: _loadEvents),
          );
  }
}

class EventCard extends StatefulWidget {
  final Event event;
  final bool isCreator;
  final VoidCallback onRefresh;

  const EventCard({required this.event, required this.isCreator, required this.onRefresh, super.key});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isJoined = false;
  int _participantCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      final countResponse = await supabase.from('event_participants').select().eq('event_id', widget.event.id);
      final joinResponse = await supabase.from('event_participants').select().eq('event_id', widget.event.id).eq('user_id', userId).limit(1);
      if (mounted && countResponse is List && joinResponse is List) {
        setState(() {
          _participantCount = countResponse.length;
          _isJoined = joinResponse.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleJoin() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      if (_isJoined) {
        await supabase.from('event_participants').delete().eq('event_id', widget.event.id).eq('user_id', userId);
      } else {
        await supabase.from('event_participants').insert({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'event_id': widget.event.id,
          'user_id': userId,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }
      _loadData();
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isJoined ? 'Left event' : 'Joined event')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(widget.event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event.description),
            const SizedBox(height: 4),
            Text('Participants: $_participantCount'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(_isJoined ? Icons.remove_circle : Icons.add_circle),
          onPressed: _isLoading ? null : _toggleJoin,
        ),
        onTap: () {
          supabase.from('event_views').insert({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'event_id': widget.event.id,
            'user_id': supabase.auth.currentUser?.id ?? '',
            'viewed_at': DateTime.now().toIso8601String(),
          }).catchError((_) {});
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(event: widget.event, isCreator: widget.isCreator),
            ),
          );
        },
      ),
    );
  }
}

class CreateEventScreen extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateEventScreen({required this.onCreated, super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id ?? '';
      await supabase.from('events').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text,
        'description': _descriptionController.text,
        'creator_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createEvent,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final bool isCreator;

  const EventDetailScreen({required this.event, required this.isCreator, super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isJoined = false;
  int _participantCount = 0;
  int _viewCount = 0;
  List<dynamic> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      final results = await Future.wait([
        supabase.from('event_participants').select().eq('event_id', widget.event.id).eq('user_id', userId).limit(1),
        supabase.from('event_participants').select().eq('event_id', widget.event.id),
        supabase.from('event_views').select().eq('event_id', widget.event.id),
      ]);
      if (mounted) {
        setState(() {
          _isJoined = (results[0] as List).isNotEmpty;
          _participantCount = (results[1] as List).length;
          _viewCount = (results[2] as List).length;
          _participants = results[1] as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleJoin() async {
    final userId = supabase.auth.currentUser?.id ?? '';
    try {
      if (_isJoined) {
        await supabase.from('event_participants').delete().eq('event_id', widget.event.id).eq('user_id', userId);
      } else {
        await supabase.from('event_participants').insert({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'event_id': widget.event.id,
          'user_id': userId,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }
      _loadDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: widget.isCreator
            ? [
                IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Event?'),
                      content: const Text('This action cannot be undone'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () async {
                            await supabase.from('events').delete().eq('id', widget.event.id);
                            if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(widget.event.description),
            const SizedBox(height: 16),
            Text('Participants: $_participantCount'),
            Text('Views: $_viewCount'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _toggleJoin,
              icon: Icon(_isJoined ? Icons.remove : Icons.add),
              label: Text(_isJoined ? 'Leave Event' : 'Join Event'),
            ),
            if (widget.isCreator) ...[
              const SizedBox(height: 20),
              const Text('Participants List', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: _participants.isEmpty
                    ? const Text('No participants yet')
                    : ListView.builder(
                        itemCount: _participants.length,
                        itemBuilder: (_, i) {
                          final p = _participants[i] as Map<String, dynamic>;
                          return ListTile(
                            title: Text(p['user_id'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () async {
                                await supabase.from('event_participants').delete().eq('id', p['id']);
                                _loadDetails();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}