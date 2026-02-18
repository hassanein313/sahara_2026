import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/smart_alert_service.dart';

/// Phase 9 - تخطيط متجاوب
enum DeviceType { mobile, tablet, desktop }

DeviceType getDeviceType(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w < 700) return DeviceType.mobile;
  if (w < 1100) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// شريط جانبي مطوي (للموبايل والتابلت)
class CollapsibleSidebar extends StatefulWidget {
  final int selectedIndex;
  final List<SidebarItem> items;
  final ValueChanged<int> onItemSelected;
  final bool collapsed;
  final VoidCallback onToggle;
  final Widget? header;
  final Widget? footer;

  const CollapsibleSidebar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
    this.collapsed = false,
    required this.onToggle,
    this.header,
    this.footer,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    _widthAnim = Tween<double>(begin: 260, end: 72)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
    if (widget.collapsed) _anim.value = 1;
  }

  @override
  void didUpdateWidget(CollapsibleSidebar old) {
    super.didUpdateWidget(old);
    if (widget.collapsed != old.collapsed)
      widget.collapsed ? _anim.forward() : _anim.reverse();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _widthAnim,
        builder: (context, _) => Container(
              width: _widthAnim.value,
              decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  border: Border(
                      left: BorderSide(color: Colors.grey[800]!, width: 0.5))),
              child: Column(children: [
                // زر الطي
                Container(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                        onTap: widget.onToggle,
                        child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: const Color(0xFF1A1F2E),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(
                                widget.collapsed ? Icons.menu : Icons.menu_open,
                                color: AppColors.accent,
                                size: 20)))),

                // الهيدر
                if (widget.header != null && !widget.collapsed) widget.header!,

                // العناصر
                Expanded(
                    child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: widget.items.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          final isSelected = i == widget.selectedIndex;

                          if (item.isSection) {
                            return widget.collapsed
                                ? Divider(color: Colors.grey[800], height: 20)
                                : Padding(
                                    padding: const EdgeInsets.only(
                                        right: 12, top: 16, bottom: 6),
                                    child: Text(item.label,
                                        style: GoogleFonts.cairo(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)));
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.accent.withOpacity(0.25))
                                  : null,
                            ),
                            child: widget.collapsed
                                ? Tooltip(
                                    message: item.label,
                                    preferBelow: false,
                                    child: InkWell(
                                        onTap: item.locked
                                            ? null
                                            : () => widget.onItemSelected(i),
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                            height: 44,
                                            child: Center(
                                                child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                  Icon(item.icon,
                                                      color: item.locked
                                                          ? Colors.grey[700]
                                                          : isSelected
                                                              ? AppColors.accent
                                                              : Colors
                                                                  .grey[500],
                                                      size: 20),
                                                  if (item.badge > 0)
                                                    Positioned(
                                                        top: -4,
                                                        right: -4,
                                                        child: Container(
                                                            width: 14,
                                                            height: 14,
                                                            decoration:
                                                                BoxDecoration(
                                                                    color: Colors
                                                                        .red,
                                                                    shape: BoxShape
                                                                        .circle),
                                                            child: Center(
                                                                child: Text(
                                                                    '${item.badge}',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            8))))),
                                                  if (item.locked)
                                                    Positioned(
                                                        bottom: -2,
                                                        left: -2,
                                                        child: Icon(Icons.lock,
                                                            size: 8,
                                                            color: Colors
                                                                .grey[600])),
                                                ])))))
                                : ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    leading: Icon(item.icon,
                                        color: item.locked
                                            ? Colors.grey[700]
                                            : isSelected
                                                ? AppColors.accent
                                                : Colors.grey[500],
                                        size: 20),
                                    title: Text(item.label,
                                        style: GoogleFonts.cairo(
                                            color: item.locked
                                                ? Colors.grey[700]
                                                : isSelected
                                                    ? AppColors.accent
                                                    : Colors.white,
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w400)),
                                    trailing: item.badge > 0
                                        ? Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle),
                                            child: Text('${item.badge}',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9)))
                                        : item.locked
                                            ? Icon(Icons.lock,
                                                size: 12,
                                                color: Colors.grey[700])
                                            : null,
                                    onTap: item.locked
                                        ? null
                                        : () => widget.onItemSelected(i),
                                  ),
                          );
                        }).toList())),

                // الفوتر
                if (widget.footer != null && !widget.collapsed) widget.footer!,
              ]),
            ));
  }
}

