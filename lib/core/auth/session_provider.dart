// lib/core/auth/session_provider.dart
// Twende: Tenant & Branch context, sync status.
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../store/json_document_store.dart';

// ─── Tenant Config ────────────────────────────────────────────────────────────
class TenantConfig {
  final String id;
  final String name;
  final String currency;
  final String taxMode; // 'inclusive' | 'exclusive'
  final double taxRate;
  final List<String> languages;
  final double discountApprovalThreshold;
  final double refundApprovalThreshold;
  final double defaultDepositAmount;
  final int defaultDailyMileageAllowanceKm;
  final int lateReturnGraceMinutes;
  final int turnaroundBufferHours;
  final String rentalDayDefinition; // '24h' | 'calendar'
  final Map<String, bool> featureFlags;

  const TenantConfig({
    required this.id,
    required this.name,
    this.currency = 'RWF',
    this.taxMode = 'inclusive',
    this.taxRate = 0.18,
    this.languages = const ['en', 'rw', 'fr'],
    this.discountApprovalThreshold = AppConstants.discountApprovalThreshold,
    this.refundApprovalThreshold = AppConstants.refundApprovalThresholdRwf,
    this.defaultDepositAmount = AppConstants.defaultDepositAmount,
    this.defaultDailyMileageAllowanceKm = AppConstants.defaultDailyMileageAllowanceKm,
    this.lateReturnGraceMinutes = AppConstants.lateReturnGraceMinutes,
    this.turnaroundBufferHours = AppConstants.turnaroundBufferHours,
    this.rentalDayDefinition = '24h',
    this.featureFlags = const {},
  });

  factory TenantConfig.demo() => const TenantConfig(
        id: 'twende-demo',
        name: 'Twende Demo',
        currency: 'RWF',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'taxMode': taxMode,
        'taxRate': taxRate,
        'languages': languages,
        'discountApprovalThreshold': discountApprovalThreshold,
        'refundApprovalThreshold': refundApprovalThreshold,
        'defaultDepositAmount': defaultDepositAmount,
        'defaultDailyMileageAllowanceKm': defaultDailyMileageAllowanceKm,
        'lateReturnGraceMinutes': lateReturnGraceMinutes,
        'turnaroundBufferHours': turnaroundBufferHours,
        'rentalDayDefinition': rentalDayDefinition,
        'featureFlags': featureFlags,
      };

