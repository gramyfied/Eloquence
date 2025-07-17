// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseConfig _$ExerciseConfigFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'confidence':
      return ConfidenceConfig.fromJson(json);
    case 'pronunciation':
      return PronunciationConfig.fromJson(json);
    case 'fluency':
      return FluencyConfig.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'ExerciseConfig',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$ExerciseConfig {
  Map<String, dynamic> get additionalParams =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            ConfidenceScenario scenario,
            List<String> keywords,
            int expectedDuration,
            Map<String, dynamic> additionalParams)
        confidence,
    required TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)
        pronunciation,
    required TResult Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)
        fluency,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult? Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult? Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)?
        fluency,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult Function(String topic, int targetDuration, int targetWordsPerMinute,
            Map<String, dynamic> additionalParams)?
        fluency,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConfidenceConfig value) confidence,
    required TResult Function(PronunciationConfig value) pronunciation,
    required TResult Function(FluencyConfig value) fluency,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceConfig value)? confidence,
    TResult? Function(PronunciationConfig value)? pronunciation,
    TResult? Function(FluencyConfig value)? fluency,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConfidenceConfig value)? confidence,
    TResult Function(PronunciationConfig value)? pronunciation,
    TResult Function(FluencyConfig value)? fluency,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ExerciseConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseConfigCopyWith<ExerciseConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseConfigCopyWith<$Res> {
  factory $ExerciseConfigCopyWith(
          ExerciseConfig value, $Res Function(ExerciseConfig) then) =
      _$ExerciseConfigCopyWithImpl<$Res, ExerciseConfig>;
  @useResult
  $Res call({Map<String, dynamic> additionalParams});
}

