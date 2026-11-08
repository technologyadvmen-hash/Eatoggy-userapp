import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'package:sizer/sizer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Orders', 'Offers', 'System'];

  final List<Map<String, dynamic>> _dummyNotifications = [
    {
      'type': 'Order',
      'title': 'Order Delivered! 🎉',
      'body': 'Your Royal Feast has arrived. Enjoy your meal!',
      'time': 'Just now',
      'isRead': false,
      'icon': Icons.check_circle_rounded,
    },
    {
      'type': 'Offer',
      'title': 'Flat ₹150 Off on Royal Tiffin',
      'body': 'Use code ROYALTIF at checkout. Valid till midnight.',
      'time': '2 hours ago',
      'isRead': false,
      'icon': Icons.local_offer_rounded,
    },
    {
      'type': 'System',
      'title': 'System Maintenance',
      'body': 'App will be under maintenance from 2 AM to 4 AM.',
      'time': 'Yesterday',
      'isRead': true,
      'icon': Icons.info_outline_rounded,
    },
    {
      'type': 'Order',
      'title': 'Order #2034 Picked Up',
      'body': 'Ravi is on the way with your hot-case delivery.',
      'time': '2 days ago',
      'isRead': true,
      'icon': Icons.delivery_dining_rounded,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: AppColors.primaryText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _dummyNotifications) {
                  n['isRead'] = true;
                }
              });
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 6.h,
      margin: EdgeInsets.only(top: 1.h, bottom: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _tabs[index],
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList() {
    final activeFilter = _tabs[_selectedTabIndex];
    final filteredList = activeFilter == 'All'
        ? _dummyNotifications
        : _dummyNotifications.where((n) => n['type'] == activeFilter.replaceAll('s', '') || n['type'] == activeFilter).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded, color: AppColors.secondaryText, size: 48.sp),
            SizedBox(height: 2.h),
            Text(
              'No Notifications',
              style: GoogleFonts.outfit(
                color: AppColors.primaryText,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'You\'re all caught up!',
              style: GoogleFonts.outfit(
                color: AppColors.secondaryText,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final notification = filteredList[index];
        final isRead = notification['isRead'] as bool;

        return Container(
          margin: EdgeInsets.only(bottom: 1.5.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              if (!isRead)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isRead ? const Color(0xFFF5F5F5) : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification['icon'] as IconData,
                  color: isRead ? AppColors.secondaryText : AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification['type'] as String,
                          style: GoogleFonts.outfit(
                            color: AppColors.secondaryText,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          notification['time'] as String,
                          style: GoogleFonts.outfit(
                            color: AppColors.secondaryText,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      notification['title'] as String,
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryText,
                        fontSize: 15.sp,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      notification['body'] as String,
                      style: GoogleFonts.outfit(
                        color: AppColors.secondaryText,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead) ...[
                SizedBox(width: 2.w),
                Container(
                  margin: EdgeInsets.only(top: 1.h),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
