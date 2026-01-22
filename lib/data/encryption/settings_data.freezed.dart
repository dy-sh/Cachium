// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SettingsData _$SettingsDataFromJson(Map<String, dynamic> json) {
  return _SettingsData.fromJson(json);
}

/// @nodoc
mixin _$SettingsData {
  /// Fixed ID - always 'app_settings'
  String get id => throw _privateConstructorUsedError;

  /// Color intensity: 'prism', 'zen', 'pastel', 'neon', 'vintage'
  String get colorIntensity => throw _privateConstructorUsedError;

  /// Accent color index
  int get accentColorIndex => throw _privateConstructorUsedError;

  /// Account card style: 'dim' or 'bright'
  String get accountCardStyle => throw _privateConstructorUsedError;

  /// Whether tab transitions are enabled
  bool get tabTransitionsEnabled => throw _privateConstructorUsedError;

  /// Whether form animations are enabled
  bool get formAnimationsEnabled => throw _privateConstructorUsedError;

  /// Whether balance counter animations are enabled
  bool get balanceCountersEnabled => throw _privateConstructorUsedError;

  /// Date format: 'mmddyyyy', 'ddmmyyyy', 'ddmmyyyyDot', 'yyyymmdd'
  String get dateFormat => throw _privateConstructorUsedError;

  /// Currency symbol: 'usd', 'eur', 'gbp', 'custom'
  String get currencySymbol => throw _privateConstructorUsedError;

  /// Custom currency symbol when currencySymbol is 'custom'
  String? get customCurrencySymbol => throw _privateConstructorUsedError;

  /// First day of week: 'sunday' or 'monday'
  String get firstDayOfWeek => throw _privateConstructorUsedError;

  /// Whether haptic feedback is enabled
  bool get hapticFeedbackEnabled => throw _privateConstructorUsedError;

  /// Start screen: 'home', 'transactions', 'accounts'
  String get startScreen => throw _privateConstructorUsedError;

  /// Last used account ID for transaction form
  String? get lastUsedAccountId => throw _privateConstructorUsedError;

  /// Serializes this SettingsData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SettingsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SettingsDataCopyWith<SettingsData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsDataCopyWith<$Res> {
  factory $SettingsDataCopyWith(
    SettingsData value,
    $Res Function(SettingsData) then,
  ) = _$SettingsDataCopyWithImpl<$Res, SettingsData>;
  @useResult
  $Res call({
    String id,
    String colorIntensity,
    int accentColorIndex,
    String accountCardStyle,
    bool tabTransitionsEnabled,
    bool formAnimationsEnabled,
    bool balanceCountersEnabled,
    String dateFormat,
    String currencySymbol,
    String? customCurrencySymbol,
    String firstDayOfWeek,
    bool hapticFeedbackEnabled,
    String startScreen,
    String? lastUsedAccountId,
  });
}

