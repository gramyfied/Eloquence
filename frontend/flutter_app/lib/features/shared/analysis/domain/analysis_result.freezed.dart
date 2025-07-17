// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) {
  return _AnalysisResult.fromJson(json);
}

/// @nodoc
mixin _$AnalysisResult {
  String get exerciseType => throw _privateConstructorUsedError;
  String get transcription => throw _privateConstructorUsedError;
  Map<String, dynamic> get recognitionDetails =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> get analysis => throw _privateConstructorUsedError;
  double get processingTimeMs => throw _privateConstructorUsedError;
  bool get isError => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this AnalysisResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalysisResultCopyWith<AnalysisResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalysisResultCopyWith<$Res> {
  factory $AnalysisResultCopyWith(
          AnalysisResult value, $Res Function(AnalysisResult) then) =
      _$AnalysisResultCopyWithImpl<$Res, AnalysisResult>;
  @useResult
  $Res call(
      {String exerciseType,
      String transcription,
      Map<String, dynamic> recognitionDetails,
      Map<String, dynamic> analysis,
      double processingTimeMs,
      bool isError,
      String? errorMessage});
}

/// @nodoc
class _$AnalysisResultCopyWithImpl<$Res, $Val extends AnalysisResult>
    implements $AnalysisResultCopyWith<$Res> {
  _$AnalysisResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseType = null,
    Object? transcription = null,
    Object? recognitionDetails = null,
    Object? analysis = null,
    Object? processingTimeMs = null,
    Object? isError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      exerciseType: null == exerciseType
          ? _value.exerciseType
          : exerciseType // ignore: cast_nullable_to_non_nullable
              as String,
      transcription: null == transcription
          ? _value.transcription
          : transcription // ignore: cast_nullable_to_non_nullable
              as String,
      recognitionDetails: null == recognitionDetails
          ? _value.recognitionDetails
          : recognitionDetails // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      analysis: null == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      processingTimeMs: null == processingTimeMs
          ? _value.processingTimeMs
          : processingTimeMs // ignore: cast_nullable_to_non_nullable
              as double,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AnalysisResultImplCopyWith<$Res>
    implements $AnalysisResultCopyWith<$Res> {
  factory _$$AnalysisResultImplCopyWith(_$AnalysisResultImpl value,
          $Res Function(_$AnalysisResultImpl) then) =
      __$$AnalysisResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String exerciseType,
      String transcription,
      Map<String, dynamic> recognitionDetails,
      Map<String, dynamic> analysis,
      double processingTimeMs,
      bool isError,
      String? errorMessage});
}

/// @nodoc
class __$$AnalysisResultImplCopyWithImpl<$Res>
    extends _$AnalysisResultCopyWithImpl<$Res, _$AnalysisResultImpl>
    implements _$$AnalysisResultImplCopyWith<$Res> {
  __$$AnalysisResultImplCopyWithImpl(
      _$AnalysisResultImpl _value, $Res Function(_$AnalysisResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseType = null,
    Object? transcription = null,
    Object? recognitionDetails = null,
    Object? analysis = null,
    Object? processingTimeMs = null,
    Object? isError = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$AnalysisResultImpl(
      exerciseType: null == exerciseType
          ? _value.exerciseType
          : exerciseType // ignore: cast_nullable_to_non_nullable
              as String,
      transcription: null == transcription
          ? _value.transcription
          : transcription // ignore: cast_nullable_to_non_nullable
              as String,
      recognitionDetails: null == recognitionDetails
          ? _value._recognitionDetails
          : recognitionDetails // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      analysis: null == analysis
          ? _value._analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      processingTimeMs: null == processingTimeMs
          ? _value.processingTimeMs
          : processingTimeMs // ignore: cast_nullable_to_non_nullable
              as double,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisResultImpl implements _AnalysisResult {
  const _$AnalysisResultImpl(
      {required this.exerciseType,
      required this.transcription,
      required final Map<String, dynamic> recognitionDetails,
      required final Map<String, dynamic> analysis,
      required this.processingTimeMs,
      this.isError = false,
      this.errorMessage})
      : _recognitionDetails = recognitionDetails,
        _analysis = analysis;

  factory _$AnalysisResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisResultImplFromJson(json);

  @override
  final String exerciseType;
  @override
  final String transcription;
  final Map<String, dynamic> _recognitionDetails;
  @override
  Map<String, dynamic> get recognitionDetails {
    if (_recognitionDetails is EqualUnmodifiableMapView)
      return _recognitionDetails;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_recognitionDetails);
  }

  final Map<String, dynamic> _analysis;
  @override
  Map<String, dynamic> get analysis {
    if (_analysis is EqualUnmodifiableMapView) return _analysis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_analysis);
  }

  @override
  final double processingTimeMs;
  @override
  @JsonKey()
  final bool isError;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'AnalysisResult(exerciseType: $exerciseType, transcription: $transcription, recognitionDetails: $recognitionDetails, analysis: $analysis, processingTimeMs: $processingTimeMs, isError: $isError, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisResultImpl &&
            (identical(other.exerciseType, exerciseType) ||
                other.exerciseType == exerciseType) &&
            (identical(other.transcription, transcription) ||
                other.transcription == transcription) &&
            const DeepCollectionEquality()
                .equals(other._recognitionDetails, _recognitionDetails) &&
            const DeepCollectionEquality().equals(other._analysis, _analysis) &&
            (identical(other.processingTimeMs, processingTimeMs) ||
                other.processingTimeMs == processingTimeMs) &&
            (identical(other.isError, isError) || other.isError == isError) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      exerciseType,
      transcription,
      const DeepCollectionEquality().hash(_recognitionDetails),
      const DeepCollectionEquality().hash(_analysis),
      processingTimeMs,
      isError,
      errorMessage);

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisResultImplCopyWith<_$AnalysisResultImpl> get copyWith =>
      __$$AnalysisResultImplCopyWithImpl<_$AnalysisResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalysisResultImplToJson(
      this,
    );
  }
}

abstract class _AnalysisResult implements AnalysisResult {
  const factory _AnalysisResult(
      {required final String exerciseType,
      required final String transcription,
      required final Map<String, dynamic> recognitionDetails,
      required final Map<String, dynamic> analysis,
      required final double processingTimeMs,
      final bool isError,
      final String? errorMessage}) = _$AnalysisResultImpl;

  factory _AnalysisResult.fromJson(Map<String, dynamic> json) =
      _$AnalysisResultImpl.fromJson;

  @override
  String get exerciseType;
  @override
  String get transcription;
  @override
  Map<String, dynamic> get recognitionDetails;
  @override
  Map<String, dynamic> get analysis;
  @override
  double get processingTimeMs;
  @override
  bool get isError;
  @override
  String? get errorMessage;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisResultImplCopyWith<_$AnalysisResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
