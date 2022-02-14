// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppInfo _$AppInfoFromJson(Map<String, dynamic> json) => AppInfo(
      name: json['name'] as String,
      description: json['description'] as String,
      image_link: json['image_link'] as String,
      android_id: json['android_id'] as String,
      ios_link: json['ios_link'] as String? ?? '',
    );

Map<String, dynamic> _$AppInfoToJson(AppInfo instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'image_link': instance.image_link,
      'android_id': instance.android_id,
      'ios_link': instance.ios_link,
    };
