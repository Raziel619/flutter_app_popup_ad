// ignore_for_file: non_constant_identifier_names

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

  factory AppInfo.fromJsonm(Map<String, dynamic> json) => _$AppInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AppInfoToJson(this);
}
