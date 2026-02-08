import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches BTC price and history from CoinGecko (free, no key).
class BtcPriceService {
  BtcPriceService._();

  static final BtcPriceService instance = BtcPriceService._();

  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  double? _lastPrice;
  List<BtcPricePoint>? _lastHistory;
  DateTime? _lastFetch;

  /// Current BTC price in USD. Cached for a short time.
  Future<double?> getCurrentPrice() async {
    if (_lastPrice != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5) {
      return _lastPrice;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/simple/price?ids=bitcoin&vs_currencies=usd',
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) return _lastPrice;
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final btc = map['bitcoin'];
      if (btc is Map && btc['usd'] != null) {
        _lastPrice = (btc['usd'] as num).toDouble();
        _lastFetch = DateTime.now();
        return _lastPrice;
      }
    } catch (_) {}
    return _lastPrice;
  }

  /// History for chart: last 7 days by default. Returns [timestampMs, price].
  Future<List<BtcPricePoint>> getPriceHistory({int days = 7}) async {
    if (_lastHistory != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 10) {
      return _lastHistory!;
    }
    try {
      final uri = Uri.parse(
        '$_baseUrl/coins/bitcoin/market_chart?vs_currency=usd&days=$days',
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
              return BtcPricePoint(
                (pair[0] as num).toDouble(),
                (pair[1] as num).toDouble(),
              );
            }
            return null;
          })
          .whereType<BtcPricePoint>()
          .toList();
      _lastHistory = list;
      _lastFetch = DateTime.now();
      return list;
    } catch (_) {}
    return _lastHistory ?? [];
  }
}

class BtcPricePoint {
  final double timestampMs;
  final double priceUsd;

  BtcPricePoint(this.timestampMs, this.priceUsd);
}
