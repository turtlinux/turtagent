import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtagent_hub/features/chat/presentation/chat.dart';
import 'package:turtagent_hub/features/conversations/presentation/conversations_sidebar.dart';
import 'package:turtagent_hub/features/conversations/providers/conversations_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _chatContainerController = ChatContainerController();
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onExitRequested: () => _handleExit());
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  Future<AppExitResponse> _handleExit() async {
    try {
      await ref.read(conversationsProvider.notifier).close();
    } catch (e) {
      debugPrint('Error while exiting ${e.toString()}');
    }

    return AppExitResponse.exit;
  }

  @override
  Widget build(BuildContext context) {
    final chatContainer = ChatContainer(controller: _chatContainerController);

    _chatContainerController.setChat(null);

    return DynamicColorBuilder(
      builder: (ColorScheme? light, ColorScheme? dark) {
        light = light ?? ColorScheme.fromSeed(seedColor: Color(0xFF00A1BC));
        dark = dark ?? ColorScheme.fromSeed(seedColor: Color(0xFF00A1BC));

        return MaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: light,
            scaffoldBackgroundColor: light.surface,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: dark,
            scaffoldBackgroundColor: dark.surface,
          ),
          home: Scaffold(
            appBar: AppBar(title: const Text('Turtagent Hub')),
            drawer: Drawer(
              child: ConversationsSidebar(
                chatContainerController: _chatContainerController,
              ),
            ),
            body: chatContainer,
          ),
        );
      },
    );
  }
}
