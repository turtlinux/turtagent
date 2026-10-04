import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turtagent/core/data/models/database_types.dart';
import 'package:turtagent/features/overlay/data/agent_rpc_service.dart';
import 'package:turtagent/features/overlay/presentation/input_overlay.dart';
import 'package:turtagent/features/overlay/presentation/response_overlay.dart';
import 'package:turtagent/features/overlay/providers/conversations_notifier.dart';
import 'package:uuid/uuid.dart';

class AgentOverlay extends ConsumerStatefulWidget {
  const AgentOverlay({super.key});

  @override
  ConsumerState<AgentOverlay> createState() => _AgentOverlayState();
}

class _AgentOverlayState extends ConsumerState<AgentOverlay> {
  bool _showResponseOverlay = false;
  final _agentRpcService = AgentRpcService();
  late Stream<({bool isThinking, String text})> _responseStream;
  final _inputOverlayController = InputOverlayController();
  late ConversationItem _currentChat;
  String? _latestAssistantMessage;
  final _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _createNewChat();
  }

  void _createNewChat() async {
    _currentChat = ConversationItem(
      id: _uuid.v4(),
      title: 'Untitled Chat',
      history: [],
      lastUpdated: DateTime.now(),
    );
    await ref.read(conversationsProvider.notifier).addHistory(_currentChat);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showResponseOverlay)
          ResponseOverlay(responseStream: _responseStream),
        InputOverlay(
          onPrompt: _onPrompt,
          inputOverlayController: _inputOverlayController,
          onStop: _onStop,
        ),
      ],
    );
  }

  void _onPrompt(String prompt) async {
    setState(() {
      _showResponseOverlay = true;

      _responseStream = _agentRpcService
          .streamPrompt(prompt)
          .asBroadcastStream();
      _responseStream.listen(
        (data) {
          _latestAssistantMessage = _latestAssistantMessage != null
              ? (_latestAssistantMessage as String) + data.text
              : data.text;
        },
        onDone: () => _onDone(),
        onError: (_) => _onDone(),
        cancelOnError: true,
      );

      _currentChat.history.add(
        ChatMessage(
          assistant: AssistantMessage(isThinking: false, text: ''),
          user: prompt,
        ),
      );
    });

    await ref.read(conversationsProvider.notifier).addHistory(_currentChat);
  }

  void _onStop() async {
    _agentRpcService.cancelCurrentStream();
    await _saveAssistantMessage();
  }

  void _onDone() async {
    _inputOverlayController.onEnd?.call();
    await _saveAssistantMessage();
  }

  Future<void> _saveAssistantMessage() async {
    _currentChat.history[_currentChat.history.length - 1].assistant.text =
        _latestAssistantMessage ?? '';
    debugPrint(
      'Assistant message: ${_currentChat.history[_currentChat.history.length - 1].assistant.text}',
    );
    _currentChat.lastUpdated = DateTime.now();
    await ref
        .read(conversationsProvider.notifier)
        .updateConversation(_currentChat);
  }
}
