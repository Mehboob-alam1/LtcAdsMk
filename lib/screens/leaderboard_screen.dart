import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../models/leaderboard_entry.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_gradients.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1A1A2E),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey.shade700,
        ),
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: DatabaseService.instance.getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No miners yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          final top3 = list.take(3).toList();
          final rest = list.length > 3 ? list.sublist(3, list.length > 53 ? 53 : list.length) : <LeaderboardEntry>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const SizedBox(height: 8),
              Text(
                'Top Miners by Balance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _TopThreeCards(entries: top3, currentUid: currentUid),
              const SizedBox(height: 24),
              if (rest.isNotEmpty) ...[
                Text(
                  'All rankings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                ...rest.map((e) => _LeaderboardListTile(
                  entry: e,
                  isCurrentUser: e.uid == currentUid,
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TopThreeCards extends StatelessWidget {
  const _TopThreeCards({required this.entries, this.currentUid});

  final List<LeaderboardEntry> entries;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    // Podium order: 2nd (left), 1st (center), 3rd (right)
    final second = entries.length > 1 ? entries[1] : null;
    final first = entries.isNotEmpty ? entries[0] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: second != null ? _PodiumCard(entry: second, place: 2, isCurrentUser: second.uid == currentUid) : const SizedBox(height: 140)),
        const SizedBox(width: 10),
        Expanded(child: first != null ? _PodiumCard(entry: first, place: 1, isCurrentUser: first.uid == currentUid) : const SizedBox(height: 140)),
        const SizedBox(width: 10),
        Expanded(child: third != null ? _PodiumCard(entry: third, place: 3, isCurrentUser: third.uid == currentUid) : const SizedBox(height: 140)),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry, required this.place, this.isCurrentUser = false});

  final LeaderboardEntry entry;
  final int place;
  final bool isCurrentUser;

  static const _placeColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFC0C0C0), // silver
    Color(0xFFCD7F32), // bronze
  ];
  static const _placeGradients = [
    LinearGradient(colors: [Color(0xFFFFE55C), Color(0xFFF7931A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFE8E8E8), Color(0xFFA8A8A8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFFE8A857), Color(0xFF8B4513)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  @override
  Widget build(BuildContext context) {
    final color = place <= 3 ? _placeColors[place - 1] : Colors.grey;
    final gradient = place <= 3 ? _placeGradients[place - 1] : null;
    final height = place == 1 ? 180.0 : (place == 2 ? 160.0 : 150.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient != null ? color : Colors.grey).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$place',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${MiningConstants.formatBtcFull(entry.balanceBtc)} BTC',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardListTile extends StatelessWidget {
  const _LeaderboardListTile({required this.entry, this.isCurrentUser = false});

  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFE8E0FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser ? Border.all(color: const Color(0xFF9B4DCC).withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrentUser)
                  const Text('You', style: TextStyle(fontSize: 11, color: Color(0xFF7B47C6), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            '${MiningConstants.formatBtcFull(entry.balanceBtc)} BTC',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF2E123B),
            ),
          ),
        ],
      ),
    );
  }
}
