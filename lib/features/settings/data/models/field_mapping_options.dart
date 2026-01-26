/// How to resolve foreign key references (category/account) during import.
enum ForeignKeyResolutionMode {
  /// Map from CSV column(s) - by name, ID, or both.
  mapFromCsv('Map from CSV'),

  /// Use the same entity for all imported rows.
  useSameForAll('Use Same for All');

  final String displayName;
  const ForeignKeyResolutionMode(this.displayName);
}

/// How to resolve amount and transaction type during import.
enum AmountResolutionMode {
  /// Separate columns for amount (always positive) and type (income/expense).
  separateAmountAndType('Separate Amount & Type'),

  /// Single column where positive = income, negative = expense.
  signedAmount('Signed Amount');

  final String displayName;
  const AmountResolutionMode(this.displayName);
}

/// Configuration for resolving amount and transaction type during import.
class AmountConfig {
  /// The resolution mode.
  final AmountResolutionMode mode;

  /// CSV column for amount value.
  final String? amountColumn;

  /// CSV column for transaction type (only for separateAmountAndType mode).
  final String? typeColumn;

  const AmountConfig({
    this.mode = AmountResolutionMode.separateAmountAndType,
    this.amountColumn,
    this.typeColumn,
  });

  AmountConfig copyWith({
    AmountResolutionMode? mode,
    String? amountColumn,
    bool clearAmountColumn = false,
    String? typeColumn,
    bool clearTypeColumn = false,
  }) {
    return AmountConfig(
      mode: mode ?? this.mode,
      amountColumn: clearAmountColumn ? null : (amountColumn ?? this.amountColumn),
      typeColumn: clearTypeColumn ? null : (typeColumn ?? this.typeColumn),
    );
  }

  /// Whether this config is valid for proceeding with import.
  bool get isValid {
    if (amountColumn == null) return false;
    switch (mode) {
      case AmountResolutionMode.separateAmountAndType:
        // Need both amount and type columns
        return typeColumn != null;
      case AmountResolutionMode.signedAmount:
        // Only need amount column
        return true;
    }
  }

  /// Get a display string describing the current configuration.
  String getDisplaySummary() {
    switch (mode) {
      case AmountResolutionMode.separateAmountAndType:
        if (amountColumn != null && typeColumn != null) {
          return '"$amountColumn" + "$typeColumn"';
        } else if (amountColumn != null) {
          return '"$amountColumn"';
        } else if (typeColumn != null) {
          return '"$typeColumn"';
        }
        return 'Select fields...';
      case AmountResolutionMode.signedAmount:
        if (amountColumn != null) {
          return '"$amountColumn"';
        }
        return 'Select field...';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmountConfig &&
        other.mode == mode &&
        other.amountColumn == amountColumn &&
        other.typeColumn == typeColumn;
  }

  @override
  int get hashCode => Object.hash(mode, amountColumn, typeColumn);
}

/// Configuration for resolving a foreign key (category or account) during import.
/// This consolidates the old categoryId/categoryName and accountId/accountName
/// into a single, clearer configuration per entity type.
class ForeignKeyConfig {
  /// The resolution mode.
  final ForeignKeyResolutionMode mode;

  /// CSV column to map entity name from (for mapFromCsv mode).
  final String? nameColumn;

  /// CSV column to map entity ID from (for mapFromCsv mode).
  final String? idColumn;

  /// Selected entity ID (for useSameForAll mode).
  final String? selectedEntityId;

  const ForeignKeyConfig({
    this.mode = ForeignKeyResolutionMode.mapFromCsv,
    this.nameColumn,
    this.idColumn,
    this.selectedEntityId,
  });

  ForeignKeyConfig copyWith({
    ForeignKeyResolutionMode? mode,
    String? nameColumn,
    bool clearNameColumn = false,
    String? idColumn,
    bool clearIdColumn = false,
    String? selectedEntityId,
    bool clearSelectedEntityId = false,
  }) {
    return ForeignKeyConfig(
      mode: mode ?? this.mode,
      nameColumn: clearNameColumn ? null : (nameColumn ?? this.nameColumn),
      idColumn: clearIdColumn ? null : (idColumn ?? this.idColumn),
      selectedEntityId: clearSelectedEntityId
          ? null
          : (selectedEntityId ?? this.selectedEntityId),
    );
  }

  /// Whether this config is valid for proceeding with import.
  bool get isValid {
    switch (mode) {
      case ForeignKeyResolutionMode.mapFromCsv:
        // At least one column must be selected
        return nameColumn != null || idColumn != null;
      case ForeignKeyResolutionMode.useSameForAll:
        // An entity must be selected
        return selectedEntityId != null;
    }
  }

  /// Get a display string describing the current configuration.
  String getDisplaySummary({String? entityName}) {
    switch (mode) {
      case ForeignKeyResolutionMode.mapFromCsv:
        if (nameColumn != null && idColumn != null) {
          return 'Mapping "$nameColumn" + "$idColumn"';
        } else if (nameColumn != null) {
          return 'Mapping "$nameColumn" column';
        } else if (idColumn != null) {
          return 'Mapping "$idColumn" column';
        }
        return 'Select column...';
      case ForeignKeyResolutionMode.useSameForAll:
        if (entityName != null) {
          return 'Using: $entityName';
        }
        return 'Select...';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForeignKeyConfig &&
        other.mode == mode &&
        other.nameColumn == nameColumn &&
        other.idColumn == idColumn &&
        other.selectedEntityId == selectedEntityId;
  }

  @override
  int get hashCode => Object.hash(mode, nameColumn, idColumn, selectedEntityId);
}