/// @nodoc
class _$SettingsDataCopyWithImpl<$Res, $Val extends SettingsData>
    implements $SettingsDataCopyWith<$Res> {
  _$SettingsDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SettingsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? colorIntensity = null,
    Object? accentColorIndex = null,
    Object? accountCardStyle = null,
    Object? tabTransitionsEnabled = null,
    Object? formAnimationsEnabled = null,
    Object? balanceCountersEnabled = null,
    Object? dateFormat = null,
    Object? currencySymbol = null,
    Object? customCurrencySymbol = freezed,
    Object? firstDayOfWeek = null,
    Object? hapticFeedbackEnabled = null,
    Object? startScreen = null,
    Object? lastUsedAccountId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            colorIntensity: null == colorIntensity
                ? _value.colorIntensity
                : colorIntensity // ignore: cast_nullable_to_non_nullable
                      as String,
            accentColorIndex: null == accentColorIndex
                ? _value.accentColorIndex
                : accentColorIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            accountCardStyle: null == accountCardStyle
                ? _value.accountCardStyle
                : accountCardStyle // ignore: cast_nullable_to_non_nullable
                      as String,
            tabTransitionsEnabled: null == tabTransitionsEnabled
                ? _value.tabTransitionsEnabled
                : tabTransitionsEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            formAnimationsEnabled: null == formAnimationsEnabled
                ? _value.formAnimationsEnabled
                : formAnimationsEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            balanceCountersEnabled: null == balanceCountersEnabled
                ? _value.balanceCountersEnabled
                : balanceCountersEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            dateFormat: null == dateFormat
                ? _value.dateFormat
                : dateFormat // ignore: cast_nullable_to_non_nullable
                      as String,
            currencySymbol: null == currencySymbol
                ? _value.currencySymbol
                : currencySymbol // ignore: cast_nullable_to_non_nullable
                      as String,
            customCurrencySymbol: freezed == customCurrencySymbol
                ? _value.customCurrencySymbol
                : customCurrencySymbol // ignore: cast_nullable_to_non_nullable
                      as String?,
            firstDayOfWeek: null == firstDayOfWeek
                ? _value.firstDayOfWeek
                : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
                      as String,
            hapticFeedbackEnabled: null == hapticFeedbackEnabled
                ? _value.hapticFeedbackEnabled
                : hapticFeedbackEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            startScreen: null == startScreen
                ? _value.startScreen
                : startScreen // ignore: cast_nullable_to_non_nullable
                      as String,
            lastUsedAccountId: freezed == lastUsedAccountId
                ? _value.lastUsedAccountId
                : lastUsedAccountId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SettingsDataImplCopyWith<$Res>
    implements $SettingsDataCopyWith<$Res> {
  factory _$$SettingsDataImplCopyWith(
    _$SettingsDataImpl value,
    $Res Function(_$SettingsDataImpl) then,
  ) = __$$SettingsDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String colorIntensity,
    int accentColorIndex,
    String accountCardStyle,
    bool tabTransitionsEnabled,
    bool formAnimationsEnabled,
    bool balanceCountersEnabled,
    String dateFormat,
    String currencySymbol,
    String? customCurrencySymbol,
    String firstDayOfWeek,
    bool hapticFeedbackEnabled,
    String startScreen,
    String? lastUsedAccountId,
  });
}

