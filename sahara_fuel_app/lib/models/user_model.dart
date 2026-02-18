import 'package:flutter/material.dart';

/// أدوار المستخدمين
enum UserRole { admin, manager, operator, viewer, auditor }

extension UserRoleExt on UserRole {
  String get arabicName {
    switch (this) {
      case UserRole.admin: return 'مدير النظام';
      case UserRole.manager: return 'مدير المحطة';
      case UserRole.operator: return 'مشغّل';
      case UserRole.viewer: return 'مستعرض';
      case UserRole.auditor: return 'مدقق';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin: return const Color(0xFFEF5350);
      case UserRole.manager: return const Color(0xFF8B5CF6);
      case UserRole.operator: return const Color(0xFF00D9A3);
      case UserRole.viewer: return const Color(0xFF42A5F5);
      case UserRole.auditor: return const Color(0xFFFFA726);
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin: return Icons.admin_panel_settings;
      case UserRole.manager: return Icons.manage_accounts;
      case UserRole.operator: return Icons.engineering;
      case UserRole.viewer: return Icons.visibility;
      case UserRole.auditor: return Icons.fact_check;
    }
  }
}

/// نموذج المستخدم
class AppUser {
  final String id, name, email, phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, bool> permissions;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    Map<String, bool>? permissions,
  }) : permissions = permissions ?? defaultPermsForRole(role);

  static Map<String, bool> defaultPermsForRole(UserRole role) {
       final all = {
      'dashboard': true, 'incoming_report': true, 'sahara_balance': true,
      'union_balance': true, 'tanks': true, 'reports': true,
      'advanced_reports': true, 'station_manager': true, 'data_management': true,
      'notifications': true, 'settings': true, 'audit_trail': true,
      'gas_balance': true, 
      'vehicles': true,
      'deserty_eye': true,
 // ← أضف هذا السطر
    };
;
    switch (role) {
      case UserRole.admin: return all;
      case UserRole.manager: return {...all, 'settings': false, 'audit_trail': false};
      case UserRole.operator: return {...all, 'settings': false, 'audit_trail': false, 'union_balance': false, 'sahara_balance': false, 'advanced_reports': false, 'station_manager': false};
      case UserRole.viewer: return all.map((k, _) => MapEntry(k, k == 'dashboard' || k == 'reports' || k == 'notifications'));
      case UserRole.auditor: return {...all, 'settings': false};
    }
  }

  AppUser copyWith({String? name, String? email, String? phone, UserRole? role, bool? isActive, Map<String, bool>? permissions}) =>
    AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLogin: lastLogin,
      permissions: permissions ?? this.permissions,
    );
}

/// سجل تسجيل الدخول
class LoginRecord {
  final String userId, userName, email;
  final DateTime time;
  final bool success;
  LoginRecord({required this.userId, required this.userName, required this.email, required this.time, required this.success});
}
