import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/balance.dart';
import 'package:habitbank/models/challenge.dart';
import 'package:habitbank/models/group.dart';
import 'package:habitbank/models/group_member.dart';
import 'package:habitbank/models/user_profile.dart';
import 'package:habitbank/models/workout_log.dart';
import 'package:habitbank/services/group_service.dart';
import 'package:habitbank/services/settlement_engine.dart';
import 'package:habitbank/services/workout_service.dart';
import 'package:habitbank/viewmodels/group_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

class _FakeGroupService extends Mock implements GroupService {}

class _FakeWorkoutService extends Mock implements WorkoutService {}

Group _g({String owner = 'me'}) => Group(
      id: 'g1',
      name: 'A',
      ownerId: owner,
      inviteCode: 'CODE12',
      createdAt: DateTime.utc(2026, 1, 1),
    );

GroupMember _m(String id, String name) => GroupMember(
      groupId: 'g1',
      userId: id,
      profile: UserProfile(id: id, name: name),
    );

void main() {
  test('progressForUser counts workouts in current week', () async {
    final gs = _FakeGroupService();
    final ws = _FakeWorkoutService();
    final week = currentIsoWeekUtc(DateTime.now().toUtc());

    when(() => gs.listMembers('g1'))
        .thenAnswer((_) async => [_m('me', 'Me'), _m('you', 'You')]);
    when(() => gs.listBalances('g1')).thenAnswer((_) async => <Balance>[]);
    when(() => gs.getChallenge('g1')).thenAnswer((_) async => Challenge(
          id: 'c1',
          groupId: 'g1',
          goalType: GoalType.workouts,
          goalTarget: 3,
          stakeCents: 100,
        ));
    when(() => ws.listForGroup('g1')).thenAnswer((_) async => [
          WorkoutLog(
            id: 'w1',
            userId: 'me',
            groupId: 'g1',
            durationMinutes: 30,
            workoutType: 'g',
            loggedAt: week.start.add(const Duration(hours: 5)),
          ),
          WorkoutLog(
            id: 'w2',
            userId: 'me',
            groupId: 'g1',
            durationMinutes: 45,
            workoutType: 'g',
            loggedAt: week.start.add(const Duration(days: 2)),
          ),
          WorkoutLog(
            id: 'w3',
            userId: 'me',
            groupId: 'g1',
            durationMinutes: 60,
            workoutType: 'g',
            loggedAt: week.start.subtract(const Duration(days: 2)),
          ),
        ]);

    final vm = GroupViewModel(
      groupService: gs,
      workoutService: ws,
      group: _g(),
      currentUserId: 'me',
    );
    await vm.load();

    expect(vm.members.length, 2);
    expect(vm.challenge?.goalTarget, 3);
    expect(vm.progressForUser('me'), 2);
    expect(vm.progressForUser('you'), 0);
    expect(vm.isOwner, isTrue);
  });

  test('non-owner cannot edit challenge', () async {
    final gs = _FakeGroupService();
    final ws = _FakeWorkoutService();
    final vm = GroupViewModel(
      groupService: gs,
      workoutService: ws,
      group: _g(owner: 'someone-else'),
      currentUserId: 'me',
    );
    await vm.updateChallenge(
        type: GoalType.workouts, target: 5, stakeCents: 200);
    verifyNever(() => gs.updateChallenge(
          groupId: any(named: 'groupId'),
          goalType: any(named: 'goalType'),
          goalTarget: any(named: 'goalTarget'),
          stakeCents: any(named: 'stakeCents'),
        ));
  });
}
