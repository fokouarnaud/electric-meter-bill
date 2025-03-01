import 'package:flutter/foundation.dart';
import '../../../data/models/currency_model.dart';

enum CurrencyStatus { initial, loading, loaded, error }

class CurrencyState {
  final CurrencyStatus status;
  final CurrencyModel activeCurrency;
  final List<CurrencyModel> supportedCurrencies;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final double? convertedAmount;

  const CurrencyState({
    this.status = CurrencyStatus.initial,
    required this.activeCurrency,
    required this.supportedCurrencies,
    this.errorMessage,
    this.lastUpdated,
    this.convertedAmount,
  });

  CurrencyState copyWith({
    CurrencyStatus? status,
    CurrencyModel? activeCurrency,
    List<CurrencyModel>? supportedCurrencies,
    String? errorMessage,
    DateTime? lastUpdated,
    double? convertedAmount,
    bool clearError = false,
    bool clearConvertedAmount = false,
  }) {
    return CurrencyState(
      status: status ?? this.status,
      activeCurrency: activeCurrency ?? this.activeCurrency,
      supportedCurrencies: supportedCurrencies ?? this.supportedCurrencies,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      convertedAmount:
          clearConvertedAmount ? null : convertedAmount ?? this.convertedAmount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyState &&
        other.status == status &&
        other.activeCurrency == activeCurrency &&
        listEquals(other.supportedCurrencies, supportedCurrencies) &&
        other.errorMessage == errorMessage &&
        other.lastUpdated == lastUpdated &&
        other.convertedAmount == convertedAmount;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        activeCurrency.hashCode ^
        supportedCurrencies.hashCode ^
        errorMessage.hashCode ^
        lastUpdated.hashCode ^
        convertedAmount.hashCode;
  }
}
