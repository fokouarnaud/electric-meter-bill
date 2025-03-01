import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/currency_model.dart';
import '../../../services/currency_service.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final CurrencyService _currencyService;

  CurrencyBloc(this._currencyService)
      : super(
          CurrencyState(
            activeCurrency: _currencyService.getActiveCurrency(),
            supportedCurrencies: _currencyService.getSupportedCurrencies(),
            lastUpdated: _currencyService.getLastUpdated(),
          ),
        ) {
    on<LoadCurrency>(_onLoadCurrency);
    on<ChangeCurrency>(_onChangeCurrency);
    on<UpdateExchangeRates>(_onUpdateExchangeRates);
    on<ConvertAmount>(_onConvertAmount);
  }

  Future<void> _onLoadCurrency(
      LoadCurrency event, Emitter<CurrencyState> emit) async {
    emit(state.copyWith(status: CurrencyStatus.loading));
    try {
      final activeCurrency = _currencyService.getActiveCurrency();
      final supportedCurrencies = _currencyService.getSupportedCurrencies();
      final lastUpdated = _currencyService.getLastUpdated();

      emit(state.copyWith(
        status: CurrencyStatus.loaded,
        activeCurrency: activeCurrency,
        supportedCurrencies: supportedCurrencies,
        lastUpdated: lastUpdated,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CurrencyStatus.error,
        errorMessage: 'Failed to load currency: ${e.toString()}',
      ));
    }
  }

  Future<void> _onChangeCurrency(
      ChangeCurrency event, Emitter<CurrencyState> emit) async {
    emit(state.copyWith(status: CurrencyStatus.loading));
    try {
      await _currencyService.setActiveCurrency(event.currencyCode);
      final activeCurrency = _currencyService.getActiveCurrency();

      emit(state.copyWith(
        status: CurrencyStatus.loaded,
        activeCurrency: activeCurrency,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CurrencyStatus.error,
        errorMessage: 'Failed to change currency: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateExchangeRates(
      UpdateExchangeRates event, Emitter<CurrencyState> emit) async {
    emit(state.copyWith(status: CurrencyStatus.loading));
    try {
      final result = await _currencyService.updateExchangeRates();
      if (result) {
        final supportedCurrencies = _currencyService.getSupportedCurrencies();
        final lastUpdated = _currencyService.getLastUpdated();

        emit(state.copyWith(
          status: CurrencyStatus.loaded,
          supportedCurrencies: supportedCurrencies,
          lastUpdated: lastUpdated,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: CurrencyStatus.error,
          errorMessage:
              'Failed to update exchange rates. Please check your internet connection.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CurrencyStatus.error,
        errorMessage: 'Failed to update exchange rates: ${e.toString()}',
      ));
    }
  }

  void _onConvertAmount(ConvertAmount event, Emitter<CurrencyState> emit) {
    try {
      final convertedAmount = _currencyService.convertAmount(
        amount: event.amount,
        fromCurrencyCode: event.fromCurrency,
        toCurrencyCode: event.toCurrency,
      );

      emit(state.copyWith(
        convertedAmount: convertedAmount,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CurrencyStatus.error,
        errorMessage: 'Failed to convert amount: ${e.toString()}',
        clearConvertedAmount: true,
      ));
    }
  }

  String formatAmount(double amount) {
    return _currencyService.formatAmount(amount, state.activeCurrency);
  }
}
