// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConfidenceConfigImpl _$$ConfidenceConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$ConfidenceConfigImpl(
      scenario:
          ConfidenceScenario.fromJson(json['scenario'] as Map<String, dynamic>),
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      expectedDuration: (json['expectedDuration'] as num?)?.toInt() ?? 60,
      additionalParams:
          json['additionalParams'] as Map<String, dynamic>? ?? const {},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ConfidenceConfigImplToJson(
        _$ConfidenceConfigImpl instance) =>
    <String, dynamic>{
      'scenario': instance.scenario,
      'keywords': instance.keywords,
      'expectedDuration': instance.expectedDuration,
      'additionalParams': instance.additionalParams,
      'runtimeType': instance.$type,
    };

_$PronunciationConfigImpl _$$PronunciationConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$PronunciationConfigImpl(
      targetText: json['targetText'] as String,
      language: json['language'] as String,
      accuracyThreshold: (json['accuracyThreshold'] as num?)?.toDouble() ?? 0.8,
      additionalParams:
          json['additionalParams'] as Map<String, dynamic>? ?? const {},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PronunciationConfigImplToJson(
        _$PronunciationConfigImpl instance) =>
    <String, dynamic>{
      'targetText': instance.targetText,
      'language': instance.language,
      'accuracyThreshold': instance.accuracyThreshold,
      'additionalParams': instance.additionalParams,
      'runtimeType': instance.$type,
    };

_$FluencyConfigImpl _$$FluencyConfigImplFromJson(Map<String, dynamic> json) =>
    _$FluencyConfigImpl(
      topic: json['topic'] as String,
      targetDuration: (json['targetDuration'] as num).toInt(),
      targetWordsPerMinute:
          (json['targetWordsPerMinute'] as num?)?.toInt() ?? 120,
      additionalParams:
          json['additionalParams'] as Map<String, dynamic>? ?? const {},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$FluencyConfigImplToJson(_$FluencyConfigImpl instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'targetDuration': instance.targetDuration,
      'targetWordsPerMinute': instance.targetWordsPerMinute,
      'additionalParams': instance.additionalParams,
      'runtimeType': instance.$type,
    };
