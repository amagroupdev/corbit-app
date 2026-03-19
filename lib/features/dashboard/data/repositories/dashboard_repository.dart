import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/api_constants.dart';
import 'package:orbit_app/core/network/api_client.dart';
import 'package:orbit_app/features/dashboard/data/models/dashboard_model.dart';

/// Repository responsible for fetching all data displayed on the dashboard.
///
/// Aggregates calls to the balance, services, and banner endpoints
/// and maps the raw JSON into strongly-typed models.
class DashboardRepository {
  DashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  // ─── Dashboard Stats ────────────────────────────────────────────────

  /// Fetches the combined dashboard statistics by calling the
  /// `/dashboard` endpoint which returns balance, services count,
  /// consumed points, groups count, and sub-accounts count.
  ///
  /// Falls back to calling individual endpoints if the dashboard
  /// aggregate endpoint is unavailable.
  Future<DashboardStats> fetchDashboardStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.dashboard,
      );

      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return DashboardStats.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }

      // If the aggregate endpoint returned unexpected shape, try individual.
      return _fetchStatsFromIndividualEndpoints();
    } catch (_) {
      return _fetchStatsFromIndividualEndpoints();
    }
  }

  /// Fetches dashboard data from individual working API endpoints.
  ///
  /// Actual API responses (verified with curl):
  /// - GET /auth/me → user profile + balance
  /// - GET /balance/current → balance, expired_at, remaining_days
  /// - GET /balance/summary → current_balance, expiry_date, total_purchased, total_used
  /// - GET /balance/transactions → paginated transaction history
  Future<DashboardStats> _fetchStatsFromIndividualEndpoints() async {
    int currentBalance = 0;
    int servicesCount = 0;
    int consumedPoints = 0;
    int unreadNotifications = 0;
    int groupsCount = 0;
    int subAccountsCount = 0;
    String userName = '';
    String userAvatar = '';
    int totalBalance = 0;
    int remainingBalance = 0;
    int consumedBalance = 0;
    int transferredBalance = 0;
    DateTime? balanceExpiryDate;
    String accountLevel = '';
    double accountLevelProgress = 0.0;
    String nextLevelName = '';
    int nextLevelRequirement = 0;
    List<RecentMessage> recentMessages = [];

    // ── 1. Fetch user profile from /auth/me ──
    // Response: {"success":true,"data":{"id":...,"name":"azzam","email":"...",
    //   "balance":7,"profile_photo_url":"...","organization_name":"...",...}}
    try {
      final meResponse = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.me,
      );
      final meData = meResponse.data;
      debugPrint('[DashboardRepo] /auth/me response: $meData');
      if (meData != null) {
        final inner = meData['data'] as Map<String, dynamic>? ?? meData;
        debugPrint('[DashboardRepo] /auth/me inner data: $inner');
        userName = inner['name'] as String? ??
            inner['full_name'] as String? ??
            '';
        userAvatar = inner['profile_photo_url'] as String? ??
            inner['avatar_url'] as String? ??
            inner['avatar'] as String? ??
            '';
        debugPrint('[DashboardRepo] userName: $userName, userAvatar: $userAvatar');
        // /auth/me also has balance directly on the user object.
        currentBalance = _safeInt(inner['balance']);

        // Extract account level from price_category or similar fields.
        final priceCategory = inner['price_category'] as Map<String, dynamic>?;
        if (priceCategory != null) {
          accountLevel = priceCategory['name'] as String? ?? '';
        }
        if (accountLevel.isEmpty) {
          accountLevel = inner['account_level'] as String? ??
              inner['level'] as String? ??
              inner['price_category_name'] as String? ??
              '';
        }
      }
    } catch (e) {
      debugPrint('[DashboardRepo] /auth/me error: $e');
      // Silently ignore – dashboard will show default avatar.
    }

    // ── 2. Fetch balance current ──
    // Response: {"success":true,"data":{"balance":7,"expired_at":"2027-02-09","remaining_days":344}}
    try {
      final currentResponse = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.balanceCurrent,
      );
      final currentData = currentResponse.data;
      if (currentData != null) {
        final inner = currentData['data'] as Map<String, dynamic>? ?? currentData;
        final balFromCurrent = _safeInt(inner['balance']);
        if (balFromCurrent > 0) {
          currentBalance = balFromCurrent;
        }
        remainingBalance = balFromCurrent;
        if (inner['expired_at'] != null) {
          balanceExpiryDate = DateTime.tryParse(inner['expired_at'].toString());
        }
      }
    } catch (_) {
      // Silently ignore.
    }

    // ── 3. Fetch balance summary ──
    // Response: {"success":true,"data":{"current_balance":7,"expiry_date":"2027-02-09",
    //   "total_purchased":1014,"total_used":0}}
    try {
      final summaryResponse = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.balanceSummary,
      );
      final summaryData = summaryResponse.data;
      if (summaryData != null) {
        final inner = summaryData['data'] as Map<String, dynamic>? ?? summaryData;
        totalBalance = _safeInt(inner['total_purchased'] ?? inner['total'] ?? inner['total_balance']);
        remainingBalance = _safeInt(inner['current_balance'] ?? inner['remaining'] ?? remainingBalance);
        consumedBalance = _safeInt(inner['total_used'] ?? inner['consumed'] ?? inner['total_sent']);
        transferredBalance = _safeInt(inner['transferred'] ?? inner['transferred_balance']);
        if (balanceExpiryDate == null) {
          final expiryStr = inner['expiry_date'] ?? inner['expired_at'];
          if (expiryStr != null) {
            balanceExpiryDate = DateTime.tryParse(expiryStr.toString());
          }
        }
        // Update currentBalance from summary if we got a better value.
        final summaryBal = _safeInt(inner['current_balance']);
        if (summaryBal > 0 && currentBalance == 0) {
          currentBalance = summaryBal;
        }
      }
    } catch (_) {
      // Silently ignore.
    }

    // If totalBalance is still 0, set it equal to remainingBalance.
    if (totalBalance == 0 && remainingBalance > 0) {
      totalBalance = remainingBalance;
    }

    // ── 4. Fetch services count from /addons/list ──
    try {
      final addonsResponse = await _apiClient.post<Map<String, dynamic>>(
        '/addons/list',
        data: {'page': 1, 'per_page': 20},
      );
      final addonsData = addonsResponse.data;
      if (addonsData != null) {
        final dataField = addonsData['data'];
        if (dataField is Map<String, dynamic>) {
          final addonsList = dataField['data'] as List? ?? [];
          servicesCount = addonsList.where((item) {
            if (item is Map<String, dynamic>) {
              return item['user_status'] == 'activated';
            }
            return false;
          }).length;
        }
      }
    } catch (_) {
      // Silently ignore.
    }

    // consumedPoints = total messages used.
    // API total_used may return 0 incorrectly; fall back to calculation.
    consumedPoints = consumedBalance;
    if (consumedPoints == 0 && totalBalance > 0 && remainingBalance > 0) {
      consumedPoints = totalBalance - remainingBalance;
      consumedBalance = consumedPoints;
    }

    // ── 5. Fetch groups count from /groups/list ──
    try {
      final groupsResponse = await _apiClient.post<Map<String, dynamic>>(
        '/groups/list',
        data: {'page': 1, 'per_page': 100},
      );
      final groupsData = groupsResponse.data;
      debugPrint('[DashboardRepo] /groups/list response: $groupsData');
      if (groupsData != null) {
        final dataField = groupsData['data'];
        debugPrint('[DashboardRepo] /groups/list dataField: $dataField');
        if (dataField is Map<String, dynamic>) {
          // API format: {data: {groups: [...], pagination: {...}}}
          final groupsList = dataField['groups'] as List?;
          final meta = dataField['meta'] as Map<String, dynamic>?;
          final pagination = dataField['pagination'] as Map<String, dynamic>?;
          groupsCount = _safeInt(
            meta?['total'] ?? pagination?['total'] ?? dataField['total'],
          );
          debugPrint('[DashboardRepo] groups from meta/pagination: $groupsCount');
          // If no pagination total, count the groups list directly
          if (groupsCount == 0 && groupsList != null) {
            groupsCount = groupsList.length;
            debugPrint('[DashboardRepo] groups from list length: $groupsCount');
          }
          if (groupsCount == 0) {
            final list = dataField['data'] as List?;
            if (list != null && list.isNotEmpty) {
              groupsCount = list.length;
              debugPrint('[DashboardRepo] groups from data list: $groupsCount');
            }
          }
        } else if (dataField is List) {
          groupsCount = dataField.length;
          debugPrint('[DashboardRepo] groups from direct list: $groupsCount');
        }
      }
    } catch (e) {
      debugPrint('[DashboardRepo] /groups/list error: $e');
    }

    // ── 6. Fetch sub-accounts count from /settings/sub-accounts ──
    try {
      final subResponse = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.settingsSubAccounts,
        queryParameters: {'page': 1, 'per_page': 100},
      );
      final subData = subResponse.data;
      debugPrint('[DashboardRepo] /settings/sub-accounts response: $subData');
      if (subData != null) {
        final dataField = subData['data'];
        debugPrint('[DashboardRepo] /settings/sub-accounts dataField: $dataField');
        if (dataField is Map<String, dynamic>) {
          // Try sub_accounts or sub-accounts key
          final subList = dataField['sub_accounts'] as List? ??
              dataField['sub-accounts'] as List? ??
              dataField['subaccounts'] as List?;
          final meta = dataField['meta'] as Map<String, dynamic>?;
          final pagination = dataField['pagination'] as Map<String, dynamic>?;
          subAccountsCount = _safeInt(
            meta?['total'] ?? pagination?['total'] ?? dataField['total'],
          );
          debugPrint('[DashboardRepo] subAccounts from meta/pagination: $subAccountsCount');
          if (subAccountsCount == 0 && subList != null) {
            subAccountsCount = subList.length;
            debugPrint('[DashboardRepo] subAccounts from subList: $subAccountsCount');
          }
          if (subAccountsCount == 0) {
            final list = dataField['data'] as List?;
            if (list != null && list.isNotEmpty) {
              subAccountsCount = list.length;
              debugPrint('[DashboardRepo] subAccounts from data list: $subAccountsCount');
            }
          }
        } else if (dataField is List) {
          subAccountsCount = dataField.length;
          debugPrint('[DashboardRepo] subAccounts from direct list: $subAccountsCount');
        }
      }
    } catch (e) {
      debugPrint('[DashboardRepo] /settings/sub-accounts error: $e');
    }

    // ── 7. Fetch recent messages from archive ──
    try {
      final archiveResponse = await _apiClient.post<Map<String, dynamic>>(
        '/archive/list',
        data: {
          'archive_type': 'general',
          'page': 1,
          'per_page': 5,
        },
      );
      final archiveData = archiveResponse.data;
      debugPrint('[DashboardRepo] /archive/list response: $archiveData');
      if (archiveData != null && archiveData['data'] != null) {
        final dataField = archiveData['data'];
        debugPrint('[DashboardRepo] /archive/list dataField type: ${dataField.runtimeType}');
        List? messagesList;
        
        if (dataField is Map<String, dynamic>) {
          // API returns {messages: [...], pagination: {...}}
          messagesList = dataField['messages'] as List? ?? dataField['data'] as List?;
        } else if (dataField is List) {
          messagesList = dataField;
        }
        
        debugPrint('[DashboardRepo] /archive/list messages count: ${messagesList?.length ?? 0}');
        if (messagesList != null) {
          for (final item in messagesList) {
            if (item is Map<String, dynamic>) {
              recentMessages.add(RecentMessage.fromArchiveJson(item));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[DashboardRepo] /archive/list error: $e');
    }

    // ── 8. Fetch account level/upgrades ──
    // Response: paginated {"success":true,"data":{"data":[],"links":{...},"meta":{...}}}
    try {
      final upgradeResponse = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.balanceUpgrades,
      );
      final upgradeData = upgradeResponse.data;
      if (upgradeData != null) {
        final dataField = upgradeData['data'];
        // The /balance/upgrades response is paginated. If there are items,
        // we infer the account level from the user's purchase history.
        if (dataField is Map<String, dynamic>) {
          // Check for level info in meta or top-level fields.
          accountLevel = dataField['current_level'] as String? ??
              upgradeData['current_level'] as String? ??
              '';
          accountLevelProgress = _safeDouble(
              dataField['progress'] ?? upgradeData['progress']);
          nextLevelName = dataField['next_level'] as String? ??
              upgradeData['next_level'] as String? ??
              '';
          nextLevelRequirement = _safeInt(
              dataField['requirement'] ?? upgradeData['requirement']);
        }
      }
    } catch (_) {
      // Silently ignore.
    }

    // Derive account level from total_purchased if API didn't provide it.
    // Tiers: اساسي (0) → البرونزي (3,500) → الفضي (10,000) → الذهبي (50,000) → الماسي (100,000)
    if (accountLevel.isEmpty) {
      if (totalBalance >= 100000) {
        accountLevel = 'الماسي';
      } else if (totalBalance >= 50000) {
        accountLevel = 'الذهبي';
        nextLevelName = 'الماسي';
        nextLevelRequirement = 100000;
        accountLevelProgress = (totalBalance / 100000).clamp(0.0, 1.0);
      } else if (totalBalance >= 10000) {
        accountLevel = 'الفضي';
        nextLevelName = 'الذهبي';
        nextLevelRequirement = 50000;
        accountLevelProgress = (totalBalance / 50000).clamp(0.0, 1.0);
      } else if (totalBalance >= 3500) {
        accountLevel = 'البرونزي';
        nextLevelName = 'الفضي';
        nextLevelRequirement = 10000;
        accountLevelProgress = (totalBalance / 10000).clamp(0.0, 1.0);
      } else {
        accountLevel = 'اساسي';
        nextLevelName = 'البرونزي';
        nextLevelRequirement = 3500;
        accountLevelProgress = totalBalance > 0
            ? (totalBalance / 3500).clamp(0.0, 1.0)
            : 0.0;
      }
    }

    debugPrint('[DashboardRepo] Final stats:');
    debugPrint('  userName: $userName');
    debugPrint('  userAvatar: $userAvatar');
    debugPrint('  currentBalance: $currentBalance');
    debugPrint('  totalBalance: $totalBalance');
    debugPrint('  consumedBalance: $consumedBalance');
    debugPrint('  groupsCount: $groupsCount');
    debugPrint('  subAccountsCount: $subAccountsCount');
    debugPrint('  servicesCount: $servicesCount');
    debugPrint('  recentMessages: ${recentMessages.length}');

    return DashboardStats(
      currentBalance: currentBalance,
      servicesCount: servicesCount,
      consumedPoints: consumedPoints,
      unreadNotifications: unreadNotifications,
      groupsCount: groupsCount,
      subAccountsCount: subAccountsCount,
      userName: userName,
      userAvatar: userAvatar,
      totalBalance: totalBalance,
      remainingBalance: remainingBalance,
      consumedBalance: consumedBalance,
      transferredBalance: transferredBalance,
      balanceExpiryDate: balanceExpiryDate,
      accountLevel: accountLevel,
      accountLevelProgress: accountLevelProgress,
      nextLevelName: nextLevelName,
      nextLevelRequirement: nextLevelRequirement,
      recentMessages: recentMessages,
    );
  }

  // ─── Banners ────────────────────────────────────────────────────────

  /// Fetches promotional banners for the dashboard carousel.
  ///
  /// Endpoint: GET `/dashboard/banners` or falls back to the
  /// `banners` key inside the dashboard aggregate.
  Future<List<BannerItem>> fetchBanners() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.dashboardBanners,
      );

      final data = response.data;
      if (data != null && data['data'] != null) {
        final list = data['data'] as List<dynamic>? ?? [];
        return list
            .map((e) => BannerItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return _defaultBanners();
    } catch (_) {
      return _defaultBanners();
    }
  }

  /// Returns placeholder banners when the API is unavailable.
  List<BannerItem> _defaultBanners() {
    return const [
      BannerItem(
        id: 1,
        imageUrl: 'https://app.mobile.net.sa/image1.png',
        title: 'مرحبا بك في اوربت SMS',
        description: 'ارسل رسائلك بكل سهولة وسرعة',
      ),
      BannerItem(
        id: 2,
        imageUrl: 'https://app.mobile.net.sa/image2.jpg',
        title: 'عروض حصرية',
        description: 'احصل على خصومات تصل الى 30%',
      ),
    ];
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient);
});
