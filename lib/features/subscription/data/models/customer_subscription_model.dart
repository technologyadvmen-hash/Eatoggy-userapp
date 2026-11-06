import '../../../../shared/models/models.dart';

class SubscriptionOccurrenceModel {
  final String id;
  final DateTime date;
  final String status; // SCHEDULED, DELIVERED, SKIPPED, PAUSED, PENDING
  final String? mealType;
  final String? dayOfWeek;
  final String? notes;

  const SubscriptionOccurrenceModel({
    required this.id,
    required this.date,
    required this.status,
    this.mealType,
    this.dayOfWeek,
    this.notes,
  });

  factory SubscriptionOccurrenceModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['scheduledDate'] ?? json['date'] ?? json['dateString'];
    if (rawDate != null) {
      try {
        parsedDate = DateTime.parse(rawDate.toString());
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    final rawStatus = (json['status'] ?? 'SCHEDULED').toString().toUpperCase();
    String normalizedStatus;
    if (rawStatus == 'SKIPPED') {
      normalizedStatus = 'Skipped';
    } else if (rawStatus == 'DELIVERED' || rawStatus == 'COMPLETED') {
      normalizedStatus = 'Delivered';
    } else if (rawStatus == 'PAUSED') {
      normalizedStatus = 'Paused';
    } else {
      normalizedStatus = 'Upcoming';
    }

    return SubscriptionOccurrenceModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      date: parsedDate,
      status: normalizedStatus,
      mealType: json['mealType'] as String?,
      dayOfWeek: json['dayOfWeek'] as String?,
      notes: json['notes'] as String?,
    );
  }

  SubscriptionCalendarDay toCalendarDay() {
    return SubscriptionCalendarDay(
      occurrenceId: id,
      date: date,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'scheduledDate': date.toIso8601String(),
        'status': status,
        'mealType': mealType,
        'dayOfWeek': dayOfWeek,
        'notes': notes,
      };
}

class CustomerSubscriptionModel {
  final String id;
  final String? subscriptionNumber;
  final String? customerId;
  final String? planId;
  final String? addressId;
  final String status; // ACTIVE, PAUSED, CANCELLED, EXPIRED
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? nextDelivery;
  final int totalMeals;
  final int remainingMeals;
  final String planName;
  final String planDescription;
  final double planPrice;
  final double grandTotal;
  final String mealType;
  final String? deliveryAddressText;
  final List<String> scheduleDays;
  final List<SubscriptionOccurrenceModel> occurrences;
  final Map<String, dynamic>? rawJson;

  const CustomerSubscriptionModel({
    required this.id,
    this.subscriptionNumber,
    this.customerId,
    this.planId,
    this.addressId,
    required this.status,
    this.startDate,
    this.endDate,
    this.nextDelivery,
    this.totalMeals = 0,
    this.remainingMeals = 0,
    this.planName = 'Royal Thali Subscription',
    this.planDescription = 'Fresh chef-curated daily meals',
    this.planPrice = 0.0,
    this.grandTotal = 0.0,
    this.mealType = 'LUNCH',
    this.deliveryAddressText,
    this.scheduleDays = const [],
    this.occurrences = const [],
    this.rawJson,
  });

