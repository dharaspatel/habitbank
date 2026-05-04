import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/group_member.dart';
import '../models/workout_log.dart';
import '../widgets/app_card.dart';
import '../widgets/shimmer.dart';

/// Full-screen activity feed for a group. Receives an already-loaded list
/// of [logs] + [members] from [GroupViewModel] so this screen never refetches
/// — it just renders. Pull-to-refresh on the parent screen reloads the data.
class GroupFeedScreen extends StatelessWidget {
  const GroupFeedScreen({
    super.key,
    required this.groupName,
    required this.logs,
    required this.members,
    this.onLogWorkout,
  });

  final String groupName;
  final List<WorkoutLog> logs;
  final List<GroupMember> members;
  final VoidCallback? onLogWorkout;

  String _nameFor(String userId) {
    for (final m in members) {
      if (m.userId == userId) {
        return m.profile.name.isEmpty ? 'Member' : m.profile.name;
      }
    }
    return 'Member';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.background,
        border: null,
        previousPageTitle: groupName,
        middle: const Text('Feed'),
        trailing: onLogWorkout == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onLogWorkout,
                child: const Icon(CupertinoIcons.add,
                    color: AppTheme.foreground),
              ),
      ),
      child: SafeArea(
        child: logs.isEmpty
            ? Center(
                child: Text(
                  'No workouts logged yet.',
                  style: AppTheme.body.copyWith(color: AppTheme.muted),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _FeedCard(
                  log: logs[i],
                  memberName: _nameFor(logs[i].userId),
                ),
              ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.log, required this.memberName});
  final WorkoutLog log;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.MMMd().add_jm().format(log.loggedAt.toLocal());
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(memberName,
                    style: AppTheme.body
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(time, style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: 8),
          if (log.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  log.photoUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Shimmer();
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.subtle,
                    alignment: Alignment.center,
                    child: const Icon(CupertinoIcons.photo,
                        color: AppTheme.muted),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.subtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(CupertinoIcons.camera, color: AppTheme.muted),
            ),
          if (log.durationMinutes > 0) ...[
            const SizedBox(height: 8),
            Text('${log.durationMinutes} min', style: AppTheme.caption),
          ],
        ],
      ),
    );
  }
}
