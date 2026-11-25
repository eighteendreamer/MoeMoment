// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LensCyclesTable extends LensCycles
    with TableInfo<$LensCyclesTable, LensCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LensCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cycleNameMeta = const VerificationMeta(
    'cycleName',
  );
  @override
  late final GeneratedColumn<String> cycleName = GeneratedColumn<String>(
    'cycle_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleUnitMeta = const VerificationMeta(
    'cycleUnit',
  );
  @override
  late final GeneratedColumn<String> cycleUnit = GeneratedColumn<String>(
    'cycle_unit',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleValueMeta = const VerificationMeta(
    'cycleValue',
  );
  @override
  late final GeneratedColumn<int> cycleValue = GeneratedColumn<int>(
    'cycle_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cycleName,
    cycleUnit,
    cycleValue,
    isBuiltin,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lens_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LensCycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cycle_name')) {
      context.handle(
        _cycleNameMeta,
        cycleName.isAcceptableOrUnknown(data['cycle_name']!, _cycleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleNameMeta);
    }
    if (data.containsKey('cycle_unit')) {
      context.handle(
        _cycleUnitMeta,
        cycleUnit.isAcceptableOrUnknown(data['cycle_unit']!, _cycleUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleUnitMeta);
    }
    if (data.containsKey('cycle_value')) {
      context.handle(
        _cycleValueMeta,
        cycleValue.isAcceptableOrUnknown(data['cycle_value']!, _cycleValueMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleValueMeta);
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LensCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LensCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cycleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_name'],
      )!,
      cycleUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_unit'],
      )!,
      cycleValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_value'],
      )!,
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LensCyclesTable createAlias(String alias) {
    return $LensCyclesTable(attachedDatabase, alias);
  }
}

class LensCycle extends DataClass implements Insertable<LensCycle> {
  final int id;
  final String cycleName;
  final String cycleUnit;
  final int cycleValue;
  final bool isBuiltin;
  final int sortOrder;
  final DateTime createdAt;
  const LensCycle({
    required this.id,
    required this.cycleName,
    required this.cycleUnit,
    required this.cycleValue,
    required this.isBuiltin,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cycle_name'] = Variable<String>(cycleName);
    map['cycle_unit'] = Variable<String>(cycleUnit);
    map['cycle_value'] = Variable<int>(cycleValue);
    map['is_builtin'] = Variable<bool>(isBuiltin);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LensCyclesCompanion toCompanion(bool nullToAbsent) {
    return LensCyclesCompanion(
      id: Value(id),
      cycleName: Value(cycleName),
      cycleUnit: Value(cycleUnit),
      cycleValue: Value(cycleValue),
      isBuiltin: Value(isBuiltin),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory LensCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LensCycle(
      id: serializer.fromJson<int>(json['id']),
      cycleName: serializer.fromJson<String>(json['cycleName']),
      cycleUnit: serializer.fromJson<String>(json['cycleUnit']),
      cycleValue: serializer.fromJson<int>(json['cycleValue']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cycleName': serializer.toJson<String>(cycleName),
      'cycleUnit': serializer.toJson<String>(cycleUnit),
      'cycleValue': serializer.toJson<int>(cycleValue),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LensCycle copyWith({
    int? id,
    String? cycleName,
    String? cycleUnit,
    int? cycleValue,
    bool? isBuiltin,
    int? sortOrder,
    DateTime? createdAt,
  }) => LensCycle(
    id: id ?? this.id,
    cycleName: cycleName ?? this.cycleName,
    cycleUnit: cycleUnit ?? this.cycleUnit,
    cycleValue: cycleValue ?? this.cycleValue,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  LensCycle copyWithCompanion(LensCyclesCompanion data) {
    return LensCycle(
      id: data.id.present ? data.id.value : this.id,
      cycleName: data.cycleName.present ? data.cycleName.value : this.cycleName,
      cycleUnit: data.cycleUnit.present ? data.cycleUnit.value : this.cycleUnit,
      cycleValue: data.cycleValue.present
          ? data.cycleValue.value
          : this.cycleValue,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LensCycle(')
          ..write('id: $id, ')
          ..write('cycleName: $cycleName, ')
          ..write('cycleUnit: $cycleUnit, ')
          ..write('cycleValue: $cycleValue, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cycleName,
    cycleUnit,
    cycleValue,
    isBuiltin,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LensCycle &&
          other.id == this.id &&
          other.cycleName == this.cycleName &&
          other.cycleUnit == this.cycleUnit &&
          other.cycleValue == this.cycleValue &&
          other.isBuiltin == this.isBuiltin &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class LensCyclesCompanion extends UpdateCompanion<LensCycle> {
  final Value<int> id;
  final Value<String> cycleName;
  final Value<String> cycleUnit;
  final Value<int> cycleValue;
  final Value<bool> isBuiltin;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const LensCyclesCompanion({
    this.id = const Value.absent(),
    this.cycleName = const Value.absent(),
    this.cycleUnit = const Value.absent(),
    this.cycleValue = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LensCyclesCompanion.insert({
    this.id = const Value.absent(),
    required String cycleName,
    required String cycleUnit,
    required int cycleValue,
    this.isBuiltin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : cycleName = Value(cycleName),
       cycleUnit = Value(cycleUnit),
       cycleValue = Value(cycleValue);
  static Insertable<LensCycle> custom({
    Expression<int>? id,
    Expression<String>? cycleName,
    Expression<String>? cycleUnit,
    Expression<int>? cycleValue,
    Expression<bool>? isBuiltin,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cycleName != null) 'cycle_name': cycleName,
      if (cycleUnit != null) 'cycle_unit': cycleUnit,
      if (cycleValue != null) 'cycle_value': cycleValue,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LensCyclesCompanion copyWith({
    Value<int>? id,
    Value<String>? cycleName,
    Value<String>? cycleUnit,
    Value<int>? cycleValue,
    Value<bool>? isBuiltin,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return LensCyclesCompanion(
      id: id ?? this.id,
      cycleName: cycleName ?? this.cycleName,
      cycleUnit: cycleUnit ?? this.cycleUnit,
      cycleValue: cycleValue ?? this.cycleValue,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cycleName.present) {
      map['cycle_name'] = Variable<String>(cycleName.value);
    }
    if (cycleUnit.present) {
      map['cycle_unit'] = Variable<String>(cycleUnit.value);
    }
    if (cycleValue.present) {
      map['cycle_value'] = Variable<int>(cycleValue.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LensCyclesCompanion(')
          ..write('id: $id, ')
          ..write('cycleName: $cycleName, ')
          ..write('cycleUnit: $cycleUnit, ')
          ..write('cycleValue: $cycleValue, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LensesTable extends Lenses with TableInfo<$LensesTable, Lens> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<int> cycleId = GeneratedColumn<int>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lens_cycles (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _colorSchemeMeta = const VerificationMeta(
    'colorScheme',
  );
  @override
  late final GeneratedColumn<String> colorScheme = GeneratedColumn<String>(
    'color_scheme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lensSpecsMeta = const VerificationMeta(
    'lensSpecs',
  );
  @override
  late final GeneratedColumn<String> lensSpecs = GeneratedColumn<String>(
    'lens_specs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unopened'),
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<String> openedAt = GeneratedColumn<String>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packageExpiryDateMeta = const VerificationMeta(
    'packageExpiryDate',
  );
  @override
  late final GeneratedColumn<String> packageExpiryDate =
      GeneratedColumn<String>(
        'package_expiry_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _discardedAtMeta = const VerificationMeta(
    'discardedAt',
  );
  @override
  late final GeneratedColumn<String> discardedAt = GeneratedColumn<String>(
    'discarded_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    name,
    cycleId,
    colorScheme,
    lensSpecs,
    status,
    openedAt,
    packageExpiryDate,
    discardedAt,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lens> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('color_scheme')) {
      context.handle(
        _colorSchemeMeta,
        colorScheme.isAcceptableOrUnknown(
          data['color_scheme']!,
          _colorSchemeMeta,
        ),
      );
    }
    if (data.containsKey('lens_specs')) {
      context.handle(
        _lensSpecsMeta,
        lensSpecs.isAcceptableOrUnknown(data['lens_specs']!, _lensSpecsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('package_expiry_date')) {
      context.handle(
        _packageExpiryDateMeta,
        packageExpiryDate.isAcceptableOrUnknown(
          data['package_expiry_date']!,
          _packageExpiryDateMeta,
        ),
      );
    }
    if (data.containsKey('discarded_at')) {
      context.handle(
        _discardedAtMeta,
        discardedAt.isAcceptableOrUnknown(
          data['discarded_at']!,
          _discardedAtMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lens map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lens(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_id'],
      )!,
      colorScheme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_scheme'],
      ),
      lensSpecs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lens_specs'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_at'],
      ),
      packageExpiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_expiry_date'],
      ),
      discardedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discarded_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LensesTable createAlias(String alias) {
    return $LensesTable(attachedDatabase, alias);
  }
}

class Lens extends DataClass implements Insertable<Lens> {
  final int id;
  final String brand;
  final String name;
  final int cycleId;
  final String? colorScheme;
  final String? lensSpecs;
  final String status;
  final String? openedAt;
  final String? packageExpiryDate;
  final String? discardedAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Lens({
    required this.id,
    required this.brand,
    required this.name,
    required this.cycleId,
    this.colorScheme,
    this.lensSpecs,
    required this.status,
    this.openedAt,
    this.packageExpiryDate,
    this.discardedAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brand'] = Variable<String>(brand);
    map['name'] = Variable<String>(name);
    map['cycle_id'] = Variable<int>(cycleId);
    if (!nullToAbsent || colorScheme != null) {
      map['color_scheme'] = Variable<String>(colorScheme);
    }
    if (!nullToAbsent || lensSpecs != null) {
      map['lens_specs'] = Variable<String>(lensSpecs);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<String>(openedAt);
    }
    if (!nullToAbsent || packageExpiryDate != null) {
      map['package_expiry_date'] = Variable<String>(packageExpiryDate);
    }
    if (!nullToAbsent || discardedAt != null) {
      map['discarded_at'] = Variable<String>(discardedAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LensesCompanion toCompanion(bool nullToAbsent) {
    return LensesCompanion(
      id: Value(id),
      brand: Value(brand),
      name: Value(name),
      cycleId: Value(cycleId),
      colorScheme: colorScheme == null && nullToAbsent
          ? const Value.absent()
          : Value(colorScheme),
      lensSpecs: lensSpecs == null && nullToAbsent
          ? const Value.absent()
          : Value(lensSpecs),
      status: Value(status),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      packageExpiryDate: packageExpiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(packageExpiryDate),
      discardedAt: discardedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(discardedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Lens.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lens(
      id: serializer.fromJson<int>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      name: serializer.fromJson<String>(json['name']),
      cycleId: serializer.fromJson<int>(json['cycleId']),
      colorScheme: serializer.fromJson<String?>(json['colorScheme']),
      lensSpecs: serializer.fromJson<String?>(json['lensSpecs']),
      status: serializer.fromJson<String>(json['status']),
      openedAt: serializer.fromJson<String?>(json['openedAt']),
      packageExpiryDate: serializer.fromJson<String?>(
        json['packageExpiryDate'],
      ),
      discardedAt: serializer.fromJson<String?>(json['discardedAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brand': serializer.toJson<String>(brand),
      'name': serializer.toJson<String>(name),
      'cycleId': serializer.toJson<int>(cycleId),
      'colorScheme': serializer.toJson<String?>(colorScheme),
      'lensSpecs': serializer.toJson<String?>(lensSpecs),
      'status': serializer.toJson<String>(status),
      'openedAt': serializer.toJson<String?>(openedAt),
      'packageExpiryDate': serializer.toJson<String?>(packageExpiryDate),
      'discardedAt': serializer.toJson<String?>(discardedAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Lens copyWith({
    int? id,
    String? brand,
    String? name,
    int? cycleId,
    Value<String?> colorScheme = const Value.absent(),
    Value<String?> lensSpecs = const Value.absent(),
    String? status,
    Value<String?> openedAt = const Value.absent(),
    Value<String?> packageExpiryDate = const Value.absent(),
    Value<String?> discardedAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Lens(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    name: name ?? this.name,
    cycleId: cycleId ?? this.cycleId,
    colorScheme: colorScheme.present ? colorScheme.value : this.colorScheme,
    lensSpecs: lensSpecs.present ? lensSpecs.value : this.lensSpecs,
    status: status ?? this.status,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    packageExpiryDate: packageExpiryDate.present
        ? packageExpiryDate.value
        : this.packageExpiryDate,
    discardedAt: discardedAt.present ? discardedAt.value : this.discardedAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Lens copyWithCompanion(LensesCompanion data) {
    return Lens(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      name: data.name.present ? data.name.value : this.name,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      colorScheme: data.colorScheme.present
          ? data.colorScheme.value
          : this.colorScheme,
      lensSpecs: data.lensSpecs.present ? data.lensSpecs.value : this.lensSpecs,
      status: data.status.present ? data.status.value : this.status,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      packageExpiryDate: data.packageExpiryDate.present
          ? data.packageExpiryDate.value
          : this.packageExpiryDate,
      discardedAt: data.discardedAt.present
          ? data.discardedAt.value
          : this.discardedAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lens(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('cycleId: $cycleId, ')
          ..write('colorScheme: $colorScheme, ')
          ..write('lensSpecs: $lensSpecs, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('packageExpiryDate: $packageExpiryDate, ')
          ..write('discardedAt: $discardedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brand,
    name,
    cycleId,
    colorScheme,
    lensSpecs,
    status,
    openedAt,
    packageExpiryDate,
    discardedAt,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lens &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.name == this.name &&
          other.cycleId == this.cycleId &&
          other.colorScheme == this.colorScheme &&
          other.lensSpecs == this.lensSpecs &&
          other.status == this.status &&
          other.openedAt == this.openedAt &&
          other.packageExpiryDate == this.packageExpiryDate &&
          other.discardedAt == this.discardedAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LensesCompanion extends UpdateCompanion<Lens> {
  final Value<int> id;
  final Value<String> brand;
  final Value<String> name;
  final Value<int> cycleId;
  final Value<String?> colorScheme;
  final Value<String?> lensSpecs;
  final Value<String> status;
  final Value<String?> openedAt;
  final Value<String?> packageExpiryDate;
  final Value<String?> discardedAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LensesCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.name = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.colorScheme = const Value.absent(),
    this.lensSpecs = const Value.absent(),
    this.status = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.packageExpiryDate = const Value.absent(),
    this.discardedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LensesCompanion.insert({
    this.id = const Value.absent(),
    required String brand,
    required String name,
    required int cycleId,
    this.colorScheme = const Value.absent(),
    this.lensSpecs = const Value.absent(),
    this.status = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.packageExpiryDate = const Value.absent(),
    this.discardedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : brand = Value(brand),
       name = Value(name),
       cycleId = Value(cycleId);
  static Insertable<Lens> custom({
    Expression<int>? id,
    Expression<String>? brand,
    Expression<String>? name,
    Expression<int>? cycleId,
    Expression<String>? colorScheme,
    Expression<String>? lensSpecs,
    Expression<String>? status,
    Expression<String>? openedAt,
    Expression<String>? packageExpiryDate,
    Expression<String>? discardedAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (name != null) 'name': name,
      if (cycleId != null) 'cycle_id': cycleId,
      if (colorScheme != null) 'color_scheme': colorScheme,
      if (lensSpecs != null) 'lens_specs': lensSpecs,
      if (status != null) 'status': status,
      if (openedAt != null) 'opened_at': openedAt,
      if (packageExpiryDate != null) 'package_expiry_date': packageExpiryDate,
      if (discardedAt != null) 'discarded_at': discardedAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LensesCompanion copyWith({
    Value<int>? id,
    Value<String>? brand,
    Value<String>? name,
    Value<int>? cycleId,
    Value<String?>? colorScheme,
    Value<String?>? lensSpecs,
    Value<String>? status,
    Value<String?>? openedAt,
    Value<String?>? packageExpiryDate,
    Value<String?>? discardedAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LensesCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      cycleId: cycleId ?? this.cycleId,
      colorScheme: colorScheme ?? this.colorScheme,
      lensSpecs: lensSpecs ?? this.lensSpecs,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      packageExpiryDate: packageExpiryDate ?? this.packageExpiryDate,
      discardedAt: discardedAt ?? this.discardedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<int>(cycleId.value);
    }
    if (colorScheme.present) {
      map['color_scheme'] = Variable<String>(colorScheme.value);
    }
    if (lensSpecs.present) {
      map['lens_specs'] = Variable<String>(lensSpecs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<String>(openedAt.value);
    }
    if (packageExpiryDate.present) {
      map['package_expiry_date'] = Variable<String>(packageExpiryDate.value);
    }
    if (discardedAt.present) {
      map['discarded_at'] = Variable<String>(discardedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LensesCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('cycleId: $cycleId, ')
          ..write('colorScheme: $colorScheme, ')
          ..write('lensSpecs: $lensSpecs, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('packageExpiryDate: $packageExpiryDate, ')
          ..write('discardedAt: $discardedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LensImagesTable extends LensImages
    with TableInfo<$LensImagesTable, LensImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LensImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lensIdMeta = const VerificationMeta('lensId');
  @override
  late final GeneratedColumn<int> lensId = GeneratedColumn<int>(
    'lens_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lenses (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lensId,
    imagePath,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lens_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<LensImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lens_id')) {
      context.handle(
        _lensIdMeta,
        lensId.isAcceptableOrUnknown(data['lens_id']!, _lensIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lensIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LensImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LensImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lensId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lens_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LensImagesTable createAlias(String alias) {
    return $LensImagesTable(attachedDatabase, alias);
  }
}

class LensImage extends DataClass implements Insertable<LensImage> {
  final int id;
  final int lensId;
  final String imagePath;
  final int sortOrder;
  final DateTime createdAt;
  const LensImage({
    required this.id,
    required this.lensId,
    required this.imagePath,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lens_id'] = Variable<int>(lensId);
    map['image_path'] = Variable<String>(imagePath);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LensImagesCompanion toCompanion(bool nullToAbsent) {
    return LensImagesCompanion(
      id: Value(id),
      lensId: Value(lensId),
      imagePath: Value(imagePath),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory LensImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LensImage(
      id: serializer.fromJson<int>(json['id']),
      lensId: serializer.fromJson<int>(json['lensId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lensId': serializer.toJson<int>(lensId),
      'imagePath': serializer.toJson<String>(imagePath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LensImage copyWith({
    int? id,
    int? lensId,
    String? imagePath,
    int? sortOrder,
    DateTime? createdAt,
  }) => LensImage(
    id: id ?? this.id,
    lensId: lensId ?? this.lensId,
    imagePath: imagePath ?? this.imagePath,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  LensImage copyWithCompanion(LensImagesCompanion data) {
    return LensImage(
      id: data.id.present ? data.id.value : this.id,
      lensId: data.lensId.present ? data.lensId.value : this.lensId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LensImage(')
          ..write('id: $id, ')
          ..write('lensId: $lensId, ')
          ..write('imagePath: $imagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lensId, imagePath, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LensImage &&
          other.id == this.id &&
          other.lensId == this.lensId &&
          other.imagePath == this.imagePath &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class LensImagesCompanion extends UpdateCompanion<LensImage> {
  final Value<int> id;
  final Value<int> lensId;
  final Value<String> imagePath;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const LensImagesCompanion({
    this.id = const Value.absent(),
    this.lensId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LensImagesCompanion.insert({
    this.id = const Value.absent(),
    required int lensId,
    required String imagePath,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : lensId = Value(lensId),
       imagePath = Value(imagePath);
  static Insertable<LensImage> custom({
    Expression<int>? id,
    Expression<int>? lensId,
    Expression<String>? imagePath,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lensId != null) 'lens_id': lensId,
      if (imagePath != null) 'image_path': imagePath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LensImagesCompanion copyWith({
    Value<int>? id,
    Value<int>? lensId,
    Value<String>? imagePath,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return LensImagesCompanion(
      id: id ?? this.id,
      lensId: lensId ?? this.lensId,
      imagePath: imagePath ?? this.imagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lensId.present) {
      map['lens_id'] = Variable<int>(lensId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LensImagesCompanion(')
          ..write('id: $id, ')
          ..write('lensId: $lensId, ')
          ..write('imagePath: $imagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LensExpiryReminderSettingsTable extends LensExpiryReminderSettings
    with
        TableInfo<$LensExpiryReminderSettingsTable, LensExpiryReminderSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LensExpiryReminderSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _advanceDaysMeta = const VerificationMeta(
    'advanceDays',
  );
  @override
  late final GeneratedColumn<int> advanceDays = GeneratedColumn<int>(
    'advance_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('09:00'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isActive,
    advanceDays,
    reminderTime,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lens_expiry_reminder_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LensExpiryReminderSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('advance_days')) {
      context.handle(
        _advanceDaysMeta,
        advanceDays.isAcceptableOrUnknown(
          data['advance_days']!,
          _advanceDaysMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LensExpiryReminderSetting map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LensExpiryReminderSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      advanceDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_days'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LensExpiryReminderSettingsTable createAlias(String alias) {
    return $LensExpiryReminderSettingsTable(attachedDatabase, alias);
  }
}

class LensExpiryReminderSetting extends DataClass
    implements Insertable<LensExpiryReminderSetting> {
  final int id;
  final bool isActive;
  final int advanceDays;
  final String reminderTime;
  final DateTime updatedAt;
  const LensExpiryReminderSetting({
    required this.id,
    required this.isActive,
    required this.advanceDays,
    required this.reminderTime,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_active'] = Variable<bool>(isActive);
    map['advance_days'] = Variable<int>(advanceDays);
    map['reminder_time'] = Variable<String>(reminderTime);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LensExpiryReminderSettingsCompanion toCompanion(bool nullToAbsent) {
    return LensExpiryReminderSettingsCompanion(
      id: Value(id),
      isActive: Value(isActive),
      advanceDays: Value(advanceDays),
      reminderTime: Value(reminderTime),
      updatedAt: Value(updatedAt),
    );
  }

  factory LensExpiryReminderSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LensExpiryReminderSetting(
      id: serializer.fromJson<int>(json['id']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      advanceDays: serializer.fromJson<int>(json['advanceDays']),
      reminderTime: serializer.fromJson<String>(json['reminderTime']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isActive': serializer.toJson<bool>(isActive),
      'advanceDays': serializer.toJson<int>(advanceDays),
      'reminderTime': serializer.toJson<String>(reminderTime),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LensExpiryReminderSetting copyWith({
    int? id,
    bool? isActive,
    int? advanceDays,
    String? reminderTime,
    DateTime? updatedAt,
  }) => LensExpiryReminderSetting(
    id: id ?? this.id,
    isActive: isActive ?? this.isActive,
    advanceDays: advanceDays ?? this.advanceDays,
    reminderTime: reminderTime ?? this.reminderTime,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LensExpiryReminderSetting copyWithCompanion(
    LensExpiryReminderSettingsCompanion data,
  ) {
    return LensExpiryReminderSetting(
      id: data.id.present ? data.id.value : this.id,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      advanceDays: data.advanceDays.present
          ? data.advanceDays.value
          : this.advanceDays,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LensExpiryReminderSetting(')
          ..write('id: $id, ')
          ..write('isActive: $isActive, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, isActive, advanceDays, reminderTime, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LensExpiryReminderSetting &&
          other.id == this.id &&
          other.isActive == this.isActive &&
          other.advanceDays == this.advanceDays &&
          other.reminderTime == this.reminderTime &&
          other.updatedAt == this.updatedAt);
}

class LensExpiryReminderSettingsCompanion
    extends UpdateCompanion<LensExpiryReminderSetting> {
  final Value<int> id;
  final Value<bool> isActive;
  final Value<int> advanceDays;
  final Value<String> reminderTime;
  final Value<DateTime> updatedAt;
  const LensExpiryReminderSettingsCompanion({
    this.id = const Value.absent(),
    this.isActive = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LensExpiryReminderSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.isActive = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<LensExpiryReminderSetting> custom({
    Expression<int>? id,
    Expression<bool>? isActive,
    Expression<int>? advanceDays,
    Expression<String>? reminderTime,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isActive != null) 'is_active': isActive,
      if (advanceDays != null) 'advance_days': advanceDays,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LensExpiryReminderSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? isActive,
    Value<int>? advanceDays,
    Value<String>? reminderTime,
    Value<DateTime>? updatedAt,
  }) {
    return LensExpiryReminderSettingsCompanion(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      advanceDays: advanceDays ?? this.advanceDays,
      reminderTime: reminderTime ?? this.reminderTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (advanceDays.present) {
      map['advance_days'] = Variable<int>(advanceDays.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LensExpiryReminderSettingsCompanion(')
          ..write('id: $id, ')
          ..write('isActive: $isActive, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CareSolutionChangeRemindersTable extends CareSolutionChangeReminders
    with
        TableInfo<
          $CareSolutionChangeRemindersTable,
          CareSolutionChangeReminder
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareSolutionChangeRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('09:00'),
  );
  static const VerificationMeta _lastChangedDateMeta = const VerificationMeta(
    'lastChangedDate',
  );
  @override
  late final GeneratedColumn<String> lastChangedDate = GeneratedColumn<String>(
    'last_changed_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextChangedDateMeta = const VerificationMeta(
    'nextChangedDate',
  );
  @override
  late final GeneratedColumn<String> nextChangedDate = GeneratedColumn<String>(
    'next_changed_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isActive,
    frequency,
    intervalDays,
    reminderTime,
    lastChangedDate,
    nextChangedDate,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_solution_change_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareSolutionChangeReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('last_changed_date')) {
      context.handle(
        _lastChangedDateMeta,
        lastChangedDate.isAcceptableOrUnknown(
          data['last_changed_date']!,
          _lastChangedDateMeta,
        ),
      );
    }
    if (data.containsKey('next_changed_date')) {
      context.handle(
        _nextChangedDateMeta,
        nextChangedDate.isAcceptableOrUnknown(
          data['next_changed_date']!,
          _nextChangedDateMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareSolutionChangeReminder map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareSolutionChangeReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      )!,
      lastChangedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_changed_date'],
      ),
      nextChangedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_changed_date'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CareSolutionChangeRemindersTable createAlias(String alias) {
    return $CareSolutionChangeRemindersTable(attachedDatabase, alias);
  }
}

class CareSolutionChangeReminder extends DataClass
    implements Insertable<CareSolutionChangeReminder> {
  final int id;
  final bool isActive;
  final String frequency;
  final int intervalDays;
  final String reminderTime;
  final String? lastChangedDate;
  final String? nextChangedDate;
  final DateTime updatedAt;
  const CareSolutionChangeReminder({
    required this.id,
    required this.isActive,
    required this.frequency,
    required this.intervalDays,
    required this.reminderTime,
    this.lastChangedDate,
    this.nextChangedDate,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_active'] = Variable<bool>(isActive);
    map['frequency'] = Variable<String>(frequency);
    map['interval_days'] = Variable<int>(intervalDays);
    map['reminder_time'] = Variable<String>(reminderTime);
    if (!nullToAbsent || lastChangedDate != null) {
      map['last_changed_date'] = Variable<String>(lastChangedDate);
    }
    if (!nullToAbsent || nextChangedDate != null) {
      map['next_changed_date'] = Variable<String>(nextChangedDate);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CareSolutionChangeRemindersCompanion toCompanion(bool nullToAbsent) {
    return CareSolutionChangeRemindersCompanion(
      id: Value(id),
      isActive: Value(isActive),
      frequency: Value(frequency),
      intervalDays: Value(intervalDays),
      reminderTime: Value(reminderTime),
      lastChangedDate: lastChangedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastChangedDate),
      nextChangedDate: nextChangedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextChangedDate),
      updatedAt: Value(updatedAt),
    );
  }

  factory CareSolutionChangeReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareSolutionChangeReminder(
      id: serializer.fromJson<int>(json['id']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      frequency: serializer.fromJson<String>(json['frequency']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      reminderTime: serializer.fromJson<String>(json['reminderTime']),
      lastChangedDate: serializer.fromJson<String?>(json['lastChangedDate']),
      nextChangedDate: serializer.fromJson<String?>(json['nextChangedDate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isActive': serializer.toJson<bool>(isActive),
      'frequency': serializer.toJson<String>(frequency),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'reminderTime': serializer.toJson<String>(reminderTime),
      'lastChangedDate': serializer.toJson<String?>(lastChangedDate),
      'nextChangedDate': serializer.toJson<String?>(nextChangedDate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CareSolutionChangeReminder copyWith({
    int? id,
    bool? isActive,
    String? frequency,
    int? intervalDays,
    String? reminderTime,
    Value<String?> lastChangedDate = const Value.absent(),
    Value<String?> nextChangedDate = const Value.absent(),
    DateTime? updatedAt,
  }) => CareSolutionChangeReminder(
    id: id ?? this.id,
    isActive: isActive ?? this.isActive,
    frequency: frequency ?? this.frequency,
    intervalDays: intervalDays ?? this.intervalDays,
    reminderTime: reminderTime ?? this.reminderTime,
    lastChangedDate: lastChangedDate.present
        ? lastChangedDate.value
        : this.lastChangedDate,
    nextChangedDate: nextChangedDate.present
        ? nextChangedDate.value
        : this.nextChangedDate,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CareSolutionChangeReminder copyWithCompanion(
    CareSolutionChangeRemindersCompanion data,
  ) {
    return CareSolutionChangeReminder(
      id: data.id.present ? data.id.value : this.id,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      lastChangedDate: data.lastChangedDate.present
          ? data.lastChangedDate.value
          : this.lastChangedDate,
      nextChangedDate: data.nextChangedDate.present
          ? data.nextChangedDate.value
          : this.nextChangedDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionChangeReminder(')
          ..write('id: $id, ')
          ..write('isActive: $isActive, ')
          ..write('frequency: $frequency, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('lastChangedDate: $lastChangedDate, ')
          ..write('nextChangedDate: $nextChangedDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    isActive,
    frequency,
    intervalDays,
    reminderTime,
    lastChangedDate,
    nextChangedDate,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareSolutionChangeReminder &&
          other.id == this.id &&
          other.isActive == this.isActive &&
          other.frequency == this.frequency &&
          other.intervalDays == this.intervalDays &&
          other.reminderTime == this.reminderTime &&
          other.lastChangedDate == this.lastChangedDate &&
          other.nextChangedDate == this.nextChangedDate &&
          other.updatedAt == this.updatedAt);
}

class CareSolutionChangeRemindersCompanion
    extends UpdateCompanion<CareSolutionChangeReminder> {
  final Value<int> id;
  final Value<bool> isActive;
  final Value<String> frequency;
  final Value<int> intervalDays;
  final Value<String> reminderTime;
  final Value<String?> lastChangedDate;
  final Value<String?> nextChangedDate;
  final Value<DateTime> updatedAt;
  const CareSolutionChangeRemindersCompanion({
    this.id = const Value.absent(),
    this.isActive = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.lastChangedDate = const Value.absent(),
    this.nextChangedDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CareSolutionChangeRemindersCompanion.insert({
    this.id = const Value.absent(),
    this.isActive = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.lastChangedDate = const Value.absent(),
    this.nextChangedDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<CareSolutionChangeReminder> custom({
    Expression<int>? id,
    Expression<bool>? isActive,
    Expression<String>? frequency,
    Expression<int>? intervalDays,
    Expression<String>? reminderTime,
    Expression<String>? lastChangedDate,
    Expression<String>? nextChangedDate,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isActive != null) 'is_active': isActive,
      if (frequency != null) 'frequency': frequency,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (lastChangedDate != null) 'last_changed_date': lastChangedDate,
      if (nextChangedDate != null) 'next_changed_date': nextChangedDate,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CareSolutionChangeRemindersCompanion copyWith({
    Value<int>? id,
    Value<bool>? isActive,
    Value<String>? frequency,
    Value<int>? intervalDays,
    Value<String>? reminderTime,
    Value<String?>? lastChangedDate,
    Value<String?>? nextChangedDate,
    Value<DateTime>? updatedAt,
  }) {
    return CareSolutionChangeRemindersCompanion(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      frequency: frequency ?? this.frequency,
      intervalDays: intervalDays ?? this.intervalDays,
      reminderTime: reminderTime ?? this.reminderTime,
      lastChangedDate: lastChangedDate ?? this.lastChangedDate,
      nextChangedDate: nextChangedDate ?? this.nextChangedDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (lastChangedDate.present) {
      map['last_changed_date'] = Variable<String>(lastChangedDate.value);
    }
    if (nextChangedDate.present) {
      map['next_changed_date'] = Variable<String>(nextChangedDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionChangeRemindersCompanion(')
          ..write('id: $id, ')
          ..write('isActive: $isActive, ')
          ..write('frequency: $frequency, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('lastChangedDate: $lastChangedDate, ')
          ..write('nextChangedDate: $nextChangedDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CareSolutionChangeLogsTable extends CareSolutionChangeLogs
    with TableInfo<$CareSolutionChangeLogsTable, CareSolutionChangeLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareSolutionChangeLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<int> reminderId = GeneratedColumn<int>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, reminderId, changedAt, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_solution_change_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareSolutionChangeLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareSolutionChangeLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareSolutionChangeLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CareSolutionChangeLogsTable createAlias(String alias) {
    return $CareSolutionChangeLogsTable(attachedDatabase, alias);
  }
}

class CareSolutionChangeLog extends DataClass
    implements Insertable<CareSolutionChangeLog> {
  final int id;
  final int reminderId;
  final DateTime changedAt;
  final String? note;
  const CareSolutionChangeLog({
    required this.id,
    required this.reminderId,
    required this.changedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reminder_id'] = Variable<int>(reminderId);
    map['changed_at'] = Variable<DateTime>(changedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CareSolutionChangeLogsCompanion toCompanion(bool nullToAbsent) {
    return CareSolutionChangeLogsCompanion(
      id: Value(id),
      reminderId: Value(reminderId),
      changedAt: Value(changedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CareSolutionChangeLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareSolutionChangeLog(
      id: serializer.fromJson<int>(json['id']),
      reminderId: serializer.fromJson<int>(json['reminderId']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reminderId': serializer.toJson<int>(reminderId),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  CareSolutionChangeLog copyWith({
    int? id,
    int? reminderId,
    DateTime? changedAt,
    Value<String?> note = const Value.absent(),
  }) => CareSolutionChangeLog(
    id: id ?? this.id,
    reminderId: reminderId ?? this.reminderId,
    changedAt: changedAt ?? this.changedAt,
    note: note.present ? note.value : this.note,
  );
  CareSolutionChangeLog copyWithCompanion(
    CareSolutionChangeLogsCompanion data,
  ) {
    return CareSolutionChangeLog(
      id: data.id.present ? data.id.value : this.id,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionChangeLog(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('changedAt: $changedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reminderId, changedAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareSolutionChangeLog &&
          other.id == this.id &&
          other.reminderId == this.reminderId &&
          other.changedAt == this.changedAt &&
          other.note == this.note);
}

class CareSolutionChangeLogsCompanion
    extends UpdateCompanion<CareSolutionChangeLog> {
  final Value<int> id;
  final Value<int> reminderId;
  final Value<DateTime> changedAt;
  final Value<String?> note;
  const CareSolutionChangeLogsCompanion({
    this.id = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.note = const Value.absent(),
  });
  CareSolutionChangeLogsCompanion.insert({
    this.id = const Value.absent(),
    required int reminderId,
    this.changedAt = const Value.absent(),
    this.note = const Value.absent(),
  }) : reminderId = Value(reminderId);
  static Insertable<CareSolutionChangeLog> custom({
    Expression<int>? id,
    Expression<int>? reminderId,
    Expression<DateTime>? changedAt,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderId != null) 'reminder_id': reminderId,
      if (changedAt != null) 'changed_at': changedAt,
      if (note != null) 'note': note,
    });
  }

  CareSolutionChangeLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? reminderId,
    Value<DateTime>? changedAt,
    Value<String?>? note,
  }) {
    return CareSolutionChangeLogsCompanion(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      changedAt: changedAt ?? this.changedAt,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<int>(reminderId.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionChangeLogsCompanion(')
          ..write('id: $id, ')
          ..write('reminderId: $reminderId, ')
          ..write('changedAt: $changedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $CareSolutionBottlesTable extends CareSolutionBottles
    with TableInfo<$CareSolutionBottlesTable, CareSolutionBottle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareSolutionBottlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<String> openedAt = GeneratedColumn<String>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packageExpiryDateMeta = const VerificationMeta(
    'packageExpiryDate',
  );
  @override
  late final GeneratedColumn<String> packageExpiryDate =
      GeneratedColumn<String>(
        'package_expiry_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _afterOpenValidDaysMeta =
      const VerificationMeta('afterOpenValidDays');
  @override
  late final GeneratedColumn<int> afterOpenValidDays = GeneratedColumn<int>(
    'after_open_valid_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    name,
    openedAt,
    packageExpiryDate,
    afterOpenValidDays,
    isCurrent,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_solution_bottles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareSolutionBottle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('package_expiry_date')) {
      context.handle(
        _packageExpiryDateMeta,
        packageExpiryDate.isAcceptableOrUnknown(
          data['package_expiry_date']!,
          _packageExpiryDateMeta,
        ),
      );
    }
    if (data.containsKey('after_open_valid_days')) {
      context.handle(
        _afterOpenValidDaysMeta,
        afterOpenValidDays.isAcceptableOrUnknown(
          data['after_open_valid_days']!,
          _afterOpenValidDaysMeta,
        ),
      );
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareSolutionBottle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareSolutionBottle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_at'],
      ),
      packageExpiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_expiry_date'],
      ),
      afterOpenValidDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}after_open_valid_days'],
      ),
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CareSolutionBottlesTable createAlias(String alias) {
    return $CareSolutionBottlesTable(attachedDatabase, alias);
  }
}

class CareSolutionBottle extends DataClass
    implements Insertable<CareSolutionBottle> {
  final int id;
  final String brand;
  final String name;
  final String? openedAt;
  final String? packageExpiryDate;
  final int? afterOpenValidDays;
  final bool isCurrent;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CareSolutionBottle({
    required this.id,
    required this.brand,
    required this.name,
    this.openedAt,
    this.packageExpiryDate,
    this.afterOpenValidDays,
    required this.isCurrent,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brand'] = Variable<String>(brand);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<String>(openedAt);
    }
    if (!nullToAbsent || packageExpiryDate != null) {
      map['package_expiry_date'] = Variable<String>(packageExpiryDate);
    }
    if (!nullToAbsent || afterOpenValidDays != null) {
      map['after_open_valid_days'] = Variable<int>(afterOpenValidDays);
    }
    map['is_current'] = Variable<bool>(isCurrent);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CareSolutionBottlesCompanion toCompanion(bool nullToAbsent) {
    return CareSolutionBottlesCompanion(
      id: Value(id),
      brand: Value(brand),
      name: Value(name),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      packageExpiryDate: packageExpiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(packageExpiryDate),
      afterOpenValidDays: afterOpenValidDays == null && nullToAbsent
          ? const Value.absent()
          : Value(afterOpenValidDays),
      isCurrent: Value(isCurrent),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CareSolutionBottle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareSolutionBottle(
      id: serializer.fromJson<int>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      name: serializer.fromJson<String>(json['name']),
      openedAt: serializer.fromJson<String?>(json['openedAt']),
      packageExpiryDate: serializer.fromJson<String?>(
        json['packageExpiryDate'],
      ),
      afterOpenValidDays: serializer.fromJson<int?>(json['afterOpenValidDays']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brand': serializer.toJson<String>(brand),
      'name': serializer.toJson<String>(name),
      'openedAt': serializer.toJson<String?>(openedAt),
      'packageExpiryDate': serializer.toJson<String?>(packageExpiryDate),
      'afterOpenValidDays': serializer.toJson<int?>(afterOpenValidDays),
      'isCurrent': serializer.toJson<bool>(isCurrent),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CareSolutionBottle copyWith({
    int? id,
    String? brand,
    String? name,
    Value<String?> openedAt = const Value.absent(),
    Value<String?> packageExpiryDate = const Value.absent(),
    Value<int?> afterOpenValidDays = const Value.absent(),
    bool? isCurrent,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CareSolutionBottle(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    name: name ?? this.name,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    packageExpiryDate: packageExpiryDate.present
        ? packageExpiryDate.value
        : this.packageExpiryDate,
    afterOpenValidDays: afterOpenValidDays.present
        ? afterOpenValidDays.value
        : this.afterOpenValidDays,
    isCurrent: isCurrent ?? this.isCurrent,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CareSolutionBottle copyWithCompanion(CareSolutionBottlesCompanion data) {
    return CareSolutionBottle(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      name: data.name.present ? data.name.value : this.name,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      packageExpiryDate: data.packageExpiryDate.present
          ? data.packageExpiryDate.value
          : this.packageExpiryDate,
      afterOpenValidDays: data.afterOpenValidDays.present
          ? data.afterOpenValidDays.value
          : this.afterOpenValidDays,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionBottle(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('openedAt: $openedAt, ')
          ..write('packageExpiryDate: $packageExpiryDate, ')
          ..write('afterOpenValidDays: $afterOpenValidDays, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    brand,
    name,
    openedAt,
    packageExpiryDate,
    afterOpenValidDays,
    isCurrent,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareSolutionBottle &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.name == this.name &&
          other.openedAt == this.openedAt &&
          other.packageExpiryDate == this.packageExpiryDate &&
          other.afterOpenValidDays == this.afterOpenValidDays &&
          other.isCurrent == this.isCurrent &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CareSolutionBottlesCompanion extends UpdateCompanion<CareSolutionBottle> {
  final Value<int> id;
  final Value<String> brand;
  final Value<String> name;
  final Value<String?> openedAt;
  final Value<String?> packageExpiryDate;
  final Value<int?> afterOpenValidDays;
  final Value<bool> isCurrent;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CareSolutionBottlesCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.name = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.packageExpiryDate = const Value.absent(),
    this.afterOpenValidDays = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CareSolutionBottlesCompanion.insert({
    this.id = const Value.absent(),
    required String brand,
    required String name,
    this.openedAt = const Value.absent(),
    this.packageExpiryDate = const Value.absent(),
    this.afterOpenValidDays = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : brand = Value(brand),
       name = Value(name);
  static Insertable<CareSolutionBottle> custom({
    Expression<int>? id,
    Expression<String>? brand,
    Expression<String>? name,
    Expression<String>? openedAt,
    Expression<String>? packageExpiryDate,
    Expression<int>? afterOpenValidDays,
    Expression<bool>? isCurrent,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (name != null) 'name': name,
      if (openedAt != null) 'opened_at': openedAt,
      if (packageExpiryDate != null) 'package_expiry_date': packageExpiryDate,
      if (afterOpenValidDays != null)
        'after_open_valid_days': afterOpenValidDays,
      if (isCurrent != null) 'is_current': isCurrent,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CareSolutionBottlesCompanion copyWith({
    Value<int>? id,
    Value<String>? brand,
    Value<String>? name,
    Value<String?>? openedAt,
    Value<String?>? packageExpiryDate,
    Value<int?>? afterOpenValidDays,
    Value<bool>? isCurrent,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CareSolutionBottlesCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      openedAt: openedAt ?? this.openedAt,
      packageExpiryDate: packageExpiryDate ?? this.packageExpiryDate,
      afterOpenValidDays: afterOpenValidDays ?? this.afterOpenValidDays,
      isCurrent: isCurrent ?? this.isCurrent,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<String>(openedAt.value);
    }
    if (packageExpiryDate.present) {
      map['package_expiry_date'] = Variable<String>(packageExpiryDate.value);
    }
    if (afterOpenValidDays.present) {
      map['after_open_valid_days'] = Variable<int>(afterOpenValidDays.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionBottlesCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('openedAt: $openedAt, ')
          ..write('packageExpiryDate: $packageExpiryDate, ')
          ..write('afterOpenValidDays: $afterOpenValidDays, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CareSolutionExpirySettingsTable extends CareSolutionExpirySettings
    with
        TableInfo<$CareSolutionExpirySettingsTable, CareSolutionExpirySetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareSolutionExpirySettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _advanceDaysMeta = const VerificationMeta(
    'advanceDays',
  );
  @override
  late final GeneratedColumn<int> advanceDays = GeneratedColumn<int>(
    'advance_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('09:00'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isActive,
    advanceDays,
    reminderTime,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'care_solution_expiry_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CareSolutionExpirySetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('advance_days')) {
      context.handle(
        _advanceDaysMeta,
        advanceDays.isAcceptableOrUnknown(
          data['advance_days']!,
          _advanceDaysMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CareSolutionExpirySetting map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareSolutionExpirySetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      advanceDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}advance_days'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CareSolutionExpirySettingsTable createAlias(String alias) {
    return $CareSolutionExpirySettingsTable(attachedDatabase, alias);
  }
}

class CareSolutionExpirySetting extends DataClass
    implements Insertable<CareSolutionExpirySetting> {
  final int id;
  final bool isActive;
  final int advanceDays;
  final String reminderTime;
  final DateTime updatedAt;
  const CareSolutionExpirySetting({
    required this.id,
    required this.isActive,
    required this.advanceDays,
    required this.reminderTime,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_active'] = Variable<bool>(isActive);
    map['advance_days'] = Variable<int>(advanceDays);
    map['reminder_time'] = Variable<String>(reminderTime);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CareSolutionExpirySettingsCompanion toCompanion(bool nullToAbsent) {
    return CareSolutionExpirySettingsCompanion(
      id: Value(id),
      isActive: Value(isActive),
      advanceDays: Value(advanceDays),
      reminderTime: Value(reminderTime),
      updatedAt: Value(updatedAt),
    );
  }

  factory CareSolutionExpirySetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareSolutionExpirySetting(
      id: serializer.fromJson<int>(json['id']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      advanceDays: serializer.fromJson<int>(json['advanceDays']),
      reminderTime: serializer.fromJson<String>(json['reminderTime']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isActive': serializer.toJson<bool>(isActive),
      'advanceDays': serializer.toJson<int>(advanceDays),
      'reminderTime': serializer.toJson<String>(reminderTime),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CareSolutionExpirySetting copyWith({
    int? id,
    bool? isActive,
    int? advanceDays,
    String? reminderTime,
    DateTime? updatedAt,
  }) => CareSolutionExpirySetting(
    id: id ?? this.id,
    isActive: isActive ?? this.isActive,
    advanceDays: advanceDays ?? this.advanceDays,
    reminderTime: reminderTime ?? this.reminderTime,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CareSolutionExpirySetting copyWithCompanion(
    CareSolutionExpirySettingsCompanion data,
  ) {
    return CareSolutionExpirySetting(
      id: data.id.present ? data.id.value : this.id,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      advanceDays: data.advanceDays.present
          ? data.advanceDays.value
          : this.advanceDays,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionExpirySetting(')
          ..write('id: $id, ')
          ..write('isActive: $isActive, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, isActive, advanceDays, reminderTime, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareSolutionExpirySetting &&
          other.id == this.id &&
          other.isActive == this.isActive &&
          other.advanceDays == this.advanceDays &&
          other.reminderTime == this.reminderTime &&
          other.updatedAt == this.updatedAt);
}

class CareSolutionExpirySettingsCompanion
    extends UpdateCompanion<CareSolutionExpirySetting> {
  final Value<int> id;
  final Value<bool> isActive;
  final Value<int> advanceDays;
  final Value<String> reminderTime;
  final Value<DateTime> updatedAt;
  const CareSolutionExpirySettingsCompanion({
    this.id = const Value.absent(),
    this.isActive = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CareSolutionExpirySettingsCompanion.insert({
    this.id = const Value.absent(),
    this.isActive = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<CareSolutionExpirySetting> custom({
    Expression<int>? id,
    Expression<bool>? isActive,
    Expression<int>? advanceDays,
    Expression<String>? reminderTime,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isActive != null) 'is_active': isActive,
      if (advanceDays != null) 'advance_days': advanceDays,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CareSolutionExpirySettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? isActive,
    Value<int>? advanceDays,
    Value<String>? reminderTime,
    Value<DateTime>? updatedAt,
  }) {
    return CareSolutionExpirySettingsCompanion(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      advanceDays: advanceDays ?? this.advanceDays,
      reminderTime: reminderTime ?? this.reminderTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (advanceDays.present) {
      map['advance_days'] = Variable<int>(advanceDays.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareSolutionExpirySettingsCompanion(')
          ..write('id: $id, ')
          ..write('isActive: $isActive, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String? value;
  final DateTime updatedAt;
  const AppSetting({required this.key, this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
    DateTime? updatedAt,
  }) => AppSetting(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationLogsTable extends NotificationLogs
    with TableInfo<$NotificationLogsTable, NotificationLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _notificationKeyMeta = const VerificationMeta(
    'notificationKey',
  );
  @override
  late final GeneratedColumn<String> notificationKey = GeneratedColumn<String>(
    'notification_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scheduled'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    notificationKey,
    targetType,
    targetId,
    scheduledDate,
    sentAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notification_key')) {
      context.handle(
        _notificationKeyMeta,
        notificationKey.isAcceptableOrUnknown(
          data['notification_key']!,
          _notificationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationKeyMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      notificationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_key'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $NotificationLogsTable createAlias(String alias) {
    return $NotificationLogsTable(attachedDatabase, alias);
  }
}

class NotificationLog extends DataClass implements Insertable<NotificationLog> {
  final int id;
  final String notificationKey;
  final String targetType;
  final String? targetId;
  final DateTime scheduledDate;
  final DateTime? sentAt;
  final String status;
  const NotificationLog({
    required this.id,
    required this.notificationKey,
    required this.targetType,
    this.targetId,
    required this.scheduledDate,
    this.sentAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notification_key'] = Variable<String>(notificationKey);
    map['target_type'] = Variable<String>(targetType);
    if (!nullToAbsent || targetId != null) {
      map['target_id'] = Variable<String>(targetId);
    }
    map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  NotificationLogsCompanion toCompanion(bool nullToAbsent) {
    return NotificationLogsCompanion(
      id: Value(id),
      notificationKey: Value(notificationKey),
      targetType: Value(targetType),
      targetId: targetId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetId),
      scheduledDate: Value(scheduledDate),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      status: Value(status),
    );
  }

  factory NotificationLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLog(
      id: serializer.fromJson<int>(json['id']),
      notificationKey: serializer.fromJson<String>(json['notificationKey']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String?>(json['targetId']),
      scheduledDate: serializer.fromJson<DateTime>(json['scheduledDate']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notificationKey': serializer.toJson<String>(notificationKey),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String?>(targetId),
      'scheduledDate': serializer.toJson<DateTime>(scheduledDate),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'status': serializer.toJson<String>(status),
    };
  }

  NotificationLog copyWith({
    int? id,
    String? notificationKey,
    String? targetType,
    Value<String?> targetId = const Value.absent(),
    DateTime? scheduledDate,
    Value<DateTime?> sentAt = const Value.absent(),
    String? status,
  }) => NotificationLog(
    id: id ?? this.id,
    notificationKey: notificationKey ?? this.notificationKey,
    targetType: targetType ?? this.targetType,
    targetId: targetId.present ? targetId.value : this.targetId,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    status: status ?? this.status,
  );
  NotificationLog copyWithCompanion(NotificationLogsCompanion data) {
    return NotificationLog(
      id: data.id.present ? data.id.value : this.id,
      notificationKey: data.notificationKey.present
          ? data.notificationKey.value
          : this.notificationKey,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLog(')
          ..write('id: $id, ')
          ..write('notificationKey: $notificationKey, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    notificationKey,
    targetType,
    targetId,
    scheduledDate,
    sentAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLog &&
          other.id == this.id &&
          other.notificationKey == this.notificationKey &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.scheduledDate == this.scheduledDate &&
          other.sentAt == this.sentAt &&
          other.status == this.status);
}

class NotificationLogsCompanion extends UpdateCompanion<NotificationLog> {
  final Value<int> id;
  final Value<String> notificationKey;
  final Value<String> targetType;
  final Value<String?> targetId;
  final Value<DateTime> scheduledDate;
  final Value<DateTime?> sentAt;
  final Value<String> status;
  const NotificationLogsCompanion({
    this.id = const Value.absent(),
    this.notificationKey = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  NotificationLogsCompanion.insert({
    this.id = const Value.absent(),
    required String notificationKey,
    required String targetType,
    this.targetId = const Value.absent(),
    required DateTime scheduledDate,
    this.sentAt = const Value.absent(),
    this.status = const Value.absent(),
  }) : notificationKey = Value(notificationKey),
       targetType = Value(targetType),
       scheduledDate = Value(scheduledDate);
  static Insertable<NotificationLog> custom({
    Expression<int>? id,
    Expression<String>? notificationKey,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<DateTime>? scheduledDate,
    Expression<DateTime>? sentAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notificationKey != null) 'notification_key': notificationKey,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (sentAt != null) 'sent_at': sentAt,
      if (status != null) 'status': status,
    });
  }

  NotificationLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? notificationKey,
    Value<String>? targetType,
    Value<String?>? targetId,
    Value<DateTime>? scheduledDate,
    Value<DateTime?>? sentAt,
    Value<String>? status,
  }) {
    return NotificationLogsCompanion(
      id: id ?? this.id,
      notificationKey: notificationKey ?? this.notificationKey,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notificationKey.present) {
      map['notification_key'] = Variable<String>(notificationKey.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogsCompanion(')
          ..write('id: $id, ')
          ..write('notificationKey: $notificationKey, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LensCyclesTable lensCycles = $LensCyclesTable(this);
  late final $LensesTable lenses = $LensesTable(this);
  late final $LensImagesTable lensImages = $LensImagesTable(this);
  late final $LensExpiryReminderSettingsTable lensExpiryReminderSettings =
      $LensExpiryReminderSettingsTable(this);
  late final $CareSolutionChangeRemindersTable careSolutionChangeReminders =
      $CareSolutionChangeRemindersTable(this);
  late final $CareSolutionChangeLogsTable careSolutionChangeLogs =
      $CareSolutionChangeLogsTable(this);
  late final $CareSolutionBottlesTable careSolutionBottles =
      $CareSolutionBottlesTable(this);
  late final $CareSolutionExpirySettingsTable careSolutionExpirySettings =
      $CareSolutionExpirySettingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $NotificationLogsTable notificationLogs = $NotificationLogsTable(
    this,
  );
  late final Index idxLensCyclesSort = Index(
    'idx_lens_cycles_sort',
    'CREATE INDEX idx_lens_cycles_sort ON lens_cycles (sort_order)',
  );
  late final Index idxLensesCycle = Index(
    'idx_lenses_cycle',
    'CREATE INDEX idx_lenses_cycle ON lenses (cycle_id)',
  );
  late final Index idxLensesStatus = Index(
    'idx_lenses_status',
    'CREATE INDEX idx_lenses_status ON lenses (status)',
  );
  late final Index idxLensImagesLens = Index(
    'idx_lens_images_lens',
    'CREATE INDEX idx_lens_images_lens ON lens_images (lens_id)',
  );
  late final Index idxNotificationLogsTarget = Index(
    'idx_notification_logs_target',
    'CREATE INDEX idx_notification_logs_target ON notification_logs (target_type, target_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lensCycles,
    lenses,
    lensImages,
    lensExpiryReminderSettings,
    careSolutionChangeReminders,
    careSolutionChangeLogs,
    careSolutionBottles,
    careSolutionExpirySettings,
    appSettings,
    notificationLogs,
    idxLensCyclesSort,
    idxLensesCycle,
    idxLensesStatus,
    idxLensImagesLens,
    idxNotificationLogsTarget,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lenses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lens_images', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LensCyclesTableCreateCompanionBuilder = LensCyclesCompanion Function({
  Value<int> id,
  required String cycleName,
  required String cycleUnit,
  required int cycleValue,
  Value<bool> isBuiltin,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$LensCyclesTableUpdateCompanionBuilder = LensCyclesCompanion Function({
  Value<int> id,
  Value<String> cycleName,
  Value<String> cycleUnit,
  Value<int> cycleValue,
  Value<bool> isBuiltin,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $$LensCyclesTableReferences
    extends BaseReferences<_$AppDatabase, $LensCyclesTable, LensCycle> {
  $$LensCyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LensesTable, List<Lens>> _lensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.lenses,
    aliasName: 'lens_cycles__id__lenses__cycle_id',
  );

  $$LensesTableProcessedTableManager get lensesRefs {
    final manager = $$LensesTableTableManager(
      $_db,
      $_db.lenses,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LensCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $LensCyclesTable> {
  $$LensCyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleName => $composableBuilder(
    column: $table.cycleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cycleUnit => $composableBuilder(
    column: $table.cycleUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleValue => $composableBuilder(
    column: $table.cycleValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> lensesRefs(
    Expression<bool> Function($$LensesTableFilterComposer f) f,
  ) {
    final $$LensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lenses,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensesTableFilterComposer(
            $db: $db,
            $table: $db.lenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LensCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $LensCyclesTable> {
  $$LensCyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleName => $composableBuilder(
    column: $table.cycleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleUnit => $composableBuilder(
    column: $table.cycleUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleValue => $composableBuilder(
    column: $table.cycleValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LensCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LensCyclesTable> {
  $$LensCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cycleName =>
      $composableBuilder(column: $table.cycleName, builder: (column) => column);

  GeneratedColumn<String> get cycleUnit =>
      $composableBuilder(column: $table.cycleUnit, builder: (column) => column);

  GeneratedColumn<int> get cycleValue => $composableBuilder(
    column: $table.cycleValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> lensesRefs<T extends Object>(
    Expression<T> Function($$LensesTableAnnotationComposer a) f,
  ) {
    final $$LensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lenses,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensesTableAnnotationComposer(
            $db: $db,
            $table: $db.lenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LensCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LensCyclesTable,
          LensCycle,
          $$LensCyclesTableFilterComposer,
          $$LensCyclesTableOrderingComposer,
          $$LensCyclesTableAnnotationComposer,
          $$LensCyclesTableCreateCompanionBuilder,
          $$LensCyclesTableUpdateCompanionBuilder,
          (LensCycle, $$LensCyclesTableReferences),
          LensCycle,
          PrefetchHooks Function({bool lensesRefs})
        > {
  $$LensCyclesTableTableManager(_$AppDatabase db, $LensCyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LensCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LensCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LensCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cycleName = const Value.absent(),
                Value<String> cycleUnit = const Value.absent(),
                Value<int> cycleValue = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LensCyclesCompanion(
                id: id,
                cycleName: cycleName,
                cycleUnit: cycleUnit,
                cycleValue: cycleValue,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String cycleName,
                required String cycleUnit,
                required int cycleValue,
                Value<bool> isBuiltin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LensCyclesCompanion.insert(
                id: id,
                cycleName: cycleName,
                cycleUnit: cycleUnit,
                cycleValue: cycleValue,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LensCyclesTable, LensCycle>(table),
                  $$LensCyclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lensesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lensesRefs) db.lenses],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lensesRefs)
                    await $_getPrefetchedDataByColumns<
                      LensCycle,
                      $LensCyclesTable,
                      Lens,
                      $LensesTable
                    >(
                      currentTable: table,
                      referencedTable: $$LensCyclesTableReferences
                          ._lensesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LensCyclesTableReferences(db, table, p0).lensesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'cycle_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LensCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LensCyclesTable,
      LensCycle,
      $$LensCyclesTableFilterComposer,
      $$LensCyclesTableOrderingComposer,
      $$LensCyclesTableAnnotationComposer,
      $$LensCyclesTableCreateCompanionBuilder,
      $$LensCyclesTableUpdateCompanionBuilder,
      (LensCycle, $$LensCyclesTableReferences),
      LensCycle,
      PrefetchHooks Function({bool lensesRefs})
    >;
typedef $$LensesTableCreateCompanionBuilder = LensesCompanion Function({
  Value<int> id,
  required String brand,
  required String name,
  required int cycleId,
  Value<String?> colorScheme,
  Value<String?> lensSpecs,
  Value<String> status,
  Value<String?> openedAt,
  Value<String?> packageExpiryDate,
  Value<String?> discardedAt,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$LensesTableUpdateCompanionBuilder = LensesCompanion Function({
  Value<int> id,
  Value<String> brand,
  Value<String> name,
  Value<int> cycleId,
  Value<String?> colorScheme,
  Value<String?> lensSpecs,
  Value<String> status,
  Value<String?> openedAt,
  Value<String?> packageExpiryDate,
  Value<String?> discardedAt,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$LensesTableReferences
    extends BaseReferences<_$AppDatabase, $LensesTable, Lens> {
  $$LensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LensCyclesTable _cycleIdTable(_$AppDatabase db) =>
      db.lensCycles.createAlias('lenses__cycle_id__lens_cycles__id');

  $$LensCyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<int>('cycle_id')!;

    final manager = $$LensCyclesTableTableManager(
      $_db,
      $_db.lensCycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LensImagesTable, List<LensImage>>
  _lensImagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lensImages,
    aliasName: 'lenses__id__lens_images__lens_id',
  );

  $$LensImagesTableProcessedTableManager get lensImagesRefs {
    final manager = $$LensImagesTableTableManager(
      $_db,
      $_db.lensImages,
    ).filter((f) => f.lensId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lensImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LensesTableFilterComposer
    extends Composer<_$AppDatabase, $LensesTable> {
  $$LensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorScheme => $composableBuilder(
    column: $table.colorScheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lensSpecs => $composableBuilder(
    column: $table.lensSpecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageExpiryDate => $composableBuilder(
    column: $table.packageExpiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discardedAt => $composableBuilder(
    column: $table.discardedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LensCyclesTableFilterComposer get cycleId {
    final $$LensCyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.lensCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensCyclesTableFilterComposer(
            $db: $db,
            $table: $db.lensCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lensImagesRefs(
    Expression<bool> Function($$LensImagesTableFilterComposer f) f,
  ) {
    final $$LensImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lensImages,
      getReferencedColumn: (t) => t.lensId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensImagesTableFilterComposer(
            $db: $db,
            $table: $db.lensImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LensesTable> {
  $$LensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorScheme => $composableBuilder(
    column: $table.colorScheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lensSpecs => $composableBuilder(
    column: $table.lensSpecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageExpiryDate => $composableBuilder(
    column: $table.packageExpiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discardedAt => $composableBuilder(
    column: $table.discardedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LensCyclesTableOrderingComposer get cycleId {
    final $$LensCyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.lensCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensCyclesTableOrderingComposer(
            $db: $db,
            $table: $db.lensCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LensesTable> {
  $$LensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorScheme => $composableBuilder(
    column: $table.colorScheme,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lensSpecs =>
      $composableBuilder(column: $table.lensSpecs, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get packageExpiryDate => $composableBuilder(
    column: $table.packageExpiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discardedAt => $composableBuilder(
    column: $table.discardedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LensCyclesTableAnnotationComposer get cycleId {
    final $$LensCyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.lensCycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensCyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.lensCycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lensImagesRefs<T extends Object>(
    Expression<T> Function($$LensImagesTableAnnotationComposer a) f,
  ) {
    final $$LensImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lensImages,
      getReferencedColumn: (t) => t.lensId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.lensImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LensesTable,
          Lens,
          $$LensesTableFilterComposer,
          $$LensesTableOrderingComposer,
          $$LensesTableAnnotationComposer,
          $$LensesTableCreateCompanionBuilder,
          $$LensesTableUpdateCompanionBuilder,
          (Lens, $$LensesTableReferences),
          Lens,
          PrefetchHooks Function({bool cycleId, bool lensImagesRefs})
        > {
  $$LensesTableTableManager(_$AppDatabase db, $LensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> cycleId = const Value.absent(),
                Value<String?> colorScheme = const Value.absent(),
                Value<String?> lensSpecs = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> openedAt = const Value.absent(),
                Value<String?> packageExpiryDate = const Value.absent(),
                Value<String?> discardedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LensesCompanion(
                id: id,
                brand: brand,
                name: name,
                cycleId: cycleId,
                colorScheme: colorScheme,
                lensSpecs: lensSpecs,
                status: status,
                openedAt: openedAt,
                packageExpiryDate: packageExpiryDate,
                discardedAt: discardedAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String brand,
                required String name,
                required int cycleId,
                Value<String?> colorScheme = const Value.absent(),
                Value<String?> lensSpecs = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> openedAt = const Value.absent(),
                Value<String?> packageExpiryDate = const Value.absent(),
                Value<String?> discardedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LensesCompanion.insert(
                id: id,
                brand: brand,
                name: name,
                cycleId: cycleId,
                colorScheme: colorScheme,
                lensSpecs: lensSpecs,
                status: status,
                openedAt: openedAt,
                packageExpiryDate: packageExpiryDate,
                discardedAt: discardedAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LensesTable, Lens>(table),
                  $$LensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cycleId = false, lensImagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lensImagesRefs) db.lensImages],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cycleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cycleId,
                        referencedTable: $$LensesTableReferences._cycleIdTable(
                          db,
                        ),
                        referencedColumn: $$LensesTableReferences
                            ._cycleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lensImagesRefs)
                    await $_getPrefetchedDataByColumns<
                      Lens,
                      $LensesTable,
                      LensImage,
                      $LensImagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$LensesTableReferences
                          ._lensImagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LensesTableReferences(db, table, p0).lensImagesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'lens_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LensesTable,
      Lens,
      $$LensesTableFilterComposer,
      $$LensesTableOrderingComposer,
      $$LensesTableAnnotationComposer,
      $$LensesTableCreateCompanionBuilder,
      $$LensesTableUpdateCompanionBuilder,
      (Lens, $$LensesTableReferences),
      Lens,
      PrefetchHooks Function({bool cycleId, bool lensImagesRefs})
    >;
typedef $$LensImagesTableCreateCompanionBuilder = LensImagesCompanion Function({
  Value<int> id,
  required int lensId,
  required String imagePath,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$LensImagesTableUpdateCompanionBuilder = LensImagesCompanion Function({
  Value<int> id,
  Value<int> lensId,
  Value<String> imagePath,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $$LensImagesTableReferences
    extends BaseReferences<_$AppDatabase, $LensImagesTable, LensImage> {
  $$LensImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LensesTable _lensIdTable(_$AppDatabase db) =>
      db.lenses.createAlias('lens_images__lens_id__lenses__id');

  $$LensesTableProcessedTableManager get lensId {
    final $_column = $_itemColumn<int>('lens_id')!;

    final manager = $$LensesTableTableManager(
      $_db,
      $_db.lenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lensIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LensImagesTableFilterComposer
    extends Composer<_$AppDatabase, $LensImagesTable> {
  $$LensImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LensesTableFilterComposer get lensId {
    final $$LensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lensId,
      referencedTable: $db.lenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensesTableFilterComposer(
            $db: $db,
            $table: $db.lenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LensImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LensImagesTable> {
  $$LensImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LensesTableOrderingComposer get lensId {
    final $$LensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lensId,
      referencedTable: $db.lenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensesTableOrderingComposer(
            $db: $db,
            $table: $db.lenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LensImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LensImagesTable> {
  $$LensImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LensesTableAnnotationComposer get lensId {
    final $$LensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lensId,
      referencedTable: $db.lenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LensesTableAnnotationComposer(
            $db: $db,
            $table: $db.lenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LensImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LensImagesTable,
          LensImage,
          $$LensImagesTableFilterComposer,
          $$LensImagesTableOrderingComposer,
          $$LensImagesTableAnnotationComposer,
          $$LensImagesTableCreateCompanionBuilder,
          $$LensImagesTableUpdateCompanionBuilder,
          (LensImage, $$LensImagesTableReferences),
          LensImage,
          PrefetchHooks Function({bool lensId})
        > {
  $$LensImagesTableTableManager(_$AppDatabase db, $LensImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LensImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LensImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LensImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lensId = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LensImagesCompanion(
                id: id,
                lensId: lensId,
                imagePath: imagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lensId,
                required String imagePath,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LensImagesCompanion.insert(
                id: id,
                lensId: lensId,
                imagePath: imagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LensImagesTable, LensImage>(table),
                  $$LensImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lensId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (lensId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.lensId,
                        referencedTable: $$LensImagesTableReferences
                            ._lensIdTable(db),
                        referencedColumn: $$LensImagesTableReferences
                            ._lensIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LensImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LensImagesTable,
      LensImage,
      $$LensImagesTableFilterComposer,
      $$LensImagesTableOrderingComposer,
      $$LensImagesTableAnnotationComposer,
      $$LensImagesTableCreateCompanionBuilder,
      $$LensImagesTableUpdateCompanionBuilder,
      (LensImage, $$LensImagesTableReferences),
      LensImage,
      PrefetchHooks Function({bool lensId})
    >;
typedef $$LensExpiryReminderSettingsTableCreateCompanionBuilder =
    LensExpiryReminderSettingsCompanion Function({
      Value<int> id,
      Value<bool> isActive,
      Value<int> advanceDays,
      Value<String> reminderTime,
      Value<DateTime> updatedAt,
    });
typedef $$LensExpiryReminderSettingsTableUpdateCompanionBuilder =
    LensExpiryReminderSettingsCompanion Function({
      Value<int> id,
      Value<bool> isActive,
      Value<int> advanceDays,
      Value<String> reminderTime,
      Value<DateTime> updatedAt,
    });

class $$LensExpiryReminderSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LensExpiryReminderSettingsTable> {
  $$LensExpiryReminderSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advanceDays => $composableBuilder(
    column: $table.advanceDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LensExpiryReminderSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LensExpiryReminderSettingsTable> {
  $$LensExpiryReminderSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advanceDays => $composableBuilder(
    column: $table.advanceDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LensExpiryReminderSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LensExpiryReminderSettingsTable> {
  $$LensExpiryReminderSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get advanceDays => $composableBuilder(
    column: $table.advanceDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LensExpiryReminderSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LensExpiryReminderSettingsTable,
          LensExpiryReminderSetting,
          $$LensExpiryReminderSettingsTableFilterComposer,
          $$LensExpiryReminderSettingsTableOrderingComposer,
          $$LensExpiryReminderSettingsTableAnnotationComposer,
          $$LensExpiryReminderSettingsTableCreateCompanionBuilder,
          $$LensExpiryReminderSettingsTableUpdateCompanionBuilder,
          (
            LensExpiryReminderSetting,
            BaseReferences<
              _$AppDatabase,
              $LensExpiryReminderSettingsTable,
              LensExpiryReminderSetting
            >,
          ),
          LensExpiryReminderSetting,
          PrefetchHooks Function()
        > {
  $$LensExpiryReminderSettingsTableTableManager(
    _$AppDatabase db,
    $LensExpiryReminderSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LensExpiryReminderSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LensExpiryReminderSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LensExpiryReminderSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> advanceDays = const Value.absent(),
                Value<String> reminderTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LensExpiryReminderSettingsCompanion(
                id: id,
                isActive: isActive,
                advanceDays: advanceDays,
                reminderTime: reminderTime,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> advanceDays = const Value.absent(),
                Value<String> reminderTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LensExpiryReminderSettingsCompanion.insert(
                id: id,
                isActive: isActive,
                advanceDays: advanceDays,
                reminderTime: reminderTime,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LensExpiryReminderSettingsTable,
                    LensExpiryReminderSetting
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LensExpiryReminderSettingsTable,
                    LensExpiryReminderSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LensExpiryReminderSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LensExpiryReminderSettingsTable,
      LensExpiryReminderSetting,
      $$LensExpiryReminderSettingsTableFilterComposer,
      $$LensExpiryReminderSettingsTableOrderingComposer,
      $$LensExpiryReminderSettingsTableAnnotationComposer,
      $$LensExpiryReminderSettingsTableCreateCompanionBuilder,
      $$LensExpiryReminderSettingsTableUpdateCompanionBuilder,
      (
        LensExpiryReminderSetting,
        BaseReferences<
          _$AppDatabase,
          $LensExpiryReminderSettingsTable,
          LensExpiryReminderSetting
        >,
      ),
      LensExpiryReminderSetting,
      PrefetchHooks Function()
    >;
typedef $$CareSolutionChangeRemindersTableCreateCompanionBuilder =
    CareSolutionChangeRemindersCompanion Function({
      Value<int> id,
      Value<bool> isActive,
      Value<String> frequency,
      Value<int> intervalDays,
      Value<String> reminderTime,
      Value<String?> lastChangedDate,
      Value<String?> nextChangedDate,
      Value<DateTime> updatedAt,
    });
typedef $$CareSolutionChangeRemindersTableUpdateCompanionBuilder =
    CareSolutionChangeRemindersCompanion Function({
      Value<int> id,
      Value<bool> isActive,
      Value<String> frequency,
      Value<int> intervalDays,
      Value<String> reminderTime,
      Value<String?> lastChangedDate,
      Value<String?> nextChangedDate,
      Value<DateTime> updatedAt,
    });

class $$CareSolutionChangeRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $CareSolutionChangeRemindersTable> {
  $$CareSolutionChangeRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastChangedDate => $composableBuilder(
    column: $table.lastChangedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextChangedDate => $composableBuilder(
    column: $table.nextChangedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareSolutionChangeRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $CareSolutionChangeRemindersTable> {
  $$CareSolutionChangeRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastChangedDate => $composableBuilder(
    column: $table.lastChangedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextChangedDate => $composableBuilder(
    column: $table.nextChangedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareSolutionChangeRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareSolutionChangeRemindersTable> {
  $$CareSolutionChangeRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastChangedDate => $composableBuilder(
    column: $table.lastChangedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextChangedDate => $composableBuilder(
    column: $table.nextChangedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CareSolutionChangeRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareSolutionChangeRemindersTable,
          CareSolutionChangeReminder,
          $$CareSolutionChangeRemindersTableFilterComposer,
          $$CareSolutionChangeRemindersTableOrderingComposer,
          $$CareSolutionChangeRemindersTableAnnotationComposer,
          $$CareSolutionChangeRemindersTableCreateCompanionBuilder,
          $$CareSolutionChangeRemindersTableUpdateCompanionBuilder,
          (
            CareSolutionChangeReminder,
            BaseReferences<
              _$AppDatabase,
              $CareSolutionChangeRemindersTable,
              CareSolutionChangeReminder
            >,
          ),
          CareSolutionChangeReminder,
          PrefetchHooks Function()
        > {
  $$CareSolutionChangeRemindersTableTableManager(
    _$AppDatabase db,
    $CareSolutionChangeRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareSolutionChangeRemindersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CareSolutionChangeRemindersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CareSolutionChangeRemindersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<String> reminderTime = const Value.absent(),
                Value<String?> lastChangedDate = const Value.absent(),
                Value<String?> nextChangedDate = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CareSolutionChangeRemindersCompanion(
                id: id,
                isActive: isActive,
                frequency: frequency,
                intervalDays: intervalDays,
                reminderTime: reminderTime,
                lastChangedDate: lastChangedDate,
                nextChangedDate: nextChangedDate,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<String> reminderTime = const Value.absent(),
                Value<String?> lastChangedDate = const Value.absent(),
                Value<String?> nextChangedDate = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CareSolutionChangeRemindersCompanion.insert(
                id: id,
                isActive: isActive,
                frequency: frequency,
                intervalDays: intervalDays,
                reminderTime: reminderTime,
                lastChangedDate: lastChangedDate,
                nextChangedDate: nextChangedDate,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CareSolutionChangeRemindersTable,
                    CareSolutionChangeReminder
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareSolutionChangeRemindersTable,
                    CareSolutionChangeReminder
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareSolutionChangeRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareSolutionChangeRemindersTable,
      CareSolutionChangeReminder,
      $$CareSolutionChangeRemindersTableFilterComposer,
      $$CareSolutionChangeRemindersTableOrderingComposer,
      $$CareSolutionChangeRemindersTableAnnotationComposer,
      $$CareSolutionChangeRemindersTableCreateCompanionBuilder,
      $$CareSolutionChangeRemindersTableUpdateCompanionBuilder,
      (
        CareSolutionChangeReminder,
        BaseReferences<
          _$AppDatabase,
          $CareSolutionChangeRemindersTable,
          CareSolutionChangeReminder
        >,
      ),
      CareSolutionChangeReminder,
      PrefetchHooks Function()
    >;
typedef $$CareSolutionChangeLogsTableCreateCompanionBuilder =
    CareSolutionChangeLogsCompanion Function({
      Value<int> id,
      required int reminderId,
      Value<DateTime> changedAt,
      Value<String?> note,
    });
typedef $$CareSolutionChangeLogsTableUpdateCompanionBuilder =
    CareSolutionChangeLogsCompanion Function({
      Value<int> id,
      Value<int> reminderId,
      Value<DateTime> changedAt,
      Value<String?> note,
    });

class $$CareSolutionChangeLogsTableFilterComposer
    extends Composer<_$AppDatabase, $CareSolutionChangeLogsTable> {
  $$CareSolutionChangeLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareSolutionChangeLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareSolutionChangeLogsTable> {
  $$CareSolutionChangeLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareSolutionChangeLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareSolutionChangeLogsTable> {
  $$CareSolutionChangeLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$CareSolutionChangeLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareSolutionChangeLogsTable,
          CareSolutionChangeLog,
          $$CareSolutionChangeLogsTableFilterComposer,
          $$CareSolutionChangeLogsTableOrderingComposer,
          $$CareSolutionChangeLogsTableAnnotationComposer,
          $$CareSolutionChangeLogsTableCreateCompanionBuilder,
          $$CareSolutionChangeLogsTableUpdateCompanionBuilder,
          (
            CareSolutionChangeLog,
            BaseReferences<
              _$AppDatabase,
              $CareSolutionChangeLogsTable,
              CareSolutionChangeLog
            >,
          ),
          CareSolutionChangeLog,
          PrefetchHooks Function()
        > {
  $$CareSolutionChangeLogsTableTableManager(
    _$AppDatabase db,
    $CareSolutionChangeLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareSolutionChangeLogsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CareSolutionChangeLogsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CareSolutionChangeLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reminderId = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => CareSolutionChangeLogsCompanion(
                id: id,
                reminderId: reminderId,
                changedAt: changedAt,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reminderId,
                Value<DateTime> changedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => CareSolutionChangeLogsCompanion.insert(
                id: id,
                reminderId: reminderId,
                changedAt: changedAt,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CareSolutionChangeLogsTable,
                    CareSolutionChangeLog
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareSolutionChangeLogsTable,
                    CareSolutionChangeLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareSolutionChangeLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareSolutionChangeLogsTable,
      CareSolutionChangeLog,
      $$CareSolutionChangeLogsTableFilterComposer,
      $$CareSolutionChangeLogsTableOrderingComposer,
      $$CareSolutionChangeLogsTableAnnotationComposer,
      $$CareSolutionChangeLogsTableCreateCompanionBuilder,
      $$CareSolutionChangeLogsTableUpdateCompanionBuilder,
      (
        CareSolutionChangeLog,
        BaseReferences<
          _$AppDatabase,
          $CareSolutionChangeLogsTable,
          CareSolutionChangeLog
        >,
      ),
      CareSolutionChangeLog,
      PrefetchHooks Function()
    >;
typedef $$CareSolutionBottlesTableCreateCompanionBuilder =
    CareSolutionBottlesCompanion Function({
      Value<int> id,
      required String brand,
      required String name,
      Value<String?> openedAt,
      Value<String?> packageExpiryDate,
      Value<int?> afterOpenValidDays,
      Value<bool> isCurrent,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CareSolutionBottlesTableUpdateCompanionBuilder =
    CareSolutionBottlesCompanion Function({
      Value<int> id,
      Value<String> brand,
      Value<String> name,
      Value<String?> openedAt,
      Value<String?> packageExpiryDate,
      Value<int?> afterOpenValidDays,
      Value<bool> isCurrent,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CareSolutionBottlesTableFilterComposer
    extends Composer<_$AppDatabase, $CareSolutionBottlesTable> {
  $$CareSolutionBottlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageExpiryDate => $composableBuilder(
    column: $table.packageExpiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get afterOpenValidDays => $composableBuilder(
    column: $table.afterOpenValidDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareSolutionBottlesTableOrderingComposer
    extends Composer<_$AppDatabase, $CareSolutionBottlesTable> {
  $$CareSolutionBottlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageExpiryDate => $composableBuilder(
    column: $table.packageExpiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get afterOpenValidDays => $composableBuilder(
    column: $table.afterOpenValidDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareSolutionBottlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareSolutionBottlesTable> {
  $$CareSolutionBottlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get packageExpiryDate => $composableBuilder(
    column: $table.packageExpiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get afterOpenValidDays => $composableBuilder(
    column: $table.afterOpenValidDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CareSolutionBottlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareSolutionBottlesTable,
          CareSolutionBottle,
          $$CareSolutionBottlesTableFilterComposer,
          $$CareSolutionBottlesTableOrderingComposer,
          $$CareSolutionBottlesTableAnnotationComposer,
          $$CareSolutionBottlesTableCreateCompanionBuilder,
          $$CareSolutionBottlesTableUpdateCompanionBuilder,
          (
            CareSolutionBottle,
            BaseReferences<
              _$AppDatabase,
              $CareSolutionBottlesTable,
              CareSolutionBottle
            >,
          ),
          CareSolutionBottle,
          PrefetchHooks Function()
        > {
  $$CareSolutionBottlesTableTableManager(
    _$AppDatabase db,
    $CareSolutionBottlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareSolutionBottlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareSolutionBottlesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CareSolutionBottlesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> openedAt = const Value.absent(),
                Value<String?> packageExpiryDate = const Value.absent(),
                Value<int?> afterOpenValidDays = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CareSolutionBottlesCompanion(
                id: id,
                brand: brand,
                name: name,
                openedAt: openedAt,
                packageExpiryDate: packageExpiryDate,
                afterOpenValidDays: afterOpenValidDays,
                isCurrent: isCurrent,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String brand,
                required String name,
                Value<String?> openedAt = const Value.absent(),
                Value<String?> packageExpiryDate = const Value.absent(),
                Value<int?> afterOpenValidDays = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CareSolutionBottlesCompanion.insert(
                id: id,
                brand: brand,
                name: name,
                openedAt: openedAt,
                packageExpiryDate: packageExpiryDate,
                afterOpenValidDays: afterOpenValidDays,
                isCurrent: isCurrent,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CareSolutionBottlesTable, CareSolutionBottle>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CareSolutionBottlesTable,
                    CareSolutionBottle
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareSolutionBottlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareSolutionBottlesTable,
      CareSolutionBottle,
      $$CareSolutionBottlesTableFilterComposer,
      $$CareSolutionBottlesTableOrderingComposer,
      $$CareSolutionBottlesTableAnnotationComposer,
      $$CareSolutionBottlesTableCreateCompanionBuilder,
      $$CareSolutionBottlesTableUpdateCompanionBuilder,
      (
        CareSolutionBottle,
        BaseReferences<
          _$AppDatabase,
          $CareSolutionBottlesTable,
          CareSolutionBottle
        >,
      ),
      CareSolutionBottle,
      PrefetchHooks Function()
    >;
typedef $$CareSolutionExpirySettingsTableCreateCompanionBuilder =
    CareSolutionExpirySettingsCompanion Function({
      Value<int> id,
      Value<bool> isActive,
      Value<int> advanceDays,
      Value<String> reminderTime,
      Value<DateTime> updatedAt,
    });
typedef $$CareSolutionExpirySettingsTableUpdateCompanionBuilder =
    CareSolutionExpirySettingsCompanion Function({
      Value<int> id,
      Value<bool> isActive,
      Value<int> advanceDays,
      Value<String> reminderTime,
      Value<DateTime> updatedAt,
    });

class $$CareSolutionExpirySettingsTableFilterComposer
    extends Composer<_$AppDatabase, $CareSolutionExpirySettingsTable> {
  $$CareSolutionExpirySettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get advanceDays => $composableBuilder(
    column: $table.advanceDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CareSolutionExpirySettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CareSolutionExpirySettingsTable> {
  $$CareSolutionExpirySettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get advanceDays => $composableBuilder(
    column: $table.advanceDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CareSolutionExpirySettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareSolutionExpirySettingsTable> {
  $$CareSolutionExpirySettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get advanceDays => $composableBuilder(
    column: $table.advanceDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CareSolutionExpirySettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CareSolutionExpirySettingsTable,
          CareSolutionExpirySetting,
          $$CareSolutionExpirySettingsTableFilterComposer,
          $$CareSolutionExpirySettingsTableOrderingComposer,
          $$CareSolutionExpirySettingsTableAnnotationComposer,
          $$CareSolutionExpirySettingsTableCreateCompanionBuilder,
          $$CareSolutionExpirySettingsTableUpdateCompanionBuilder,
          (
            CareSolutionExpirySetting,
            BaseReferences<
              _$AppDatabase,
              $CareSolutionExpirySettingsTable,
              CareSolutionExpirySetting
            >,
          ),
          CareSolutionExpirySetting,
          PrefetchHooks Function()
        > {
  $$CareSolutionExpirySettingsTableTableManager(
    _$AppDatabase db,
    $CareSolutionExpirySettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareSolutionExpirySettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CareSolutionExpirySettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CareSolutionExpirySettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> advanceDays = const Value.absent(),
                Value<String> reminderTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CareSolutionExpirySettingsCompanion(
                id: id,
                isActive: isActive,
                advanceDays: advanceDays,
                reminderTime: reminderTime,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> advanceDays = const Value.absent(),
                Value<String> reminderTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CareSolutionExpirySettingsCompanion.insert(
                id: id,
                isActive: isActive,
                advanceDays: advanceDays,
                reminderTime: reminderTime,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CareSolutionExpirySettingsTable,
                    CareSolutionExpirySetting
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CareSolutionExpirySettingsTable,
                    CareSolutionExpirySetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CareSolutionExpirySettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CareSolutionExpirySettingsTable,
      CareSolutionExpirySetting,
      $$CareSolutionExpirySettingsTableFilterComposer,
      $$CareSolutionExpirySettingsTableOrderingComposer,
      $$CareSolutionExpirySettingsTableAnnotationComposer,
      $$CareSolutionExpirySettingsTableCreateCompanionBuilder,
      $$CareSolutionExpirySettingsTableUpdateCompanionBuilder,
      (
        CareSolutionExpirySetting,
        BaseReferences<
          _$AppDatabase,
          $CareSolutionExpirySettingsTable,
          CareSolutionExpirySetting
        >,
      ),
      CareSolutionExpirySetting,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      Value<String?> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$NotificationLogsTableCreateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      required String notificationKey,
      required String targetType,
      Value<String?> targetId,
      required DateTime scheduledDate,
      Value<DateTime?> sentAt,
      Value<String> status,
    });
typedef $$NotificationLogsTableUpdateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      Value<String> notificationKey,
      Value<String> targetType,
      Value<String?> targetId,
      Value<DateTime> scheduledDate,
      Value<DateTime?> sentAt,
      Value<String> status,
    });

class $$NotificationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationKey => $composableBuilder(
    column: $table.notificationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationKey => $composableBuilder(
    column: $table.notificationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get notificationKey => $composableBuilder(
    column: $table.notificationKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$NotificationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationLogsTable,
          NotificationLog,
          $$NotificationLogsTableFilterComposer,
          $$NotificationLogsTableOrderingComposer,
          $$NotificationLogsTableAnnotationComposer,
          $$NotificationLogsTableCreateCompanionBuilder,
          $$NotificationLogsTableUpdateCompanionBuilder,
          (
            NotificationLog,
            BaseReferences<
              _$AppDatabase,
              $NotificationLogsTable,
              NotificationLog
            >,
          ),
          NotificationLog,
          PrefetchHooks Function()
        > {
  $$NotificationLogsTableTableManager(
    _$AppDatabase db,
    $NotificationLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> notificationKey = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
                Value<DateTime> scheduledDate = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => NotificationLogsCompanion(
                id: id,
                notificationKey: notificationKey,
                targetType: targetType,
                targetId: targetId,
                scheduledDate: scheduledDate,
                sentAt: sentAt,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String notificationKey,
                required String targetType,
                Value<String?> targetId = const Value.absent(),
                required DateTime scheduledDate,
                Value<DateTime?> sentAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => NotificationLogsCompanion.insert(
                id: id,
                notificationKey: notificationKey,
                targetType: targetType,
                targetId: targetId,
                scheduledDate: scheduledDate,
                sentAt: sentAt,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotificationLogsTable, NotificationLog>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationLogsTable,
                    NotificationLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationLogsTable,
      NotificationLog,
      $$NotificationLogsTableFilterComposer,
      $$NotificationLogsTableOrderingComposer,
      $$NotificationLogsTableAnnotationComposer,
      $$NotificationLogsTableCreateCompanionBuilder,
      $$NotificationLogsTableUpdateCompanionBuilder,
      (
        NotificationLog,
        BaseReferences<_$AppDatabase, $NotificationLogsTable, NotificationLog>,
      ),
      NotificationLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LensCyclesTableTableManager get lensCycles =>
      $$LensCyclesTableTableManager(_db, _db.lensCycles);
  $$LensesTableTableManager get lenses =>
      $$LensesTableTableManager(_db, _db.lenses);
  $$LensImagesTableTableManager get lensImages =>
      $$LensImagesTableTableManager(_db, _db.lensImages);
  $$LensExpiryReminderSettingsTableTableManager
  get lensExpiryReminderSettings =>
      $$LensExpiryReminderSettingsTableTableManager(
        _db,
        _db.lensExpiryReminderSettings,
      );
  $$CareSolutionChangeRemindersTableTableManager
  get careSolutionChangeReminders =>
      $$CareSolutionChangeRemindersTableTableManager(
        _db,
        _db.careSolutionChangeReminders,
      );
  $$CareSolutionChangeLogsTableTableManager get careSolutionChangeLogs =>
      $$CareSolutionChangeLogsTableTableManager(
        _db,
        _db.careSolutionChangeLogs,
      );
  $$CareSolutionBottlesTableTableManager get careSolutionBottles =>
      $$CareSolutionBottlesTableTableManager(_db, _db.careSolutionBottles);
  $$CareSolutionExpirySettingsTableTableManager
  get careSolutionExpirySettings =>
      $$CareSolutionExpirySettingsTableTableManager(
        _db,
        _db.careSolutionExpirySettings,
      );
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$NotificationLogsTableTableManager get notificationLogs =>
      $$NotificationLogsTableTableManager(_db, _db.notificationLogs);
}
