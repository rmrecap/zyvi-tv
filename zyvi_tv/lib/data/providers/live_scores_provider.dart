import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class LiveMatch {
  final String homeTeam;
  final String awayTeam;
  final String homeScore;
  final String awayScore;
  final String status;
  final String league;

  const LiveMatch({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.league,
  });

  factory LiveMatch.fromOpenLigaDB(Map<String, dynamic> json) {
    final team1 = json['Team1'] as Map<String, dynamic>? ?? {};
    final team2 = json['Team2'] as Map<String, dynamic>? ?? {};
    final results = json['MatchResults'] as List<dynamic>? ?? [];
    String homeScore = '-', awayScore = '-';
    for (final r in results) {
      final result = r as Map<String, dynamic>;
      if (result['ResultOrderID'] == 1) {
        homeScore = '${result['PointsTeam1'] ?? '-'}';
        awayScore = '${result['PointsTeam2'] ?? '-'}';
      }
    }
    final matchStatus = json['MatchStatus'] as Map<String, dynamic>? ?? {};
    return LiveMatch(
      homeTeam: team1['TeamName'] ?? 'Home',
      awayTeam: team2['TeamName'] ?? 'Away',
      homeScore: homeScore,
      awayScore: awayScore,
      status: matchStatus['ShortName'] ?? 'Scheduled',
      league: json['LeagueName'] ?? '',
    );
  }

  factory LiveMatch.fromMap(Map<String, dynamic> json) {
    return LiveMatch(
      homeTeam: json['homeTeam'] as String? ?? 'Home',
      awayTeam: json['awayTeam'] as String? ?? 'Away',
      homeScore: json['homeScore'] as String? ?? '-',
      awayScore: json['awayScore'] as String? ?? '-',
      status: json['status'] as String? ?? 'SCHEDULED',
      league: json['league'] as String? ?? '',
    );
  }
}

String countryFlag(String countryName) {
  const flags = {
    'Germany': '\u{1F1E9}\u{1F1EA}',
    'England': '\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}',
    'France': '\u{1F1EB}\u{1F1F7}',
    'Spain': '\u{1F1EA}\u{1F1F8}',
    'Italy': '\u{1F1EE}\u{1F1F9}',
    'Portugal': '\u{1F1F5}\u{1F1F9}',
    'Netherlands': '\u{1F1F3}\u{1F1F1}',
    'Belgium': '\u{1F1E7}\u{1F1EA}',
    'Brazil': '\u{1F1E7}\u{1F1F7}',
    'Argentina': '\u{1F1E6}\u{1F1F7}',
    'USA': '\u{1F1FA}\u{1F1F8}',
    'International': '\u{1F30D}',
  };
  for (final entry in flags.entries) {
    if (countryName.contains(entry.key)) return entry.value;
  }
  return '\u{26BD}';
}

final liveScoresProvider = FutureProvider<List<LiveMatch>>((ref) async {
  final results = <LiveMatch>[];
  const leagues = [
    'bl1', 'bl2', 'bl3',
    'pl', 'sa', 'pd', 'fl1',
    'fra1',
  ];
  for (final league in leagues) {
    try {
      final uri = Uri.parse(
          'https://api.openligadb.de/getmatchdata/$league/2026');
      final response = await uri
          .read(timeout: const Duration(seconds: 5));
      final List<dynamic> data = jsonDecode(response) as List<dynamic>;
      for (final item in data) {
        results.add(LiveMatch.fromOpenLigaDB(item as Map<String, dynamic>));
      }
    } catch (_) {}
  }
  results.sort((a, b) => a.league.compareTo(b.league));
  return results;
});

extension _UriRead on Uri {
  Future<String> read({Duration? timeout}) async {
    final client = http.Client();
    try {
      final response = await client.get(this).timeout(timeout ?? const Duration(seconds: 10));
      if (response.statusCode == 200) return response.body;
      return '[]';
    } finally {
      client.close();
    }
  }
}
