class Currency {
  final String code;
  final String name;
  final String symbol;
  final double exchangeRate;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.exchangeRate,
  });

  factory Currency.fcfa() {
    return const Currency(
      code: 'XAF',
      name: 'Franc CFA',
      symbol: 'FCFA',
      exchangeRate: 1.0, // Base currency
    );
  }

  factory Currency.euro() {
    return const Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      exchangeRate: 0.00152, // 1 FCFA = 0.00152 EUR
    );
  }

  factory Currency.usd() {
    return const Currency(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      exchangeRate: 0.00165, // 1 FCFA = 0.00165 USD
    );
  }

  Currency copyWith({
    String? code,
    String? name,
    String? symbol,
    double? exchangeRate,
  }) {
    return Currency(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency &&
        other.code == code &&
        other.name == name &&
        other.symbol == symbol &&
        other.exchangeRate == exchangeRate;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        name.hashCode ^
        symbol.hashCode ^
        exchangeRate.hashCode;
  }

  @override
  String toString() {
    return 'Currency(code: $code, name: $name, symbol: $symbol, exchangeRate: $exchangeRate)';
  }
}
