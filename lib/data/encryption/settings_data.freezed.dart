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

  /// Theme mode: 'dark', 'light', 'system'
  String get themeMode => throw _privateConstructorUsedError;

  /// Color intensity: 'prism', 'zen', 'neon'
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

  /// Main currency code (ISO 4217)
  String get mainCurrencyCode => throw _privateConstructorUsedError;

  /// Exchange rate API option: 'frankfurter', 'exchangeRateHost', 'manual'
  String get exchangeRateApiOption => throw _privateConstructorUsedError;

  /// Cached exchange rates as JSON string
  String? get cachedExchangeRates => throw _privateConstructorUsedError;

  /// Timestamp of last successful rate fetch
  int? get lastRateFetchTimestamp => throw _privateConstructorUsedError;

  /// First day of week: 'sunday' or 'monday'
  String get firstDayOfWeek => throw _privateConstructorUsedError;

  /// Whether haptic feedback is enabled
  bool get hapticFeedbackEnabled => throw _privateConstructorUsedError;

  /// Start screen: 'home', 'transactions', 'accounts'
  String get startScreen => throw _privateConstructorUsedError;

  /// Last used account ID for transaction form
  String? get lastUsedAccountId => throw _privateConstructorUsedError;

  /// Whether to pre-select last used category
  bool get selectLastCategory => throw _privateConstructorUsedError;

  /// Whether to pre-select last used account
  bool get selectLastAccount => throw _privateConstructorUsedError;

  /// Number of accounts shown before "More" button
  int get accountsFoldedCount => throw _privateConstructorUsedError;

  /// Number of categories shown before "More" button
  int get categoriesFoldedCount => throw _privateConstructorUsedError;

  /// Whether to show "New Account" button in form
  bool get showAddAccountButton => throw _privateConstructorUsedError;

  /// Whether to show "New" category button in form
  bool get showAddCategoryButton => throw _privateConstructorUsedError;

  /// Default transaction type: 'income' or 'expense'
  String get defaultTransactionType => throw _privateConstructorUsedError;

  /// Whether to allow saving with amount = 0
  bool get allowZeroAmount => throw _privateConstructorUsedError;

  /// Category sort option: 'lastUsed', 'listOrder', 'alphabetical'
  String get categorySortOption => throw _privateConstructorUsedError;

  /// Last used category ID for income transactions
  String? get lastUsedIncomeCategoryId => throw _privateConstructorUsedError;

  /// Last used category ID for expense transactions
  String? get lastUsedExpenseCategoryId => throw _privateConstructorUsedError;

  /// Whether app lock (biometric/PIN) is enabled
  bool get appLockEnabled => throw _privateConstructorUsedError;

  /// App PIN code (stored as plaintext 4-8 digit string)
  String? get appPinCode => throw _privateConstructorUsedError;

  /// App password (stored as plaintext string)
  String? get appPassword => throw _privateConstructorUsedError;

  /// Auto-lock timeout: 'immediate', 'after30Seconds', 'after1Minute', 'after5Minutes', 'after15Minutes', 'never'
  String get autoLockTimeout => throw _privateConstructorUsedError;

  /// Whether biometric unlock is enabled (when hardware is available)
  bool get biometricUnlockEnabled => throw _privateConstructorUsedError;

  /// Whether notifications are enabled
  bool get notificationsEnabled => throw _privateConstructorUsedError;

  /// Budget alert thresholds (percentages)
  List<int> get budgetAlertThresholds => throw _privateConstructorUsedError;

  /// Whether recurring transaction reminders are enabled
  bool get recurringRemindersEnabled => throw _privateConstructorUsedError;

  /// Days in advance for recurring reminders
  int get recurringReminderAdvanceDays => throw _privateConstructorUsedError;

  /// Whether weekly spending summary is enabled
  bool get weeklySpendingSummaryEnabled => throw _privateConstructorUsedError;

  /// Day of week for weekly summary (1=Monday, 7=Sunday)
  int get weeklySpendingSummaryDay => throw _privateConstructorUsedError;

  /// Whether attachment files on disk are encrypted
  bool get encryptAttachments => throw _privateConstructorUsedError;

  /// Whether budget progress is shown on home
  bool get homeShowBudgetProgress => throw _privateConstructorUsedError;

  /// Home section ordering
  List<String> get homeSectionOrder => throw _privateConstructorUsedError;

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
    String themeMode,
    String colorIntensity,
    int accentColorIndex,
    String accountCardStyle,
    bool tabTransitionsEnabled,
    bool formAnimationsEnabled,
    bool balanceCountersEnabled,
    String dateFormat,
    String mainCurrencyCode,
    String exchangeRateApiOption,
    String? cachedExchangeRates,
    int? lastRateFetchTimestamp,
    String firstDayOfWeek,
    bool hapticFeedbackEnabled,
    String startScreen,
    String? lastUsedAccountId,
    bool selectLastCategory,
    bool selectLastAccount,
    int accountsFoldedCount,
    int categoriesFoldedCount,
    bool showAddAccountButton,
    bool showAddCategoryButton,
    String defaultTransactionType,
    bool allowZeroAmount,
    String categorySortOption,
    String? lastUsedIncomeCategoryId,
    String? lastUsedExpenseCategoryId,
    bool appLockEnabled,
    String? appPinCode,
    String? appPassword,
    String autoLockTimeout,
    bool biometricUnlockEnabled,
    bool notificationsEnabled,
    List<int> budgetAlertThresholds,
    bool recurringRemindersEnabled,
    int recurringReminderAdvanceDays,
    bool weeklySpendingSummaryEnabled,
    int weeklySpendingSummaryDay,
    bool encryptAttachments,
    bool homeShowBudgetProgress,
    List<String> homeSectionOrder,
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
    Object? themeMode = null,
    Object? colorIntensity = null,
    Object? accentColorIndex = null,
    Object? accountCardStyle = null,
    Object? tabTransitionsEnabled = null,
    Object? formAnimationsEnabled = null,
    Object? balanceCountersEnabled = null,
    Object? dateFormat = null,
    Object? mainCurrencyCode = null,
    Object? exchangeRateApiOption = null,
    Object? cachedExchangeRates = freezed,
    Object? lastRateFetchTimestamp = freezed,
    Object? firstDayOfWeek = null,
    Object? hapticFeedbackEnabled = null,
    Object? startScreen = null,
    Object? lastUsedAccountId = freezed,
    Object? selectLastCategory = null,
    Object? selectLastAccount = null,
    Object? accountsFoldedCount = null,
    Object? categoriesFoldedCount = null,
    Object? showAddAccountButton = null,
    Object? showAddCategoryButton = null,
    Object? defaultTransactionType = null,
    Object? allowZeroAmount = null,
    Object? categorySortOption = null,
    Object? lastUsedIncomeCategoryId = freezed,
    Object? lastUsedExpenseCategoryId = freezed,
    Object? appLockEnabled = null,
    Object? appPinCode = freezed,
    Object? appPassword = freezed,
    Object? autoLockTimeout = null,
    Object? biometricUnlockEnabled = null,
    Object? notificationsEnabled = null,
    Object? budgetAlertThresholds = null,
    Object? recurringRemindersEnabled = null,
    Object? recurringReminderAdvanceDays = null,
    Object? weeklySpendingSummaryEnabled = null,
    Object? weeklySpendingSummaryDay = null,
    Object? encryptAttachments = null,
    Object? homeShowBudgetProgress = null,
    Object? homeSectionOrder = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            themeMode: null == themeMode
                ? _value.themeMode
                : themeMode // ignore: cast_nullable_to_non_nullable
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
            mainCurrencyCode: null == mainCurrencyCode
                ? _value.mainCurrencyCode
                : mainCurrencyCode // ignore: cast_nullable_to_non_nullable
                      as String,
            exchangeRateApiOption: null == exchangeRateApiOption
                ? _value.exchangeRateApiOption
                : exchangeRateApiOption // ignore: cast_nullable_to_non_nullable
                      as String,
            cachedExchangeRates: freezed == cachedExchangeRates
                ? _value.cachedExchangeRates
                : cachedExchangeRates // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastRateFetchTimestamp: freezed == lastRateFetchTimestamp
                ? _value.lastRateFetchTimestamp
                : lastRateFetchTimestamp // ignore: cast_nullable_to_non_nullable
                      as int?,
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
            selectLastCategory: null == selectLastCategory
                ? _value.selectLastCategory
                : selectLastCategory // ignore: cast_nullable_to_non_nullable
                      as bool,
            selectLastAccount: null == selectLastAccount
                ? _value.selectLastAccount
                : selectLastAccount // ignore: cast_nullable_to_non_nullable
                      as bool,
            accountsFoldedCount: null == accountsFoldedCount
                ? _value.accountsFoldedCount
                : accountsFoldedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            categoriesFoldedCount: null == categoriesFoldedCount
                ? _value.categoriesFoldedCount
                : categoriesFoldedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            showAddAccountButton: null == showAddAccountButton
                ? _value.showAddAccountButton
                : showAddAccountButton // ignore: cast_nullable_to_non_nullable
                      as bool,
            showAddCategoryButton: null == showAddCategoryButton
                ? _value.showAddCategoryButton
                : showAddCategoryButton // ignore: cast_nullable_to_non_nullable
                      as bool,
            defaultTransactionType: null == defaultTransactionType
                ? _value.defaultTransactionType
                : defaultTransactionType // ignore: cast_nullable_to_non_nullable
                      as String,
            allowZeroAmount: null == allowZeroAmount
                ? _value.allowZeroAmount
                : allowZeroAmount // ignore: cast_nullable_to_non_nullable
                      as bool,
            categorySortOption: null == categorySortOption
                ? _value.categorySortOption
                : categorySortOption // ignore: cast_nullable_to_non_nullable
                      as String,
            lastUsedIncomeCategoryId: freezed == lastUsedIncomeCategoryId
                ? _value.lastUsedIncomeCategoryId
                : lastUsedIncomeCategoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUsedExpenseCategoryId: freezed == lastUsedExpenseCategoryId
                ? _value.lastUsedExpenseCategoryId
                : lastUsedExpenseCategoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            appLockEnabled: null == appLockEnabled
                ? _value.appLockEnabled
                : appLockEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            appPinCode: freezed == appPinCode
                ? _value.appPinCode
                : appPinCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            appPassword: freezed == appPassword
                ? _value.appPassword
                : appPassword // ignore: cast_nullable_to_non_nullable
                      as String?,
            autoLockTimeout: null == autoLockTimeout
                ? _value.autoLockTimeout
                : autoLockTimeout // ignore: cast_nullable_to_non_nullable
                      as String,
            biometricUnlockEnabled: null == biometricUnlockEnabled
                ? _value.biometricUnlockEnabled
                : biometricUnlockEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            notificationsEnabled: null == notificationsEnabled
                ? _value.notificationsEnabled
                : notificationsEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            budgetAlertThresholds: null == budgetAlertThresholds
                ? _value.budgetAlertThresholds
                : budgetAlertThresholds // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            recurringRemindersEnabled: null == recurringRemindersEnabled
                ? _value.recurringRemindersEnabled
                : recurringRemindersEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            recurringReminderAdvanceDays: null == recurringReminderAdvanceDays
                ? _value.recurringReminderAdvanceDays
                : recurringReminderAdvanceDays // ignore: cast_nullable_to_non_nullable
                      as int,
            weeklySpendingSummaryEnabled: null == weeklySpendingSummaryEnabled
                ? _value.weeklySpendingSummaryEnabled
                : weeklySpendingSummaryEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            weeklySpendingSummaryDay: null == weeklySpendingSummaryDay
                ? _value.weeklySpendingSummaryDay
                : weeklySpendingSummaryDay // ignore: cast_nullable_to_non_nullable
                      as int,
            encryptAttachments: null == encryptAttachments
                ? _value.encryptAttachments
                : encryptAttachments // ignore: cast_nullable_to_non_nullable
                      as bool,
            homeShowBudgetProgress: null == homeShowBudgetProgress
                ? _value.homeShowBudgetProgress
                : homeShowBudgetProgress // ignore: cast_nullable_to_non_nullable
                      as bool,
            homeSectionOrder: null == homeSectionOrder
                ? _value.homeSectionOrder
                : homeSectionOrder // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
    String themeMode,
    String colorIntensity,
    int accentColorIndex,
    String accountCardStyle,
    bool tabTransitionsEnabled,
    bool formAnimationsEnabled,
    bool balanceCountersEnabled,
    String dateFormat,
    String mainCurrencyCode,
    String exchangeRateApiOption,
    String? cachedExchangeRates,
    int? lastRateFetchTimestamp,
    String firstDayOfWeek,
    bool hapticFeedbackEnabled,
    String startScreen,
    String? lastUsedAccountId,
    bool selectLastCategory,
    bool selectLastAccount,
    int accountsFoldedCount,
    int categoriesFoldedCount,
    bool showAddAccountButton,
    bool showAddCategoryButton,
    String defaultTransactionType,
    bool allowZeroAmount,
    String categorySortOption,
    String? lastUsedIncomeCategoryId,
    String? lastUsedExpenseCategoryId,
    bool appLockEnabled,
    String? appPinCode,
    String? appPassword,
    String autoLockTimeout,
    bool biometricUnlockEnabled,
    bool notificationsEnabled,
    List<int> budgetAlertThresholds,
    bool recurringRemindersEnabled,
    int recurringReminderAdvanceDays,
    bool weeklySpendingSummaryEnabled,
    int weeklySpendingSummaryDay,
    bool encryptAttachments,
    bool homeShowBudgetProgress,
    List<String> homeSectionOrder,
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
    Object? themeMode = null,
    Object? colorIntensity = null,
    Object? accentColorIndex = null,
    Object? accountCardStyle = null,
    Object? tabTransitionsEnabled = null,
    Object? formAnimationsEnabled = null,
    Object? balanceCountersEnabled = null,
    Object? dateFormat = null,
    Object? mainCurrencyCode = null,
    Object? exchangeRateApiOption = null,
    Object? cachedExchangeRates = freezed,
    Object? lastRateFetchTimestamp = freezed,
    Object? firstDayOfWeek = null,
    Object? hapticFeedbackEnabled = null,
    Object? startScreen = null,
    Object? lastUsedAccountId = freezed,
    Object? selectLastCategory = null,
    Object? selectLastAccount = null,
    Object? accountsFoldedCount = null,
    Object? categoriesFoldedCount = null,
    Object? showAddAccountButton = null,
    Object? showAddCategoryButton = null,
    Object? defaultTransactionType = null,
    Object? allowZeroAmount = null,
    Object? categorySortOption = null,
    Object? lastUsedIncomeCategoryId = freezed,
    Object? lastUsedExpenseCategoryId = freezed,
    Object? appLockEnabled = null,
    Object? appPinCode = freezed,
    Object? appPassword = freezed,
    Object? autoLockTimeout = null,
    Object? biometricUnlockEnabled = null,
    Object? notificationsEnabled = null,
    Object? budgetAlertThresholds = null,
    Object? recurringRemindersEnabled = null,
    Object? recurringReminderAdvanceDays = null,
    Object? weeklySpendingSummaryEnabled = null,
    Object? weeklySpendingSummaryDay = null,
    Object? encryptAttachments = null,
    Object? homeShowBudgetProgress = null,
    Object? homeSectionOrder = null,
  }) {
    return _then(
      _$SettingsDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        themeMode: null == themeMode
            ? _value.themeMode
            : themeMode // ignore: cast_nullable_to_non_nullable
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
        mainCurrencyCode: null == mainCurrencyCode
            ? _value.mainCurrencyCode
            : mainCurrencyCode // ignore: cast_nullable_to_non_nullable
                  as String,
        exchangeRateApiOption: null == exchangeRateApiOption
            ? _value.exchangeRateApiOption
            : exchangeRateApiOption // ignore: cast_nullable_to_non_nullable
                  as String,
        cachedExchangeRates: freezed == cachedExchangeRates
            ? _value.cachedExchangeRates
            : cachedExchangeRates // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastRateFetchTimestamp: freezed == lastRateFetchTimestamp
            ? _value.lastRateFetchTimestamp
            : lastRateFetchTimestamp // ignore: cast_nullable_to_non_nullable
                  as int?,
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
        selectLastCategory: null == selectLastCategory
            ? _value.selectLastCategory
            : selectLastCategory // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectLastAccount: null == selectLastAccount
            ? _value.selectLastAccount
            : selectLastAccount // ignore: cast_nullable_to_non_nullable
                  as bool,
        accountsFoldedCount: null == accountsFoldedCount
            ? _value.accountsFoldedCount
            : accountsFoldedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        categoriesFoldedCount: null == categoriesFoldedCount
            ? _value.categoriesFoldedCount
            : categoriesFoldedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        showAddAccountButton: null == showAddAccountButton
            ? _value.showAddAccountButton
            : showAddAccountButton // ignore: cast_nullable_to_non_nullable
                  as bool,
        showAddCategoryButton: null == showAddCategoryButton
            ? _value.showAddCategoryButton
            : showAddCategoryButton // ignore: cast_nullable_to_non_nullable
                  as bool,
        defaultTransactionType: null == defaultTransactionType
            ? _value.defaultTransactionType
            : defaultTransactionType // ignore: cast_nullable_to_non_nullable
                  as String,
        allowZeroAmount: null == allowZeroAmount
            ? _value.allowZeroAmount
            : allowZeroAmount // ignore: cast_nullable_to_non_nullable
                  as bool,
        categorySortOption: null == categorySortOption
            ? _value.categorySortOption
            : categorySortOption // ignore: cast_nullable_to_non_nullable
                  as String,
        lastUsedIncomeCategoryId: freezed == lastUsedIncomeCategoryId
            ? _value.lastUsedIncomeCategoryId
            : lastUsedIncomeCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUsedExpenseCategoryId: freezed == lastUsedExpenseCategoryId
            ? _value.lastUsedExpenseCategoryId
            : lastUsedExpenseCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        appLockEnabled: null == appLockEnabled
            ? _value.appLockEnabled
            : appLockEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        appPinCode: freezed == appPinCode
            ? _value.appPinCode
            : appPinCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        appPassword: freezed == appPassword
            ? _value.appPassword
            : appPassword // ignore: cast_nullable_to_non_nullable
                  as String?,
        autoLockTimeout: null == autoLockTimeout
            ? _value.autoLockTimeout
            : autoLockTimeout // ignore: cast_nullable_to_non_nullable
                  as String,
        biometricUnlockEnabled: null == biometricUnlockEnabled
            ? _value.biometricUnlockEnabled
            : biometricUnlockEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        notificationsEnabled: null == notificationsEnabled
            ? _value.notificationsEnabled
            : notificationsEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        budgetAlertThresholds: null == budgetAlertThresholds
            ? _value._budgetAlertThresholds
            : budgetAlertThresholds // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        recurringRemindersEnabled: null == recurringRemindersEnabled
            ? _value.recurringRemindersEnabled
            : recurringRemindersEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        recurringReminderAdvanceDays: null == recurringReminderAdvanceDays
            ? _value.recurringReminderAdvanceDays
            : recurringReminderAdvanceDays // ignore: cast_nullable_to_non_nullable
                  as int,
        weeklySpendingSummaryEnabled: null == weeklySpendingSummaryEnabled
            ? _value.weeklySpendingSummaryEnabled
            : weeklySpendingSummaryEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        weeklySpendingSummaryDay: null == weeklySpendingSummaryDay
            ? _value.weeklySpendingSummaryDay
            : weeklySpendingSummaryDay // ignore: cast_nullable_to_non_nullable
                  as int,
        encryptAttachments: null == encryptAttachments
            ? _value.encryptAttachments
            : encryptAttachments // ignore: cast_nullable_to_non_nullable
                  as bool,
        homeShowBudgetProgress: null == homeShowBudgetProgress
            ? _value.homeShowBudgetProgress
            : homeShowBudgetProgress // ignore: cast_nullable_to_non_nullable
                  as bool,
        homeSectionOrder: null == homeSectionOrder
            ? _value._homeSectionOrder
            : homeSectionOrder // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SettingsDataImpl implements _SettingsData {
  const _$SettingsDataImpl({
    this.id = 'app_settings',
    this.themeMode = 'dark',
    this.colorIntensity = 'prism',
    this.accentColorIndex = 0,
    this.accountCardStyle = 'dim',
    this.tabTransitionsEnabled = true,
    this.formAnimationsEnabled = true,
    this.balanceCountersEnabled = true,
    this.dateFormat = 'mmddyyyy',
    this.mainCurrencyCode = 'USD',
    this.exchangeRateApiOption = 'frankfurter',
    this.cachedExchangeRates,
    this.lastRateFetchTimestamp,
    this.firstDayOfWeek = 'sunday',
    this.hapticFeedbackEnabled = true,
    this.startScreen = 'home',
    this.lastUsedAccountId,
    this.selectLastCategory = false,
    this.selectLastAccount = true,
    this.accountsFoldedCount = 3,
    this.categoriesFoldedCount = 5,
    this.showAddAccountButton = true,
    this.showAddCategoryButton = true,
    this.defaultTransactionType = 'expense',
    this.allowZeroAmount = true,
    this.categorySortOption = 'lastUsed',
    this.lastUsedIncomeCategoryId,
    this.lastUsedExpenseCategoryId,
    this.appLockEnabled = false,
    this.appPinCode,
    this.appPassword,
    this.autoLockTimeout = 'immediate',
    this.biometricUnlockEnabled = true,
    this.notificationsEnabled = false,
    final List<int> budgetAlertThresholds = const [75, 90, 100],
    this.recurringRemindersEnabled = true,
    this.recurringReminderAdvanceDays = 1,
    this.weeklySpendingSummaryEnabled = false,
    this.weeklySpendingSummaryDay = 1,
    this.encryptAttachments = false,
    this.homeShowBudgetProgress = true,
    final List<String> homeSectionOrder = const [
      'accounts',
      'totalBalance',
      'quickActions',
      'budgetProgress',
      'recentTransactions',
    ],
  }) : _budgetAlertThresholds = budgetAlertThresholds,
       _homeSectionOrder = homeSectionOrder;

  factory _$SettingsDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SettingsDataImplFromJson(json);

  /// Fixed ID - always 'app_settings'
  @override
  @JsonKey()
  final String id;

  /// Theme mode: 'dark', 'light', 'system'
  @override
  @JsonKey()
  final String themeMode;

  /// Color intensity: 'prism', 'zen', 'neon'
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

  /// Main currency code (ISO 4217)
  @override
  @JsonKey()
  final String mainCurrencyCode;

  /// Exchange rate API option: 'frankfurter', 'exchangeRateHost', 'manual'
  @override
  @JsonKey()
  final String exchangeRateApiOption;

  /// Cached exchange rates as JSON string
  @override
  final String? cachedExchangeRates;

  /// Timestamp of last successful rate fetch
  @override
  final int? lastRateFetchTimestamp;

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

  /// Whether to pre-select last used category
  @override
  @JsonKey()
  final bool selectLastCategory;

  /// Whether to pre-select last used account
  @override
  @JsonKey()
  final bool selectLastAccount;

  /// Number of accounts shown before "More" button
  @override
  @JsonKey()
  final int accountsFoldedCount;

  /// Number of categories shown before "More" button
  @override
  @JsonKey()
  final int categoriesFoldedCount;

  /// Whether to show "New Account" button in form
  @override
  @JsonKey()
  final bool showAddAccountButton;

  /// Whether to show "New" category button in form
  @override
  @JsonKey()
  final bool showAddCategoryButton;

  /// Default transaction type: 'income' or 'expense'
  @override
  @JsonKey()
  final String defaultTransactionType;

  /// Whether to allow saving with amount = 0
  @override
  @JsonKey()
  final bool allowZeroAmount;

  /// Category sort option: 'lastUsed', 'listOrder', 'alphabetical'
  @override
  @JsonKey()
  final String categorySortOption;

  /// Last used category ID for income transactions
  @override
  final String? lastUsedIncomeCategoryId;

  /// Last used category ID for expense transactions
  @override
  final String? lastUsedExpenseCategoryId;

  /// Whether app lock (biometric/PIN) is enabled
  @override
  @JsonKey()
  final bool appLockEnabled;

  /// App PIN code (stored as plaintext 4-8 digit string)
  @override
  final String? appPinCode;

  /// App password (stored as plaintext string)
  @override
  final String? appPassword;

  /// Auto-lock timeout: 'immediate', 'after30Seconds', 'after1Minute', 'after5Minutes', 'after15Minutes', 'never'
  @override
  @JsonKey()
  final String autoLockTimeout;

  /// Whether biometric unlock is enabled (when hardware is available)
  @override
  @JsonKey()
  final bool biometricUnlockEnabled;

  /// Whether notifications are enabled
  @override
  @JsonKey()
  final bool notificationsEnabled;

  /// Budget alert thresholds (percentages)
  final List<int> _budgetAlertThresholds;

  /// Budget alert thresholds (percentages)
  @override
  @JsonKey()
  List<int> get budgetAlertThresholds {
    if (_budgetAlertThresholds is EqualUnmodifiableListView)
      return _budgetAlertThresholds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_budgetAlertThresholds);
  }

  /// Whether recurring transaction reminders are enabled
  @override
  @JsonKey()
  final bool recurringRemindersEnabled;

  /// Days in advance for recurring reminders
  @override
  @JsonKey()
  final int recurringReminderAdvanceDays;

  /// Whether weekly spending summary is enabled
  @override
  @JsonKey()
  final bool weeklySpendingSummaryEnabled;

  /// Day of week for weekly summary (1=Monday, 7=Sunday)
  @override
  @JsonKey()
  final int weeklySpendingSummaryDay;

  /// Whether attachment files on disk are encrypted
  @override
  @JsonKey()
  final bool encryptAttachments;

  /// Whether budget progress is shown on home
  @override
  @JsonKey()
  final bool homeShowBudgetProgress;

  /// Home section ordering
  final List<String> _homeSectionOrder;

  /// Home section ordering
  @override
  @JsonKey()
  List<String> get homeSectionOrder {
    if (_homeSectionOrder is EqualUnmodifiableListView)
      return _homeSectionOrder;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_homeSectionOrder);
  }

  @override
  String toString() {
    return 'SettingsData(id: $id, themeMode: $themeMode, colorIntensity: $colorIntensity, accentColorIndex: $accentColorIndex, accountCardStyle: $accountCardStyle, tabTransitionsEnabled: $tabTransitionsEnabled, formAnimationsEnabled: $formAnimationsEnabled, balanceCountersEnabled: $balanceCountersEnabled, dateFormat: $dateFormat, mainCurrencyCode: $mainCurrencyCode, exchangeRateApiOption: $exchangeRateApiOption, cachedExchangeRates: $cachedExchangeRates, lastRateFetchTimestamp: $lastRateFetchTimestamp, firstDayOfWeek: $firstDayOfWeek, hapticFeedbackEnabled: $hapticFeedbackEnabled, startScreen: $startScreen, lastUsedAccountId: $lastUsedAccountId, selectLastCategory: $selectLastCategory, selectLastAccount: $selectLastAccount, accountsFoldedCount: $accountsFoldedCount, categoriesFoldedCount: $categoriesFoldedCount, showAddAccountButton: $showAddAccountButton, showAddCategoryButton: $showAddCategoryButton, defaultTransactionType: $defaultTransactionType, allowZeroAmount: $allowZeroAmount, categorySortOption: $categorySortOption, lastUsedIncomeCategoryId: $lastUsedIncomeCategoryId, lastUsedExpenseCategoryId: $lastUsedExpenseCategoryId, appLockEnabled: $appLockEnabled, appPinCode: $appPinCode, appPassword: $appPassword, autoLockTimeout: $autoLockTimeout, biometricUnlockEnabled: $biometricUnlockEnabled, notificationsEnabled: $notificationsEnabled, budgetAlertThresholds: $budgetAlertThresholds, recurringRemindersEnabled: $recurringRemindersEnabled, recurringReminderAdvanceDays: $recurringReminderAdvanceDays, weeklySpendingSummaryEnabled: $weeklySpendingSummaryEnabled, weeklySpendingSummaryDay: $weeklySpendingSummaryDay, encryptAttachments: $encryptAttachments, homeShowBudgetProgress: $homeShowBudgetProgress, homeSectionOrder: $homeSectionOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
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
            (identical(other.mainCurrencyCode, mainCurrencyCode) ||
                other.mainCurrencyCode == mainCurrencyCode) &&
            (identical(other.exchangeRateApiOption, exchangeRateApiOption) ||
                other.exchangeRateApiOption == exchangeRateApiOption) &&
            (identical(other.cachedExchangeRates, cachedExchangeRates) ||
                other.cachedExchangeRates == cachedExchangeRates) &&
            (identical(other.lastRateFetchTimestamp, lastRateFetchTimestamp) ||
                other.lastRateFetchTimestamp == lastRateFetchTimestamp) &&
            (identical(other.firstDayOfWeek, firstDayOfWeek) ||
                other.firstDayOfWeek == firstDayOfWeek) &&
            (identical(other.hapticFeedbackEnabled, hapticFeedbackEnabled) ||
                other.hapticFeedbackEnabled == hapticFeedbackEnabled) &&
            (identical(other.startScreen, startScreen) ||
                other.startScreen == startScreen) &&
            (identical(other.lastUsedAccountId, lastUsedAccountId) ||
                other.lastUsedAccountId == lastUsedAccountId) &&
            (identical(other.selectLastCategory, selectLastCategory) ||
                other.selectLastCategory == selectLastCategory) &&
            (identical(other.selectLastAccount, selectLastAccount) ||
                other.selectLastAccount == selectLastAccount) &&
            (identical(other.accountsFoldedCount, accountsFoldedCount) ||
                other.accountsFoldedCount == accountsFoldedCount) &&
            (identical(other.categoriesFoldedCount, categoriesFoldedCount) ||
                other.categoriesFoldedCount == categoriesFoldedCount) &&
            (identical(other.showAddAccountButton, showAddAccountButton) ||
                other.showAddAccountButton == showAddAccountButton) &&
            (identical(other.showAddCategoryButton, showAddCategoryButton) ||
                other.showAddCategoryButton == showAddCategoryButton) &&
            (identical(other.defaultTransactionType, defaultTransactionType) ||
                other.defaultTransactionType == defaultTransactionType) &&
            (identical(other.allowZeroAmount, allowZeroAmount) ||
                other.allowZeroAmount == allowZeroAmount) &&
            (identical(other.categorySortOption, categorySortOption) ||
                other.categorySortOption == categorySortOption) &&
            (identical(
                  other.lastUsedIncomeCategoryId,
                  lastUsedIncomeCategoryId,
                ) ||
                other.lastUsedIncomeCategoryId == lastUsedIncomeCategoryId) &&
            (identical(
                  other.lastUsedExpenseCategoryId,
                  lastUsedExpenseCategoryId,
                ) ||
                other.lastUsedExpenseCategoryId == lastUsedExpenseCategoryId) &&
            (identical(other.appLockEnabled, appLockEnabled) ||
                other.appLockEnabled == appLockEnabled) &&
            (identical(other.appPinCode, appPinCode) ||
                other.appPinCode == appPinCode) &&
            (identical(other.appPassword, appPassword) ||
                other.appPassword == appPassword) &&
            (identical(other.autoLockTimeout, autoLockTimeout) ||
                other.autoLockTimeout == autoLockTimeout) &&
            (identical(other.biometricUnlockEnabled, biometricUnlockEnabled) ||
                other.biometricUnlockEnabled == biometricUnlockEnabled) &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled) &&
            const DeepCollectionEquality().equals(
              other._budgetAlertThresholds,
              _budgetAlertThresholds,
            ) &&
            (identical(
                  other.recurringRemindersEnabled,
                  recurringRemindersEnabled,
                ) ||
                other.recurringRemindersEnabled == recurringRemindersEnabled) &&
            (identical(
                  other.recurringReminderAdvanceDays,
                  recurringReminderAdvanceDays,
                ) ||
                other.recurringReminderAdvanceDays ==
                    recurringReminderAdvanceDays) &&
            (identical(
                  other.weeklySpendingSummaryEnabled,
                  weeklySpendingSummaryEnabled,
                ) ||
                other.weeklySpendingSummaryEnabled ==
                    weeklySpendingSummaryEnabled) &&
            (identical(
                  other.weeklySpendingSummaryDay,
                  weeklySpendingSummaryDay,
                ) ||
                other.weeklySpendingSummaryDay == weeklySpendingSummaryDay) &&
            (identical(other.encryptAttachments, encryptAttachments) ||
                other.encryptAttachments == encryptAttachments) &&
            (identical(other.homeShowBudgetProgress, homeShowBudgetProgress) ||
                other.homeShowBudgetProgress == homeShowBudgetProgress) &&
            const DeepCollectionEquality().equals(
              other._homeSectionOrder,
              _homeSectionOrder,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    themeMode,
    colorIntensity,
    accentColorIndex,
    accountCardStyle,
    tabTransitionsEnabled,
    formAnimationsEnabled,
    balanceCountersEnabled,
    dateFormat,
    mainCurrencyCode,
    exchangeRateApiOption,
    cachedExchangeRates,
    lastRateFetchTimestamp,
    firstDayOfWeek,
    hapticFeedbackEnabled,
    startScreen,
    lastUsedAccountId,
    selectLastCategory,
    selectLastAccount,
    accountsFoldedCount,
    categoriesFoldedCount,
    showAddAccountButton,
    showAddCategoryButton,
    defaultTransactionType,
    allowZeroAmount,
    categorySortOption,
    lastUsedIncomeCategoryId,
    lastUsedExpenseCategoryId,
    appLockEnabled,
    appPinCode,
    appPassword,
    autoLockTimeout,
    biometricUnlockEnabled,
    notificationsEnabled,
    const DeepCollectionEquality().hash(_budgetAlertThresholds),
    recurringRemindersEnabled,
    recurringReminderAdvanceDays,
    weeklySpendingSummaryEnabled,
    weeklySpendingSummaryDay,
    encryptAttachments,
    homeShowBudgetProgress,
    const DeepCollectionEquality().hash(_homeSectionOrder),
  ]);

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
    final String themeMode,
    final String colorIntensity,
    final int accentColorIndex,
    final String accountCardStyle,
    final bool tabTransitionsEnabled,
    final bool formAnimationsEnabled,
    final bool balanceCountersEnabled,
    final String dateFormat,
    final String mainCurrencyCode,
    final String exchangeRateApiOption,
    final String? cachedExchangeRates,
    final int? lastRateFetchTimestamp,
    final String firstDayOfWeek,
    final bool hapticFeedbackEnabled,
    final String startScreen,
    final String? lastUsedAccountId,
    final bool selectLastCategory,
    final bool selectLastAccount,
    final int accountsFoldedCount,
    final int categoriesFoldedCount,
    final bool showAddAccountButton,
    final bool showAddCategoryButton,
    final String defaultTransactionType,
    final bool allowZeroAmount,
    final String categorySortOption,
    final String? lastUsedIncomeCategoryId,
    final String? lastUsedExpenseCategoryId,
    final bool appLockEnabled,
    final String? appPinCode,
    final String? appPassword,
    final String autoLockTimeout,
    final bool biometricUnlockEnabled,
    final bool notificationsEnabled,
    final List<int> budgetAlertThresholds,
    final bool recurringRemindersEnabled,
    final int recurringReminderAdvanceDays,
    final bool weeklySpendingSummaryEnabled,
    final int weeklySpendingSummaryDay,
    final bool encryptAttachments,
    final bool homeShowBudgetProgress,
    final List<String> homeSectionOrder,
  }) = _$SettingsDataImpl;

  factory _SettingsData.fromJson(Map<String, dynamic> json) =
      _$SettingsDataImpl.fromJson;

  /// Fixed ID - always 'app_settings'
  @override
  String get id;

  /// Theme mode: 'dark', 'light', 'system'
  @override
  String get themeMode;

  /// Color intensity: 'prism', 'zen', 'neon'
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

  /// Main currency code (ISO 4217)
  @override
  String get mainCurrencyCode;

  /// Exchange rate API option: 'frankfurter', 'exchangeRateHost', 'manual'
  @override
  String get exchangeRateApiOption;

  /// Cached exchange rates as JSON string
  @override
  String? get cachedExchangeRates;

  /// Timestamp of last successful rate fetch
  @override
  int? get lastRateFetchTimestamp;

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

  /// Whether to pre-select last used category
  @override
  bool get selectLastCategory;

  /// Whether to pre-select last used account
  @override
  bool get selectLastAccount;

  /// Number of accounts shown before "More" button
  @override
  int get accountsFoldedCount;

  /// Number of categories shown before "More" button
  @override
  int get categoriesFoldedCount;

  /// Whether to show "New Account" button in form
  @override
  bool get showAddAccountButton;

  /// Whether to show "New" category button in form
  @override
  bool get showAddCategoryButton;

  /// Default transaction type: 'income' or 'expense'
  @override
  String get defaultTransactionType;

  /// Whether to allow saving with amount = 0
  @override
  bool get allowZeroAmount;

  /// Category sort option: 'lastUsed', 'listOrder', 'alphabetical'
  @override
  String get categorySortOption;

  /// Last used category ID for income transactions
  @override
  String? get lastUsedIncomeCategoryId;

  /// Last used category ID for expense transactions
  @override
  String? get lastUsedExpenseCategoryId;

  /// Whether app lock (biometric/PIN) is enabled
  @override
  bool get appLockEnabled;

  /// App PIN code (stored as plaintext 4-8 digit string)
  @override
  String? get appPinCode;

  /// App password (stored as plaintext string)
  @override
  String? get appPassword;

  /// Auto-lock timeout: 'immediate', 'after30Seconds', 'after1Minute', 'after5Minutes', 'after15Minutes', 'never'
  @override
  String get autoLockTimeout;

  /// Whether biometric unlock is enabled (when hardware is available)
  @override
  bool get biometricUnlockEnabled;

  /// Whether notifications are enabled
  @override
  bool get notificationsEnabled;

  /// Budget alert thresholds (percentages)
  @override
  List<int> get budgetAlertThresholds;

  /// Whether recurring transaction reminders are enabled
  @override
  bool get recurringRemindersEnabled;

  /// Days in advance for recurring reminders
  @override
  int get recurringReminderAdvanceDays;

  /// Whether weekly spending summary is enabled
  @override
  bool get weeklySpendingSummaryEnabled;

  /// Day of week for weekly summary (1=Monday, 7=Sunday)
  @override
  int get weeklySpendingSummaryDay;

  /// Whether attachment files on disk are encrypted
  @override
  bool get encryptAttachments;

  /// Whether budget progress is shown on home
  @override
  bool get homeShowBudgetProgress;

  /// Home section ordering
  @override
  List<String> get homeSectionOrder;

  /// Create a copy of SettingsData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsDataImplCopyWith<_$SettingsDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
