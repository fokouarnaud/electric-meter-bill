import '../../domain/entities/currency.dart';

class CurrencyModel extends Currency {
  final DateTime? lastUpdated;

  const CurrencyModel({
    required super.code,
    required super.name,
    required super.symbol,
    required super.exchangeRate,
    this.lastUpdated,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      code: json['code'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      exchangeRate: (json['exchange_rate'] as num).toDouble(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String,
      exchangeRate: (map['exchange_rate'] as num).toDouble(),
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'exchange_rate': exchangeRate,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'exchange_rate': exchangeRate,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  @override
  CurrencyModel copyWith({
    String? code,
    String? name,
    String? symbol,
    double? exchangeRate,
    DateTime? lastUpdated,
  }) {
    return CurrencyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory CurrencyModel.fromCurrency(Currency currency) {
    if (currency is CurrencyModel) {
      return currency;
    }
    return CurrencyModel(
      code: currency.code,
      name: currency.name,
      symbol: currency.symbol,
      exchangeRate: currency.exchangeRate,
      lastUpdated: null,
    );
  }

  factory CurrencyModel.fcfa() {
    return CurrencyModel(
      code: 'XAF',
      name: 'Franc CFA',
      symbol: 'FCFA',
      exchangeRate: 1.0,
      lastUpdated: DateTime.now(),
    );
  }

  factory CurrencyModel.euro() {
    return CurrencyModel(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      exchangeRate: 0.00152,
      lastUpdated: DateTime.now(),
    );
  }

  factory CurrencyModel.usd() {
    return CurrencyModel(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      exchangeRate: 0.00165,
      lastUpdated: DateTime.now(),
    );
  }
}