  factory CustomerSubscriptionModel.fromJson(Map<String, dynamic> json) {
    // Unnest if wrapped in "subscription" or "data"
    Map<String, dynamic> subMap = json;
    if (json['subscription'] is Map<String, dynamic>) {
      subMap = json['subscription'] as Map<String, dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      final inner = json['data'] as Map<String, dynamic>;
      if (inner['subscription'] is Map<String, dynamic>) {
        subMap = inner['subscription'] as Map<String, dynamic>;
      } else {
        subMap = inner;
      }
    }

    final id = subMap['_id'] as String? ?? subMap['id'] as String? ?? '';
    final subNum = subMap['subscriptionNumber'] as String? ?? subMap['subNumber'] as String?;
    final status = (subMap['status'] as String? ?? 'ACTIVE').toUpperCase();

    DateTime? start;
    if (subMap['startDate'] != null) {
      try {
        start = DateTime.parse(subMap['startDate'].toString());
      } catch (_) {}
    }

    DateTime? end;
    if (subMap['endDate'] != null) {
      try {
        end = DateTime.parse(subMap['endDate'].toString());
      } catch (_) {}
    }

    DateTime? next;
    if (subMap['nextDelivery'] != null) {
      try {
        next = DateTime.parse(subMap['nextDelivery'].toString());
      } catch (_) {}
    } else if (start != null) {
      next = start.isAfter(DateTime.now()) ? start : DateTime.now().add(const Duration(days: 1));
    }

    // Extract Plan details: check planSnapshot first, then planId, then plan
    String pName = 'Royal Thali Subscription';
    String pDesc = 'Fresh chef-curated daily meals';
    double pPrice = 0.0;
    int totMeals = 0;
    String pMealType = 'LUNCH';
    String? pId;

    if (subMap['planSnapshot'] is Map<String, dynamic>) {
      final snap = subMap['planSnapshot'] as Map<String, dynamic>;
      pName = snap['name'] as String? ?? pName;
      pDesc = snap['description'] as String? ?? pDesc;
      pPrice = (snap['totalPrice'] as num?)?.toDouble() ?? 0.0;
      totMeals = (snap['totalMeals'] as num?)?.toInt() ?? (snap['planDurationDays'] as num?)?.toInt() ?? 0;
      pMealType = snap['mealType'] as String? ?? pMealType;
    }

    if (subMap['planId'] is Map<String, dynamic>) {
      final pMap = subMap['planId'] as Map<String, dynamic>;
      pId = pMap['_id'] as String? ?? pMap['id'] as String?;
      if (pName == 'Royal Thali Subscription') pName = pMap['name'] as String? ?? pName;
      if (pDesc == 'Fresh chef-curated daily meals') pDesc = pMap['description'] as String? ?? pDesc;
      if (pPrice == 0.0) pPrice = (pMap['totalPrice'] as num?)?.toDouble() ?? 0.0;
      if (totMeals == 0) totMeals = (pMap['totalMeals'] as num?)?.toInt() ?? (pMap['planDurationDays'] as num?)?.toInt() ?? 0;
    } else if (subMap['planId'] is String) {
      pId = subMap['planId'] as String;
    }

    if (subMap['plan'] is Map<String, dynamic>) {
      final pMap = subMap['plan'] as Map<String, dynamic>;
      pId ??= pMap['_id'] as String? ?? pMap['id'] as String?;
      if (pName == 'Royal Thali Subscription') pName = pMap['name'] as String? ?? pName;
      if (pPrice == 0.0) pPrice = (pMap['totalPrice'] as num?)?.toDouble() ?? pPrice;
      if (totMeals == 0) totMeals = (pMap['totalMeals'] as num?)?.toInt() ?? (pMap['planDurationDays'] as num?)?.toInt() ?? 0;
    }

    // Occurrences count from backend
    final int backendTotalOccurrences = (subMap['totalOccurrences'] as num?)?.toInt() ?? 0;
    final int completedCount = (subMap['completedOccurrencesCount'] as num?)?.toInt() ?? 0;

    if (totMeals == 0 && backendTotalOccurrences > 0) {
      totMeals = backendTotalOccurrences;
    }
    if (totMeals == 0) totMeals = 7;

    int remMeals = totMeals - completedCount;
    if (subMap['remainingMeals'] != null) {
      remMeals = (subMap['remainingMeals'] as num?)?.toInt() ?? remMeals;
    }
    if (remMeals < 0) remMeals = 0;

    // Pricing
    double totalAmt = pPrice;
    if (subMap['pricing'] is Map<String, dynamic>) {
      final pr = subMap['pricing'] as Map<String, dynamic>;
      totalAmt = (pr['grandTotal'] as num?)?.toDouble() ?? (pr['planPrice'] as num?)?.toDouble() ?? totalAmt;
      if (pPrice == 0.0) pPrice = (pr['planPrice'] as num?)?.toDouble() ?? 0.0;
    }

    // Schedule days
    List<String> days = [];
    final rawDays = subMap['scheduleDays'] ?? subMap['availableDays'];
    if (rawDays is List) {
      days = rawDays.map((e) => e.toString()).toList();
    }

    // Address text
    String? addrText;
    if (subMap['deliveryAddress'] is Map<String, dynamic>) {
      final a = subMap['deliveryAddress'] as Map<String, dynamic>;
      final line1 = a['addressLine1'] ?? a['address'] ?? '';
      final city = a['city'] ?? '';
      addrText = [line1, city].where((s) => s.toString().isNotEmpty).join(', ');
    }

    // Occurrences parsing: could be in json['occurrences'], subMap['occurrences'], or json['data']['occurrences']
    List<SubscriptionOccurrenceModel> occList = [];
    final rawOcc = json['occurrences'] ??
        subMap['occurrences'] ??
        (json['data'] is Map ? (json['data'] as Map)['occurrences'] : null) ??
        subMap['schedule'];

    if (rawOcc is List) {
      for (final occ in rawOcc) {
        if (occ is Map<String, dynamic>) {
          occList.add(SubscriptionOccurrenceModel.fromJson(occ));
        } else if (occ is Map) {
          occList.add(SubscriptionOccurrenceModel.fromJson(Map<String, dynamic>.from(occ)));
        }
      }
    }

    return CustomerSubscriptionModel(
      id: id,
      subscriptionNumber: subNum,
      customerId: subMap['customerId']?.toString(),
      planId: pId,
      addressId: subMap['addressId']?.toString(),
      status: status,
      startDate: start,
      endDate: end,
      nextDelivery: next,
      totalMeals: totMeals,
      remainingMeals: remMeals,
      planName: pName,
      planDescription: pDesc,
      planPrice: pPrice > 0 ? pPrice : totalAmt,
      grandTotal: totalAmt,
      mealType: pMealType,
      deliveryAddressText: addrText,
      scheduleDays: days,
      occurrences: occList,
      rawJson: subMap,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'subscriptionNumber': subscriptionNumber,
        'customerId': customerId,
        'planId': planId,
        'addressId': addressId,
        'status': status,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'nextDelivery': nextDelivery?.toIso8601String(),
        'totalMeals': totalMeals,
        'remainingMeals': remainingMeals,
        'planName': planName,
        'planDescription': planDescription,
        'planPrice': planPrice,
        'grandTotal': grandTotal,
        'mealType': mealType,
        'deliveryAddressText': deliveryAddressText,
        'scheduleDays': scheduleDays,
        'occurrences': occurrences.map((o) => o.toJson()).toList(),
      };

  /// Converts to shared UI [Subscription] model
  Subscription toSubscriptionEntity({SubscriptionPlan? fallbackPlan}) {
    final calendarSchedule = occurrences.isNotEmpty
        ? occurrences.map((o) => o.toCalendarDay()).toList()
        : _generateDefaultSchedule(startDate ?? DateTime.now(), totalMeals);

    final normalizedStatus = (status == 'ACTIVE' || status == 'CONFIRMED')
        ? 'Active'
        : (status == 'PAUSED' ? 'Paused' : 'Cancelled');

    final effectiveTotalMeals = totalMeals > 0 ? totalMeals : 7;
    final effectivePricePerMeal = planPrice > 0
        ? planPrice / effectiveTotalMeals
        : (grandTotal > 0 ? grandTotal / effectiveTotalMeals : 150.0);

    final plan = fallbackPlan ??
        SubscriptionPlan(
          id: planId ?? id,
          name: planName,
          pricePerMeal: effectivePricePerMeal,
          totalMeals: effectiveTotalMeals,
          durationDays: effectiveTotalMeals,
          deliveryDays: scheduleDays.isNotEmpty ? scheduleDays : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
          benefits: [
            planDescription,
            'Zero contact delivery',
            'Skip or pause calendar anytime',
          ],
        );

    return Subscription(
      id: id,
      plan: plan,
      status: normalizedStatus,
      remainingMeals: remainingMeals,
      nextDelivery: nextDelivery ?? (startDate ?? DateTime.now().add(const Duration(days: 1))),
      schedule: calendarSchedule,
    );
  }

  static List<SubscriptionCalendarDay> _generateDefaultSchedule(DateTime start, int count) {
    return List.generate(count, (index) {
      final date = start.add(Duration(days: index + 1));
      return SubscriptionCalendarDay(
        occurrenceId: 'occ_$index',
        date: date,
        status: 'Upcoming',
      );
    });
  }
}
