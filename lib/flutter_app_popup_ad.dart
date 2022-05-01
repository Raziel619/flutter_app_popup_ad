// ignore_for_file: avoid_print

library flutter_app_popup_ad;

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:nice_buttons/nice_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_info.dart';

enum _lsKey {
  apps,
  freqCounter,
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

  /// Fetches a list of apps to be advertised from the URL (Get), set updateFreqDays to limit the
  /// http calls. Ensure that the response matches the AppInfo model otherwise this will fail.
  /// Alternative is to use initializeWithApps if you would like the pass the data in directly
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

  /// Initializes the package with a list of apps that you would like to advertise
  /// Alternative is to use initializeWithUrl if you wish to fetch app via a public URL
  void initializeWithApps(List<AppInfo> apps) async {
    customPrint("Initializing");
    _prefs = await SharedPreferences.getInstance();
    _apps = apps;
    customPrint("Initialization Complete");
  }

  //endregion

  /// Determines the next app ad to be shown and shows it via a showDialog
  /// `freq` - sets the number of times the app must be opened to show the next ad.
  /// If set to 0, an ad will be shown everytime the `determineAndShowAd` method is called
  Future<void> determineAndShowAd(BuildContext context, {int freq = 0}) async {
    // validations
    if (!canShowAd(freq)){
      return;
    }
    if (_apps.isEmpty) {
      customPrint("No app ads has been set, will do nothing");
      return;
    }
    final ad = _selectAdToShow();
    if(Platform.isIOS && ad.ios_link.isEmpty){
      customPrint("Invalid ios_link, will do nothing");
      return;
    }
    if(ad.android_id == thisAppId){
      customPrint("Package name is the same as thisAppId, will do nothing");
      return;
    }
    final _isAppInstalled = await FlutterAppPopupAd.isAppInstalled(ad);

    // popping dialog
    await showDialog(
        builder: (BuildContext context) {
          return SimpleDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            titlePadding: const EdgeInsets.all(0),
            title: Column(
              children: [
                CachedNetworkImage(
                  imageUrl: ad.image_link,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: _isAppInstalled ? _openBtn(ad) : _downloadBtn(ad),
                ),
              ],
            ),
          );
        },
        context: context);
  }

  //region Widgets

  Widget _openBtn(AppInfo app) {
    return NiceButtons(
      stretch: true,
      gradientOrientation: GradientOrientation.Horizontal,
      onTap: (finish) async {
        if (Platform.isAndroid) {
          await LaunchApp.openApp(androidPackageName: app.android_id);
        } else if (Platform.isIOS) {
          await launch(app.ios_link);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: const [
            Icon(Icons.open_in_new, color: Colors.white, size: 32),
            Expanded(
              child: SizedBox.shrink(),
            ),
            Text(
              'Open',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            Expanded(
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadBtn(AppInfo app) {
    return NiceButtons(
      startColor: const Color(0xFFF00B51),
      endColor: const Color(0xFF780061),
      borderColor: const Color(0xFF780061),
      stretch: true,
      gradientOrientation: GradientOrientation.Horizontal,
      onTap: (finish) async {
        if (Platform.isAndroid) {
          await LaunchApp.openApp(androidPackageName: app.android_id);
        } else if (Platform.isIOS) {
          await launch(app.ios_link);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: const [
            Icon(Icons.download, color: Colors.white, size: 32),
            Expanded(
              child: SizedBox.shrink(),
            ),
            Text(
              'Download',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            Expanded(
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  //endregion

  //region Helper methods

  bool canShowAd(int freq) {
    var counter = (_prefs.getInt(_lsKey.freqCounter.toKeyString()) ?? 0) + 1;
    if (counter >= freq){
      _prefs.setInt(_lsKey.freqCounter.toKeyString(), 0);
      return true;
    }
    _prefs.setInt(_lsKey.freqCounter.toKeyString(), counter);
    return false;
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

  static Future<bool> isAppInstalled(AppInfo app) async {
    if (Platform.isAndroid) {
      return await LaunchApp.isAppInstalled(androidPackageName: app.android_id);
    } else if (Platform.isIOS) {
      return true;
    } else {
      return false;
    }
  }

  AppInfo _selectAdToShow() {
    var lastApp = _prefs.getInt(_lsKey.lastShownAd.toKeyString()) ?? 0;
    lastApp = (lastApp >= _apps.length) ? 0 : lastApp;
    _prefs.setInt(_lsKey.lastShownAd.toKeyString(), lastApp + 1);
    return _apps[lastApp];
  }
//endregion
}
