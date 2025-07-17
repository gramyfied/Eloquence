// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnalysisResultImpl _$$AnalysisResultImplFromJson(Map<String, dynamic> json) =>
    _$AnalysisResultImpl(
      exerciseType: json['exerciseType'] as String,
      transcription: json['transcription'] as String,
      recognitionDetails: json['recognitionDetails'] as Map<String, dynamic>,
      analysis: json['analysis'] as Map<String, dynamic>,
      processingTimeMs: (json['processingTimeMs'] as num).toDouble(),
      isError: json['isError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$AnalysisResultImplToJson(
        _$AnalysisResultImpl instance) =>
    <String, dynamic>{
      'exerciseType': instance.exerciseType,
      'transcription': instance.transcription,
      'recognitionDetails': instance.recognitionDetails,
      'analysis': instance.analysis,
      'processingTimeMs': instance.processingTimeMs,
      'isError': instance.isError,
      'errorMessage': instance.errorMessage,
    };
