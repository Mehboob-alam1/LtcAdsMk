/// Shop item definitions: rigs, boosters, features. Unlock by watching ads.
class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.adsRequired,
    required this.description,
    required this.type,
    this.rigBonusPercent = 0,
    this.boosterMinutes,
    this.featureType,
  });

  final String id;
  final String name;
  final int adsRequired;
  final String description;
  final String type; // 'rig' | 'booster' | 'feature'
  final double rigBonusPercent;
  final int? boosterMinutes;
  final String? featureType;

  static const List<ShopItem> rigs = [
    ShopItem(
      id: 'rig1',
      name: 'Rig Tier 1',
      adsRequired: 2,
      description: '+10% mining rate permanently',
      type: 'rig',
      rigBonusPercent: 10,
    ),
    ShopItem(
      id: 'rig2',
      name: 'Rig Tier 2',
      adsRequired: 5,
      description: '+20% mining rate permanently',
      type: 'rig',
      rigBonusPercent: 20,
    ),
    ShopItem(
      id: 'rig3',
      name: 'Rig Tier 3',
      adsRequired: 10,
      description: '+35% mining rate permanently',
      type: 'rig',
      rigBonusPercent: 35,
    ),
  ];

  static const List<ShopItem> boosters = [
    ShopItem(
      id: 'megaBoost',
      name: 'Mega Boost',
      adsRequired: 3,
      description: '2x mining rate for 1 hour',
      type: 'booster',
      boosterMinutes: 60,
    ),
  ];

  static const List<ShopItem> features = [
    ShopItem(
      id: 'autoMiningDay',
      name: 'Auto mining 1 day',
      adsRequired: 5,
      description: 'Start a 24-hour mining session (one-time use)',
      type: 'feature',
      featureType: 'autoMiningDay',
    ),
    ShopItem(
      id: 'doubleSession',
      name: 'Double Session',
      adsRequired: 4,
      description: 'Next session lasts 8 hours instead of 4',
      type: 'feature',
      featureType: 'doubleSession',
    ),
  ];

  static List<ShopItem> get all => [...rigs, ...boosters, ...features];
  static ShopItem? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