class SidebarItem {
  final String label;
  final IconData icon;
  final bool isSection;
  final bool locked;
  final int badge;

  const SidebarItem(
      {required this.label,
      this.icon = Icons.circle,
      this.isSection = false,
      this.locked = false,
      this.badge = 0});
}

/// لوحة التنبيهات العائمة
class FloatingAlertsPanel extends StatelessWidget {
  const FloatingAlertsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final alertService = SmartAlertService();
    final active = alertService.activeAlerts;
    if (active.isEmpty) return const SizedBox();

    return Positioned(
        bottom: 80,
        left: 20,
        child: Container(
          width: 360,
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2D3748)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // هيدر
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: Color(0xFF1E2127),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16))),
                child: Row(children: [
                  const Icon(Icons.notifications_active,
                      color: Color(0xFFFFA726), size: 18),
                  const SizedBox(width: 8),
                  Text('تنبيهات ذكية',
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const Spacer(),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('${active.length}',
                          style: GoogleFonts.cairo(
                              color: const Color(0xFFEF5350),
                              fontSize: 10,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () => alertService.dismissAll(),
                      child: Text('إخفاء الكل',
                          style: GoogleFonts.cairo(
                              color: Colors.grey[500], fontSize: 10))),
                ])),
            // قائمة التنبيهات
            Flexible(
                child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: active.length.clamp(0, 5),
              itemBuilder: (_, i) {
                final a = active[i];
                return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: a.color.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: a.color.withOpacity(0.15))),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(a.icon, color: a.color, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(a.title,
                                          style: GoogleFonts.cairo(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                          color: a.color.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text(a.priorityText,
                                          style: GoogleFonts.cairo(
                                              color: a.color, fontSize: 8))),
                                ]),
                                Text(a.message,
                                    style: GoogleFonts.cairo(
                                        color: Colors.grey[500], fontSize: 9),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ])),
                          const SizedBox(width: 6),
                          GestureDetector(
                              onTap: () => alertService.dismissAlert(a.id),
                              child: Icon(Icons.close,
                                  color: Colors.grey[600], size: 14)),
                        ]));
              },
            )),
          ]),
        ));
  }
}

/// شريط الحالة السفلي (للموبايل)
class MobileBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<BottomBarItem> items;

  const MobileBottomBar(
      {super.key,
      required this.selectedIndex,
      required this.onTap,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ]),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isSelected = i == selectedIndex;
            return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Icon(item.icon,
                          color:
                              isSelected ? AppColors.accent : Colors.grey[600],
                          size: 22),
                      if (item.badge > 0)
                        Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                                child: Text('${item.badge}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 8)))),
                    ]),
                    const SizedBox(height: 2),
                    Text(item.label,
                        style: GoogleFonts.cairo(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.grey[600],
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ]),
                ));
          }).toList()),
    );
  }
}

class BottomBarItem {
  final String label;
  final IconData icon;
  final int badge;
  const BottomBarItem(
      {required this.label, required this.icon, this.badge = 0});
}
/// واجهة موبايل للرئيسية
class MobileDashboardHeader extends StatelessWidget {
  final String userName;
  final String userRole;
  final Color roleColor;
  final int notifications;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  const MobileDashboardHeader({
    super.key,
    required this.userName,
    required this.userRole,
    required this.roleColor,
    required this.notifications,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          border:
              Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5))),
      child: SafeArea(
          bottom: false,
          child: Row(children: [
            GestureDetector(
                onTap: onMenuTap,
                child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.menu,
                        color: AppColors.accent, size: 22))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(userName,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Row(children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: roleColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(userRole,
                        style:
                            GoogleFonts.cairo(color: roleColor, fontSize: 10))
                  ]),
                ])),
            GestureDetector(
                onTap: onNotificationTap,
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A1F2E),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22)),
                  if (notifications > 0)
                    Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: Text('$notifications',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)))),
                ])),
          ])),
    );
  }
}
