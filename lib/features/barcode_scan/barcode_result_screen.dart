import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/cached_barcode_product.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/core/services/barcode_cache_service.dart';
import 'package:plate_track_ai/core/services/open_food_facts_service.dart';

enum _BarcodeResultState { loading, found, notFound, error }

class BarcodeResultScreen extends StatefulWidget {
  final String barcode;
  final CachedBarcodeProduct? initialProduct;
  final Function(FoodItem) onSave;

  const BarcodeResultScreen({
    super.key,
    required this.barcode,
    required this.onSave,
    this.initialProduct,
  });

  @override
  State<BarcodeResultScreen> createState() => _BarcodeResultScreenState();
}

class _BarcodeResultScreenState extends State<BarcodeResultScreen> {
  _BarcodeResultState _state = _BarcodeResultState.loading;
  bool _fromCache = false;
  bool _saveToLibrary = true;

  late TextEditingController _nameController;
  late TextEditingController _massController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  double _caloriesPer100g = 0;
  double _proteinPer100g = 0;
  double _carbsPer100g = 0;
  double _fatPer100g = 0;

  /// Prevents circular updates: mass change → nutrition fields → back-calc per100g → loop.
  bool _isRecalculating = false;

  final _barcodeCacheService = BarcodeCacheService();
  final _openFoodFactsService = OpenFoodFactsService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _massController = TextEditingController(text: '100');
    _caloriesController = TextEditingController(text: '0');
    _proteinController = TextEditingController(text: '0');
    _carbsController = TextEditingController(text: '0');
    _fatController = TextEditingController(text: '0');
    _massController.addListener(_onMassChanged);
    _caloriesController.addListener(_onCaloriesChanged);
    _proteinController.addListener(_onProteinChanged);
    _carbsController.addListener(_onCarbsChanged);
    _fatController.addListener(_onFatChanged);

