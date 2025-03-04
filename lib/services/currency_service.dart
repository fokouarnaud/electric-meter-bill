import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/currency_model.dart';
import '../domain/entities/currency.dart';

class CurrencyService {
  static const String _currencyCodeKey = 'currency_code';
  static const String _exchangeRatesKey = 'exchange_rates';
  static const String _lastUpdatedKey = 'exchange_rates_last_updated';
  static const String _baseCurrency = 'XAF'; // FCFA as base currency
  static const Duration _refreshInterval = Duration(hours: 12);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  static SharedPreferences? _prefs;
  Timer? _refreshTimer;
  final _connectivity = Connectivity();

  final List<CurrencyModel> _supportedCurrencies = [
    CurrencyModel.fcfa(),
    CurrencyModel.euro(),
    CurrencyModel.usd(),
  ];

  final String _apiKey;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Set default currency if not set
    if (_prefs!.getString(_currencyCodeKey) == null) {
      await _prefs!.setString(_currencyCodeKey, _baseCurrency);
    }
  }

  CurrencyService({required String apiKey}) : _apiKey = apiKey {
    // Load saved rates or defaults
    _loadExchangeRatesFromPrefs().then((_) {
      // Attempt immediate update of exchange rates
      updateExchangeRates().then((success) {
        if (!success) {
          debugPrint('Initial exchange rate update failed, will retry later');
        }
      });

      // Start periodic refresh
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(_refreshInterval, (_) {
        updateExchangeRates();
      });
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
  }

  Future<void> loadExchangeRatesFromPrefs() async {
    await _loadExchangeRatesFromPrefs();
  }

  CurrencyModel getActiveCurrency() {
    if (_prefs == null) {
      return CurrencyModel.fcfa(); // Default to base currency (FCFA)
    }

    final String? currencyCode = _prefs!.getString(_currencyCodeKey);
    if (currencyCode == null) {
      return CurrencyModel.fcfa();
    }

    return _supportedCurrencies.firstWhere(
      (currency) => currency.code == currencyCode,
      orElse: () => CurrencyModel.fcfa(),
    );
  }

  Future<void> setActiveCurrency(String currencyCode) async {
    if (_prefs == null) {
      await initialize();
    }

    await _prefs!.setString(_currencyCodeKey, currencyCode);
  }

  List<CurrencyModel> getSupportedCurrencies() {
    return _supportedCurrencies;
  }

  double convertAmount({
    required double amount,
    required String fromCurrencyCode,
    required String toCurrencyCode,
  }) {
    if (fromCurrencyCode == toCurrencyCode) {
      return amount;
    }

    final Currency from = _supportedCurrencies.firstWhere(
      (currency) => currency.code == fromCurrencyCode,
      orElse: () => CurrencyModel.fcfa(),
    );

    final Currency to = _supportedCurrencies.firstWhere(
      (currency) => currency.code == toCurrencyCode,
      orElse: () => CurrencyModel.fcfa(),
    );

    // Convert from source currency to base currency (FCFA)
    final double amountInBaseCurrency =
        from.code == _baseCurrency ? amount : amount / from.exchangeRate;

    // Convert from base currency to target currency
    return to.code == _baseCurrency
        ? amountInBaseCurrency
        : amountInBaseCurrency * to.exchangeRate;
  }

  String formatAmount(double amount, CurrencyModel currency) {
    return '${currency.symbol} ${amount.toStringAsFixed(2)}';
  }

  Future<bool> updateExchangeRates([int retryCount = 0]) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('No internet connection available');
        return false;
      }

      // Build API URL with proper error handling
      final uri = Uri.https('api.currencyapi.com', '/v3/latest', {
        'apikey': _apiKey,
        'base_currency': _baseCurrency,
        'currencies': _supportedCurrencies
            .where((c) => c.code != _baseCurrency)
            .map((c) => c.code)
            .join(','),
      });

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('The connection has timed out'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['data'] as Map<String, dynamic>;

        bool hasUpdates = false;
        for (var i = 0; i < _supportedCurrencies.length; i++) {
          final currency = _supportedCurrencies[i];
          if (currency.code != _baseCurrency &&
              rates.containsKey(currency.code)) {
            final rate = rates[currency.code]['value'] as double;
            if (currency.exchangeRate != rate) {
              hasUpdates = true;
              _supportedCurrencies[i] = currency.copyWith(
                exchangeRate: rate,
                lastUpdated: DateTime.now(),
              );
            }
          }
        }

        if (hasUpdates) {
          await _saveExchangeRatesToPrefs();
          debugPrint('Exchange rates updated successfully');
        } else {
          debugPrint('Exchange rates are already up to date');
        }
        return true;
      } else if (response.statusCode == 429 && retryCount < _maxRetries) {
        // Rate limit hit, retry after delay
        await Future<void>.delayed(_retryDelay * (retryCount + 1));
        return updateExchangeRates(retryCount + 1);
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout error: $e');
      if (retryCount < _maxRetries) {
        await Future<void>.delayed(_retryDelay * (retryCount + 1));
        return updateExchangeRates(retryCount + 1);
      }
      return false;
    } catch (e) {
      debugPrint('Error updating exchange rates: $e');
      if (retryCount < _maxRetries) {
        await Future<void>.delayed(_retryDelay * (retryCount + 1));
        return updateExchangeRates(retryCount + 1);
      }
      return false;
    }
  }

  DateTime? getLastUpdated() {
    if (_prefs == null) {
      return null;
    }

    final String? lastUpdatedString = _prefs!.getString(_lastUpdatedKey);
    if (lastUpdatedString == null) {
      return null;
    }

    return DateTime.parse(lastUpdatedString);
  }

  Future<void> _saveExchangeRatesToPrefs() async {
    if (_prefs == null) {
      await initialize();
    }

    final List<Map<String, dynamic>> ratesJson =
        _supportedCurrencies.map((currency) => currency.toJson()).toList();

    await _prefs!.setString(_exchangeRatesKey, json.encode(ratesJson));
    await _prefs!.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  Future<void> _loadExchangeRatesFromPrefs() async {
    if (_prefs == null) {
      return;
    }

    final String? ratesJson = _prefs!.getString(_exchangeRatesKey);
    if (ratesJson == null) {
      return;
    }

    try {
      final List<dynamic> ratesList = json.decode(ratesJson) as List<dynamic>;
      final List<CurrencyModel> loadedCurrencies = ratesList
          .map((rateJson) =>
              CurrencyModel.fromJson(rateJson as Map<String, dynamic>))
          .toList();

      // Update supported currencies with loaded values
      for (var i = 0; i < _supportedCurrencies.length; i++) {
        final loadedCurrency = loadedCurrencies.firstWhere(
          (currency) => currency.code == _supportedCurrencies[i].code,
          orElse: () => _supportedCurrencies[i],
        );
        _supportedCurrencies[i] = loadedCurrency;
      }
    } catch (e) {
      debugPrint('Error loading exchange rates: $e');
    }
  }
}
