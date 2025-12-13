import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grok-Style Terminal',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1117), // Deep dark background like Grok
        cardColor: const Color(0xFF1A1D24),
        primaryColor: const Color(0xFFD1D5DB),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFFFFF),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF1A1D24),
          background: Color(0xFF0F1117),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE5E7EB), fontFamily: 'Inter'),
          bodySmall: TextStyle(color: Color(0xFF9CA3AF), fontFamily: 'Inter'),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TerminalScreen(),
    const TasksScreen(),
    const ToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (Navigation)
          Container(
            width: 60,
            color: const Color(0xFF0F1117),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildNavItem(Icons.terminal, 0),
                const SizedBox(height: 20),
                _buildNavItem(Icons.task_alt, 1),
                const SizedBox(height: 20),
                _buildNavItem(Icons.construction, 2),
              ],
            ),
          ),
          // Vertical Divider
          Container(width: 1, color: const Color(0xFF2D3748)),
          // Main Content
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => setState(() => _selectedIndex = index),
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey,
        size: 28,
      ),
      tooltip: index == 0 ? 'Terminal' : index == 1 ? 'Tasks' : 'Tools',
    );
  }
}

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<TerminalMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addSystemMessage('Grok-Style Terminal Interface Initialized.');
    _addSystemMessage('Connected to local shell. Ready for commands.');
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
       _addSystemMessage('WARNING: Web/Mobile environment detected. Real execution disabled.');
    }
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(TerminalMessage(text: text, type: MessageType.system));
    });
  }

  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty) return;

    setState(() {
      _messages.add(TerminalMessage(text: command, type: MessageType.user));
    });
    _controller.clear();
    _scrollToBottom();

    try {
      String shell;
      List<String> args;

      if (Platform.isWindows) {
        shell = 'cmd';
        args = ['/c', command];
      } else if (Platform.isLinux || Platform.isMacOS) {
        shell = 'bash';
        args = ['-c', command];
      } else {
        setState(() {
          _messages.add(TerminalMessage(
              text: 'Error: Real command execution requires Desktop (Windows/Linux/macOS).',
              type: MessageType.error));
        });
        return;
      }

      final result = await Process.run(shell, args);

      setState(() {
        if (result.stdout.toString().isNotEmpty) {
          _messages.add(TerminalMessage(
              text: result.stdout.toString().trim(), type: MessageType.output));
        }
        if (result.stderr.toString().isNotEmpty) {
          _messages.add(TerminalMessage(
              text: result.stderr.toString().trim(), type: MessageType.error));
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(TerminalMessage(
            text: 'Execution Error: $e', type: MessageType.error));
      });
    } finally {
      _scrollToBottom();
      _focusNode.requestFocus();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF2D3748))),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Local Terminal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // Output Area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      if (msg.type == MessageType.user)
                        const TextSpan(
                          text: '\$ ',
                          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      TextSpan(
                        text: msg.text,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: msg.type == MessageType.error
                              ? Colors.redAccent
                              : msg.type == MessageType.user
                                  ? Colors.white
                                  : msg.type == MessageType.system
                                      ? Colors.grey
                                      : const Color(0xFFA7F3D0), // Light green for output
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Input Area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2D3748))),
            color: Color(0xFF1A1D24),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter command...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: _executeCommand,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: () => _executeCommand(_controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Placeholder for Tasks Screen (inspired by uploaded files)
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Scheduled Tasks',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Automate your workflow with scheduled commands.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        _buildTaskCard('Daily System Update', '00:00 AM', 'apt-get update && apt-get upgrade -y', true),
        _buildTaskCard('Backup Database', '03:00 AM', 'pg_dump dbname > backup.sql', true),
        _buildTaskCard('Clear Temp Files', 'Weekly', 'rm -rf /tmp/*', false),
      ],
    );
  }

  Widget _buildTaskCard(String title, String schedule, String command, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Switch(value: isActive, onChanged: (val) {}, activeColor: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(schedule, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1117),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              command,
              style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFA7F3D0), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder for Tools Screen
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Tools & Integrations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Configure external tools and APIs here.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

enum MessageType { user, output, error, system }

class TerminalMessage {
  final String text;
  final MessageType type;

  TerminalMessage({required this.text, required this.type});
}