    if (widget.initialProduct != null) {
      _populateFromProduct(widget.initialProduct!, fromCache: false);
    } else {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _massController.removeListener(_onMassChanged);
    _caloriesController.removeListener(_onCaloriesChanged);
    _proteinController.removeListener(_onProteinChanged);
    _carbsController.removeListener(_onCarbsChanged);
    _fatController.removeListener(_onFatChanged);
    _nameController.dispose();
    _massController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _populateFromProduct(CachedBarcodeProduct product, {required bool fromCache}) {
    _caloriesPer100g = product.caloriesPer100g;
    _proteinPer100g = product.proteinPer100g;
    _carbsPer100g = product.carbsPer100g;
    _fatPer100g = product.fatPer100g;

    _nameController.text = product.productName;
    _massController.text = '100';
    _recalculateFromMass(100.0);

    setState(() {
      _state = _BarcodeResultState.found;
      _fromCache = fromCache;
      _saveToLibrary = !fromCache;
    });
  }

  void _initEmptyForm() {
    _caloriesPer100g = 0;
    _proteinPer100g = 0;
    _carbsPer100g = 0;
    _fatPer100g = 0;
    _nameController.text = '';
    _massController.text = '100';
    _caloriesController.text = '0';
    _proteinController.text = '0';
    _carbsController.text = '0';
    _fatController.text = '0';
    _saveToLibrary = true;
  }

  Future<void> _loadProduct() async {
    // Check local cache first
    final cached = _barcodeCacheService.lookup(widget.barcode);
    if (cached != null) {
      _populateFromProduct(cached, fromCache: true);
      return;
    }

    setState(() => _state = _BarcodeResultState.loading);

    try {
      final product = await _openFoodFactsService.fetchProduct(widget.barcode);
      _populateFromProduct(product, fromCache: false);
    } on OpenFoodFactsException catch (e) {
      if (e.reason == OpenFoodFactsFailureReason.notFound ||
          e.reason == OpenFoodFactsFailureReason.parseError) {
        _initEmptyForm();
        setState(() => _state = _BarcodeResultState.notFound);
      } else {
        setState(() {
          _state = _BarcodeResultState.error;
        });
      }
    }
  }

  void _onMassChanged() {
    final mass = double.tryParse(_massController.text);
    if (mass != null && mass > 0) {
      // Guard flag prevents nutrition listeners from back-calculating per100g
      // while we are the ones changing the nutrition fields.
      _isRecalculating = true;
      _recalculateFromMass(mass);
      _isRecalculating = false;
    }
  }

  void _recalculateFromMass(double mass) {
    _caloriesController.text = (_caloriesPer100g * mass / 100).toStringAsFixed(1);
    _proteinController.text  = (_proteinPer100g  * mass / 100).toStringAsFixed(1);
    _carbsController.text    = (_carbsPer100g    * mass / 100).toStringAsFixed(1);
    _fatController.text      = (_fatPer100g      * mass / 100).toStringAsFixed(1);
  }

  // Four separate listeners — each only updates its OWN per-100 g value.
  // A shared listener was the root cause of cross-field corruption: editing
  // calories would re-read the carbs field (already scaled to the current
  // portion mass) and overwrite _carbsPer100g with a wrong value.

  void _onCaloriesChanged() {
    if (_isRecalculating) return;
    final mass = double.tryParse(_massController.text) ?? 0;
    if (mass <= 0) return;
    _caloriesPer100g = (double.tryParse(_caloriesController.text) ?? 0) * 100 / mass;
  }

  void _onProteinChanged() {
    if (_isRecalculating) return;
    final mass = double.tryParse(_massController.text) ?? 0;
    if (mass <= 0) return;
    _proteinPer100g = (double.tryParse(_proteinController.text) ?? 0) * 100 / mass;
  }

  void _onCarbsChanged() {
    if (_isRecalculating) return;
    final mass = double.tryParse(_massController.text) ?? 0;
    if (mass <= 0) return;
    _carbsPer100g = (double.tryParse(_carbsController.text) ?? 0) * 100 / mass;
  }

  void _onFatChanged() {
    if (_isRecalculating) return;
    final mass = double.tryParse(_massController.text) ?? 0;
    if (mass <= 0) return;
    _fatPer100g = (double.tryParse(_fatController.text) ?? 0) * 100 / mass;
  }

  void _saveFoodItem() {
    try {
      final mass = double.parse(_massController.text);
      // Validate all numeric fields
      double.parse(_caloriesController.text);
      double.parse(_proteinController.text);
      double.parse(_carbsController.text);
      double.parse(_fatController.text);

      // Per-100g values are kept in sync by _onNutritionChanged as the user
      // types, so they are always correct here — no extra recalculation needed.

      if (_saveToLibrary) {
        final product = CachedBarcodeProduct(
          barcode: widget.barcode,
          productName: _nameController.text,
          caloriesPer100g: _caloriesPer100g,
          proteinPer100g: _proteinPer100g,
          carbsPer100g: _carbsPer100g,
          fatPer100g: _fatPer100g,
          cachedAt: DateTime.now(),
        );
        _barcodeCacheService.save(product);
      }

      final foodItem = FoodItem(
        id: const Uuid().v4(),
        name: _nameController.text.isNotEmpty ? _nameController.text : widget.barcode,
        calories: _caloriesPer100g,
        nutritionFacts: NutritionFacts(
          protein: _proteinPer100g,
          carbs: _carbsPer100g,
          fat: _fatPer100g,
          mass: mass,
        ),
        imagePath: null,
      );

      widget.onSave(foodItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('food_item_saved'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error_saving_food_item'.tr()}: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        titleText: 'barcode_scanner'.tr(),
        showLogo: false,
      ),
      body: _buildBody(),
      bottomNavigationBar: _state == _BarcodeResultState.loading
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _BarcodeResultState.loading:
        return LoadingIndicator(message: 'barcode_loading_product'.tr());

      case _BarcodeResultState.error:
        return _buildErrorState();

      case _BarcodeResultState.found:
      case _BarcodeResultState.notFound:
        return _buildForm();
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'barcode_product_fetch_error'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'barcode_no_internet'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'barcode_retry'.tr(),
              onPressed: _loadProduct,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingValuesBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[700]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'barcode_missing_values_warning'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber[900],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBarcodeHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                // Single ListenableBuilder drives both the warning banner and
                // per-card highlighting so allZero is computed only once.
                ListenableBuilder(
                  listenable: Listenable.merge([
                    _caloriesController,
                    _proteinController,
                    _carbsController,
                    _fatController,
                  ]),
                  builder: (context, _) {
                    final allZero = _state == _BarcodeResultState.found &&
                        [
                          _caloriesController,
                          _proteinController,
                          _carbsController,
                          _fatController,
                        ].every((c) => (double.tryParse(c.text) ?? 0) == 0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (allZero) ...[
                          _buildMissingValuesBanner(),
                          const SizedBox(height: 16),
                        ],
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildMassField(),
                        const SizedBox(height: 24),
                        _buildNutritionHeader(),
                        const SizedBox(height: 16),
                        _buildNutritionGrid(highlightAll: allZero),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSaveToLibrarySwitch(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeHeader() {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.barcode_reader,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            widget.barcode,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isFound = _state == _BarcodeResultState.found;
    final title = _fromCache
        ? 'barcode_product_found_cache'.tr()
        : isFound
            ? 'barcode_product_found'.tr()
            : 'barcode_product_not_found'.tr();
    final subtitle = isFound
        ? 'review_and_adjust_nutrition'.tr()
        : 'barcode_not_found_message'.tr();
    final color = isFound
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    final icon = isFound ? Icons.check_circle_outline : Icons.edit_note;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'food_name'.tr(),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.food_bank,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMassField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.scale,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'portion_size'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _massController,
              decoration: InputDecoration(
                labelText: 'mass'.tr(),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'g'.tr(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.analytics,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'nutrition_facts'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNutritionGrid({bool highlightAll = false}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                controller: _caloriesController,
                label: 'calories'.tr(),
                icon: Icons.local_fire_department,
                suffix: 'kcal'.tr(),
                color: Colors.red[400]!,
                highlighted: highlightAll,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard(
                controller: _proteinController,
                label: 'protein'.tr(),
                icon: Icons.fitness_center,
                suffix: 'g'.tr(),
                color: Colors.purple[400]!,
                highlighted: highlightAll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                controller: _carbsController,
                label: 'carbs'.tr(),
                icon: Icons.grain,
                suffix: 'g'.tr(),
                color: Colors.amber[700]!,
                highlighted: highlightAll,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNutritionCard(
                controller: _fatController,
                label: 'fat'.tr(),
                icon: Icons.opacity,
                suffix: 'g'.tr(),
                color: Colors.blue[400]!,
                highlighted: highlightAll,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
    required Color color,
    bool highlighted = false,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlighted
            ? BorderSide(color: Colors.amber[700]!, width: 1.5)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                suffixText: suffix,
                suffixStyle: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveToLibrarySwitch() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        value: _saveToLibrary,
        onChanged: (v) => setState(() => _saveToLibrary = v),
        title: Text(
          'save_to_barcode_library'.tr(),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        secondary: Icon(
          Icons.bookmark_add_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'cancel'.tr(),
              onPressed: () => Navigator.pop(context),
              isSecondary: true,
              icon: Icons.close,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppButton(
              text: 'save_result'.tr(),
              onPressed: _saveFoodItem,
              icon: Icons.save_alt,
            ),
          ),
        ],
      ),
    );
  }
}
