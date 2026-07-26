import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liangzhi/core/database/default_data.dart';
import 'package:liangzhi/core/providers/food_providers.dart';
import 'package:liangzhi/core/providers/reference_providers.dart';
import 'package:liangzhi/shared/design/app_colors.dart';
import 'package:liangzhi/shared/design/app_dimensions.dart';
import 'package:liangzhi/shared/models/food.dart';
import 'package:liangzhi/shared/models/reference_item.dart';
import 'package:liangzhi/shared/models/shelf_life_calculator.dart';
import 'package:liangzhi/shared/widgets/responsive_page.dart';
import 'package:uuid/uuid.dart';

class AddFoodPage extends ConsumerStatefulWidget {
  const AddFoodPage({
    required this.onSaved,
    required this.onCancel,
    this.initialBarcode,
    this.initialName,
    this.initialBrand,
    this.initialSpecification,
    this.initialRemoteImageUrl,
    this.initialExpiryDate,
    super.key,
  });

  final ValueChanged<Food> onSaved;
  final VoidCallback onCancel;
  final String? initialBarcode;
  final String? initialName;
  final String? initialBrand;
  final String? initialSpecification;
  final Uri? initialRemoteImageUrl;
  final DateTime? initialExpiryDate;

  @override
  ConsumerState<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends ConsumerState<AddFoodPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  final TextEditingController _shelfLifeController = TextEditingController();
  ExpiryInputType _expiryInputType = ExpiryInputType.direct;
  DateTime? _expiryDate;
  DateTime? _productionDate;
  ShelfLifeUnit _shelfLifeUnit = ShelfLifeUnit.day;
  String _categoryId = DefaultIds.categoryOther;
  String _locationId = DefaultIds.locationOther;
  String? _expiryError;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _quantityController = TextEditingController(text: '1');
    _unitController = TextEditingController(text: '份');
    _expiryDate = widget.initialExpiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _shelfLifeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> submitState = ref.watch(addFoodControllerProvider);
    final List<ReferenceItem> categories = ref.watch(categoryListProvider).value ?? <ReferenceItem>[];
    final List<ReferenceItem> locations = ref.watch(locationListProvider).value ?? <ReferenceItem>[];
    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.close),
            tooltip: '取消添加',
          ),
          title: const Text('添加食物'),
        ),
        body: ResponsivePage(
          child: Form(
            key: _formKey,
            onChanged: () {
              if (!_dirty) {
                setState(() => _dirty = true);
              }
            },
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (widget.initialBarcode != null) ...[
                  Text('条形码 ${widget.initialBarcode}'),
                  const SizedBox(height: AppSpacing.sm),
                ],
                TextFormField(
                  key: const ValueKey<String>('food-name'),
                  controller: _nameController,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '食品名称 *'),
                  validator: _validateName,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey<String>('food-quantity'),
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                        ],
                        decoration: const InputDecoration(labelText: '数量 *'),
                        validator: _validateQuantity,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        maxLength: 20,
                        decoration: const InputDecoration(labelText: '单位 *', counterText: ''),
                        validator: _validateUnit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ExpiryInputType>(
                  segments: const [
                    ButtonSegment<ExpiryInputType>(
                      value: ExpiryInputType.direct,
                      label: Text('直接到期日期'),
                    ),
                    ButtonSegment<ExpiryInputType>(
                      value: ExpiryInputType.productionShelfLife,
                      label: Text('生产日期＋保质期'),
                    ),
                  ],
                  selected: <ExpiryInputType>{_expiryInputType},
                  onSelectionChanged: submitState.isLoading
                      ? null
                      : (Set<ExpiryInputType> values) {
                          setState(() {
                            _expiryInputType = values.single;
                            _expiryError = null;
                            _dirty = true;
                          });
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                if (_expiryInputType == ExpiryInputType.direct)
                  _DateField(
                    key: const ValueKey<String>('expiry-date'),
                    label: '到期日期 *',
                    value: _expiryDate,
                    onTap: () => _pickDate(isProductionDate: false),
                  )
                else ...[
                  _DateField(
                    key: const ValueKey<String>('production-date'),
                    label: '生产日期 *',
                    value: _productionDate,
                    onTap: () => _pickDate(isProductionDate: true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey<String>('shelf-life-value'),
                          controller: _shelfLifeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: '保质期 *'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      DropdownButton<ShelfLifeUnit>(
                        value: _shelfLifeUnit,
                        items: ShelfLifeUnit.values
                            .map(
                              (ShelfLifeUnit unit) =>
                                  DropdownMenuItem(value: unit, child: Text(unit.label)),
                            )
                            .toList(growable: false),
                        onChanged: (ShelfLifeUnit? value) {
                          if (value != null) {
                            setState(() {
                              _shelfLifeUnit = value;
                              _dirty = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
                if (_expiryError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(_expiryError!, style: const TextStyle(color: AppColors.error)),
                ],
                if (_selectedExpiryDate()?.isBefore(dateOnly(DateTime.now())) ?? false) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    '所选日期已经过去，仍可保存，请确认记录是否正确。',
                    style: TextStyle(color: AppColors.expiring),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _ReferenceDropdown(
                  label: '分类',
                  value: _categoryId,
                  items: categories,
                  onChanged: (String value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ReferenceDropdown(
                  label: '存放位置',
                  value: _locationId,
                  items: locations,
                  onChanged: (String value) => setState(() => _locationId = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  key: const ValueKey<String>('save-food'),
                  onPressed: submitState.isLoading ? null : _submit,
                  child: submitState.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '请输入食品名称';
    }
    if (normalized.length > 100) {
      return '食品名称不能超过 100 个字符';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    final double? quantity = double.tryParse(value ?? '');
    if (quantity == null || quantity <= 0) {
      return '数量必须大于 0';
    }
    final int decimals = (value!.split('.').elementAtOrNull(1) ?? '').length;
    return decimals > 3 ? '数量最多保留 3 位小数' : null;
  }

  String? _validateUnit(String? value) {
    return (value?.trim().isEmpty ?? true) ? '请输入单位' : null;
  }

  Future<void> _pickDate({required bool isProductionDate}) async {
    final DateTime now = DateTime.now();
    final DateTime? value = await showDatePicker(
      context: context,
      initialDate: isProductionDate
          ? (_productionDate ?? now)
          : (_expiryDate ?? now.add(const Duration(days: 7))),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 100),
    );
    if (value != null) {
      setState(() {
        if (isProductionDate) {
          _productionDate = value;
        } else {
          _expiryDate = value;
        }
        _expiryError = null;
        _dirty = true;
      });
    }
  }

  DateTime? _selectedExpiryDate() {
    if (_expiryInputType == ExpiryInputType.direct) {
      return _expiryDate;
    }
    final int? shelfLife = int.tryParse(_shelfLifeController.text);
    if (_productionDate == null || shelfLife == null || shelfLife <= 0) {
      return null;
    }
    return calculateExpiryDate(
      productionDate: _productionDate!,
      shelfLifeValue: shelfLife,
      shelfLifeUnit: _shelfLifeUnit,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final DateTime? expiryDate = _selectedExpiryDate();
    if (expiryDate == null) {
      setState(() => _expiryError = '请填写有效的到期信息');
      return;
    }
    final int? shelfLife = _expiryInputType == ExpiryInputType.productionShelfLife
        ? int.tryParse(_shelfLifeController.text)
        : null;
    final DateTime now = DateTime.now().toUtc();
    final Food food = Food(
      id: const Uuid().v4(),
      barcode: widget.initialBarcode,
      name: _nameController.text,
      brand: widget.initialBrand,
      specification: widget.initialSpecification,
      imageRemoteUrl: widget.initialRemoteImageUrl,
      categoryId: _categoryId,
      locationId: _locationId,
      quantity: double.parse(_quantityController.text),
      unit: _unitController.text,
      expiryInputType: _expiryInputType,
      productionDate: _expiryInputType == ExpiryInputType.productionShelfLife
          ? _productionDate
          : null,
      shelfLifeValue: shelfLife,
      shelfLifeUnit: _expiryInputType == ExpiryInputType.productionShelfLife
          ? _shelfLifeUnit
          : null,
      expiryDate: expiryDate,
      status: FoodStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    final bool success = await ref.read(addFoodControllerProvider.notifier).submit(food);
    if (!mounted) {
      return;
    }
    if (success) {
      _dirty = false;
      widget.onSaved(food);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存失败，输入内容已保留')));
    }
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      widget.onCancel();
      return;
    }
    await _confirmDiscard();
  }

  Future<void> _confirmDiscard() async {
    final bool discard =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('放弃本次编辑？'),
              content: const Text('已填写的内容不会保存。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('继续编辑'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('放弃'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (discard && mounted) {
      _dirty = false;
      widget.onCancel();
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, super.key});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label：${value == null ? '未选择' : formatLocalDate(value!)}'),
      ),
    );
  }
}

class _ReferenceDropdown extends StatelessWidget {
  const _ReferenceDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<ReferenceItem> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool containsValue = items.any((ReferenceItem item) => item.id == value);
    return DropdownButtonFormField<String>(
      initialValue: containsValue ? value : null,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (ReferenceItem item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.name),
            ),
          )
          .toList(growable: false),
      onChanged: (String? selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}
