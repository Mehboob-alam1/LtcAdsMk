import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches Kaspa price and history from CoinGecko (free, no key).
class KasPriceService {
  KasPriceService._();

  static final KasPriceService instance = KasPriceService._();

  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  double? _lastPrice;
  List<KasPricePoint>? _lastHistory;
  DateTime? _lastFetch;

  /// Current KAS price in USD. Cached for a short time.
  Future<double?> getCurrentPrice() async {
    if (_lastPrice != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      return _lastPrice;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/simple/price?ids=kaspa&vs_currencies=usd',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return _lastPrice;
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final kas = map['kaspa'];
      if (kas is Map && kas['usd'] != null) {
        _lastPrice = (kas['usd'] as num).toDouble();
        _lastFetch = DateTime.now();
        return _lastPrice;
      }
    } catch (_) {}
    return _lastPrice;
  }

  DateTime? _lastHistoryFetch;

  /// History for chart: last 7 days by default.
  Future<List<KasPricePoint>> getPriceHistory({int days = 7}) async {
    if (_lastHistory != null &&
        _lastHistoryFetch != null &&
        DateTime.now().difference(_lastHistoryFetch!).inMinutes < 10) {
      return _lastHistory!;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/coins/kaspa/market_chart?vs_currency=usd&days=$days',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return _lastHistory ?? [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final prices = map['prices'] as List<dynamic>?;
      if (prices == null || prices.isEmpty) return _lastHistory ?? [];
      final list = prices
          .map((e) {
            final pair = e as List<dynamic>;
            if (pair.length >= 2) {
              return KasPricePoint(
                (pair[0] as num).toDouble(),
                (pair[1] as num).toDouble(),
              );
            }
            return null;
          })
          .whereType<KasPricePoint>()
          .toList();
      _lastHistory = list;
      _lastHistoryFetch = DateTime.now();
      return list;
    } catch (_) {}
    return _lastHistory ?? [];
  }
}

class KasPricePoint {
  final double timestampMs;
  final double priceUsd;

  KasPricePoint(this.timestampMs, this.priceUsd);
}
