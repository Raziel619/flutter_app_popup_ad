import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

part 'app_info.g.dart';

@JsonSerializable()
class AppInfo {
  final String name;
  final String description;
  final String image_link;
  final String android_id;
  final String ios_id;

  AppInfo(this.name, this.description, this.image_link, this.android_id,
      this.ios_id);
}
