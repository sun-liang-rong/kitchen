enum SpiritStage {
  baby,
  growing,
  intimate,
}

enum SpiritMood {
  normal,
  happy,
  hungry,
  excited,
}

enum SpiritStyle {
  flame,
  shadow,
  celestial,
}

enum FeedType {
  normal,
  delicate,
  feast,
}

enum PointTransactionType {
  earn,
  spend,
}

enum PointReason {
  checkin,
  createWish,
  respondWish,
  confirmResponse,
  fulfillWish,
  addDish,
  feedSpirit,
}

enum SpiritLogType {
  checkin,
  feed,
  levelUp,
  stageChanged,
  wishFulfilled,
}

class CoupleSpirit {
  const CoupleSpirit({
    required this.id,
    required this.name,
    required this.level,
    required this.exp,
    required this.stage,
    required this.mood,
    required this.style,
    required this.appearance,
    required this.expToNextLevel,
    required this.createdAt,
    required this.updatedAt,
    this.lastFedAt,
  });

  final String id;
  final String name;
  final int level;
  final int exp;
  final SpiritStage stage;
  final SpiritMood mood;
  final SpiritStyle style;
  final String appearance;
  final int expToNextLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastFedAt;

  double get progress {
    if (expToNextLevel <= 0) {
      return 1;
    }
    return (exp / expToNextLevel).clamp(0, 1).toDouble();
  }
}

class PointAccount {
  const PointAccount({
    required this.id,
    required this.coupleId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String coupleId;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CheckinStatus {
  const CheckinStatus({
    required this.checkedInToday,
    required this.streakDays,
    required this.todayPoints,
    required this.checkinDate,
  });

  final bool checkedInToday;
  final int streakDays;
  final int todayPoints;
  final DateTime checkinDate;
}

class SpiritHome {
  const SpiritHome({
    required this.spirit,
    required this.points,
    required this.checkin,
  });

  final CoupleSpirit spirit;
  final PointAccount points;
  final CheckinStatus checkin;
}

class SpiritFeedResult {
  const SpiritFeedResult({
    required this.spirit,
    required this.points,
    required this.levelUp,
    required this.stageChanged,
  });

  final CoupleSpirit spirit;
  final PointAccount points;
  final bool levelUp;
  final bool stageChanged;
}

class CheckinResult {
  const CheckinResult({
    required this.alreadyCheckedIn,
    required this.points,
    required this.status,
    this.spirit,
  });

  final bool alreadyCheckedIn;
  final PointAccount points;
  final CheckinStatus status;
  final CoupleSpirit? spirit;
}

class PointTransaction {
  const PointTransaction({
    required this.id,
    required this.type,
    required this.reason,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.relatedId,
    this.description,
  });

  final String id;
  final PointTransactionType type;
  final PointReason reason;
  final int amount;
  final int balanceAfter;
  final DateTime createdAt;
  final String? relatedId;
  final String? description;
}

class SpiritGrowthLog {
  const SpiritGrowthLog({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final SpiritLogType type;
  final String content;
  final DateTime createdAt;
  final Map<String, Object?> metadata;
}

String feedTypeToApi(FeedType type) {
  return switch (type) {
    FeedType.normal => 'NORMAL',
    FeedType.delicate => 'DELICATE',
    FeedType.feast => 'FEAST',
  };
}

String feedTypeLabel(FeedType type) {
  return switch (type) {
    FeedType.normal => '家常投喂',
    FeedType.delicate => '精致点心',
    FeedType.feast => '丰盛大餐',
  };
}

int feedTypeCost(FeedType type) {
  return switch (type) {
    FeedType.normal => 10,
    FeedType.delicate => 30,
    FeedType.feast => 80,
  };
}

int feedTypeExp(FeedType type) {
  return switch (type) {
    FeedType.normal => 10,
    FeedType.delicate => 35,
    FeedType.feast => 100,
  };
}

String spiritStageLabel(SpiritStage stage) {
  return switch (stage) {
    SpiritStage.baby => '幼年期',
    SpiritStage.growing => '成长期',
    SpiritStage.intimate => '亲密期',
  };
}

String spiritStyleToApi(SpiritStyle style) {
  return switch (style) {
    SpiritStyle.flame => 'FLAME',
    SpiritStyle.shadow => 'SHADOW',
    SpiritStyle.celestial => 'CELESTIAL',
  };
}

String spiritStyleLabel(SpiritStyle style) {
  return switch (style) {
    SpiritStyle.flame => '曜焰',
    SpiritStyle.shadow => '影刃',
    SpiritStyle.celestial => '星穹',
  };
}

String spiritStyleDescription(SpiritStyle style) {
  return switch (style) {
    SpiritStyle.flame => '热烈、利落，像小小的厨房火种。',
    SpiritStyle.shadow => '酷一点的暗色系，带一点守护感。',
    SpiritStyle.celestial => '清亮的星光系，轻盈但很有存在感。',
  };
}

String spiritAssetFor(String appearance) {
  return switch (appearance) {
    'flame_baby' => 'assets/spirit/flame_baby.png',
    'flame_growing' => 'assets/spirit/flame_growing.png',
    'flame_intimate' => 'assets/spirit/flame_intimate.png',
    'shadow_baby' => 'assets/spirit/shadow_baby.png',
    'shadow_growing' => 'assets/spirit/shadow_growing.png',
    'shadow_intimate' => 'assets/spirit/shadow_intimate.png',
    'celestial_baby' => 'assets/spirit/celestial_baby.png',
    'celestial_growing' => 'assets/spirit/celestial_growing.png',
    'celestial_intimate' => 'assets/spirit/celestial_intimate.png',
    'spirit_growing' => 'assets/spirit/spirit_growing.png',
    'spirit_intimate' => 'assets/spirit/spirit_intimate.png',
    _ => 'assets/spirit/spirit_baby.png',
  };
}