  factory TenantConfig.fromJson(Map<String, dynamic> json) => TenantConfig(
        id: json['id'] as String? ?? 'twende-demo',
        name: json['name'] as String? ?? 'Twende Demo',
        currency: json['currency'] as String? ?? 'RWF',
        taxMode: json['taxMode'] as String? ?? 'inclusive',
        taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.18,
        languages: (json['languages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['en', 'rw', 'fr'],
        discountApprovalThreshold:
            (json['discountApprovalThreshold'] as num?)?.toDouble() ??
                AppConstants.discountApprovalThreshold,
        refundApprovalThreshold:
            (json['refundApprovalThreshold'] as num?)?.toDouble() ??
                AppConstants.refundApprovalThresholdRwf,
        defaultDepositAmount:
            (json['defaultDepositAmount'] as num?)?.toDouble() ??
                AppConstants.defaultDepositAmount,
        defaultDailyMileageAllowanceKm:
            (json['defaultDailyMileageAllowanceKm'] as num?)?.toInt() ??
                AppConstants.defaultDailyMileageAllowanceKm,
        lateReturnGraceMinutes:
            (json['lateReturnGraceMinutes'] as num?)?.toInt() ??
                AppConstants.lateReturnGraceMinutes,
        turnaroundBufferHours:
            (json['turnaroundBufferHours'] as num?)?.toInt() ??
                AppConstants.turnaroundBufferHours,
        rentalDayDefinition: json['rentalDayDefinition'] as String? ?? '24h',
        featureFlags: (json['featureFlags'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(key, value == true)) ??
            const {},
      );

  TenantConfig copyWith({
    String? currency,
    String? taxMode,
    double? taxRate,
    double? discountApprovalThreshold,
    double? refundApprovalThreshold,
    double? defaultDepositAmount,
    int? defaultDailyMileageAllowanceKm,
    int? lateReturnGraceMinutes,
    int? turnaroundBufferHours,
    Map<String, bool>? featureFlags,
  }) =>
      TenantConfig(
        id: id,
        name: name,
        currency: currency ?? this.currency,
        taxMode: taxMode ?? this.taxMode,
        taxRate: taxRate ?? this.taxRate,
        discountApprovalThreshold:
            discountApprovalThreshold ?? this.discountApprovalThreshold,
        refundApprovalThreshold:
            refundApprovalThreshold ?? this.refundApprovalThreshold,
        defaultDepositAmount: defaultDepositAmount ?? this.defaultDepositAmount,
        defaultDailyMileageAllowanceKm:
            defaultDailyMileageAllowanceKm ?? this.defaultDailyMileageAllowanceKm,
        lateReturnGraceMinutes:
            lateReturnGraceMinutes ?? this.lateReturnGraceMinutes,
        turnaroundBufferHours:
            turnaroundBufferHours ?? this.turnaroundBufferHours,
        featureFlags: featureFlags ?? this.featureFlags,
      );
}

// ─── Branch ───────────────────────────────────────────────────────────────────
class Branch {
  final String id;
  final String name;
  final String timezone;
  final String? address;
  final String? phone;

  const Branch({
    required this.id,
    required this.name,
    this.timezone = 'Africa/Kigali',
    this.address,
    this.phone,
  });

  factory Branch.demo() => const Branch(
        id: 'branch-kigali-main',
        name: 'Kigali Main',
        timezone: 'Africa/Kigali',
        address: 'KN 4 Ave, Kigali',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'timezone': timezone};
  factory Branch.fromJson(Map<String, dynamic> m) =>
      Branch(id: m['id'], name: m['name'], timezone: m['timezone'] ?? 'Africa/Kigali');
}

// ─── Sync Status ──────────────────────────────────────────────────────────────
enum AppSyncStatus { online, offline, syncing }

// ─── Session State ────────────────────────────────────────────────────────────
class SessionState {
  final TenantConfig tenantConfig;
  final Branch? selectedBranch;
  final List<Branch> availableBranches;
  final AppSyncStatus syncStatus;
  final bool isLoading;

  const SessionState({
    required this.tenantConfig,
    this.selectedBranch,
    this.availableBranches = const [],
    this.syncStatus = AppSyncStatus.online,
    this.isLoading = false,
  });

  SessionState copyWith({
    TenantConfig? tenantConfig,
    Branch? selectedBranch,
    List<Branch>? availableBranches,
    AppSyncStatus? syncStatus,
    bool? isLoading,
  }) =>
      SessionState(
        tenantConfig: tenantConfig ?? this.tenantConfig,
        selectedBranch: selectedBranch ?? this.selectedBranch,
        availableBranches: availableBranches ?? this.availableBranches,
        syncStatus: syncStatus ?? this.syncStatus,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class SessionNotifier extends StateNotifier<SessionState> {
  final _storage = const FlutterSecureStorage();
  final JsonDocumentStore _store = JsonDocumentStore.instance;

  SessionNotifier()
      : super(SessionState(
          tenantConfig: TenantConfig.demo(),
          selectedBranch: Branch.demo(),
          availableBranches: [Branch.demo()],
        )) {
    _loadSavedBranch();
    _loadSavedTenantConfig();
  }

  Future<void> _loadSavedBranch() async {
    try {
      final raw = await _storage.read(key: AppConstants.branchStorageKey);
      if (raw != null) {
        final branch = Branch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        state = state.copyWith(selectedBranch: branch);
      }
    } catch (_) {}
  }

  Future<void> _loadSavedTenantConfig() async {
    try {
      await _store.initialize();
      final data = await _store.readDocument('tenant_settings', 'active');
      if (data.isEmpty) {
        final raw = await _storage.read(key: AppConstants.tenantStorageKey);
        if (raw == null || raw.isEmpty) {
          return;
        }
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          state = state.copyWith(tenantConfig: TenantConfig.fromJson(parsed));
        }
        return;
      }
      state = state.copyWith(tenantConfig: TenantConfig.fromJson(data));
    } catch (_) {}
  }

  Future<void> selectBranch(Branch branch) async {
    state = state.copyWith(selectedBranch: branch);
    await _storage.write(
      key: AppConstants.branchStorageKey,
      value: jsonEncode(branch.toJson()),
    );
  }

  Future<void> updateTenantConfig(TenantConfig config) async {
    final previous = state.tenantConfig.toJson();
    state = state.copyWith(tenantConfig: config);
    try {
      await _store.initialize();
      await _store.apply(
        StoreWriteCommand(
          collection: 'tenant_settings',
          entityId: 'active',
          action: 'update',
          actor: 'tenant-admin',
          reason: 'Save tenant config',
          before: previous,
          after: config.toJson(),
          metadata: {'source': 'session_provider'},
        ),
      );
      await _storage.write(
        key: AppConstants.tenantStorageKey,
        value: jsonEncode(config.toJson()),
      );
    } catch (_) {}
  }

  void setSyncStatus(AppSyncStatus status) =>
      state = state.copyWith(syncStatus: status);
}

// ─── Providers ────────────────────────────────────────────────────────────────
final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) => SessionNotifier());

final tenantConfigProvider =
    Provider<TenantConfig>((ref) => ref.watch(sessionProvider).tenantConfig);

final selectedBranchProvider =
    Provider<Branch?>((ref) => ref.watch(sessionProvider).selectedBranch);

final syncStatusProvider =
    Provider<AppSyncStatus>((ref) => ref.watch(sessionProvider).syncStatus);
