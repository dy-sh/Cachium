class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });

  static const defaultCurrency = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    flag: '\u{1F1FA}\u{1F1F8}',
  );

  static Currency fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => defaultCurrency,
    );
  }

  static String symbolFromCode(String code) {
    return fromCode(code).symbol;
  }

  static const List<Currency> all = [
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '\u{1F1FA}\u{1F1F8}'),
    Currency(code: 'EUR', symbol: '\u20AC', name: 'Euro', flag: '\u{1F1EA}\u{1F1FA}'),
    Currency(code: 'GBP', symbol: '\u00A3', name: 'British Pound', flag: '\u{1F1EC}\u{1F1E7}'),
    Currency(code: 'JPY', symbol: '\u00A5', name: 'Japanese Yen', flag: '\u{1F1EF}\u{1F1F5}'),
    Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', flag: '\u{1F1E8}\u{1F1ED}'),
    Currency(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', flag: '\u{1F1E8}\u{1F1E6}'),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '\u{1F1E6}\u{1F1FA}'),
    Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar', flag: '\u{1F1F3}\u{1F1FF}'),
    Currency(code: 'CNY', symbol: '\u00A5', name: 'Chinese Yuan', flag: '\u{1F1E8}\u{1F1F3}'),
    Currency(code: 'INR', symbol: '\u20B9', name: 'Indian Rupee', flag: '\u{1F1EE}\u{1F1F3}'),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real', flag: '\u{1F1E7}\u{1F1F7}'),
    Currency(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso', flag: '\u{1F1F2}\u{1F1FD}'),
    Currency(code: 'KRW', symbol: '\u20A9', name: 'South Korean Won', flag: '\u{1F1F0}\u{1F1F7}'),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '\u{1F1F8}\u{1F1EC}'),
    Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar', flag: '\u{1F1ED}\u{1F1F0}'),
    Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona', flag: '\u{1F1F8}\u{1F1EA}'),
    Currency(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone', flag: '\u{1F1F3}\u{1F1F4}'),
    Currency(code: 'DKK', symbol: 'kr', name: 'Danish Krone', flag: '\u{1F1E9}\u{1F1F0}'),
    Currency(code: 'PLN', symbol: 'z\u0142', name: 'Polish Zloty', flag: '\u{1F1F5}\u{1F1F1}'),
    Currency(code: 'CZK', symbol: 'K\u010D', name: 'Czech Koruna', flag: '\u{1F1E8}\u{1F1FF}'),
    Currency(code: 'TRY', symbol: '\u20BA', name: 'Turkish Lira', flag: '\u{1F1F9}\u{1F1F7}'),
    Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand', flag: '\u{1F1FF}\u{1F1E6}'),
    Currency(code: 'RUB', symbol: '\u20BD', name: 'Russian Ruble', flag: '\u{1F1F7}\u{1F1FA}'),
    Currency(code: 'THB', symbol: '\u0E3F', name: 'Thai Baht', flag: '\u{1F1F9}\u{1F1ED}'),
    Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', flag: '\u{1F1EE}\u{1F1E9}'),
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', flag: '\u{1F1F2}\u{1F1FE}'),
    Currency(code: 'PHP', symbol: '\u20B1', name: 'Philippine Peso', flag: '\u{1F1F5}\u{1F1ED}'),
    Currency(code: 'AED', symbol: 'AED', name: 'UAE Dirham', flag: '\u{1F1E6}\u{1F1EA}'),
    Currency(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal', flag: '\u{1F1F8}\u{1F1E6}'),
    Currency(code: 'ILS', symbol: '\u20AA', name: 'Israeli Shekel', flag: '\u{1F1EE}\u{1F1F1}'),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
