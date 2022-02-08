// ignore_for_file: avoid_print

library flutter_app_popup_ad;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_info.dart';

enum _lsKey {
  apps,
  lastUpdated,
  lastShownAd,
}

extension _LsKeyExtension on _lsKey {
  String toKeyString() {
    return "FlutterPopUpAd$this";
  }
}

class FlutterAppPopupAd {
  // ignore: prefer_final_fields
  List<AppInfo> _apps = [];
  String thisAppId = '';
  late SharedPreferences _prefs;

  List<AppInfo> get apps => _apps;

  //region Initializers

  Future<void> initializeWithUrl(String url, {int updateFreqDays = 0}) async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (canUpdateAds(updateFreqDays)) {
        var response = await http.get(Uri.parse(url));

        // save apps and lastUpdated to local storage
        _apps = AppInfo.fromJsonList(response.body);
        await _prefs.setString(_lsKey.apps.toKeyString(), jsonEncode(_apps));
        await _prefs.setString(
            _lsKey.lastUpdated.toKeyString(), DateTime.now().toString());
      } else {
        // not enough time has passed to update, fetch from shared preferences
        _apps = AppInfo.fromJsonList(
            _prefs.getString(_lsKey.apps.toKeyString()) ?? '[]');
      }
    } catch (e) {
      print("FlutterAppPopupAd - ${e.toString()}");
    }
  }

  void initializeWithApps(List<AppInfo> apps) async {
    _prefs = await SharedPreferences.getInstance();
    _apps = apps;
  }

  //endregion

  void determineAndShowAd({int freq = 0}) {}

  //region Helper methods

  bool canShowAd(int freq) {
    var counter = (_prefs.getInt(_lsKey.lastShownAd.toKeyString()) ?? 0) + 1;
    return counter >= freq;
  }

  bool canUpdateAds(int updateFreqDays) {
    final lastUpdatedString =
        _prefs.getString(_lsKey.lastUpdated.toKeyString());
    if (lastUpdatedString == null) return true;

    final lastUpdated = DateTime.parse(lastUpdatedString);
    final nextDate = lastUpdated.add(Duration(days: updateFreqDays));
    return DateTime.now().isAfter(nextDate);
  }
//endregion
}