/// @nodoc
class _$ExerciseConfigCopyWithImpl<$Res, $Val extends ExerciseConfig>
    implements $ExerciseConfigCopyWith<$Res> {
  _$ExerciseConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? additionalParams = null,
  }) {
    return _then(_value.copyWith(
      additionalParams: null == additionalParams
          ? _value.additionalParams
          : additionalParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConfidenceConfigImplCopyWith<$Res>
    implements $ExerciseConfigCopyWith<$Res> {
  factory _$$ConfidenceConfigImplCopyWith(_$ConfidenceConfigImpl value,
          $Res Function(_$ConfidenceConfigImpl) then) =
      __$$ConfidenceConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ConfidenceScenario scenario,
      List<String> keywords,
      int expectedDuration,
      Map<String, dynamic> additionalParams});
}

/// @nodoc
class __$$ConfidenceConfigImplCopyWithImpl<$Res>
    extends _$ExerciseConfigCopyWithImpl<$Res, _$ConfidenceConfigImpl>
    implements _$$ConfidenceConfigImplCopyWith<$Res> {
  __$$ConfidenceConfigImplCopyWithImpl(_$ConfidenceConfigImpl _value,
      $Res Function(_$ConfidenceConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scenario = null,
    Object? keywords = null,
    Object? expectedDuration = null,
    Object? additionalParams = null,
  }) {
    return _then(_$ConfidenceConfigImpl(
      scenario: null == scenario
          ? _value.scenario
          : scenario // ignore: cast_nullable_to_non_nullable
              as ConfidenceScenario,
      keywords: null == keywords
          ? _value._keywords
          : keywords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      expectedDuration: null == expectedDuration
          ? _value.expectedDuration
          : expectedDuration // ignore: cast_nullable_to_non_nullable
              as int,
      additionalParams: null == additionalParams
          ? _value._additionalParams
          : additionalParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConfidenceConfigImpl implements ConfidenceConfig {
  const _$ConfidenceConfigImpl(
      {required this.scenario,
      final List<String> keywords = const [],
      this.expectedDuration = 60,
      final Map<String, dynamic> additionalParams = const {},
      final String? $type})
      : _keywords = keywords,
        _additionalParams = additionalParams,
        $type = $type ?? 'confidence';

  factory _$ConfidenceConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConfidenceConfigImplFromJson(json);

  @override
  final ConfidenceScenario scenario;
  final List<String> _keywords;
  @override
  @JsonKey()
  List<String> get keywords {
    if (_keywords is EqualUnmodifiableListView) return _keywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keywords);
  }

  @override
  @JsonKey()
  final int expectedDuration;
  final Map<String, dynamic> _additionalParams;
  @override
  @JsonKey()
  Map<String, dynamic> get additionalParams {
    if (_additionalParams is EqualUnmodifiableMapView) return _additionalParams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_additionalParams);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ExerciseConfig.confidence(scenario: $scenario, keywords: $keywords, expectedDuration: $expectedDuration, additionalParams: $additionalParams)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConfidenceConfigImpl &&
            (identical(other.scenario, scenario) ||
                other.scenario == scenario) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords) &&
            (identical(other.expectedDuration, expectedDuration) ||
                other.expectedDuration == expectedDuration) &&
            const DeepCollectionEquality()
                .equals(other._additionalParams, _additionalParams));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      scenario,
      const DeepCollectionEquality().hash(_keywords),
      expectedDuration,
      const DeepCollectionEquality().hash(_additionalParams));

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConfidenceConfigImplCopyWith<_$ConfidenceConfigImpl> get copyWith =>
      __$$ConfidenceConfigImplCopyWithImpl<_$ConfidenceConfigImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            ConfidenceScenario scenario,
            List<String> keywords,
            int expectedDuration,
            Map<String, dynamic> additionalParams)
        confidence,
    required TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)
        pronunciation,
    required TResult Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)
        fluency,
  }) {
    return confidence(scenario, keywords, expectedDuration, additionalParams);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult? Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult? Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)?
        fluency,
  }) {
    return confidence?.call(
        scenario, keywords, expectedDuration, additionalParams);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult Function(String topic, int targetDuration, int targetWordsPerMinute,
            Map<String, dynamic> additionalParams)?
        fluency,
    required TResult orElse(),
  }) {
    if (confidence != null) {
      return confidence(scenario, keywords, expectedDuration, additionalParams);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConfidenceConfig value) confidence,
    required TResult Function(PronunciationConfig value) pronunciation,
    required TResult Function(FluencyConfig value) fluency,
  }) {
    return confidence(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceConfig value)? confidence,
    TResult? Function(PronunciationConfig value)? pronunciation,
    TResult? Function(FluencyConfig value)? fluency,
  }) {
    return confidence?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConfidenceConfig value)? confidence,
    TResult Function(PronunciationConfig value)? pronunciation,
    TResult Function(FluencyConfig value)? fluency,
    required TResult orElse(),
  }) {
    if (confidence != null) {
      return confidence(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ConfidenceConfigImplToJson(
      this,
    );
  }
}

abstract class ConfidenceConfig implements ExerciseConfig {
  const factory ConfidenceConfig(
      {required final ConfidenceScenario scenario,
      final List<String> keywords,
      final int expectedDuration,
      final Map<String, dynamic> additionalParams}) = _$ConfidenceConfigImpl;

  factory ConfidenceConfig.fromJson(Map<String, dynamic> json) =
      _$ConfidenceConfigImpl.fromJson;

  ConfidenceScenario get scenario;
  List<String> get keywords;
  int get expectedDuration;
  @override
  Map<String, dynamic> get additionalParams;

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConfidenceConfigImplCopyWith<_$ConfidenceConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PronunciationConfigImplCopyWith<$Res>
    implements $ExerciseConfigCopyWith<$Res> {
  factory _$$PronunciationConfigImplCopyWith(_$PronunciationConfigImpl value,
          $Res Function(_$PronunciationConfigImpl) then) =
      __$$PronunciationConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String targetText,
      String language,
      double accuracyThreshold,
      Map<String, dynamic> additionalParams});
}

