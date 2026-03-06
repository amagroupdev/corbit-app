/// Data models for the ORBIT SMS V3 Dashboard feature.
///
/// Contains [DashboardStats] for balance/service/point data,
/// [BannerItem] for promotional carousel items, and [QuickAction]
/// for the quick-access grid below the stats row.

class DashboardStats {
  const DashboardStats({
    required this.currentBalance,
    required this.servicesCount,
    required this.consumedPoints,
    this.unreadNotifications = 0,
    this.groupsCount = 0,
    this.subAccountsCount = 0,
    this.userName = '',
    this.userAvatar = '',
    this.totalBalance = 0,
    this.remainingBalance = 0,
    this.consumedBalance = 0,
    this.transferredBalance = 0,
    this.balanceExpiryDate,
    this.accountLevel = '',
    this.accountLevelProgress = 0.0,
    this.nextLevelName = '',
    this.nextLevelRequirement = 0,
    this.recentMessages = const [],
  });

  /// SMS credit balance (e.g. 40,541 messages remaining).
  final int currentBalance;

  /// Number of active services / addons.
  final int servicesCount;

  /// Points consumed in the current billing period.
  final int consumedPoints;

  /// Badge count shown on the notification bell.
  final int unreadNotifications;

  /// Total contact groups.
  final int groupsCount;

  /// Total sub-accounts under this user.
  final int subAccountsCount;

  /// Authenticated user's display name.
  final String userName;

  /// URL for the user's avatar image.
  final String userAvatar;

  // ── Balance Summary (matching new portal) ──
  final int totalBalance;
  final int remainingBalance;
  final int consumedBalance;
  final int transferredBalance;
  final DateTime? balanceExpiryDate;

  // ── Account Level (matching new portal) ──
  final String accountLevel;
  final double accountLevelProgress;
  final String nextLevelName;
  final int nextLevelRequirement;

  // ── Recent Messages (matching new portal) ──
  final List<RecentMessage> recentMessages;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Parse recent messages if present
    final messagesList = <RecentMessage>[];
    if (json['recent_messages'] is List) {
      for (final m in json['recent_messages'] as List) {
        if (m is Map<String, dynamic>) {
          messagesList.add(RecentMessage.fromJson(m));
        }
      }
    }

    // Parse account level info
    final levelData = json['account_level'] as Map<String, dynamic>? ?? {};

    // Parse balance summary
    final balanceData = json['balance_summary'] as Map<String, dynamic>? ?? {};

