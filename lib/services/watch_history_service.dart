import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WatchEntry {
  final String id;
  final String name;
  final String? poster;
  final String url;
  final int positionMs;
  final int durationMs;
  final DateTime watchedAt;
  final String type; // 'movie' | 'live'

  WatchEntry({
    required this.id,
    required this.name,
    this.poster,
    required this.url,
    required this.positionMs,
    required this.durationMs,
    required this.watchedAt,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'poster': poster, 'url': url,
    'positionMs': positionMs, 'durationMs': durationMs,
    'watchedAt': watchedAt.toIso8601String(), 'type': type,
  };

  factory WatchEntry.fromJson(Map<String, dynamic> j) => WatchEntry(
    id: j['id'], name: j['name'], poster: j['poster'], url: j['url'],
    positionMs: j['positionMs'] ?? 0, durationMs: j['durationMs'] ?? 0,
    watchedAt: DateTime.parse(j['watchedAt']), type: j['type'] ?? 'movie',
  );

  double get progress => durationMs > 0 ? positionMs / durationMs : 0;
}

class WatchHistoryService {
  static const _key = 'watch_history';

  static Future<List<WatchEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => WatchEntry.fromJson(e)).toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
  }

  static Future<void> save(WatchEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((e) => e.id == entry.id);
    history.insert(0, entry);
    final trimmed = history.take(20).toList();
    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<WatchEntry?> get(String id) async {
    final history = await getHistory();
    try { return history.firstWhere((e) => e.id == id); } catch (_) { return null; }
  }
}
