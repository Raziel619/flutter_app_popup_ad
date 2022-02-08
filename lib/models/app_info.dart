// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

part 'app_info.g.dart';

@JsonSerializable()
class AppInfo {
  final String name;
  final String description;
  final String image_link;

  // final String android_id;
  // final String ios_id;

  AppInfo(this.name, this.description, this.image_link);

  factory AppInfo.fromJson(Map<String, dynamic> json) =>
      _$AppInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AppInfoToJson(this);

  static List<AppInfo> fromJsonList(String jsonString) {
    final map = jsonDecode(jsonString);

    return (map as List)
        .map((e) => AppInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
