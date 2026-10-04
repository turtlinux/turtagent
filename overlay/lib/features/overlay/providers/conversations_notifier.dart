import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/nitrite_hive_adapter.dart';
import 'package:path/path.dart' as path;
import 'package:turtagent/core/data/models/chat_types.dart';
import 'package:turtagent/core/data/models/database_types.dart';

class _ConversationsNotifier extends AsyncNotifier<Conversations> {
  late Nitrite _db;

  @override
  Future<Conversations> build() async {
    final String? home = Platform.environment['HOME'];
    final String storageDir = '.local/share/turtagent/';
    final String dbDir = 'database/';
    final String filename = 'main';

    final String dbPath = path.join(home ?? '', storageDir, dbDir, filename);

    var storeModule = HiveModule.withConfig()
        .crashRecovery(true)
        .path(dbPath)
        .build();

    _db = await Nitrite.builder()
        .loadModule(storeModule)
        .registerEntityConverter(ConversationItemConverter())
        .registerEntityConverter(ChatMessageConverter())
        .registerEntityConverter(AssistantMessageConverter())
        .openOrCreate();

    return await getHistory(10);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => getHistory(10));
  }

  Future<Conversations> getHistory(int amountToLoad) async {
    final repository = await _db.getRepository<ConversationItem>(
      key: 'history',
    );
    final history = await repository
        .find(findOptions: FindOptions(limit: amountToLoad))
        .toList();
    history.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return history;
  }

  Future<void> addHistory(ConversationItem item) async {
    final currentHistory = state.valueOrNull ?? [];
    state = await AsyncValue.guard(() async {
      final repository = await _db.getRepository<ConversationItem>(
        key: 'history',
      );
      await repository.insert(item);
      await _db.commit();
      debugPrint('Successfully inserted item into repository.');
      return [item, ...currentHistory];
    });
  }

  Future<void> updateConversation(ConversationItem item) async {
    final currentHistory = state.valueOrNull ?? [];
    state = await AsyncValue.guard(() async {
      final repository = await _db.getRepository<ConversationItem>(
        key: 'history',
      );
      await repository.update(where('id').eq(item.id), item);
      await _db.commit();

      final updatedHistory = currentHistory.map((h) {
        if (h.id == item.id) {
          return item;
        }
        return h;
      }).toList();

      debugPrint('Successfully updated conversation.');

      return updatedHistory;
    });
  }

  Future<void> deleteConversation(ConversationItem item) async {
    final currentHistory = state.valueOrNull ?? [];
    state = await AsyncValue.guard(() async {
      final repository = await _db.getRepository<ConversationItem>(
        key: 'history',
      );
      await repository.removeOne(item);
      await _db.commit();
      currentHistory.remove(item);
      return currentHistory;
    });
  }

  Future<void> close() async {
    await _db.close();
  }
}

final conversationsProvider =
    AsyncNotifierProvider<_ConversationsNotifier, Conversations>(() {
      return _ConversationsNotifier();
    });
