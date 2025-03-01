import 'package:flutter/foundation.dart';
import '../../../data/models/currency_model.dart';

abstract class CurrencyEvent {
  const CurrencyEvent();
}

class LoadCurrency extends CurrencyEvent {
  const LoadCurrency();
}

class ChangeCurrency extends CurrencyEvent {
  final String currencyCode;

  const ChangeCurrency(this.currencyCode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChangeCurrency && other.currencyCode == currencyCode;
  }

  @override
  int get hashCode => currencyCode.hashCode;
}

class UpdateExchangeRates extends CurrencyEvent {
  const UpdateExchangeRates();
}

class ConvertAmount extends CurrencyEvent {
  final double amount;
  final String fromCurrency;
  final String toCurrency;

  const ConvertAmount({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConvertAmount &&
        other.amount == amount &&
        other.fromCurrency == fromCurrency &&
        other.toCurrency == toCurrency;
  }

  @override
  int get hashCode =>
      amount.hashCode ^ fromCurrency.hashCode ^ toCurrency.hashCode;
}
