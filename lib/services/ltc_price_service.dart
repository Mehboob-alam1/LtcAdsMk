import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches Litecoin price and history from CoinGecko (free, no key).
class LtcPriceService {
  LtcPriceService._();

  static final LtcPriceService instance = LtcPriceService._();

  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  double? _lastPrice;
  List<LtcPricePoint>? _lastHistory;
  DateTime? _lastFetch;

  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'GIGA-LTC-Mining/1.0 (https://example.com)',
  };

  /// Current LTC price in USD. Cached for a short time.
  Future<double?> getCurrentPrice() async {
    if (_lastPrice != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      return _lastPrice;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/simple/price?ids=litecoin&vs_currencies=usd',
      );
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) return _lastPrice;
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final ltc = map['litecoin'];
      if (ltc is Map && ltc['usd'] != null) {
        _lastPrice = (ltc['usd'] as num).toDouble();
        _lastFetch = DateTime.now();
        return _lastPrice;
      }
    } catch (_) {}
    return _lastPrice;
  }

  DateTime? _lastHistoryFetch;

  /// History for chart: last 7 days by default. Returns [timestampMs, price].
  Future<List<LtcPricePoint>> getPriceHistory({int days = 7}) async {
    final cached = _lastHistory;
    if (cached != null &&
        cached.isNotEmpty &&
        _lastHistoryFetch != null &&
        DateTime.now().difference(_lastHistoryFetch!).inMinutes < 10) {
      return cached;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/coins/litecoin/market_chart?vs_currency=usd&days=$days',
      );
      var response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 2));
        response = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 20),
        );
      }
      if (response.statusCode != 200) return _lastHistory ?? [];
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final prices = map['prices'] as List<dynamic>?;
      if (prices == null || prices.isEmpty) return _lastHistory ?? [];
      final list = prices
          .map((e) {
            final pair = e as List<dynamic>;
            if (pair.length >= 2) {
              return LtcPricePoint(
                (pair[0] as num).toDouble(),
                (pair[1] as num).toDouble(),
              );
            }
            return null;
          })
          .whereType<LtcPricePoint>()
          .toList();
      if (list.isNotEmpty) {
        _lastHistory = list;
        _lastHistoryFetch = DateTime.now();
      }
      return list;
    } catch (_) {}
    return _lastHistory ?? [];
  }
}

class LtcPricePoint {
  final double timestampMs;
  final double priceUsd;

  LtcPricePoint(this.timestampMs, this.priceUsd);
}
