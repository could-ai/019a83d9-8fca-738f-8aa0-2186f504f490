import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Terminal App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      debugShowCheckedModeBanner: false,
      home: const TerminalScreen(),
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
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    _output.add('Welcome to the Real Terminal. Type a command and press Enter.');
    _output.add(
        'NOTE: This will only execute real commands on Desktop platforms (Windows, macOS, Linux).');
    _output.add(
        '------------------------------------------------------------------');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty) {
      return;
    }

    setState(() {
      _output.add('\$ $command');
    });

    // Ensure UI updates before running the process
    _scrollToBottom();

    try {
      // Platform detection for command execution
      String shell;
      List<String> args;

      // This part will not work in the web preview.
      // It's designed for desktop execution.
      if (Platform.isWindows) {
        shell = 'cmd';
        args = ['/c', command];
      } else if (Platform.isLinux || Platform.isMacOS) {
        shell = 'bash';
        args = ['-c', command];
      } else {
        setState(() {
          _output.add('Error: Unsupported platform for command execution.');
        });
        return;
      }

      final result = await Process.run(shell, args);

      setState(() {
        if (result.stdout.toString().isNotEmpty) {
          _output.addAll(result.stdout.toString().trim().split('\n'));
        }
        if (result.stderr.toString().isNotEmpty) {
          _output.addAll(result.stderr.toString().trim().split('\n'));
        }
      });
    } catch (e) {
      setState(() {
        _output.add('Error: This app is running in a web environment where real command execution is not possible.');
        _output.add('To test this functionality, please run as a Windows, macOS, or Linux application.');
      });
    } finally {
      _controller.clear();
      _scrollToBottom();
      // Refocus after command execution
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  void _scrollToBottom() {
    // A short delay ensures that the list has been updated before scrolling.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Terminal Executor'),
        backgroundColor: const Color(0xFF333333),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _output.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _output[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.lightGreen,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              onSubmitted: _executeCommand,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.lightGreen,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: Color(0xFF333333),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