/// @nodoc
class __$$PronunciationConfigImplCopyWithImpl<$Res>
    extends _$ExerciseConfigCopyWithImpl<$Res, _$PronunciationConfigImpl>
    implements _$$PronunciationConfigImplCopyWith<$Res> {
  __$$PronunciationConfigImplCopyWithImpl(_$PronunciationConfigImpl _value,
      $Res Function(_$PronunciationConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetText = null,
    Object? language = null,
    Object? accuracyThreshold = null,
    Object? additionalParams = null,
  }) {
    return _then(_$PronunciationConfigImpl(
      targetText: null == targetText
          ? _value.targetText
          : targetText // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      accuracyThreshold: null == accuracyThreshold
          ? _value.accuracyThreshold
          : accuracyThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      additionalParams: null == additionalParams
          ? _value._additionalParams
          : additionalParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PronunciationConfigImpl implements PronunciationConfig {
  const _$PronunciationConfigImpl(
      {required this.targetText,
      required this.language,
      this.accuracyThreshold = 0.8,
      final Map<String, dynamic> additionalParams = const {},
      final String? $type})
      : _additionalParams = additionalParams,
        $type = $type ?? 'pronunciation';

  factory _$PronunciationConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$PronunciationConfigImplFromJson(json);

  @override
  final String targetText;
  @override
  final String language;
  @override
  @JsonKey()
  final double accuracyThreshold;
  final Map<String, dynamic> _additionalParams;
  @override
  @JsonKey()
  Map<String, dynamic> get additionalParams {
    if (_additionalParams is EqualUnmodifiableMapView) return _additionalParams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_additionalParams);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ExerciseConfig.pronunciation(targetText: $targetText, language: $language, accuracyThreshold: $accuracyThreshold, additionalParams: $additionalParams)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PronunciationConfigImpl &&
            (identical(other.targetText, targetText) ||
                other.targetText == targetText) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.accuracyThreshold, accuracyThreshold) ||
                other.accuracyThreshold == accuracyThreshold) &&
            const DeepCollectionEquality()
                .equals(other._additionalParams, _additionalParams));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      targetText,
      language,
      accuracyThreshold,
      const DeepCollectionEquality().hash(_additionalParams));

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PronunciationConfigImplCopyWith<_$PronunciationConfigImpl> get copyWith =>
      __$$PronunciationConfigImplCopyWithImpl<_$PronunciationConfigImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            ConfidenceScenario scenario,
            List<String> keywords,
            int expectedDuration,
            Map<String, dynamic> additionalParams)
        confidence,
    required TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)
        pronunciation,
    required TResult Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)
        fluency,
  }) {
    return pronunciation(
        targetText, language, accuracyThreshold, additionalParams);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult? Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult? Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)?
        fluency,
  }) {
    return pronunciation?.call(
        targetText, language, accuracyThreshold, additionalParams);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult Function(String topic, int targetDuration, int targetWordsPerMinute,
            Map<String, dynamic> additionalParams)?
        fluency,
    required TResult orElse(),
  }) {
    if (pronunciation != null) {
      return pronunciation(
          targetText, language, accuracyThreshold, additionalParams);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConfidenceConfig value) confidence,
    required TResult Function(PronunciationConfig value) pronunciation,
    required TResult Function(FluencyConfig value) fluency,
  }) {
    return pronunciation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceConfig value)? confidence,
    TResult? Function(PronunciationConfig value)? pronunciation,
    TResult? Function(FluencyConfig value)? fluency,
  }) {
    return pronunciation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConfidenceConfig value)? confidence,
    TResult Function(PronunciationConfig value)? pronunciation,
    TResult Function(FluencyConfig value)? fluency,
    required TResult orElse(),
  }) {
    if (pronunciation != null) {
      return pronunciation(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PronunciationConfigImplToJson(
      this,
    );
  }
}

abstract class PronunciationConfig implements ExerciseConfig {
  const factory PronunciationConfig(
      {required final String targetText,
      required final String language,
      final double accuracyThreshold,
      final Map<String, dynamic> additionalParams}) = _$PronunciationConfigImpl;

  factory PronunciationConfig.fromJson(Map<String, dynamic> json) =
      _$PronunciationConfigImpl.fromJson;

  String get targetText;
  String get language;
  double get accuracyThreshold;
  @override
  Map<String, dynamic> get additionalParams;

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PronunciationConfigImplCopyWith<_$PronunciationConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FluencyConfigImplCopyWith<$Res>
    implements $ExerciseConfigCopyWith<$Res> {
  factory _$$FluencyConfigImplCopyWith(
          _$FluencyConfigImpl value, $Res Function(_$FluencyConfigImpl) then) =
      __$$FluencyConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String topic,
      int targetDuration,
      int targetWordsPerMinute,
      Map<String, dynamic> additionalParams});
}

