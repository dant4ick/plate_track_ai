import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// What the user typed into the weight sheet.
@immutable
class WeightGoalResult {
  const WeightGoalResult({required this.weight, required this.goalWeight});

  final double weight;
  final double? goalWeight;
}

/// Bottom sheet for editing current weight and goal weight together.
///
/// Returns a [WeightGoalResult] on save, or null if dismissed. Persisting is
/// the caller's job — the sheet stays free of the profile service so it can be
/// driven from anywhere and tested on its own.
class WeightGoalSheet extends StatefulWidget {
  const WeightGoalSheet({
    super.key,
    required this.weight,
    this.goalWeight,
    this.minimumGoal,
  });

  final double weight;
  final double? goalWeight;

  /// Lowest goal the sheet will accept, in kg — the healthy-BMI floor for the
  /// user's height. Null leaves the goal unbounded below.
  final double? minimumGoal;

  static Future<WeightGoalResult?> show(
    BuildContext context, {
    required double weight,
    double? goalWeight,
    double? minimumGoal,
  }) {
    return showModalBottomSheet<WeightGoalResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WeightGoalSheet(
        weight: weight,
        goalWeight: goalWeight,
        minimumGoal: minimumGoal,
      ),
    );
  }

  @override
  State<WeightGoalSheet> createState() => _WeightGoalSheetState();
}

class _WeightGoalSheetState extends State<WeightGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _goalController;

  static String _initial(double? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: _initial(widget.weight));
    _goalController = TextEditingController(text: _initial(widget.goalWeight));
  }

  @override
  void dispose() {
    _weightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  /// Accepts both `70.5` and `70,5` — the comma is the decimal separator in the
  /// Russian locale the app ships, and the numeric keyboard offers it there.
  static double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      WeightGoalResult(
        weight: _parse(_weightController.text)!,
        goalWeight: _parse(_goalController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Two different things can eat the bottom of the sheet, and only one of
    // them applies at a time: the keyboard while a field is focused, and the
    // system navigation bar otherwise. The keyboard already covers the nav bar,
    // so adding both would leave a gap the height of the nav bar above it.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.gutter,
        right: AppDimens.gutter,
        bottom:
            AppDimens.gutter + (keyboard > 0 ? keyboard : systemBar),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'update_weight'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _WeightField(
              controller: _weightController,
              label: 'current_weight'.tr(),
              validator: (value) {
                final parsed = _parse(value ?? '');
                if (parsed == null || parsed <= 0 || parsed > 500) {
                  return 'please_enter_valid_weight'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _WeightField(
              controller: _goalController,
              label: 'goal_weight'.tr(),
              // Optional: an empty goal is the "no goal set" state.
              validator: (value) {
                final raw = (value ?? '').trim();
                if (raw.isEmpty) return null;
                final parsed = _parse(raw);
                if (parsed == null || parsed <= 0 || parsed > 500) {
                  return 'please_enter_valid_goal_weight'.tr();
                }
                final minimum = widget.minimumGoal;
                if (minimum != null && parsed < minimum) {
                  return 'goal_weight_below_minimum'.tr(
                    namedArgs: {'min': minimum.toStringAsFixed(1)},
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _save,
              child: Text('save'.tr()),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _WeightField extends StatelessWidget {
  const _WeightField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'kg'.tr(),
        suffixStyle: TextStyle(color: AppPalette.of(context).textTertiary),
      ),
      validator: validator,
    );
  }
}
