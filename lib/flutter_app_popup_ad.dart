// ignore_for_file: avoid_print

library flutter_app_popup_ad;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nice_buttons/nice_buttons.dart';
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

  Future<void> initializeWithUrl(String url, {int updateFreqDays = 1}) async {
    customPrint("Initializing");
    try {
      _prefs = await SharedPreferences.getInstance();
      if (canUpdateAds(updateFreqDays)) {
        customPrint("Calling URL to update ads");
        var response = await http.get(Uri.parse(url));

        // save apps and lastUpdated to local storage
        _apps = AppInfo.fromJsonList(response.body);
        await _prefs.setString(_lsKey.apps.toKeyString(), jsonEncode(_apps));
        await _prefs.setString(
            _lsKey.lastUpdated.toKeyString(), DateTime.now().toString());
      } else {
        customPrint("Loading ads from storage");
        // not enough time has passed to update, fetch from shared preferences
        _apps = AppInfo.fromJsonList(
            _prefs.getString(_lsKey.apps.toKeyString()) ?? '[]');
      }
      customPrint("Initialization Complete");
    } catch (e) {
      customPrint(e.toString());
    }
  }

  void initializeWithApps(List<AppInfo> apps) async {
    customPrint("Initializing");
    _prefs = await SharedPreferences.getInstance();
    _apps = apps;
    customPrint("Initialization Complete");
  }

  //endregion

  Future<void> determineAndShowAd(BuildContext context, {int freq = 0}) async {
    if (_apps.isEmpty) {
      customPrint("No app ads has been set, will do nothing");
      return;
    }
    final ad = _selectAdToShow();

    await showDialog(
        builder: (BuildContext context) {
          return SimpleDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            titlePadding: const EdgeInsets.all(0),
            title: Column(
              children: [
                Image.network(
                  ad.image_link,
                  width: MediaQuery.of(context).size.width,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    ad.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: downloadBtn(ad),
                ),
              ],
            ),
          );
        },
        context: context);
  }

  //region Widgets

  Widget openBtn(AppInfo app){
    return NiceButtons(
      stretch: true,
      gradientOrientation: GradientOrientation.Horizontal,
      onTap: (finish) {
        print('On tap called');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: const [
            Icon(Icons.open_in_new, color: Colors.white, size: 32),
            Expanded(child: SizedBox.shrink(),),
            Text(
              'Open',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            Expanded(child: SizedBox.shrink(),),
          ],
        ),
      ),
    );
  }

  Widget downloadBtn(AppInfo app){
    return NiceButtons(
      startColor: Color(0xFFF00B51),
      endColor: Color(0xFF780061),
      borderColor: Color(0xFF780061),
      stretch: true,
      gradientOrientation: GradientOrientation.Horizontal,
      onTap: (finish) {
        print('On tap called');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: const [
            Icon(Icons.download, color: Colors.white, size: 32),
            Expanded(child: SizedBox.shrink(),),
            Text(
              'Download',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            Expanded(child: SizedBox.shrink(),),
          ],
        ),
      ),
    );
  }

  //endregion

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

  void customPrint(String message) {
    print("FlutterAppPopupAd - $message");
  }

  AppInfo _selectAdToShow() {
    var lastApp = _prefs.getInt(_lsKey.lastShownAd.toKeyString()) ?? 0;
    lastApp = lastApp >= _apps.length ? 0 : lastApp;
    _prefs.setInt(_lsKey.lastShownAd.toKeyString(), lastApp + 1);
    return _apps[lastApp];
  }
//endregion
}