/// @nodoc
class __$$FluencyConfigImplCopyWithImpl<$Res>
    extends _$ExerciseConfigCopyWithImpl<$Res, _$FluencyConfigImpl>
    implements _$$FluencyConfigImplCopyWith<$Res> {
  __$$FluencyConfigImplCopyWithImpl(
      _$FluencyConfigImpl _value, $Res Function(_$FluencyConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? topic = null,
    Object? targetDuration = null,
    Object? targetWordsPerMinute = null,
    Object? additionalParams = null,
  }) {
    return _then(_$FluencyConfigImpl(
      topic: null == topic
          ? _value.topic
          : topic // ignore: cast_nullable_to_non_nullable
              as String,
      targetDuration: null == targetDuration
          ? _value.targetDuration
          : targetDuration // ignore: cast_nullable_to_non_nullable
              as int,
      targetWordsPerMinute: null == targetWordsPerMinute
          ? _value.targetWordsPerMinute
          : targetWordsPerMinute // ignore: cast_nullable_to_non_nullable
              as int,
      additionalParams: null == additionalParams
          ? _value._additionalParams
          : additionalParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FluencyConfigImpl implements FluencyConfig {
  const _$FluencyConfigImpl(
      {required this.topic,
      required this.targetDuration,
      this.targetWordsPerMinute = 120,
      final Map<String, dynamic> additionalParams = const {},
      final String? $type})
      : _additionalParams = additionalParams,
        $type = $type ?? 'fluency';

  factory _$FluencyConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$FluencyConfigImplFromJson(json);

  @override
  final String topic;
  @override
  final int targetDuration;
  @override
  @JsonKey()
  final int targetWordsPerMinute;
  final Map<String, dynamic> _additionalParams;
  @override
  @JsonKey()
  Map<String, dynamic> get additionalParams {
    if (_additionalParams is EqualUnmodifiableMapView) return _additionalParams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_additionalParams);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ExerciseConfig.fluency(topic: $topic, targetDuration: $targetDuration, targetWordsPerMinute: $targetWordsPerMinute, additionalParams: $additionalParams)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FluencyConfigImpl &&
            (identical(other.topic, topic) || other.topic == topic) &&
            (identical(other.targetDuration, targetDuration) ||
                other.targetDuration == targetDuration) &&
            (identical(other.targetWordsPerMinute, targetWordsPerMinute) ||
                other.targetWordsPerMinute == targetWordsPerMinute) &&
            const DeepCollectionEquality()
                .equals(other._additionalParams, _additionalParams));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      topic,
      targetDuration,
      targetWordsPerMinute,
      const DeepCollectionEquality().hash(_additionalParams));

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FluencyConfigImplCopyWith<_$FluencyConfigImpl> get copyWith =>
      __$$FluencyConfigImplCopyWithImpl<_$FluencyConfigImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            ConfidenceScenario scenario,
            List<String> keywords,
            int expectedDuration,
            Map<String, dynamic> additionalParams)
        confidence,
    required TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)
        pronunciation,
    required TResult Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)
        fluency,
  }) {
    return fluency(
        topic, targetDuration, targetWordsPerMinute, additionalParams);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult? Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult? Function(String topic, int targetDuration,
            int targetWordsPerMinute, Map<String, dynamic> additionalParams)?
        fluency,
  }) {
    return fluency?.call(
        topic, targetDuration, targetWordsPerMinute, additionalParams);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(ConfidenceScenario scenario, List<String> keywords,
            int expectedDuration, Map<String, dynamic> additionalParams)?
        confidence,
    TResult Function(String targetText, String language,
            double accuracyThreshold, Map<String, dynamic> additionalParams)?
        pronunciation,
    TResult Function(String topic, int targetDuration, int targetWordsPerMinute,
            Map<String, dynamic> additionalParams)?
        fluency,
    required TResult orElse(),
  }) {
    if (fluency != null) {
      return fluency(
          topic, targetDuration, targetWordsPerMinute, additionalParams);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ConfidenceConfig value) confidence,
    required TResult Function(PronunciationConfig value) pronunciation,
    required TResult Function(FluencyConfig value) fluency,
  }) {
    return fluency(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ConfidenceConfig value)? confidence,
    TResult? Function(PronunciationConfig value)? pronunciation,
    TResult? Function(FluencyConfig value)? fluency,
  }) {
    return fluency?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ConfidenceConfig value)? confidence,
    TResult Function(PronunciationConfig value)? pronunciation,
    TResult Function(FluencyConfig value)? fluency,
    required TResult orElse(),
  }) {
    if (fluency != null) {
      return fluency(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$FluencyConfigImplToJson(
      this,
    );
  }
}

abstract class FluencyConfig implements ExerciseConfig {
  const factory FluencyConfig(
      {required final String topic,
      required final int targetDuration,
      final int targetWordsPerMinute,
      final Map<String, dynamic> additionalParams}) = _$FluencyConfigImpl;

  factory FluencyConfig.fromJson(Map<String, dynamic> json) =
      _$FluencyConfigImpl.fromJson;

  String get topic;
  int get targetDuration;
  int get targetWordsPerMinute;
  @override
  Map<String, dynamic> get additionalParams;

  /// Create a copy of ExerciseConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FluencyConfigImplCopyWith<_$FluencyConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
