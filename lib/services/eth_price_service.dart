import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches ETH price and history from CoinGecko (free, no key).
class EthPriceService {
  EthPriceService._();

  static final EthPriceService instance = EthPriceService._();

  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  double? _lastPrice;
  List<EthPricePoint>? _lastHistory;
  DateTime? _lastFetch;

  /// Current ETH price in USD. Cached for a short time.
  Future<double?> getCurrentPrice() async {
    if (_lastPrice != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      return _lastPrice;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/simple/price?ids=ethereum&vs_currencies=usd',
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) return _lastPrice;
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final eth = map['ethereum'];
      if (eth is Map && eth['usd'] != null) {
        _lastPrice = (eth['usd'] as num).toDouble();
        _lastFetch = DateTime.now();
        return _lastPrice;
      }
    } catch (_) {}
    return _lastPrice;
  }

  /// History for chart: last 7 days by default. Returns [timestampMs, price].
  Future<List<EthPricePoint>> getPriceHistory({int days = 7}) async {
    if (_lastHistory != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 10) {
      return _lastHistory!;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/coins/ethereum/market_chart?vs_currency=usd&days=$days',
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) return _lastHistory ?? [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final prices = map['prices'] as List<dynamic>?;
      if (prices == null || prices.isEmpty) return _lastHistory ?? [];
      final list = prices
          .map((e) {
            final pair = e as List<dynamic>;
            if (pair.length >= 2) {
              return EthPricePoint(
                (pair[0] as num).toDouble(),
                (pair[1] as num).toDouble(),
              );
            }
            return null;
          })
          .whereType<EthPricePoint>()
          .toList();
      _lastHistory = list;
      _lastFetch = DateTime.now();
      return list;
    } catch (_) {}
    return _lastHistory ?? [];
  }
}

class EthPricePoint {
  final double timestampMs;
  final double priceUsd;

  EthPricePoint(this.timestampMs, this.priceUsd);
}
