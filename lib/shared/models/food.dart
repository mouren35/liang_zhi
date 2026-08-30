enum FoodStatus {
  active('active'),
  consumed('consumed'),
  discarded('discarded')
  ;

  const FoodStatus(this.storageValue);

  final String storageValue;

  static FoodStatus fromStorage(String value) {
    return FoodStatus.values.firstWhere(
      (FoodStatus status) => status.storageValue == value,
      orElse: () => throw const FormatException('未知食品状态'),
    );
  }
}

enum ExpiryInputType {
  direct('direct'),
  productionShelfLife('production_shelf_life')
  ;

  const ExpiryInputType(this.storageValue);

  final String storageValue;

  static ExpiryInputType fromStorage(String value) {
    return ExpiryInputType.values.firstWhere(
      (ExpiryInputType type) => type.storageValue == value,
      orElse: () => throw const FormatException('未知到期录入方式'),
    );
  }
}

enum ShelfLifeUnit {
  day('day', '天'),
  month('month', '月'),
  year('year', '年')
  ;

  const ShelfLifeUnit(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static ShelfLifeUnit fromStorage(String value) {
    return ShelfLifeUnit.values.firstWhere(
      (ShelfLifeUnit unit) => unit.storageValue == value,
      orElse: () => throw const FormatException('未知保质期单位'),
    );
  }
}

final class Food {
  Food({
    required this.id,
    required String name,
    required double quantity,
    required String unit,
    required this.expiryInputType,
    required DateTime expiryDate,
    required this.status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.barcode,
    this.brand,
    this.specification,
    this.imageLocalPath,
    this.imageRemoteUrl,
    this.categoryId,
    this.locationId,
    DateTime? productionDate,
    this.shelfLifeValue,
    this.shelfLifeUnit,
    this.reminderDaysBefore,
    DateTime? deletedAt,
  }) : name = _normalizeRequired(name, fieldName: '食品名称', maxLength: 100),
       quantity = _normalizeQuantity(quantity),
       unit = _normalizeRequired(unit, fieldName: '单位', maxLength: 20),
       expiryDate = dateOnly(expiryDate),
       productionDate = productionDate == null ? null : dateOnly(productionDate),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc(),
       deletedAt = deletedAt?.toUtc() {
    if (id.trim().isEmpty) {
      throw const FormatException('食品 ID 不能为空');
    }
    if (reminderDaysBefore != null && reminderDaysBefore! < 0) {
      throw const FormatException('提前提醒天数不能小于 0');
    }
    if (imageRemoteUrl != null && imageRemoteUrl!.scheme != 'https') {
      throw const FormatException('远程图片必须使用 HTTPS');
    }
    switch (expiryInputType) {
      case ExpiryInputType.direct:
        if (this.productionDate != null || shelfLifeValue != null || shelfLifeUnit != null) {
          throw const FormatException('直接到期模式不能包含保质期组合字段');
        }
      case ExpiryInputType.productionShelfLife:
        if (this.productionDate == null ||
            shelfLifeValue == null ||
            shelfLifeValue! <= 0 ||
            shelfLifeUnit == null) {
          throw const FormatException('生产日期模式缺少有效保质期信息');
        }
    }
  }

  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final String? specification;
  final String? imageLocalPath;
  final Uri? imageRemoteUrl;
  final String? categoryId;
  final String? locationId;
  final double quantity;
  final String unit;
  final ExpiryInputType expiryInputType;
  final DateTime? productionDate;
  final int? shelfLifeValue;
  final ShelfLifeUnit? shelfLifeUnit;
  final DateTime expiryDate;
  final int? reminderDaysBefore;
  final FoodStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isActive => status == FoodStatus.active && deletedAt == null;

  Food copyWith({
    String? name,
    double? quantity,
    String? unit,
    String? categoryId,
    String? locationId,
    DateTime? expiryDate,
    FoodStatus? status,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Food(
      id: id,
      barcode: barcode,
      name: name ?? this.name,
      brand: brand,
      specification: specification,
      imageLocalPath: imageLocalPath,
      imageRemoteUrl: imageRemoteUrl,
      categoryId: categoryId ?? this.categoryId,
      locationId: locationId ?? this.locationId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryInputType: expiryInputType,
      productionDate: productionDate,
      shelfLifeValue: shelfLifeValue,
      shelfLifeUnit: shelfLifeUnit,
      expiryDate: expiryDate ?? this.expiryDate,
      reminderDaysBefore: reminderDaysBefore,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime parseLocalDate(String value) {
  final RegExpMatch? match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw const FormatException('日期格式必须为 YYYY-MM-DD');
  }
  final DateTime parsed = DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  if (formatLocalDate(parsed) != value) {
    throw const FormatException('日期值无效');
  }
  return parsed;
}

String formatLocalDate(DateTime value) {
  final DateTime date = dateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _normalizeRequired(String value, {required String fieldName, required int maxLength}) {
  final String normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maxLength) {
    throw FormatException('$fieldName长度必须为 1—$maxLength 个字符');
  }
  return normalized;
}

double _normalizeQuantity(double value) {
  if (!value.isFinite || value <= 0) {
    throw const FormatException('数量必须大于 0');
  }
  final double normalized = (value * 1000).round() / 1000;
  if ((normalized - value).abs() > 0.0000001) {
    throw const FormatException('数量最多保留 3 位小数');
  }
  return normalized;
}