/// @nodoc
class __$$SettingsDataImplCopyWithImpl<$Res>
    extends _$SettingsDataCopyWithImpl<$Res, _$SettingsDataImpl>
    implements _$$SettingsDataImplCopyWith<$Res> {
  __$$SettingsDataImplCopyWithImpl(
    _$SettingsDataImpl _value,
    $Res Function(_$SettingsDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SettingsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? colorIntensity = null,
    Object? accentColorIndex = null,
    Object? accountCardStyle = null,
    Object? tabTransitionsEnabled = null,
    Object? formAnimationsEnabled = null,
    Object? balanceCountersEnabled = null,
    Object? dateFormat = null,
    Object? currencySymbol = null,
    Object? customCurrencySymbol = freezed,
    Object? firstDayOfWeek = null,
    Object? hapticFeedbackEnabled = null,
    Object? startScreen = null,
    Object? lastUsedAccountId = freezed,
  }) {
    return _then(
      _$SettingsDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        colorIntensity: null == colorIntensity
            ? _value.colorIntensity
            : colorIntensity // ignore: cast_nullable_to_non_nullable
                  as String,
        accentColorIndex: null == accentColorIndex
            ? _value.accentColorIndex
            : accentColorIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        accountCardStyle: null == accountCardStyle
            ? _value.accountCardStyle
            : accountCardStyle // ignore: cast_nullable_to_non_nullable
                  as String,
        tabTransitionsEnabled: null == tabTransitionsEnabled
            ? _value.tabTransitionsEnabled
            : tabTransitionsEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        formAnimationsEnabled: null == formAnimationsEnabled
            ? _value.formAnimationsEnabled
            : formAnimationsEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        balanceCountersEnabled: null == balanceCountersEnabled
            ? _value.balanceCountersEnabled
            : balanceCountersEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        dateFormat: null == dateFormat
            ? _value.dateFormat
            : dateFormat // ignore: cast_nullable_to_non_nullable
                  as String,
        currencySymbol: null == currencySymbol
            ? _value.currencySymbol
            : currencySymbol // ignore: cast_nullable_to_non_nullable
                  as String,
        customCurrencySymbol: freezed == customCurrencySymbol
            ? _value.customCurrencySymbol
            : customCurrencySymbol // ignore: cast_nullable_to_non_nullable
                  as String?,
        firstDayOfWeek: null == firstDayOfWeek
            ? _value.firstDayOfWeek
            : firstDayOfWeek // ignore: cast_nullable_to_non_nullable
                  as String,
        hapticFeedbackEnabled: null == hapticFeedbackEnabled
            ? _value.hapticFeedbackEnabled
            : hapticFeedbackEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        startScreen: null == startScreen
            ? _value.startScreen
            : startScreen // ignore: cast_nullable_to_non_nullable
                  as String,
        lastUsedAccountId: freezed == lastUsedAccountId
            ? _value.lastUsedAccountId
            : lastUsedAccountId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SettingsDataImpl implements _SettingsData {
  const _$SettingsDataImpl({
    this.id = 'app_settings',
    this.colorIntensity = 'prism',
    this.accentColorIndex = 0,
    this.accountCardStyle = 'dim',
    this.tabTransitionsEnabled = true,
    this.formAnimationsEnabled = true,
    this.balanceCountersEnabled = true,
    this.dateFormat = 'mmddyyyy',
    this.currencySymbol = 'usd',
    this.customCurrencySymbol,
    this.firstDayOfWeek = 'sunday',
    this.hapticFeedbackEnabled = true,
    this.startScreen = 'home',
    this.lastUsedAccountId,
  });

  factory _$SettingsDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SettingsDataImplFromJson(json);

  /// Fixed ID - always 'app_settings'
  @override
  @JsonKey()
  final String id;

  /// Color intensity: 'prism', 'zen', 'pastel', 'neon', 'vintage'
  @override
  @JsonKey()
  final String colorIntensity;

  /// Accent color index
  @override
  @JsonKey()
  final int accentColorIndex;

  /// Account card style: 'dim' or 'bright'
  @override
  @JsonKey()
  final String accountCardStyle;

  /// Whether tab transitions are enabled
  @override
  @JsonKey()
  final bool tabTransitionsEnabled;

  /// Whether form animations are enabled
  @override
  @JsonKey()
  final bool formAnimationsEnabled;

  /// Whether balance counter animations are enabled
  @override
  @JsonKey()
  final bool balanceCountersEnabled;

  /// Date format: 'mmddyyyy', 'ddmmyyyy', 'ddmmyyyyDot', 'yyyymmdd'
  @override
  @JsonKey()
  final String dateFormat;

  /// Currency symbol: 'usd', 'eur', 'gbp', 'custom'
  @override
  @JsonKey()
  final String currencySymbol;

  /// Custom currency symbol when currencySymbol is 'custom'
  @override
  final String? customCurrencySymbol;

  /// First day of week: 'sunday' or 'monday'
  @override
  @JsonKey()
  final String firstDayOfWeek;

  /// Whether haptic feedback is enabled
  @override
  @JsonKey()
  final bool hapticFeedbackEnabled;

  /// Start screen: 'home', 'transactions', 'accounts'
  @override
  @JsonKey()
  final String startScreen;

  /// Last used account ID for transaction form
  @override
  final String? lastUsedAccountId;

  @override
  String toString() {
    return 'SettingsData(id: $id, colorIntensity: $colorIntensity, accentColorIndex: $accentColorIndex, accountCardStyle: $accountCardStyle, tabTransitionsEnabled: $tabTransitionsEnabled, formAnimationsEnabled: $formAnimationsEnabled, balanceCountersEnabled: $balanceCountersEnabled, dateFormat: $dateFormat, currencySymbol: $currencySymbol, customCurrencySymbol: $customCurrencySymbol, firstDayOfWeek: $firstDayOfWeek, hapticFeedbackEnabled: $hapticFeedbackEnabled, startScreen: $startScreen, lastUsedAccountId: $lastUsedAccountId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.colorIntensity, colorIntensity) ||
                other.colorIntensity == colorIntensity) &&
            (identical(other.accentColorIndex, accentColorIndex) ||
                other.accentColorIndex == accentColorIndex) &&
            (identical(other.accountCardStyle, accountCardStyle) ||
                other.accountCardStyle == accountCardStyle) &&
            (identical(other.tabTransitionsEnabled, tabTransitionsEnabled) ||
                other.tabTransitionsEnabled == tabTransitionsEnabled) &&
            (identical(other.formAnimationsEnabled, formAnimationsEnabled) ||
                other.formAnimationsEnabled == formAnimationsEnabled) &&
            (identical(other.balanceCountersEnabled, balanceCountersEnabled) ||
                other.balanceCountersEnabled == balanceCountersEnabled) &&
            (identical(other.dateFormat, dateFormat) ||
                other.dateFormat == dateFormat) &&
            (identical(other.currencySymbol, currencySymbol) ||
                other.currencySymbol == currencySymbol) &&
            (identical(other.customCurrencySymbol, customCurrencySymbol) ||
                other.customCurrencySymbol == customCurrencySymbol) &&
            (identical(other.firstDayOfWeek, firstDayOfWeek) ||
                other.firstDayOfWeek == firstDayOfWeek) &&
            (identical(other.hapticFeedbackEnabled, hapticFeedbackEnabled) ||
                other.hapticFeedbackEnabled == hapticFeedbackEnabled) &&
            (identical(other.startScreen, startScreen) ||
                other.startScreen == startScreen) &&
            (identical(other.lastUsedAccountId, lastUsedAccountId) ||
                other.lastUsedAccountId == lastUsedAccountId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    colorIntensity,
    accentColorIndex,
    accountCardStyle,
    tabTransitionsEnabled,
    formAnimationsEnabled,
    balanceCountersEnabled,
    dateFormat,
    currencySymbol,
    customCurrencySymbol,
    firstDayOfWeek,
    hapticFeedbackEnabled,
    startScreen,
    lastUsedAccountId,
  );

  /// Create a copy of SettingsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsDataImplCopyWith<_$SettingsDataImpl> get copyWith =>
      __$$SettingsDataImplCopyWithImpl<_$SettingsDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SettingsDataImplToJson(this);
  }
}

abstract class _SettingsData implements SettingsData {
  const factory _SettingsData({
    final String id,
    final String colorIntensity,
    final int accentColorIndex,
    final String accountCardStyle,
    final bool tabTransitionsEnabled,
    final bool formAnimationsEnabled,
    final bool balanceCountersEnabled,
    final String dateFormat,
    final String currencySymbol,
    final String? customCurrencySymbol,
    final String firstDayOfWeek,
    final bool hapticFeedbackEnabled,
    final String startScreen,
    final String? lastUsedAccountId,
  }) = _$SettingsDataImpl;

  factory _SettingsData.fromJson(Map<String, dynamic> json) =
      _$SettingsDataImpl.fromJson;

  /// Fixed ID - always 'app_settings'
  @override
  String get id;

  /// Color intensity: 'prism', 'zen', 'pastel', 'neon', 'vintage'
  @override
  String get colorIntensity;

  /// Accent color index
  @override
  int get accentColorIndex;

  /// Account card style: 'dim' or 'bright'
  @override
  String get accountCardStyle;

  /// Whether tab transitions are enabled
  @override
  bool get tabTransitionsEnabled;

  /// Whether form animations are enabled
  @override
  bool get formAnimationsEnabled;

  /// Whether balance counter animations are enabled
  @override
  bool get balanceCountersEnabled;

  /// Date format: 'mmddyyyy', 'ddmmyyyy', 'ddmmyyyyDot', 'yyyymmdd'
  @override
  String get dateFormat;

  /// Currency symbol: 'usd', 'eur', 'gbp', 'custom'
  @override
  String get currencySymbol;

  /// Custom currency symbol when currencySymbol is 'custom'
  @override
  String? get customCurrencySymbol;

  /// First day of week: 'sunday' or 'monday'
  @override
  String get firstDayOfWeek;

  /// Whether haptic feedback is enabled
  @override
  bool get hapticFeedbackEnabled;

  /// Start screen: 'home', 'transactions', 'accounts'
  @override
  String get startScreen;

  /// Last used account ID for transaction form
  @override
  String? get lastUsedAccountId;

  /// Create a copy of SettingsData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsDataImplCopyWith<_$SettingsDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
