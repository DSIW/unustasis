import 'dart:developer';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unustasis/infrastructure/utils.dart';

class StateOfChargeReader {
  final String _name;
  final BluetoothCharacteristic? _socCharacteristic;
  final BehaviorSubject<int?> _socController;
  final SharedPreferences _sharedPrefs;

  StateOfChargeReader(this._name, this._socCharacteristic, this._socController, this._sharedPrefs);

  readAndSubscribe(Function() ping) {
    _socCharacteristic!.setNotifyValue(true);
    _socCharacteristic.lastValueStream.listen((value) async {
      int? soc = convertUint32ToInt(value);
      log("$_name SOC received: $soc");
      _socController.add(soc);
      if (soc != null) {
        ping();
        _sharedPrefs.setInt("${_name}SOC", soc);
      }
    });

    _socCharacteristic.read();
  }
}
