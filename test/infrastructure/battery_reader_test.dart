import 'package:clock/clock.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unustasis/domain/scooter_battery.dart';
import 'package:unustasis/infrastructure/battery_reader.dart';

import 'battery_reader_test.mocks.dart';

@GenerateMocks([BluetoothCharacteristic, BehaviorSubject])
void main() {
  group('BatteryReader', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('readAndSubscribeSOC', () {
      test('reads state of charge', () async {
        var uint32 = [40, 0, 0, 0];
        var mockSocCharacteristic = buildCharacterWithValue(uint32);
        var mockSocController = BehaviorSubject<int?>();
        var lastPingController = BehaviorSubject<DateTime?>();

        BatteryReader batteryReader =
            BatteryReader(ScooterBattery.primary, lastPingController);

        await batteryReader.readAndSubscribeSOC(
            mockSocCharacteristic, mockSocController);

        verify(await mockSocCharacteristic.setNotifyValue(true)).called(1);
        verify(await mockSocCharacteristic.read()).called(1);
        expect(mockSocController.stream, emitsInOrder([40]));

        // writes cache
        var instance = await SharedPreferences.getInstance();
        expect(instance.getInt("primarySOC"), equals(40));
      });

      test('ignores state of charge value which does not have length of 4',
          () async {
        var uint32 = [0];
        var mockSocCharacteristic = buildCharacterWithValue(uint32);
        var mockSocController = BehaviorSubject<int?>();
        var lastPingController = BehaviorSubject<DateTime?>();

        BatteryReader batteryReader =
            BatteryReader(ScooterBattery.primary, lastPingController);

        await batteryReader.readAndSubscribeSOC(
            mockSocCharacteristic, mockSocController);

        expect(mockSocController.stream, emitsInOrder([]));
          });

      test('writes valid state of charge to cache', () async {
        var uint32 = [40, 0, 0, 0];
        var mockSocCharacteristic = buildCharacterWithValue(uint32);
        var socController = BehaviorSubject<int?>();
        var lastPingController = BehaviorSubject<DateTime?>();

        final fixedDate = DateTime(2024, 01, 01, 12, 00, 00);
        final fakeClock = Clock(() => fixedDate);

        withClock(fakeClock, () async {
          BatteryReader batteryReader =
              BatteryReader(ScooterBattery.primary, lastPingController);

          await batteryReader.readAndSubscribeSOC(
              mockSocCharacteristic, socController);

          // We wrap our test in a fakeAsync to control the time in called code
          expect(lastPingController.stream, emitsInOrder([fixedDate]));

          // writes cache
          var instance = await SharedPreferences.getInstance();
          expect(instance.getKeys(), equals({"primarySOC", "lastPing"}));
          expect(instance.getInt("primarySOC"), equals(40));
          expect(instance.getInt("lastPing"),
              equals(fixedDate.microsecondsSinceEpoch));
        });
      });

      test('reads from cache', () async {
        var uint32 = [0];
        var mockSocCharacteristic = buildCharacterWithValue(uint32);
        var socController = BehaviorSubject<int?>();
        var lastPingController = BehaviorSubject<DateTime?>();

        final fixedDate = DateTime(2024, 01, 01, 12, 00, 00);

        SharedPreferences.setMockInitialValues({
          "lastPing": fixedDate.microsecondsSinceEpoch,
          "primarySOC": 30,
        });

        BatteryReader batteryReader =
            BatteryReader(ScooterBattery.primary, lastPingController);

        await batteryReader.readAndSubscribeSOC(
            mockSocCharacteristic, socController);

        // We wrap our test in a fakeAsync to control the time in called code
        expect(socController.stream, emitsInOrder([30]));
        expect(lastPingController.stream, emitsInOrder([fixedDate]));
      });
    });
  });
}

MockBluetoothCharacteristic buildCharacterWithValue(List<int> stateAsByteList) {
  MockBluetoothCharacteristic mockCharacteristic =
      MockBluetoothCharacteristic();
  when(mockCharacteristic.setNotifyValue(any))
      .thenAnswer((_) => Future.value(true));
  when(mockCharacteristic.read()).thenAnswer((_) => Future.value([0]));
  when(mockCharacteristic.lastValueStream).thenAnswer((_) {
    return Stream.fromIterable([stateAsByteList]);
  });

  return mockCharacteristic;
}
