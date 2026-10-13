import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/features/meals/meal_detail_screen.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/meal_day.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/food_items.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';

/// Every logged meal, grouped by day with the day's calories in the header.
class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final FoodStorageService _storage = FoodStorageService();

  List<MealDay> _days = const [];
  bool _isLoading = true;
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _changes = _storage.onDataChanged.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.getAllFoodItems();
    if (!mounted) return;
    setState(() {
      _days = groupMealsByDay(items);
      _isLoading = false;
    });
  }

  Future<void> _open(FoodItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealDetailScreen(item: item)),
    );
    // The storage stream normally covers this; the explicit reload keeps the
    // list right even if the stream fires before the box has settled.
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(titleText: 'all_meals'.tr(), showLogo: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _days.isEmpty
              ? Padding(
                  padding: AppDimens.pagePadding(context),
                  child: buildFoodItemSection(
                    context: context,
                    items: const [],
                    refreshCallback: _load,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppDimens.pagePadding(context),
                    itemCount: _days.length,
                    itemBuilder: (context, index) => _DaySection(
                      day: _days[index],
                      isLast: index == _days.length - 1,
                      onOpen: _open,
                    ),
                  ),
                ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.isLast,
    required this.onOpen,
  });

  final MealDay day;
  final bool isLast;
  final ValueChanged<FoodItem> onOpen;

  /// "Today" and "Yesterday" by name, everything older by date.
  static String labelFor(BuildContext context, DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'today'.tr();
    if (diff == 1) return 'yesterday'.tr();
    return DateFormat('EEEE, d MMM', context.locale.toString()).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            right: 4,
            bottom: AppDimens.headerGap,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  labelFor(context, day.date, DateTime.now()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${day.totals.calories.round()} ${'kcal'.tr()}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        for (final item in day.items) ...[
          FoodItemCard(
            item: item,
            // The day header already says which day; the row only needs the time.
            timeFormat: 'HH:mm',
            onTap: () => onOpen(item),
          ),
          const SizedBox(height: 10),
        ],
        if (!isLast) const SizedBox(height: AppDimens.sectionGap - 10),
      ],
    );
  }
}
