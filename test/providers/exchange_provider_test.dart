import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fake_repositories.dart';

/// Güç harcaması sunucuda başarılı olduktan sonra bakiye YEREL düşülür; sunucuya
/// tekrar gidilmez. Öncelik sunucuyla aynı (`tryUseInventory` → `spendPurple`):
/// envanterde hak varsa oradan, yoksa mor elmastan.
Future<ProviderContainer> _container({
  List<PowerInventoryItem> inventory = const [],
}) async {
  final container = ProviderContainer(overrides: [
    exchangeRepositoryProvider
        .overrideWithValue(FakeExchangeRepository(inventory: inventory)),
    userRepositoryProvider.overrideWithValue(FakeUserRepository(_user)),
  ]);
  addTearDown(container.dispose);
  await container.read(exchangeProvider.notifier).fetchAll();
  await container.read(userProvider.notifier).fetchMe();
  return container;
}

const _user = UserModel(
  id: 'u1',
  email: 'u1@qulo.test',
  purpleDiamonds: 50,
  greenDiamonds: 7,
);

int _purple(ProviderContainer c) =>
    c.read(userProvider).valueOrNull!.purpleDiamonds;

void main() {
  test('envanterde hak varken sayacı bir düşer, mor bakiyeye dokunmaz', () async {
    final c = await _container(
      inventory: const [PowerInventoryItem(powerName: 'ORACLE', count: 2)],
    );

    final fromInventory =
        c.read(exchangeProvider.notifier).settlePowerSpend('ORACLE', 15);

    expect(fromInventory, isTrue);
    expect(c.read(exchangeProvider).getCount('ORACLE'), 1);
    expect(_purple(c), 50);
  });

  test('envanter yokken moru maliyet kadar düşer', () async {
    final c = await _container();

    final fromInventory =
        c.read(exchangeProvider.notifier).settlePowerSpend('ORACLE', 15);

    expect(fromInventory, isFalse);
    expect(_purple(c), 35);
  });

  test('envanter sayacı sıfırsa mordan düşer', () async {
    final c = await _container(
      inventory: const [PowerInventoryItem(powerName: 'HALF', count: 0)],
    );

    c.read(exchangeProvider.notifier).settlePowerSpend('HALF', 10);

    expect(_purple(c), 40);
    expect(c.read(exchangeProvider).getCount('HALF'), 0);
  });

  test('başka gücün envanteri bu gücü ödemez', () async {
    final c = await _container(
      inventory: const [PowerInventoryItem(powerName: 'HALF', count: 3)],
    );

    c.read(exchangeProvider.notifier).settlePowerSpend('ORACLE', 15);

    expect(c.read(exchangeProvider).getCount('HALF'), 3);
    expect(_purple(c), 35);
  });

  test('aynı güç için birden fazla envanter satırında toplam bir azalır', () async {
    final c = await _container(inventory: const [
      PowerInventoryItem(powerName: 'HALF', count: 0),
      PowerInventoryItem(powerName: 'HALF', count: 2),
    ]);

    c.read(exchangeProvider.notifier).settlePowerSpend('HALF', 10);

    expect(c.read(exchangeProvider).getCount('HALF'), 1);
    expect(_purple(c), 50);
  });

  test('maliyet 0 ve envanter yoksa hiçbir şey değişmez', () async {
    final c = await _container();

    c.read(exchangeProvider.notifier).settlePowerSpend('ORACLE', 0);

    expect(_purple(c), 50);
  });
}
