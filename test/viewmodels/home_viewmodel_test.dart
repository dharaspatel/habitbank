import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/models/balance.dart';
import 'package:habitbank/models/group.dart';
import 'package:habitbank/services/group_service.dart';
import 'package:habitbank/viewmodels/home_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

class _FakeGroupService extends Mock implements GroupService {}

Group _g(String id, String name) => Group(
      id: id,
      name: name,
      ownerId: 'me',
      inviteCode: 'AAAAAA',
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  test('load aggregates balance per group and total', () async {
    final svc = _FakeGroupService();
    when(() => svc.listMyGroups('me')).thenAnswer(
      (_) async => [_g('1', 'A'), _g('2', 'B')],
    );
    when(() => svc.listBalances('1')).thenAnswer(
      (_) async => [Balance(groupId: '1', userId: 'me', balance: 30)],
    );
    when(() => svc.listBalances('2')).thenAnswer(
      (_) async => [Balance(groupId: '2', userId: 'me', balance: -10)],
    );

    final vm = HomeViewModel(svc);
    await vm.load('me');

    expect(vm.groups.length, 2);
    expect(vm.balanceForGroup('1'), 30);
    expect(vm.balanceForGroup('2'), -10);
    expect(vm.totalBalance, 20);
    expect(vm.error, isNull);
  });

  test('load surfaces errors', () async {
    final svc = _FakeGroupService();
    when(() => svc.listMyGroups('me')).thenThrow(Exception('boom'));
    final vm = HomeViewModel(svc);
    await vm.load('me');
    expect(vm.error, contains('boom'));
    expect(vm.groups, isEmpty);
  });
}