    return DashboardStats(
      currentBalance: _parseInt(json['current_balance']),
      servicesCount: _parseInt(json['services_count']),
      consumedPoints: _parseInt(json['consumed_points']),
      unreadNotifications: _parseInt(json['unread_notifications']),
      groupsCount: _parseInt(json['groups_count']),
      subAccountsCount: _parseInt(json['sub_accounts_count']),
      userName: json['user_name'] as String? ?? json['name'] as String? ?? '',
      userAvatar: json['user_avatar'] as String? ??
          json['profile_photo_url'] as String? ??
          json['avatar'] as String? ??
          '',
      // Balance summary
      totalBalance: _parseInt(balanceData['total'] ?? json['total_balance']),
      remainingBalance: _parseInt(balanceData['remaining'] ?? json['remaining_balance']),
      consumedBalance: _parseInt(balanceData['consumed'] ?? json['consumed_balance']),
      transferredBalance: _parseInt(balanceData['transferred'] ?? json['transferred_balance']),
      balanceExpiryDate: _parseDate(balanceData['expiry_date'] ?? json['balance_expiry_date'] ?? json['expired_at']),
      // Account level
      accountLevel: levelData['current'] as String? ?? json['account_level_name'] as String? ?? '',
      accountLevelProgress: _parseDouble(levelData['progress'] ?? json['account_level_progress']),
      nextLevelName: levelData['next'] as String? ?? json['next_level_name'] as String? ?? '',
      nextLevelRequirement: _parseInt(levelData['requirement'] ?? json['next_level_requirement']),
      // Recent messages
      recentMessages: messagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_balance': currentBalance,
      'services_count': servicesCount,
      'consumed_points': consumedPoints,
      'unread_notifications': unreadNotifications,
      'groups_count': groupsCount,
      'sub_accounts_count': subAccountsCount,
      'user_name': userName,
      'user_avatar': userAvatar,
      'total_balance': totalBalance,
      'remaining_balance': remainingBalance,
      'consumed_balance': consumedBalance,
      'transferred_balance': transferredBalance,
      'balance_expiry_date': balanceExpiryDate?.toIso8601String(),
      'account_level_name': accountLevel,
      'account_level_progress': accountLevelProgress,
      'next_level_name': nextLevelName,
      'next_level_requirement': nextLevelRequirement,
      'recent_messages': recentMessages.map((m) => m.toJson()).toList(),
    };
  }

  DashboardStats copyWith({
    int? currentBalance,
    int? servicesCount,
    int? consumedPoints,
    int? unreadNotifications,
    int? groupsCount,
    int? subAccountsCount,
    String? userName,
    String? userAvatar,
    int? totalBalance,
    int? remainingBalance,
    int? consumedBalance,
    int? transferredBalance,
    DateTime? balanceExpiryDate,
    String? accountLevel,
    double? accountLevelProgress,
    String? nextLevelName,
    int? nextLevelRequirement,
    List<RecentMessage>? recentMessages,
  }) {
    return DashboardStats(
      currentBalance: currentBalance ?? this.currentBalance,
      servicesCount: servicesCount ?? this.servicesCount,
      consumedPoints: consumedPoints ?? this.consumedPoints,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      groupsCount: groupsCount ?? this.groupsCount,
      subAccountsCount: subAccountsCount ?? this.subAccountsCount,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      totalBalance: totalBalance ?? this.totalBalance,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      consumedBalance: consumedBalance ?? this.consumedBalance,
      transferredBalance: transferredBalance ?? this.transferredBalance,
      balanceExpiryDate: balanceExpiryDate ?? this.balanceExpiryDate,
      accountLevel: accountLevel ?? this.accountLevel,
      accountLevelProgress: accountLevelProgress ?? this.accountLevelProgress,
      nextLevelName: nextLevelName ?? this.nextLevelName,
      nextLevelRequirement: nextLevelRequirement ?? this.nextLevelRequirement,
      recentMessages: recentMessages ?? this.recentMessages,
    );
  }

  /// Safely parses an int from a dynamic value (handles String and num).
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Message (shown on dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class RecentMessage {
  const RecentMessage({
    this.id = 0,
    this.senderName = '',
    this.messageType = '',
    this.sentAt,
    this.status = '',
    this.recipientCount = 0,
    this.amount = '',
    this.note = '',
    this.invoiceNo = '',
  });

  final int id;
  final String senderName;
  final String messageType;
  final DateTime? sentAt;
  final String status;
  final int recipientCount;
  final String amount;
  final String note;
  final String invoiceNo;

  /// Parses from either an archive message or a balance transaction.
  ///
  /// Transaction fields: id, invoice_no, amount, status, method, bank, note, created_at
  /// Archive fields: id, sender_name, message_type, sent_at, status, recipient_count
  factory RecentMessage.fromJson(Map<String, dynamic> json) {
    return RecentMessage(
      id: json['id'] as int? ?? 0,
      senderName: json['sender_name'] as String? ??
          json['sender'] as String? ??
          json['bank'] as String? ??
          '',
      messageType: json['message_type'] as String? ??
          json['type'] as String? ??
          json['method'] as String? ??
          '',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null),
      status: json['status'] as String? ?? '',
      recipientCount: json['recipient_count'] as int? ??
          json['recipients'] as int? ??
          0,
      amount: json['amount']?.toString() ?? '',
      note: json['note'] as String? ?? '',
      invoiceNo: json['invoice_no'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_name': senderName,
        'message_type': messageType,
        'sent_at': sentAt?.toIso8601String(),
        'status': status,
        'recipient_count': recipientCount,
        'amount': amount,
        'note': note,
        'invoice_no': invoiceNo,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner / Carousel Item
// ─────────────────────────────────────────────────────────────────────────────

class BannerItem {
  const BannerItem({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.description = '',
    this.linkUrl,
    this.sortOrder = 0,
  });

  final int id;
  final String imageUrl;
  final String title;
  final String description;
  final String? linkUrl;
  final int sortOrder;

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? json['image'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      linkUrl: json['link_url'] as String? ?? json['link'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'description': description,
      'link_url': linkUrl,
      'sort_order': sortOrder,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action
// ─────────────────────────────────────────────────────────────────────────────

class QuickAction {
  const QuickAction({
    required this.id,
    required this.title,
    required this.iconName,
    this.count = 0,
    this.subtitle = '',
    this.route = '',
  });

  final String id;
  final String title;
  final String iconName;
  final int count;
  final String subtitle;
  final String route;

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      iconName: json['icon_name'] as String? ?? json['icon'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      subtitle: json['subtitle'] as String? ?? '',
      route: json['route'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon_name': iconName,
      'count': count,
      'subtitle': subtitle,
      'route': route,
    };
  }
}
