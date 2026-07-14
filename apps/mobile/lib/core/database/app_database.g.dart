// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProyectosTable extends Proyectos
    with TableInfo<$ProyectosTable, Proyecto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProyectosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    tenantId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proyectos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Proyecto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Proyecto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Proyecto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
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
  $ProyectosTable createAlias(String alias) {
    return $ProyectosTable(attachedDatabase, alias);
  }
}

class Proyecto extends DataClass implements Insertable<Proyecto> {
  final String id;
  final String nombre;
  final String tenantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Proyecto({
    required this.id,
    required this.nombre,
    required this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['tenant_id'] = Variable<String>(tenantId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProyectosCompanion toCompanion(bool nullToAbsent) {
    return ProyectosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      tenantId: Value(tenantId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Proyecto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Proyecto(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'tenantId': serializer.toJson<String>(tenantId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Proyecto copyWith({
    String? id,
    String? nombre,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Proyecto(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    tenantId: tenantId ?? this.tenantId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Proyecto copyWithCompanion(ProyectosCompanion data) {
    return Proyecto(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Proyecto(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tenantId: $tenantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, tenantId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Proyecto &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.tenantId == this.tenantId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProyectosCompanion extends UpdateCompanion<Proyecto> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> tenantId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProyectosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProyectosCompanion.insert({
    required String id,
    required String nombre,
    required String tenantId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       tenantId = Value(tenantId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Proyecto> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? tenantId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (tenantId != null) 'tenant_id': tenantId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProyectosCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? tenantId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProyectosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('ProyectosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('tenantId: $tenantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EtapasTable extends Etapas with TableInfo<$EtapasTable, Etapa> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EtapasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proyectoIdMeta = const VerificationMeta(
    'proyectoId',
  );
  @override
  late final GeneratedColumn<String> proyectoId = GeneratedColumn<String>(
    'proyecto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, proyectoId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'etapas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Etapa> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('proyecto_id')) {
      context.handle(
        _proyectoIdMeta,
        proyectoId.isAcceptableOrUnknown(data['proyecto_id']!, _proyectoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_proyectoIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Etapa map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Etapa(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      proyectoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proyecto_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EtapasTable createAlias(String alias) {
    return $EtapasTable(attachedDatabase, alias);
  }
}

class Etapa extends DataClass implements Insertable<Etapa> {
  final String id;
  final String nombre;
  final String proyectoId;
  final DateTime createdAt;
  const Etapa({
    required this.id,
    required this.nombre,
    required this.proyectoId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['proyecto_id'] = Variable<String>(proyectoId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EtapasCompanion toCompanion(bool nullToAbsent) {
    return EtapasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      proyectoId: Value(proyectoId),
      createdAt: Value(createdAt),
    );
  }

  factory Etapa.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Etapa(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      proyectoId: serializer.fromJson<String>(json['proyectoId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'proyectoId': serializer.toJson<String>(proyectoId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Etapa copyWith({
    String? id,
    String? nombre,
    String? proyectoId,
    DateTime? createdAt,
  }) => Etapa(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    proyectoId: proyectoId ?? this.proyectoId,
    createdAt: createdAt ?? this.createdAt,
  );
  Etapa copyWithCompanion(EtapasCompanion data) {
    return Etapa(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      proyectoId: data.proyectoId.present
          ? data.proyectoId.value
          : this.proyectoId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Etapa(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, proyectoId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Etapa &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.proyectoId == this.proyectoId &&
          other.createdAt == this.createdAt);
}

class EtapasCompanion extends UpdateCompanion<Etapa> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> proyectoId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EtapasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.proyectoId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EtapasCompanion.insert({
    required String id,
    required String nombre,
    required String proyectoId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       proyectoId = Value(proyectoId),
       createdAt = Value(createdAt);
  static Insertable<Etapa> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? proyectoId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (proyectoId != null) 'proyecto_id': proyectoId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EtapasCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? proyectoId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EtapasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      proyectoId: proyectoId ?? this.proyectoId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (proyectoId.present) {
      map['proyecto_id'] = Variable<String>(proyectoId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EtapasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CasasTable extends Casas with TableInfo<$CasasTable, Casa> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CasasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _direccionInternaMeta = const VerificationMeta(
    'direccionInterna',
  );
  @override
  late final GeneratedColumn<String> direccionInterna = GeneratedColumn<String>(
    'direccion_interna',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etapaIdMeta = const VerificationMeta(
    'etapaId',
  );
  @override
  late final GeneratedColumn<String> etapaId = GeneratedColumn<String>(
    'etapa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    direccionInterna,
    etapaId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'casas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Casa> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('direccion_interna')) {
      context.handle(
        _direccionInternaMeta,
        direccionInterna.isAcceptableOrUnknown(
          data['direccion_interna']!,
          _direccionInternaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_direccionInternaMeta);
    }
    if (data.containsKey('etapa_id')) {
      context.handle(
        _etapaIdMeta,
        etapaId.isAcceptableOrUnknown(data['etapa_id']!, _etapaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_etapaIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Casa map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Casa(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      direccionInterna: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direccion_interna'],
      )!,
      etapaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etapa_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CasasTable createAlias(String alias) {
    return $CasasTable(attachedDatabase, alias);
  }
}

class Casa extends DataClass implements Insertable<Casa> {
  final String id;
  final String direccionInterna;
  final String etapaId;
  final DateTime createdAt;
  const Casa({
    required this.id,
    required this.direccionInterna,
    required this.etapaId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['direccion_interna'] = Variable<String>(direccionInterna);
    map['etapa_id'] = Variable<String>(etapaId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CasasCompanion toCompanion(bool nullToAbsent) {
    return CasasCompanion(
      id: Value(id),
      direccionInterna: Value(direccionInterna),
      etapaId: Value(etapaId),
      createdAt: Value(createdAt),
    );
  }

  factory Casa.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Casa(
      id: serializer.fromJson<String>(json['id']),
      direccionInterna: serializer.fromJson<String>(json['direccionInterna']),
      etapaId: serializer.fromJson<String>(json['etapaId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'direccionInterna': serializer.toJson<String>(direccionInterna),
      'etapaId': serializer.toJson<String>(etapaId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Casa copyWith({
    String? id,
    String? direccionInterna,
    String? etapaId,
    DateTime? createdAt,
  }) => Casa(
    id: id ?? this.id,
    direccionInterna: direccionInterna ?? this.direccionInterna,
    etapaId: etapaId ?? this.etapaId,
    createdAt: createdAt ?? this.createdAt,
  );
  Casa copyWithCompanion(CasasCompanion data) {
    return Casa(
      id: data.id.present ? data.id.value : this.id,
      direccionInterna: data.direccionInterna.present
          ? data.direccionInterna.value
          : this.direccionInterna,
      etapaId: data.etapaId.present ? data.etapaId.value : this.etapaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Casa(')
          ..write('id: $id, ')
          ..write('direccionInterna: $direccionInterna, ')
          ..write('etapaId: $etapaId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, direccionInterna, etapaId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Casa &&
          other.id == this.id &&
          other.direccionInterna == this.direccionInterna &&
          other.etapaId == this.etapaId &&
          other.createdAt == this.createdAt);
}

class CasasCompanion extends UpdateCompanion<Casa> {
  final Value<String> id;
  final Value<String> direccionInterna;
  final Value<String> etapaId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CasasCompanion({
    this.id = const Value.absent(),
    this.direccionInterna = const Value.absent(),
    this.etapaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CasasCompanion.insert({
    required String id,
    required String direccionInterna,
    required String etapaId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       direccionInterna = Value(direccionInterna),
       etapaId = Value(etapaId),
       createdAt = Value(createdAt);
  static Insertable<Casa> custom({
    Expression<String>? id,
    Expression<String>? direccionInterna,
    Expression<String>? etapaId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direccionInterna != null) 'direccion_interna': direccionInterna,
      if (etapaId != null) 'etapa_id': etapaId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CasasCompanion copyWith({
    Value<String>? id,
    Value<String>? direccionInterna,
    Value<String>? etapaId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CasasCompanion(
      id: id ?? this.id,
      direccionInterna: direccionInterna ?? this.direccionInterna,
      etapaId: etapaId ?? this.etapaId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (direccionInterna.present) {
      map['direccion_interna'] = Variable<String>(direccionInterna.value);
    }
    if (etapaId.present) {
      map['etapa_id'] = Variable<String>(etapaId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CasasCompanion(')
          ..write('id: $id, ')
          ..write('direccionInterna: $direccionInterna, ')
          ..write('etapaId: $etapaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResidentesTable extends Residentes
    with TableInfo<$ResidentesTable, Residente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResidentesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    telefono,
    email,
    tenantId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'residentes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Residente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    } else if (isInserting) {
      context.missing(_telefonoMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Residente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Residente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
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
  $ResidentesTable createAlias(String alias) {
    return $ResidentesTable(attachedDatabase, alias);
  }
}

class Residente extends DataClass implements Insertable<Residente> {
  final String id;
  final String nombre;
  final String telefono;
  final String? email;
  final String tenantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Residente({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    required this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['telefono'] = Variable<String>(telefono);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['tenant_id'] = Variable<String>(tenantId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ResidentesCompanion toCompanion(bool nullToAbsent) {
    return ResidentesCompanion(
      id: Value(id),
      nombre: Value(nombre),
      telefono: Value(telefono),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      tenantId: Value(tenantId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Residente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Residente(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      telefono: serializer.fromJson<String>(json['telefono']),
      email: serializer.fromJson<String?>(json['email']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'telefono': serializer.toJson<String>(telefono),
      'email': serializer.toJson<String?>(email),
      'tenantId': serializer.toJson<String>(tenantId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Residente copyWith({
    String? id,
    String? nombre,
    String? telefono,
    Value<String?> email = const Value.absent(),
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Residente(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    telefono: telefono ?? this.telefono,
    email: email.present ? email.value : this.email,
    tenantId: tenantId ?? this.tenantId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Residente copyWithCompanion(ResidentesCompanion data) {
    return Residente(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      email: data.email.present ? data.email.value : this.email,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Residente(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('tenantId: $tenantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nombre, telefono, email, tenantId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Residente &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.telefono == this.telefono &&
          other.email == this.email &&
          other.tenantId == this.tenantId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ResidentesCompanion extends UpdateCompanion<Residente> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> telefono;
  final Value<String?> email;
  final Value<String> tenantId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ResidentesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.telefono = const Value.absent(),
    this.email = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResidentesCompanion.insert({
    required String id,
    required String nombre,
    required String telefono,
    this.email = const Value.absent(),
    required String tenantId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       telefono = Value(telefono),
       tenantId = Value(tenantId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Residente> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? telefono,
    Expression<String>? email,
    Expression<String>? tenantId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (tenantId != null) 'tenant_id': tenantId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResidentesCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? telefono,
    Value<String?>? email,
    Value<String>? tenantId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ResidentesCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('ResidentesCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('tenantId: $tenantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TenenciasTable extends Tenencias
    with TableInfo<$TenenciasTable, Tenencia> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenenciasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _residenteIdMeta = const VerificationMeta(
    'residenteId',
  );
  @override
  late final GeneratedColumn<String> residenteId = GeneratedColumn<String>(
    'residente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _casaIdMeta = const VerificationMeta('casaId');
  @override
  late final GeneratedColumn<String> casaId = GeneratedColumn<String>(
    'casa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaInicioMeta = const VerificationMeta(
    'fechaInicio',
  );
  @override
  late final GeneratedColumn<DateTime> fechaInicio = GeneratedColumn<DateTime>(
    'fecha_inicio',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaFinMeta = const VerificationMeta(
    'fechaFin',
  );
  @override
  late final GeneratedColumn<DateTime> fechaFin = GeneratedColumn<DateTime>(
    'fecha_fin',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    residenteId,
    casaId,
    fechaInicio,
    fechaFin,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenencias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tenencia> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('residente_id')) {
      context.handle(
        _residenteIdMeta,
        residenteId.isAcceptableOrUnknown(
          data['residente_id']!,
          _residenteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_residenteIdMeta);
    }
    if (data.containsKey('casa_id')) {
      context.handle(
        _casaIdMeta,
        casaId.isAcceptableOrUnknown(data['casa_id']!, _casaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_casaIdMeta);
    }
    if (data.containsKey('fecha_inicio')) {
      context.handle(
        _fechaInicioMeta,
        fechaInicio.isAcceptableOrUnknown(
          data['fecha_inicio']!,
          _fechaInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaInicioMeta);
    }
    if (data.containsKey('fecha_fin')) {
      context.handle(
        _fechaFinMeta,
        fechaFin.isAcceptableOrUnknown(data['fecha_fin']!, _fechaFinMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tenencia map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tenencia(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      residenteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residente_id'],
      )!,
      casaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}casa_id'],
      )!,
      fechaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_inicio'],
      )!,
      fechaFin: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_fin'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TenenciasTable createAlias(String alias) {
    return $TenenciasTable(attachedDatabase, alias);
  }
}

class Tenencia extends DataClass implements Insertable<Tenencia> {
  final String id;
  final String residenteId;
  final String casaId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final DateTime createdAt;
  const Tenencia({
    required this.id,
    required this.residenteId,
    required this.casaId,
    required this.fechaInicio,
    this.fechaFin,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['residente_id'] = Variable<String>(residenteId);
    map['casa_id'] = Variable<String>(casaId);
    map['fecha_inicio'] = Variable<DateTime>(fechaInicio);
    if (!nullToAbsent || fechaFin != null) {
      map['fecha_fin'] = Variable<DateTime>(fechaFin);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TenenciasCompanion toCompanion(bool nullToAbsent) {
    return TenenciasCompanion(
      id: Value(id),
      residenteId: Value(residenteId),
      casaId: Value(casaId),
      fechaInicio: Value(fechaInicio),
      fechaFin: fechaFin == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaFin),
      createdAt: Value(createdAt),
    );
  }

  factory Tenencia.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tenencia(
      id: serializer.fromJson<String>(json['id']),
      residenteId: serializer.fromJson<String>(json['residenteId']),
      casaId: serializer.fromJson<String>(json['casaId']),
      fechaInicio: serializer.fromJson<DateTime>(json['fechaInicio']),
      fechaFin: serializer.fromJson<DateTime?>(json['fechaFin']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'residenteId': serializer.toJson<String>(residenteId),
      'casaId': serializer.toJson<String>(casaId),
      'fechaInicio': serializer.toJson<DateTime>(fechaInicio),
      'fechaFin': serializer.toJson<DateTime?>(fechaFin),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tenencia copyWith({
    String? id,
    String? residenteId,
    String? casaId,
    DateTime? fechaInicio,
    Value<DateTime?> fechaFin = const Value.absent(),
    DateTime? createdAt,
  }) => Tenencia(
    id: id ?? this.id,
    residenteId: residenteId ?? this.residenteId,
    casaId: casaId ?? this.casaId,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin.present ? fechaFin.value : this.fechaFin,
    createdAt: createdAt ?? this.createdAt,
  );
  Tenencia copyWithCompanion(TenenciasCompanion data) {
    return Tenencia(
      id: data.id.present ? data.id.value : this.id,
      residenteId: data.residenteId.present
          ? data.residenteId.value
          : this.residenteId,
      casaId: data.casaId.present ? data.casaId.value : this.casaId,
      fechaInicio: data.fechaInicio.present
          ? data.fechaInicio.value
          : this.fechaInicio,
      fechaFin: data.fechaFin.present ? data.fechaFin.value : this.fechaFin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tenencia(')
          ..write('id: $id, ')
          ..write('residenteId: $residenteId, ')
          ..write('casaId: $casaId, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('fechaFin: $fechaFin, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, residenteId, casaId, fechaInicio, fechaFin, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tenencia &&
          other.id == this.id &&
          other.residenteId == this.residenteId &&
          other.casaId == this.casaId &&
          other.fechaInicio == this.fechaInicio &&
          other.fechaFin == this.fechaFin &&
          other.createdAt == this.createdAt);
}

class TenenciasCompanion extends UpdateCompanion<Tenencia> {
  final Value<String> id;
  final Value<String> residenteId;
  final Value<String> casaId;
  final Value<DateTime> fechaInicio;
  final Value<DateTime?> fechaFin;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TenenciasCompanion({
    this.id = const Value.absent(),
    this.residenteId = const Value.absent(),
    this.casaId = const Value.absent(),
    this.fechaInicio = const Value.absent(),
    this.fechaFin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenenciasCompanion.insert({
    required String id,
    required String residenteId,
    required String casaId,
    required DateTime fechaInicio,
    this.fechaFin = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       residenteId = Value(residenteId),
       casaId = Value(casaId),
       fechaInicio = Value(fechaInicio),
       createdAt = Value(createdAt);
  static Insertable<Tenencia> custom({
    Expression<String>? id,
    Expression<String>? residenteId,
    Expression<String>? casaId,
    Expression<DateTime>? fechaInicio,
    Expression<DateTime>? fechaFin,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (residenteId != null) 'residente_id': residenteId,
      if (casaId != null) 'casa_id': casaId,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio,
      if (fechaFin != null) 'fecha_fin': fechaFin,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenenciasCompanion copyWith({
    Value<String>? id,
    Value<String>? residenteId,
    Value<String>? casaId,
    Value<DateTime>? fechaInicio,
    Value<DateTime?>? fechaFin,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TenenciasCompanion(
      id: id ?? this.id,
      residenteId: residenteId ?? this.residenteId,
      casaId: casaId ?? this.casaId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (residenteId.present) {
      map['residente_id'] = Variable<String>(residenteId.value);
    }
    if (casaId.present) {
      map['casa_id'] = Variable<String>(casaId.value);
    }
    if (fechaInicio.present) {
      map['fecha_inicio'] = Variable<DateTime>(fechaInicio.value);
    }
    if (fechaFin.present) {
      map['fecha_fin'] = Variable<DateTime>(fechaFin.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TenenciasCompanion(')
          ..write('id: $id, ')
          ..write('residenteId: $residenteId, ')
          ..write('casaId: $casaId, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('fechaFin: $fechaFin, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsuariosTable extends Usuarios with TableInfo<$UsuariosTable, Usuario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsuariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolMeta = const VerificationMeta('rol');
  @override
  late final GeneratedColumn<String> rol = GeneratedColumn<String>(
    'rol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _residenteIdMeta = const VerificationMeta(
    'residenteId',
  );
  @override
  late final GeneratedColumn<String> residenteId = GeneratedColumn<String>(
    'residente_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    nombre,
    rol,
    residenteId,
    tenantId,
    activo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Usuario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('rol')) {
      context.handle(
        _rolMeta,
        rol.isAcceptableOrUnknown(data['rol']!, _rolMeta),
      );
    } else if (isInserting) {
      context.missing(_rolMeta);
    }
    if (data.containsKey('residente_id')) {
      context.handle(
        _residenteIdMeta,
        residenteId.isAcceptableOrUnknown(
          data['residente_id']!,
          _residenteIdMeta,
        ),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    } else if (isInserting) {
      context.missing(_activoMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Usuario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Usuario(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      rol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol'],
      )!,
      residenteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residente_id'],
      ),
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
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
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }
}

class Usuario extends DataClass implements Insertable<Usuario> {
  final String id;
  final String email;
  final String nombre;
  final String rol;
  final String? residenteId;
  final String tenantId;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    this.residenteId,
    required this.tenantId,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['nombre'] = Variable<String>(nombre);
    map['rol'] = Variable<String>(rol);
    if (!nullToAbsent || residenteId != null) {
      map['residente_id'] = Variable<String>(residenteId);
    }
    map['tenant_id'] = Variable<String>(tenantId);
    map['activo'] = Variable<bool>(activo);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsuariosCompanion toCompanion(bool nullToAbsent) {
    return UsuariosCompanion(
      id: Value(id),
      email: Value(email),
      nombre: Value(nombre),
      rol: Value(rol),
      residenteId: residenteId == null && nullToAbsent
          ? const Value.absent()
          : Value(residenteId),
      tenantId: Value(tenantId),
      activo: Value(activo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Usuario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Usuario(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      nombre: serializer.fromJson<String>(json['nombre']),
      rol: serializer.fromJson<String>(json['rol']),
      residenteId: serializer.fromJson<String?>(json['residenteId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      activo: serializer.fromJson<bool>(json['activo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'nombre': serializer.toJson<String>(nombre),
      'rol': serializer.toJson<String>(rol),
      'residenteId': serializer.toJson<String?>(residenteId),
      'tenantId': serializer.toJson<String>(tenantId),
      'activo': serializer.toJson<bool>(activo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Usuario copyWith({
    String? id,
    String? email,
    String? nombre,
    String? rol,
    Value<String?> residenteId = const Value.absent(),
    String? tenantId,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Usuario(
    id: id ?? this.id,
    email: email ?? this.email,
    nombre: nombre ?? this.nombre,
    rol: rol ?? this.rol,
    residenteId: residenteId.present ? residenteId.value : this.residenteId,
    tenantId: tenantId ?? this.tenantId,
    activo: activo ?? this.activo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Usuario copyWithCompanion(UsuariosCompanion data) {
    return Usuario(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      rol: data.rol.present ? data.rol.value : this.rol,
      residenteId: data.residenteId.present
          ? data.residenteId.value
          : this.residenteId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      activo: data.activo.present ? data.activo.value : this.activo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Usuario(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('nombre: $nombre, ')
          ..write('rol: $rol, ')
          ..write('residenteId: $residenteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('activo: $activo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    nombre,
    rol,
    residenteId,
    tenantId,
    activo,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Usuario &&
          other.id == this.id &&
          other.email == this.email &&
          other.nombre == this.nombre &&
          other.rol == this.rol &&
          other.residenteId == this.residenteId &&
          other.tenantId == this.tenantId &&
          other.activo == this.activo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsuariosCompanion extends UpdateCompanion<Usuario> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> nombre;
  final Value<String> rol;
  final Value<String?> residenteId;
  final Value<String> tenantId;
  final Value<bool> activo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.nombre = const Value.absent(),
    this.rol = const Value.absent(),
    this.residenteId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.activo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsuariosCompanion.insert({
    required String id,
    required String email,
    required String nombre,
    required String rol,
    this.residenteId = const Value.absent(),
    required String tenantId,
    required bool activo,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       nombre = Value(nombre),
       rol = Value(rol),
       tenantId = Value(tenantId),
       activo = Value(activo),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Usuario> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? nombre,
    Expression<String>? rol,
    Expression<String>? residenteId,
    Expression<String>? tenantId,
    Expression<bool>? activo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (nombre != null) 'nombre': nombre,
      if (rol != null) 'rol': rol,
      if (residenteId != null) 'residente_id': residenteId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (activo != null) 'activo': activo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsuariosCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? nombre,
    Value<String>? rol,
    Value<String?>? residenteId,
    Value<String>? tenantId,
    Value<bool>? activo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsuariosCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      residenteId: residenteId ?? this.residenteId,
      tenantId: tenantId ?? this.tenantId,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    if (residenteId.present) {
      map['residente_id'] = Variable<String>(residenteId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('UsuariosCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('nombre: $nombre, ')
          ..write('rol: $rol, ')
          ..write('residenteId: $residenteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('activo: $activo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AsignacionesEtapaTable extends AsignacionesEtapa
    with TableInfo<$AsignacionesEtapaTable, AsignacionesEtapaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AsignacionesEtapaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etapaIdMeta = const VerificationMeta(
    'etapaId',
  );
  @override
  late final GeneratedColumn<String> etapaId = GeneratedColumn<String>(
    'etapa_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    usuarioId,
    etapaId,
    tenantId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asignaciones_etapa';
  @override
  VerificationContext validateIntegrity(
    Insertable<AsignacionesEtapaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('etapa_id')) {
      context.handle(
        _etapaIdMeta,
        etapaId.isAcceptableOrUnknown(data['etapa_id']!, _etapaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_etapaIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AsignacionesEtapaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AsignacionesEtapaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_id'],
      )!,
      etapaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etapa_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AsignacionesEtapaTable createAlias(String alias) {
    return $AsignacionesEtapaTable(attachedDatabase, alias);
  }
}

class AsignacionesEtapaData extends DataClass
    implements Insertable<AsignacionesEtapaData> {
  final String id;
  final String usuarioId;
  final String etapaId;
  final String tenantId;
  final DateTime createdAt;
  const AsignacionesEtapaData({
    required this.id,
    required this.usuarioId,
    required this.etapaId,
    required this.tenantId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['etapa_id'] = Variable<String>(etapaId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AsignacionesEtapaCompanion toCompanion(bool nullToAbsent) {
    return AsignacionesEtapaCompanion(
      id: Value(id),
      usuarioId: Value(usuarioId),
      etapaId: Value(etapaId),
      tenantId: Value(tenantId),
      createdAt: Value(createdAt),
    );
  }

  factory AsignacionesEtapaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AsignacionesEtapaData(
      id: serializer.fromJson<String>(json['id']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      etapaId: serializer.fromJson<String>(json['etapaId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'etapaId': serializer.toJson<String>(etapaId),
      'tenantId': serializer.toJson<String>(tenantId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AsignacionesEtapaData copyWith({
    String? id,
    String? usuarioId,
    String? etapaId,
    String? tenantId,
    DateTime? createdAt,
  }) => AsignacionesEtapaData(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    etapaId: etapaId ?? this.etapaId,
    tenantId: tenantId ?? this.tenantId,
    createdAt: createdAt ?? this.createdAt,
  );
  AsignacionesEtapaData copyWithCompanion(AsignacionesEtapaCompanion data) {
    return AsignacionesEtapaData(
      id: data.id.present ? data.id.value : this.id,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      etapaId: data.etapaId.present ? data.etapaId.value : this.etapaId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AsignacionesEtapaData(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('etapaId: $etapaId, ')
          ..write('tenantId: $tenantId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, usuarioId, etapaId, tenantId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsignacionesEtapaData &&
          other.id == this.id &&
          other.usuarioId == this.usuarioId &&
          other.etapaId == this.etapaId &&
          other.tenantId == this.tenantId &&
          other.createdAt == this.createdAt);
}

class AsignacionesEtapaCompanion
    extends UpdateCompanion<AsignacionesEtapaData> {
  final Value<String> id;
  final Value<String> usuarioId;
  final Value<String> etapaId;
  final Value<String> tenantId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AsignacionesEtapaCompanion({
    this.id = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.etapaId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AsignacionesEtapaCompanion.insert({
    required String id,
    required String usuarioId,
    required String etapaId,
    required String tenantId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       usuarioId = Value(usuarioId),
       etapaId = Value(etapaId),
       tenantId = Value(tenantId),
       createdAt = Value(createdAt);
  static Insertable<AsignacionesEtapaData> custom({
    Expression<String>? id,
    Expression<String>? usuarioId,
    Expression<String>? etapaId,
    Expression<String>? tenantId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (etapaId != null) 'etapa_id': etapaId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AsignacionesEtapaCompanion copyWith({
    Value<String>? id,
    Value<String>? usuarioId,
    Value<String>? etapaId,
    Value<String>? tenantId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AsignacionesEtapaCompanion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      etapaId: etapaId ?? this.etapaId,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (etapaId.present) {
      map['etapa_id'] = Variable<String>(etapaId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AsignacionesEtapaCompanion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('etapaId: $etapaId, ')
          ..write('tenantId: $tenantId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TarifasTable extends Tarifas with TableInfo<$TarifasTable, Tarifa> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TarifasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proyectoIdMeta = const VerificationMeta(
    'proyectoId',
  );
  @override
  late final GeneratedColumn<String> proyectoId = GeneratedColumn<String>(
    'proyecto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frecuenciaMeta = const VerificationMeta(
    'frecuencia',
  );
  @override
  late final GeneratedColumn<String> frecuencia = GeneratedColumn<String>(
    'frecuencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<int> monto = GeneratedColumn<int>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaVigenciaMeta = const VerificationMeta(
    'fechaVigencia',
  );
  @override
  late final GeneratedColumn<String> fechaVigencia = GeneratedColumn<String>(
    'fecha_vigencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activaMeta = const VerificationMeta('activa');
  @override
  late final GeneratedColumn<bool> activa = GeneratedColumn<bool>(
    'activa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activa" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    proyectoId,
    frecuencia,
    monto,
    fechaVigencia,
    activa,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tarifas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tarifa> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('proyecto_id')) {
      context.handle(
        _proyectoIdMeta,
        proyectoId.isAcceptableOrUnknown(data['proyecto_id']!, _proyectoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_proyectoIdMeta);
    }
    if (data.containsKey('frecuencia')) {
      context.handle(
        _frecuenciaMeta,
        frecuencia.isAcceptableOrUnknown(data['frecuencia']!, _frecuenciaMeta),
      );
    } else if (isInserting) {
      context.missing(_frecuenciaMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('fecha_vigencia')) {
      context.handle(
        _fechaVigenciaMeta,
        fechaVigencia.isAcceptableOrUnknown(
          data['fecha_vigencia']!,
          _fechaVigenciaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaVigenciaMeta);
    }
    if (data.containsKey('activa')) {
      context.handle(
        _activaMeta,
        activa.isAcceptableOrUnknown(data['activa']!, _activaMeta),
      );
    } else if (isInserting) {
      context.missing(_activaMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tarifa map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tarifa(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      proyectoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proyecto_id'],
      )!,
      frecuencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto'],
      )!,
      fechaVigencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha_vigencia'],
      )!,
      activa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activa'],
      )!,
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
  $TarifasTable createAlias(String alias) {
    return $TarifasTable(attachedDatabase, alias);
  }
}

class Tarifa extends DataClass implements Insertable<Tarifa> {
  final String id;
  final String tenantId;
  final String proyectoId;
  final String frecuencia;
  final int monto;
  final String fechaVigencia;
  final bool activa;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Tarifa({
    required this.id,
    required this.tenantId,
    required this.proyectoId,
    required this.frecuencia,
    required this.monto,
    required this.fechaVigencia,
    required this.activa,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['proyecto_id'] = Variable<String>(proyectoId);
    map['frecuencia'] = Variable<String>(frecuencia);
    map['monto'] = Variable<int>(monto);
    map['fecha_vigencia'] = Variable<String>(fechaVigencia);
    map['activa'] = Variable<bool>(activa);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TarifasCompanion toCompanion(bool nullToAbsent) {
    return TarifasCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      proyectoId: Value(proyectoId),
      frecuencia: Value(frecuencia),
      monto: Value(monto),
      fechaVigencia: Value(fechaVigencia),
      activa: Value(activa),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Tarifa.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tarifa(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      proyectoId: serializer.fromJson<String>(json['proyectoId']),
      frecuencia: serializer.fromJson<String>(json['frecuencia']),
      monto: serializer.fromJson<int>(json['monto']),
      fechaVigencia: serializer.fromJson<String>(json['fechaVigencia']),
      activa: serializer.fromJson<bool>(json['activa']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'proyectoId': serializer.toJson<String>(proyectoId),
      'frecuencia': serializer.toJson<String>(frecuencia),
      'monto': serializer.toJson<int>(monto),
      'fechaVigencia': serializer.toJson<String>(fechaVigencia),
      'activa': serializer.toJson<bool>(activa),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Tarifa copyWith({
    String? id,
    String? tenantId,
    String? proyectoId,
    String? frecuencia,
    int? monto,
    String? fechaVigencia,
    bool? activa,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Tarifa(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    proyectoId: proyectoId ?? this.proyectoId,
    frecuencia: frecuencia ?? this.frecuencia,
    monto: monto ?? this.monto,
    fechaVigencia: fechaVigencia ?? this.fechaVigencia,
    activa: activa ?? this.activa,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Tarifa copyWithCompanion(TarifasCompanion data) {
    return Tarifa(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      proyectoId: data.proyectoId.present
          ? data.proyectoId.value
          : this.proyectoId,
      frecuencia: data.frecuencia.present
          ? data.frecuencia.value
          : this.frecuencia,
      monto: data.monto.present ? data.monto.value : this.monto,
      fechaVigencia: data.fechaVigencia.present
          ? data.fechaVigencia.value
          : this.fechaVigencia,
      activa: data.activa.present ? data.activa.value : this.activa,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tarifa(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('monto: $monto, ')
          ..write('fechaVigencia: $fechaVigencia, ')
          ..write('activa: $activa, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    proyectoId,
    frecuencia,
    monto,
    fechaVigencia,
    activa,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tarifa &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.proyectoId == this.proyectoId &&
          other.frecuencia == this.frecuencia &&
          other.monto == this.monto &&
          other.fechaVigencia == this.fechaVigencia &&
          other.activa == this.activa &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TarifasCompanion extends UpdateCompanion<Tarifa> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> proyectoId;
  final Value<String> frecuencia;
  final Value<int> monto;
  final Value<String> fechaVigencia;
  final Value<bool> activa;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TarifasCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.proyectoId = const Value.absent(),
    this.frecuencia = const Value.absent(),
    this.monto = const Value.absent(),
    this.fechaVigencia = const Value.absent(),
    this.activa = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TarifasCompanion.insert({
    required String id,
    required String tenantId,
    required String proyectoId,
    required String frecuencia,
    required int monto,
    required String fechaVigencia,
    required bool activa,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       proyectoId = Value(proyectoId),
       frecuencia = Value(frecuencia),
       monto = Value(monto),
       fechaVigencia = Value(fechaVigencia),
       activa = Value(activa),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Tarifa> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? proyectoId,
    Expression<String>? frecuencia,
    Expression<int>? monto,
    Expression<String>? fechaVigencia,
    Expression<bool>? activa,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (proyectoId != null) 'proyecto_id': proyectoId,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (monto != null) 'monto': monto,
      if (fechaVigencia != null) 'fecha_vigencia': fechaVigencia,
      if (activa != null) 'activa': activa,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TarifasCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? proyectoId,
    Value<String>? frecuencia,
    Value<int>? monto,
    Value<String>? fechaVigencia,
    Value<bool>? activa,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TarifasCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      proyectoId: proyectoId ?? this.proyectoId,
      frecuencia: frecuencia ?? this.frecuencia,
      monto: monto ?? this.monto,
      fechaVigencia: fechaVigencia ?? this.fechaVigencia,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (proyectoId.present) {
      map['proyecto_id'] = Variable<String>(proyectoId.value);
    }
    if (frecuencia.present) {
      map['frecuencia'] = Variable<String>(frecuencia.value);
    }
    if (monto.present) {
      map['monto'] = Variable<int>(monto.value);
    }
    if (fechaVigencia.present) {
      map['fecha_vigencia'] = Variable<String>(fechaVigencia.value);
    }
    if (activa.present) {
      map['activa'] = Variable<bool>(activa.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('TarifasCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('monto: $monto, ')
          ..write('fechaVigencia: $fechaVigencia, ')
          ..write('activa: $activa, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MontosPredefinidosTable extends MontosPredefinidos
    with TableInfo<$MontosPredefinidosTable, MontosPredefinido> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MontosPredefinidosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proyectoIdMeta = const VerificationMeta(
    'proyectoId',
  );
  @override
  late final GeneratedColumn<String> proyectoId = GeneratedColumn<String>(
    'proyecto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<int> monto = GeneratedColumn<int>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    proyectoId,
    monto,
    descripcion,
    activo,
    orden,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'montos_predefinidos';
  @override
  VerificationContext validateIntegrity(
    Insertable<MontosPredefinido> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('proyecto_id')) {
      context.handle(
        _proyectoIdMeta,
        proyectoId.isAcceptableOrUnknown(data['proyecto_id']!, _proyectoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_proyectoIdMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    } else if (isInserting) {
      context.missing(_activoMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MontosPredefinido map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MontosPredefinido(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      proyectoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proyecto_id'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
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
  $MontosPredefinidosTable createAlias(String alias) {
    return $MontosPredefinidosTable(attachedDatabase, alias);
  }
}

class MontosPredefinido extends DataClass
    implements Insertable<MontosPredefinido> {
  final String id;
  final String tenantId;
  final String proyectoId;
  final int monto;
  final String descripcion;
  final bool activo;
  final int orden;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MontosPredefinido({
    required this.id,
    required this.tenantId,
    required this.proyectoId,
    required this.monto,
    required this.descripcion,
    required this.activo,
    required this.orden,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['proyecto_id'] = Variable<String>(proyectoId);
    map['monto'] = Variable<int>(monto);
    map['descripcion'] = Variable<String>(descripcion);
    map['activo'] = Variable<bool>(activo);
    map['orden'] = Variable<int>(orden);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MontosPredefinidosCompanion toCompanion(bool nullToAbsent) {
    return MontosPredefinidosCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      proyectoId: Value(proyectoId),
      monto: Value(monto),
      descripcion: Value(descripcion),
      activo: Value(activo),
      orden: Value(orden),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MontosPredefinido.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MontosPredefinido(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      proyectoId: serializer.fromJson<String>(json['proyectoId']),
      monto: serializer.fromJson<int>(json['monto']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      activo: serializer.fromJson<bool>(json['activo']),
      orden: serializer.fromJson<int>(json['orden']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'proyectoId': serializer.toJson<String>(proyectoId),
      'monto': serializer.toJson<int>(monto),
      'descripcion': serializer.toJson<String>(descripcion),
      'activo': serializer.toJson<bool>(activo),
      'orden': serializer.toJson<int>(orden),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MontosPredefinido copyWith({
    String? id,
    String? tenantId,
    String? proyectoId,
    int? monto,
    String? descripcion,
    bool? activo,
    int? orden,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MontosPredefinido(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    proyectoId: proyectoId ?? this.proyectoId,
    monto: monto ?? this.monto,
    descripcion: descripcion ?? this.descripcion,
    activo: activo ?? this.activo,
    orden: orden ?? this.orden,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MontosPredefinido copyWithCompanion(MontosPredefinidosCompanion data) {
    return MontosPredefinido(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      proyectoId: data.proyectoId.present
          ? data.proyectoId.value
          : this.proyectoId,
      monto: data.monto.present ? data.monto.value : this.monto,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      activo: data.activo.present ? data.activo.value : this.activo,
      orden: data.orden.present ? data.orden.value : this.orden,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MontosPredefinido(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('monto: $monto, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo, ')
          ..write('orden: $orden, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    proyectoId,
    monto,
    descripcion,
    activo,
    orden,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MontosPredefinido &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.proyectoId == this.proyectoId &&
          other.monto == this.monto &&
          other.descripcion == this.descripcion &&
          other.activo == this.activo &&
          other.orden == this.orden &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MontosPredefinidosCompanion extends UpdateCompanion<MontosPredefinido> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> proyectoId;
  final Value<int> monto;
  final Value<String> descripcion;
  final Value<bool> activo;
  final Value<int> orden;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MontosPredefinidosCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.proyectoId = const Value.absent(),
    this.monto = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
    this.orden = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MontosPredefinidosCompanion.insert({
    required String id,
    required String tenantId,
    required String proyectoId,
    required int monto,
    required String descripcion,
    required bool activo,
    required int orden,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       proyectoId = Value(proyectoId),
       monto = Value(monto),
       descripcion = Value(descripcion),
       activo = Value(activo),
       orden = Value(orden),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MontosPredefinido> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? proyectoId,
    Expression<int>? monto,
    Expression<String>? descripcion,
    Expression<bool>? activo,
    Expression<int>? orden,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (proyectoId != null) 'proyecto_id': proyectoId,
      if (monto != null) 'monto': monto,
      if (descripcion != null) 'descripcion': descripcion,
      if (activo != null) 'activo': activo,
      if (orden != null) 'orden': orden,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MontosPredefinidosCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? proyectoId,
    Value<int>? monto,
    Value<String>? descripcion,
    Value<bool>? activo,
    Value<int>? orden,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MontosPredefinidosCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      proyectoId: proyectoId ?? this.proyectoId,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (proyectoId.present) {
      map['proyecto_id'] = Variable<String>(proyectoId.value);
    }
    if (monto.present) {
      map['monto'] = Variable<int>(monto.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('MontosPredefinidosCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('monto: $monto, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo, ')
          ..write('orden: $orden, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanesDeCobroTable extends PlanesDeCobro
    with TableInfo<$PlanesDeCobroTable, PlanesDeCobroData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanesDeCobroTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _residenteIdMeta = const VerificationMeta(
    'residenteId',
  );
  @override
  late final GeneratedColumn<String> residenteId = GeneratedColumn<String>(
    'residente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proyectoIdMeta = const VerificationMeta(
    'proyectoId',
  );
  @override
  late final GeneratedColumn<String> proyectoId = GeneratedColumn<String>(
    'proyecto_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frecuenciaMeta = const VerificationMeta(
    'frecuencia',
  );
  @override
  late final GeneratedColumn<String> frecuencia = GeneratedColumn<String>(
    'frecuencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaActivacionMeta = const VerificationMeta(
    'fechaActivacion',
  );
  @override
  late final GeneratedColumn<String> fechaActivacion = GeneratedColumn<String>(
    'fecha_activacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activaMeta = const VerificationMeta('activa');
  @override
  late final GeneratedColumn<bool> activa = GeneratedColumn<bool>(
    'activa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activa" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    residenteId,
    tenantId,
    proyectoId,
    frecuencia,
    fechaActivacion,
    activa,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planes_de_cobro';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanesDeCobroData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('residente_id')) {
      context.handle(
        _residenteIdMeta,
        residenteId.isAcceptableOrUnknown(
          data['residente_id']!,
          _residenteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_residenteIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('proyecto_id')) {
      context.handle(
        _proyectoIdMeta,
        proyectoId.isAcceptableOrUnknown(data['proyecto_id']!, _proyectoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_proyectoIdMeta);
    }
    if (data.containsKey('frecuencia')) {
      context.handle(
        _frecuenciaMeta,
        frecuencia.isAcceptableOrUnknown(data['frecuencia']!, _frecuenciaMeta),
      );
    } else if (isInserting) {
      context.missing(_frecuenciaMeta);
    }
    if (data.containsKey('fecha_activacion')) {
      context.handle(
        _fechaActivacionMeta,
        fechaActivacion.isAcceptableOrUnknown(
          data['fecha_activacion']!,
          _fechaActivacionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaActivacionMeta);
    }
    if (data.containsKey('activa')) {
      context.handle(
        _activaMeta,
        activa.isAcceptableOrUnknown(data['activa']!, _activaMeta),
      );
    } else if (isInserting) {
      context.missing(_activaMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanesDeCobroData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanesDeCobroData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      residenteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residente_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      proyectoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proyecto_id'],
      )!,
      frecuencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia'],
      )!,
      fechaActivacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha_activacion'],
      )!,
      activa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activa'],
      )!,
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
  $PlanesDeCobroTable createAlias(String alias) {
    return $PlanesDeCobroTable(attachedDatabase, alias);
  }
}

class PlanesDeCobroData extends DataClass
    implements Insertable<PlanesDeCobroData> {
  final String id;
  final String residenteId;
  final String tenantId;
  final String proyectoId;
  final String frecuencia;
  final String fechaActivacion;
  final bool activa;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlanesDeCobroData({
    required this.id,
    required this.residenteId,
    required this.tenantId,
    required this.proyectoId,
    required this.frecuencia,
    required this.fechaActivacion,
    required this.activa,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['residente_id'] = Variable<String>(residenteId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['proyecto_id'] = Variable<String>(proyectoId);
    map['frecuencia'] = Variable<String>(frecuencia);
    map['fecha_activacion'] = Variable<String>(fechaActivacion);
    map['activa'] = Variable<bool>(activa);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlanesDeCobroCompanion toCompanion(bool nullToAbsent) {
    return PlanesDeCobroCompanion(
      id: Value(id),
      residenteId: Value(residenteId),
      tenantId: Value(tenantId),
      proyectoId: Value(proyectoId),
      frecuencia: Value(frecuencia),
      fechaActivacion: Value(fechaActivacion),
      activa: Value(activa),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlanesDeCobroData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanesDeCobroData(
      id: serializer.fromJson<String>(json['id']),
      residenteId: serializer.fromJson<String>(json['residenteId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      proyectoId: serializer.fromJson<String>(json['proyectoId']),
      frecuencia: serializer.fromJson<String>(json['frecuencia']),
      fechaActivacion: serializer.fromJson<String>(json['fechaActivacion']),
      activa: serializer.fromJson<bool>(json['activa']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'residenteId': serializer.toJson<String>(residenteId),
      'tenantId': serializer.toJson<String>(tenantId),
      'proyectoId': serializer.toJson<String>(proyectoId),
      'frecuencia': serializer.toJson<String>(frecuencia),
      'fechaActivacion': serializer.toJson<String>(fechaActivacion),
      'activa': serializer.toJson<bool>(activa),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlanesDeCobroData copyWith({
    String? id,
    String? residenteId,
    String? tenantId,
    String? proyectoId,
    String? frecuencia,
    String? fechaActivacion,
    bool? activa,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlanesDeCobroData(
    id: id ?? this.id,
    residenteId: residenteId ?? this.residenteId,
    tenantId: tenantId ?? this.tenantId,
    proyectoId: proyectoId ?? this.proyectoId,
    frecuencia: frecuencia ?? this.frecuencia,
    fechaActivacion: fechaActivacion ?? this.fechaActivacion,
    activa: activa ?? this.activa,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlanesDeCobroData copyWithCompanion(PlanesDeCobroCompanion data) {
    return PlanesDeCobroData(
      id: data.id.present ? data.id.value : this.id,
      residenteId: data.residenteId.present
          ? data.residenteId.value
          : this.residenteId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      proyectoId: data.proyectoId.present
          ? data.proyectoId.value
          : this.proyectoId,
      frecuencia: data.frecuencia.present
          ? data.frecuencia.value
          : this.frecuencia,
      fechaActivacion: data.fechaActivacion.present
          ? data.fechaActivacion.value
          : this.fechaActivacion,
      activa: data.activa.present ? data.activa.value : this.activa,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanesDeCobroData(')
          ..write('id: $id, ')
          ..write('residenteId: $residenteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fechaActivacion: $fechaActivacion, ')
          ..write('activa: $activa, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    residenteId,
    tenantId,
    proyectoId,
    frecuencia,
    fechaActivacion,
    activa,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanesDeCobroData &&
          other.id == this.id &&
          other.residenteId == this.residenteId &&
          other.tenantId == this.tenantId &&
          other.proyectoId == this.proyectoId &&
          other.frecuencia == this.frecuencia &&
          other.fechaActivacion == this.fechaActivacion &&
          other.activa == this.activa &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlanesDeCobroCompanion extends UpdateCompanion<PlanesDeCobroData> {
  final Value<String> id;
  final Value<String> residenteId;
  final Value<String> tenantId;
  final Value<String> proyectoId;
  final Value<String> frecuencia;
  final Value<String> fechaActivacion;
  final Value<bool> activa;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlanesDeCobroCompanion({
    this.id = const Value.absent(),
    this.residenteId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.proyectoId = const Value.absent(),
    this.frecuencia = const Value.absent(),
    this.fechaActivacion = const Value.absent(),
    this.activa = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanesDeCobroCompanion.insert({
    required String id,
    required String residenteId,
    required String tenantId,
    required String proyectoId,
    required String frecuencia,
    required String fechaActivacion,
    required bool activa,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       residenteId = Value(residenteId),
       tenantId = Value(tenantId),
       proyectoId = Value(proyectoId),
       frecuencia = Value(frecuencia),
       fechaActivacion = Value(fechaActivacion),
       activa = Value(activa),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlanesDeCobroData> custom({
    Expression<String>? id,
    Expression<String>? residenteId,
    Expression<String>? tenantId,
    Expression<String>? proyectoId,
    Expression<String>? frecuencia,
    Expression<String>? fechaActivacion,
    Expression<bool>? activa,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (residenteId != null) 'residente_id': residenteId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (proyectoId != null) 'proyecto_id': proyectoId,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (fechaActivacion != null) 'fecha_activacion': fechaActivacion,
      if (activa != null) 'activa': activa,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanesDeCobroCompanion copyWith({
    Value<String>? id,
    Value<String>? residenteId,
    Value<String>? tenantId,
    Value<String>? proyectoId,
    Value<String>? frecuencia,
    Value<String>? fechaActivacion,
    Value<bool>? activa,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlanesDeCobroCompanion(
      id: id ?? this.id,
      residenteId: residenteId ?? this.residenteId,
      tenantId: tenantId ?? this.tenantId,
      proyectoId: proyectoId ?? this.proyectoId,
      frecuencia: frecuencia ?? this.frecuencia,
      fechaActivacion: fechaActivacion ?? this.fechaActivacion,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (residenteId.present) {
      map['residente_id'] = Variable<String>(residenteId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (proyectoId.present) {
      map['proyecto_id'] = Variable<String>(proyectoId.value);
    }
    if (frecuencia.present) {
      map['frecuencia'] = Variable<String>(frecuencia.value);
    }
    if (fechaActivacion.present) {
      map['fecha_activacion'] = Variable<String>(fechaActivacion.value);
    }
    if (activa.present) {
      map['activa'] = Variable<bool>(activa.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('PlanesDeCobroCompanion(')
          ..write('id: $id, ')
          ..write('residenteId: $residenteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('proyectoId: $proyectoId, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fechaActivacion: $fechaActivacion, ')
          ..write('activa: $activa, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CobrosTable extends Cobros with TableInfo<$CobrosTable, Cobro> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CobrosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _residenteIdMeta = const VerificationMeta(
    'residenteId',
  );
  @override
  late final GeneratedColumn<String> residenteId = GeneratedColumn<String>(
    'residente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tarifaIdMeta = const VerificationMeta(
    'tarifaId',
  );
  @override
  late final GeneratedColumn<String> tarifaId = GeneratedColumn<String>(
    'tarifa_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conceptoMeta = const VerificationMeta(
    'concepto',
  );
  @override
  late final GeneratedColumn<String> concepto = GeneratedColumn<String>(
    'concepto',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<int> monto = GeneratedColumn<int>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montoPagadoMeta = const VerificationMeta(
    'montoPagado',
  );
  @override
  late final GeneratedColumn<int> montoPagado = GeneratedColumn<int>(
    'monto_pagado',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodoInicioMeta = const VerificationMeta(
    'periodoInicio',
  );
  @override
  late final GeneratedColumn<String> periodoInicio = GeneratedColumn<String>(
    'periodo_inicio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodoFinMeta = const VerificationMeta(
    'periodoFin',
  );
  @override
  late final GeneratedColumn<String> periodoFin = GeneratedColumn<String>(
    'periodo_fin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaVencimientoMeta = const VerificationMeta(
    'fechaVencimiento',
  );
  @override
  late final GeneratedColumn<String> fechaVencimiento = GeneratedColumn<String>(
    'fecha_vencimiento',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificacionEnviadaMeta =
      const VerificationMeta('notificacionEnviada');
  @override
  late final GeneratedColumn<bool> notificacionEnviada = GeneratedColumn<bool>(
    'notificacion_enviada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notificacion_enviada" IN (0, 1))',
    ),
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    residenteId,
    tenantId,
    tarifaId,
    concepto,
    monto,
    montoPagado,
    periodoInicio,
    periodoFin,
    fechaVencimiento,
    estado,
    notificacionEnviada,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cobros';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cobro> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('residente_id')) {
      context.handle(
        _residenteIdMeta,
        residenteId.isAcceptableOrUnknown(
          data['residente_id']!,
          _residenteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_residenteIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('tarifa_id')) {
      context.handle(
        _tarifaIdMeta,
        tarifaId.isAcceptableOrUnknown(data['tarifa_id']!, _tarifaIdMeta),
      );
    }
    if (data.containsKey('concepto')) {
      context.handle(
        _conceptoMeta,
        concepto.isAcceptableOrUnknown(data['concepto']!, _conceptoMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptoMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('monto_pagado')) {
      context.handle(
        _montoPagadoMeta,
        montoPagado.isAcceptableOrUnknown(
          data['monto_pagado']!,
          _montoPagadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montoPagadoMeta);
    }
    if (data.containsKey('periodo_inicio')) {
      context.handle(
        _periodoInicioMeta,
        periodoInicio.isAcceptableOrUnknown(
          data['periodo_inicio']!,
          _periodoInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodoInicioMeta);
    }
    if (data.containsKey('periodo_fin')) {
      context.handle(
        _periodoFinMeta,
        periodoFin.isAcceptableOrUnknown(data['periodo_fin']!, _periodoFinMeta),
      );
    } else if (isInserting) {
      context.missing(_periodoFinMeta);
    }
    if (data.containsKey('fecha_vencimiento')) {
      context.handle(
        _fechaVencimientoMeta,
        fechaVencimiento.isAcceptableOrUnknown(
          data['fecha_vencimiento']!,
          _fechaVencimientoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaVencimientoMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoMeta);
    }
    if (data.containsKey('notificacion_enviada')) {
      context.handle(
        _notificacionEnviadaMeta,
        notificacionEnviada.isAcceptableOrUnknown(
          data['notificacion_enviada']!,
          _notificacionEnviadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificacionEnviadaMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cobro map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cobro(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      residenteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residente_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      tarifaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tarifa_id'],
      ),
      concepto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concepto'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto'],
      )!,
      montoPagado: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto_pagado'],
      )!,
      periodoInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}periodo_inicio'],
      )!,
      periodoFin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}periodo_fin'],
      )!,
      fechaVencimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha_vencimiento'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      notificacionEnviada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notificacion_enviada'],
      )!,
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
  $CobrosTable createAlias(String alias) {
    return $CobrosTable(attachedDatabase, alias);
  }
}

class Cobro extends DataClass implements Insertable<Cobro> {
  final String id;
  final String residenteId;
  final String tenantId;
  final String? tarifaId;
  final String concepto;
  final int monto;
  final int montoPagado;
  final String periodoInicio;
  final String periodoFin;
  final String fechaVencimiento;
  final String estado;
  final bool notificacionEnviada;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Cobro({
    required this.id,
    required this.residenteId,
    required this.tenantId,
    this.tarifaId,
    required this.concepto,
    required this.monto,
    required this.montoPagado,
    required this.periodoInicio,
    required this.periodoFin,
    required this.fechaVencimiento,
    required this.estado,
    required this.notificacionEnviada,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['residente_id'] = Variable<String>(residenteId);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || tarifaId != null) {
      map['tarifa_id'] = Variable<String>(tarifaId);
    }
    map['concepto'] = Variable<String>(concepto);
    map['monto'] = Variable<int>(monto);
    map['monto_pagado'] = Variable<int>(montoPagado);
    map['periodo_inicio'] = Variable<String>(periodoInicio);
    map['periodo_fin'] = Variable<String>(periodoFin);
    map['fecha_vencimiento'] = Variable<String>(fechaVencimiento);
    map['estado'] = Variable<String>(estado);
    map['notificacion_enviada'] = Variable<bool>(notificacionEnviada);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CobrosCompanion toCompanion(bool nullToAbsent) {
    return CobrosCompanion(
      id: Value(id),
      residenteId: Value(residenteId),
      tenantId: Value(tenantId),
      tarifaId: tarifaId == null && nullToAbsent
          ? const Value.absent()
          : Value(tarifaId),
      concepto: Value(concepto),
      monto: Value(monto),
      montoPagado: Value(montoPagado),
      periodoInicio: Value(periodoInicio),
      periodoFin: Value(periodoFin),
      fechaVencimiento: Value(fechaVencimiento),
      estado: Value(estado),
      notificacionEnviada: Value(notificacionEnviada),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Cobro.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cobro(
      id: serializer.fromJson<String>(json['id']),
      residenteId: serializer.fromJson<String>(json['residenteId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      tarifaId: serializer.fromJson<String?>(json['tarifaId']),
      concepto: serializer.fromJson<String>(json['concepto']),
      monto: serializer.fromJson<int>(json['monto']),
      montoPagado: serializer.fromJson<int>(json['montoPagado']),
      periodoInicio: serializer.fromJson<String>(json['periodoInicio']),
      periodoFin: serializer.fromJson<String>(json['periodoFin']),
      fechaVencimiento: serializer.fromJson<String>(json['fechaVencimiento']),
      estado: serializer.fromJson<String>(json['estado']),
      notificacionEnviada: serializer.fromJson<bool>(
        json['notificacionEnviada'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'residenteId': serializer.toJson<String>(residenteId),
      'tenantId': serializer.toJson<String>(tenantId),
      'tarifaId': serializer.toJson<String?>(tarifaId),
      'concepto': serializer.toJson<String>(concepto),
      'monto': serializer.toJson<int>(monto),
      'montoPagado': serializer.toJson<int>(montoPagado),
      'periodoInicio': serializer.toJson<String>(periodoInicio),
      'periodoFin': serializer.toJson<String>(periodoFin),
      'fechaVencimiento': serializer.toJson<String>(fechaVencimiento),
      'estado': serializer.toJson<String>(estado),
      'notificacionEnviada': serializer.toJson<bool>(notificacionEnviada),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Cobro copyWith({
    String? id,
    String? residenteId,
    String? tenantId,
    Value<String?> tarifaId = const Value.absent(),
    String? concepto,
    int? monto,
    int? montoPagado,
    String? periodoInicio,
    String? periodoFin,
    String? fechaVencimiento,
    String? estado,
    bool? notificacionEnviada,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Cobro(
    id: id ?? this.id,
    residenteId: residenteId ?? this.residenteId,
    tenantId: tenantId ?? this.tenantId,
    tarifaId: tarifaId.present ? tarifaId.value : this.tarifaId,
    concepto: concepto ?? this.concepto,
    monto: monto ?? this.monto,
    montoPagado: montoPagado ?? this.montoPagado,
    periodoInicio: periodoInicio ?? this.periodoInicio,
    periodoFin: periodoFin ?? this.periodoFin,
    fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
    estado: estado ?? this.estado,
    notificacionEnviada: notificacionEnviada ?? this.notificacionEnviada,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Cobro copyWithCompanion(CobrosCompanion data) {
    return Cobro(
      id: data.id.present ? data.id.value : this.id,
      residenteId: data.residenteId.present
          ? data.residenteId.value
          : this.residenteId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      tarifaId: data.tarifaId.present ? data.tarifaId.value : this.tarifaId,
      concepto: data.concepto.present ? data.concepto.value : this.concepto,
      monto: data.monto.present ? data.monto.value : this.monto,
      montoPagado: data.montoPagado.present
          ? data.montoPagado.value
          : this.montoPagado,
      periodoInicio: data.periodoInicio.present
          ? data.periodoInicio.value
          : this.periodoInicio,
      periodoFin: data.periodoFin.present
          ? data.periodoFin.value
          : this.periodoFin,
      fechaVencimiento: data.fechaVencimiento.present
          ? data.fechaVencimiento.value
          : this.fechaVencimiento,
      estado: data.estado.present ? data.estado.value : this.estado,
      notificacionEnviada: data.notificacionEnviada.present
          ? data.notificacionEnviada.value
          : this.notificacionEnviada,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cobro(')
          ..write('id: $id, ')
          ..write('residenteId: $residenteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('tarifaId: $tarifaId, ')
          ..write('concepto: $concepto, ')
          ..write('monto: $monto, ')
          ..write('montoPagado: $montoPagado, ')
          ..write('periodoInicio: $periodoInicio, ')
          ..write('periodoFin: $periodoFin, ')
          ..write('fechaVencimiento: $fechaVencimiento, ')
          ..write('estado: $estado, ')
          ..write('notificacionEnviada: $notificacionEnviada, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    residenteId,
    tenantId,
    tarifaId,
    concepto,
    monto,
    montoPagado,
    periodoInicio,
    periodoFin,
    fechaVencimiento,
    estado,
    notificacionEnviada,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cobro &&
          other.id == this.id &&
          other.residenteId == this.residenteId &&
          other.tenantId == this.tenantId &&
          other.tarifaId == this.tarifaId &&
          other.concepto == this.concepto &&
          other.monto == this.monto &&
          other.montoPagado == this.montoPagado &&
          other.periodoInicio == this.periodoInicio &&
          other.periodoFin == this.periodoFin &&
          other.fechaVencimiento == this.fechaVencimiento &&
          other.estado == this.estado &&
          other.notificacionEnviada == this.notificacionEnviada &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CobrosCompanion extends UpdateCompanion<Cobro> {
  final Value<String> id;
  final Value<String> residenteId;
  final Value<String> tenantId;
  final Value<String?> tarifaId;
  final Value<String> concepto;
  final Value<int> monto;
  final Value<int> montoPagado;
  final Value<String> periodoInicio;
  final Value<String> periodoFin;
  final Value<String> fechaVencimiento;
  final Value<String> estado;
  final Value<bool> notificacionEnviada;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CobrosCompanion({
    this.id = const Value.absent(),
    this.residenteId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.tarifaId = const Value.absent(),
    this.concepto = const Value.absent(),
    this.monto = const Value.absent(),
    this.montoPagado = const Value.absent(),
    this.periodoInicio = const Value.absent(),
    this.periodoFin = const Value.absent(),
    this.fechaVencimiento = const Value.absent(),
    this.estado = const Value.absent(),
    this.notificacionEnviada = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CobrosCompanion.insert({
    required String id,
    required String residenteId,
    required String tenantId,
    this.tarifaId = const Value.absent(),
    required String concepto,
    required int monto,
    required int montoPagado,
    required String periodoInicio,
    required String periodoFin,
    required String fechaVencimiento,
    required String estado,
    required bool notificacionEnviada,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       residenteId = Value(residenteId),
       tenantId = Value(tenantId),
       concepto = Value(concepto),
       monto = Value(monto),
       montoPagado = Value(montoPagado),
       periodoInicio = Value(periodoInicio),
       periodoFin = Value(periodoFin),
       fechaVencimiento = Value(fechaVencimiento),
       estado = Value(estado),
       notificacionEnviada = Value(notificacionEnviada),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Cobro> custom({
    Expression<String>? id,
    Expression<String>? residenteId,
    Expression<String>? tenantId,
    Expression<String>? tarifaId,
    Expression<String>? concepto,
    Expression<int>? monto,
    Expression<int>? montoPagado,
    Expression<String>? periodoInicio,
    Expression<String>? periodoFin,
    Expression<String>? fechaVencimiento,
    Expression<String>? estado,
    Expression<bool>? notificacionEnviada,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (residenteId != null) 'residente_id': residenteId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (tarifaId != null) 'tarifa_id': tarifaId,
      if (concepto != null) 'concepto': concepto,
      if (monto != null) 'monto': monto,
      if (montoPagado != null) 'monto_pagado': montoPagado,
      if (periodoInicio != null) 'periodo_inicio': periodoInicio,
      if (periodoFin != null) 'periodo_fin': periodoFin,
      if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento,
      if (estado != null) 'estado': estado,
      if (notificacionEnviada != null)
        'notificacion_enviada': notificacionEnviada,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CobrosCompanion copyWith({
    Value<String>? id,
    Value<String>? residenteId,
    Value<String>? tenantId,
    Value<String?>? tarifaId,
    Value<String>? concepto,
    Value<int>? monto,
    Value<int>? montoPagado,
    Value<String>? periodoInicio,
    Value<String>? periodoFin,
    Value<String>? fechaVencimiento,
    Value<String>? estado,
    Value<bool>? notificacionEnviada,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CobrosCompanion(
      id: id ?? this.id,
      residenteId: residenteId ?? this.residenteId,
      tenantId: tenantId ?? this.tenantId,
      tarifaId: tarifaId ?? this.tarifaId,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      montoPagado: montoPagado ?? this.montoPagado,
      periodoInicio: periodoInicio ?? this.periodoInicio,
      periodoFin: periodoFin ?? this.periodoFin,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      notificacionEnviada: notificacionEnviada ?? this.notificacionEnviada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (residenteId.present) {
      map['residente_id'] = Variable<String>(residenteId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (tarifaId.present) {
      map['tarifa_id'] = Variable<String>(tarifaId.value);
    }
    if (concepto.present) {
      map['concepto'] = Variable<String>(concepto.value);
    }
    if (monto.present) {
      map['monto'] = Variable<int>(monto.value);
    }
    if (montoPagado.present) {
      map['monto_pagado'] = Variable<int>(montoPagado.value);
    }
    if (periodoInicio.present) {
      map['periodo_inicio'] = Variable<String>(periodoInicio.value);
    }
    if (periodoFin.present) {
      map['periodo_fin'] = Variable<String>(periodoFin.value);
    }
    if (fechaVencimiento.present) {
      map['fecha_vencimiento'] = Variable<String>(fechaVencimiento.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (notificacionEnviada.present) {
      map['notificacion_enviada'] = Variable<bool>(notificacionEnviada.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('CobrosCompanion(')
          ..write('id: $id, ')
          ..write('residenteId: $residenteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('tarifaId: $tarifaId, ')
          ..write('concepto: $concepto, ')
          ..write('monto: $monto, ')
          ..write('montoPagado: $montoPagado, ')
          ..write('periodoInicio: $periodoInicio, ')
          ..write('periodoFin: $periodoFin, ')
          ..write('fechaVencimiento: $fechaVencimiento, ')
          ..write('estado: $estado, ')
          ..write('notificacionEnviada: $notificacionEnviada, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PagosTable extends Pagos with TableInfo<$PagosTable, Pago> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientPaymentIdMeta = const VerificationMeta(
    'clientPaymentId',
  );
  @override
  late final GeneratedColumn<String> clientPaymentId = GeneratedColumn<String>(
    'client_payment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cobroIdMeta = const VerificationMeta(
    'cobroId',
  );
  @override
  late final GeneratedColumn<String> cobroId = GeneratedColumn<String>(
    'cobro_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _solicitudIdMeta = const VerificationMeta(
    'solicitudId',
  );
  @override
  late final GeneratedColumn<String> solicitudId = GeneratedColumn<String>(
    'solicitud_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<int> monto = GeneratedColumn<int>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaPagoMeta = const VerificationMeta(
    'fechaPago',
  );
  @override
  late final GeneratedColumn<String> fechaPago = GeneratedColumn<String>(
    'fecha_pago',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cobradorIdMeta = const VerificationMeta(
    'cobradorId',
  );
  @override
  late final GeneratedColumn<String> cobradorId = GeneratedColumn<String>(
    'cobrador_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _residenteIdMeta = const VerificationMeta(
    'residenteId',
  );
  @override
  late final GeneratedColumn<String> residenteId = GeneratedColumn<String>(
    'residente_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaSyncMeta = const VerificationMeta(
    'fechaSync',
  );
  @override
  late final GeneratedColumn<DateTime> fechaSync = GeneratedColumn<DateTime>(
    'fecha_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientPaymentId,
    tenantId,
    cobroId,
    serverId,
    solicitudId,
    monto,
    fechaPago,
    cobradorId,
    residenteId,
    fechaSync,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pagos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pago> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_payment_id')) {
      context.handle(
        _clientPaymentIdMeta,
        clientPaymentId.isAcceptableOrUnknown(
          data['client_payment_id']!,
          _clientPaymentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientPaymentIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('cobro_id')) {
      context.handle(
        _cobroIdMeta,
        cobroId.isAcceptableOrUnknown(data['cobro_id']!, _cobroIdMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('solicitud_id')) {
      context.handle(
        _solicitudIdMeta,
        solicitudId.isAcceptableOrUnknown(
          data['solicitud_id']!,
          _solicitudIdMeta,
        ),
      );
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('fecha_pago')) {
      context.handle(
        _fechaPagoMeta,
        fechaPago.isAcceptableOrUnknown(data['fecha_pago']!, _fechaPagoMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaPagoMeta);
    }
    if (data.containsKey('cobrador_id')) {
      context.handle(
        _cobradorIdMeta,
        cobradorId.isAcceptableOrUnknown(data['cobrador_id']!, _cobradorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cobradorIdMeta);
    }
    if (data.containsKey('residente_id')) {
      context.handle(
        _residenteIdMeta,
        residenteId.isAcceptableOrUnknown(
          data['residente_id']!,
          _residenteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_residenteIdMeta);
    }
    if (data.containsKey('fecha_sync')) {
      context.handle(
        _fechaSyncMeta,
        fechaSync.isAcceptableOrUnknown(data['fecha_sync']!, _fechaSyncMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pago map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pago(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientPaymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_payment_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      cobroId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cobro_id'],
      ),
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      solicitudId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solicitud_id'],
      ),
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto'],
      )!,
      fechaPago: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha_pago'],
      )!,
      cobradorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cobrador_id'],
      )!,
      residenteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}residente_id'],
      )!,
      fechaSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_sync'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
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
  $PagosTable createAlias(String alias) {
    return $PagosTable(attachedDatabase, alias);
  }
}

class Pago extends DataClass implements Insertable<Pago> {
  final String id;
  final String clientPaymentId;
  final String tenantId;
  final String? cobroId;
  final String? serverId;
  final String? solicitudId;
  final int monto;
  final String fechaPago;
  final String cobradorId;
  final String residenteId;
  final DateTime? fechaSync;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Pago({
    required this.id,
    required this.clientPaymentId,
    required this.tenantId,
    this.cobroId,
    this.serverId,
    this.solicitudId,
    required this.monto,
    required this.fechaPago,
    required this.cobradorId,
    required this.residenteId,
    this.fechaSync,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_payment_id'] = Variable<String>(clientPaymentId);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || cobroId != null) {
      map['cobro_id'] = Variable<String>(cobroId);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    if (!nullToAbsent || solicitudId != null) {
      map['solicitud_id'] = Variable<String>(solicitudId);
    }
    map['monto'] = Variable<int>(monto);
    map['fecha_pago'] = Variable<String>(fechaPago);
    map['cobrador_id'] = Variable<String>(cobradorId);
    map['residente_id'] = Variable<String>(residenteId);
    if (!nullToAbsent || fechaSync != null) {
      map['fecha_sync'] = Variable<DateTime>(fechaSync);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PagosCompanion toCompanion(bool nullToAbsent) {
    return PagosCompanion(
      id: Value(id),
      clientPaymentId: Value(clientPaymentId),
      tenantId: Value(tenantId),
      cobroId: cobroId == null && nullToAbsent
          ? const Value.absent()
          : Value(cobroId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      solicitudId: solicitudId == null && nullToAbsent
          ? const Value.absent()
          : Value(solicitudId),
      monto: Value(monto),
      fechaPago: Value(fechaPago),
      cobradorId: Value(cobradorId),
      residenteId: Value(residenteId),
      fechaSync: fechaSync == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaSync),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Pago.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pago(
      id: serializer.fromJson<String>(json['id']),
      clientPaymentId: serializer.fromJson<String>(json['clientPaymentId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      cobroId: serializer.fromJson<String?>(json['cobroId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      solicitudId: serializer.fromJson<String?>(json['solicitudId']),
      monto: serializer.fromJson<int>(json['monto']),
      fechaPago: serializer.fromJson<String>(json['fechaPago']),
      cobradorId: serializer.fromJson<String>(json['cobradorId']),
      residenteId: serializer.fromJson<String>(json['residenteId']),
      fechaSync: serializer.fromJson<DateTime?>(json['fechaSync']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientPaymentId': serializer.toJson<String>(clientPaymentId),
      'tenantId': serializer.toJson<String>(tenantId),
      'cobroId': serializer.toJson<String?>(cobroId),
      'serverId': serializer.toJson<String?>(serverId),
      'solicitudId': serializer.toJson<String?>(solicitudId),
      'monto': serializer.toJson<int>(monto),
      'fechaPago': serializer.toJson<String>(fechaPago),
      'cobradorId': serializer.toJson<String>(cobradorId),
      'residenteId': serializer.toJson<String>(residenteId),
      'fechaSync': serializer.toJson<DateTime?>(fechaSync),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Pago copyWith({
    String? id,
    String? clientPaymentId,
    String? tenantId,
    Value<String?> cobroId = const Value.absent(),
    Value<String?> serverId = const Value.absent(),
    Value<String?> solicitudId = const Value.absent(),
    int? monto,
    String? fechaPago,
    String? cobradorId,
    String? residenteId,
    Value<DateTime?> fechaSync = const Value.absent(),
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Pago(
    id: id ?? this.id,
    clientPaymentId: clientPaymentId ?? this.clientPaymentId,
    tenantId: tenantId ?? this.tenantId,
    cobroId: cobroId.present ? cobroId.value : this.cobroId,
    serverId: serverId.present ? serverId.value : this.serverId,
    solicitudId: solicitudId.present ? solicitudId.value : this.solicitudId,
    monto: monto ?? this.monto,
    fechaPago: fechaPago ?? this.fechaPago,
    cobradorId: cobradorId ?? this.cobradorId,
    residenteId: residenteId ?? this.residenteId,
    fechaSync: fechaSync.present ? fechaSync.value : this.fechaSync,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Pago copyWithCompanion(PagosCompanion data) {
    return Pago(
      id: data.id.present ? data.id.value : this.id,
      clientPaymentId: data.clientPaymentId.present
          ? data.clientPaymentId.value
          : this.clientPaymentId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      cobroId: data.cobroId.present ? data.cobroId.value : this.cobroId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      solicitudId: data.solicitudId.present
          ? data.solicitudId.value
          : this.solicitudId,
      monto: data.monto.present ? data.monto.value : this.monto,
      fechaPago: data.fechaPago.present ? data.fechaPago.value : this.fechaPago,
      cobradorId: data.cobradorId.present
          ? data.cobradorId.value
          : this.cobradorId,
      residenteId: data.residenteId.present
          ? data.residenteId.value
          : this.residenteId,
      fechaSync: data.fechaSync.present ? data.fechaSync.value : this.fechaSync,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pago(')
          ..write('id: $id, ')
          ..write('clientPaymentId: $clientPaymentId, ')
          ..write('tenantId: $tenantId, ')
          ..write('cobroId: $cobroId, ')
          ..write('serverId: $serverId, ')
          ..write('solicitudId: $solicitudId, ')
          ..write('monto: $monto, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('cobradorId: $cobradorId, ')
          ..write('residenteId: $residenteId, ')
          ..write('fechaSync: $fechaSync, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientPaymentId,
    tenantId,
    cobroId,
    serverId,
    solicitudId,
    monto,
    fechaPago,
    cobradorId,
    residenteId,
    fechaSync,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pago &&
          other.id == this.id &&
          other.clientPaymentId == this.clientPaymentId &&
          other.tenantId == this.tenantId &&
          other.cobroId == this.cobroId &&
          other.serverId == this.serverId &&
          other.solicitudId == this.solicitudId &&
          other.monto == this.monto &&
          other.fechaPago == this.fechaPago &&
          other.cobradorId == this.cobradorId &&
          other.residenteId == this.residenteId &&
          other.fechaSync == this.fechaSync &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PagosCompanion extends UpdateCompanion<Pago> {
  final Value<String> id;
  final Value<String> clientPaymentId;
  final Value<String> tenantId;
  final Value<String?> cobroId;
  final Value<String?> serverId;
  final Value<String?> solicitudId;
  final Value<int> monto;
  final Value<String> fechaPago;
  final Value<String> cobradorId;
  final Value<String> residenteId;
  final Value<DateTime?> fechaSync;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PagosCompanion({
    this.id = const Value.absent(),
    this.clientPaymentId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.cobroId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.solicitudId = const Value.absent(),
    this.monto = const Value.absent(),
    this.fechaPago = const Value.absent(),
    this.cobradorId = const Value.absent(),
    this.residenteId = const Value.absent(),
    this.fechaSync = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagosCompanion.insert({
    required String id,
    required String clientPaymentId,
    required String tenantId,
    this.cobroId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.solicitudId = const Value.absent(),
    required int monto,
    required String fechaPago,
    required String cobradorId,
    required String residenteId,
    this.fechaSync = const Value.absent(),
    required String syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientPaymentId = Value(clientPaymentId),
       tenantId = Value(tenantId),
       monto = Value(monto),
       fechaPago = Value(fechaPago),
       cobradorId = Value(cobradorId),
       residenteId = Value(residenteId),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Pago> custom({
    Expression<String>? id,
    Expression<String>? clientPaymentId,
    Expression<String>? tenantId,
    Expression<String>? cobroId,
    Expression<String>? serverId,
    Expression<String>? solicitudId,
    Expression<int>? monto,
    Expression<String>? fechaPago,
    Expression<String>? cobradorId,
    Expression<String>? residenteId,
    Expression<DateTime>? fechaSync,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientPaymentId != null) 'client_payment_id': clientPaymentId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (cobroId != null) 'cobro_id': cobroId,
      if (serverId != null) 'server_id': serverId,
      if (solicitudId != null) 'solicitud_id': solicitudId,
      if (monto != null) 'monto': monto,
      if (fechaPago != null) 'fecha_pago': fechaPago,
      if (cobradorId != null) 'cobrador_id': cobradorId,
      if (residenteId != null) 'residente_id': residenteId,
      if (fechaSync != null) 'fecha_sync': fechaSync,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagosCompanion copyWith({
    Value<String>? id,
    Value<String>? clientPaymentId,
    Value<String>? tenantId,
    Value<String?>? cobroId,
    Value<String?>? serverId,
    Value<String?>? solicitudId,
    Value<int>? monto,
    Value<String>? fechaPago,
    Value<String>? cobradorId,
    Value<String>? residenteId,
    Value<DateTime?>? fechaSync,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PagosCompanion(
      id: id ?? this.id,
      clientPaymentId: clientPaymentId ?? this.clientPaymentId,
      tenantId: tenantId ?? this.tenantId,
      cobroId: cobroId ?? this.cobroId,
      serverId: serverId ?? this.serverId,
      solicitudId: solicitudId ?? this.solicitudId,
      monto: monto ?? this.monto,
      fechaPago: fechaPago ?? this.fechaPago,
      cobradorId: cobradorId ?? this.cobradorId,
      residenteId: residenteId ?? this.residenteId,
      fechaSync: fechaSync ?? this.fechaSync,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientPaymentId.present) {
      map['client_payment_id'] = Variable<String>(clientPaymentId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (cobroId.present) {
      map['cobro_id'] = Variable<String>(cobroId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (solicitudId.present) {
      map['solicitud_id'] = Variable<String>(solicitudId.value);
    }
    if (monto.present) {
      map['monto'] = Variable<int>(monto.value);
    }
    if (fechaPago.present) {
      map['fecha_pago'] = Variable<String>(fechaPago.value);
    }
    if (cobradorId.present) {
      map['cobrador_id'] = Variable<String>(cobradorId.value);
    }
    if (residenteId.present) {
      map['residente_id'] = Variable<String>(residenteId.value);
    }
    if (fechaSync.present) {
      map['fecha_sync'] = Variable<DateTime>(fechaSync.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
    return (StringBuffer('PagosCompanion(')
          ..write('id: $id, ')
          ..write('clientPaymentId: $clientPaymentId, ')
          ..write('tenantId: $tenantId, ')
          ..write('cobroId: $cobroId, ')
          ..write('serverId: $serverId, ')
          ..write('solicitudId: $solicitudId, ')
          ..write('monto: $monto, ')
          ..write('fechaPago: $fechaPago, ')
          ..write('cobradorId: $cobradorId, ')
          ..write('residenteId: $residenteId, ')
          ..write('fechaSync: $fechaSync, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProyectosTable proyectos = $ProyectosTable(this);
  late final $EtapasTable etapas = $EtapasTable(this);
  late final $CasasTable casas = $CasasTable(this);
  late final $ResidentesTable residentes = $ResidentesTable(this);
  late final $TenenciasTable tenencias = $TenenciasTable(this);
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $AsignacionesEtapaTable asignacionesEtapa =
      $AsignacionesEtapaTable(this);
  late final $TarifasTable tarifas = $TarifasTable(this);
  late final $MontosPredefinidosTable montosPredefinidos =
      $MontosPredefinidosTable(this);
  late final $PlanesDeCobroTable planesDeCobro = $PlanesDeCobroTable(this);
  late final $CobrosTable cobros = $CobrosTable(this);
  late final $PagosTable pagos = $PagosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    proyectos,
    etapas,
    casas,
    residentes,
    tenencias,
    usuarios,
    asignacionesEtapa,
    tarifas,
    montosPredefinidos,
    planesDeCobro,
    cobros,
    pagos,
  ];
}

typedef $$ProyectosTableCreateCompanionBuilder =
    ProyectosCompanion Function({
      required String id,
      required String nombre,
      required String tenantId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProyectosTableUpdateCompanionBuilder =
    ProyectosCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> tenantId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProyectosTableFilterComposer
    extends Composer<_$AppDatabase, $ProyectosTable> {
  $$ProyectosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
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

class $$ProyectosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProyectosTable> {
  $$ProyectosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
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

class $$ProyectosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProyectosTable> {
  $$ProyectosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProyectosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProyectosTable,
          Proyecto,
          $$ProyectosTableFilterComposer,
          $$ProyectosTableOrderingComposer,
          $$ProyectosTableAnnotationComposer,
          $$ProyectosTableCreateCompanionBuilder,
          $$ProyectosTableUpdateCompanionBuilder,
          (Proyecto, BaseReferences<_$AppDatabase, $ProyectosTable, Proyecto>),
          Proyecto,
          PrefetchHooks Function()
        > {
  $$ProyectosTableTableManager(_$AppDatabase db, $ProyectosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProyectosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProyectosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProyectosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProyectosCompanion(
                id: id,
                nombre: nombre,
                tenantId: tenantId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String tenantId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProyectosCompanion.insert(
                id: id,
                nombre: nombre,
                tenantId: tenantId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProyectosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProyectosTable,
      Proyecto,
      $$ProyectosTableFilterComposer,
      $$ProyectosTableOrderingComposer,
      $$ProyectosTableAnnotationComposer,
      $$ProyectosTableCreateCompanionBuilder,
      $$ProyectosTableUpdateCompanionBuilder,
      (Proyecto, BaseReferences<_$AppDatabase, $ProyectosTable, Proyecto>),
      Proyecto,
      PrefetchHooks Function()
    >;
typedef $$EtapasTableCreateCompanionBuilder =
    EtapasCompanion Function({
      required String id,
      required String nombre,
      required String proyectoId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$EtapasTableUpdateCompanionBuilder =
    EtapasCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> proyectoId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$EtapasTableFilterComposer
    extends Composer<_$AppDatabase, $EtapasTable> {
  $$EtapasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EtapasTableOrderingComposer
    extends Composer<_$AppDatabase, $EtapasTable> {
  $$EtapasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EtapasTableAnnotationComposer
    extends Composer<_$AppDatabase, $EtapasTable> {
  $$EtapasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EtapasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EtapasTable,
          Etapa,
          $$EtapasTableFilterComposer,
          $$EtapasTableOrderingComposer,
          $$EtapasTableAnnotationComposer,
          $$EtapasTableCreateCompanionBuilder,
          $$EtapasTableUpdateCompanionBuilder,
          (Etapa, BaseReferences<_$AppDatabase, $EtapasTable, Etapa>),
          Etapa,
          PrefetchHooks Function()
        > {
  $$EtapasTableTableManager(_$AppDatabase db, $EtapasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EtapasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EtapasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EtapasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> proyectoId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EtapasCompanion(
                id: id,
                nombre: nombre,
                proyectoId: proyectoId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String proyectoId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EtapasCompanion.insert(
                id: id,
                nombre: nombre,
                proyectoId: proyectoId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EtapasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EtapasTable,
      Etapa,
      $$EtapasTableFilterComposer,
      $$EtapasTableOrderingComposer,
      $$EtapasTableAnnotationComposer,
      $$EtapasTableCreateCompanionBuilder,
      $$EtapasTableUpdateCompanionBuilder,
      (Etapa, BaseReferences<_$AppDatabase, $EtapasTable, Etapa>),
      Etapa,
      PrefetchHooks Function()
    >;
typedef $$CasasTableCreateCompanionBuilder =
    CasasCompanion Function({
      required String id,
      required String direccionInterna,
      required String etapaId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CasasTableUpdateCompanionBuilder =
    CasasCompanion Function({
      Value<String> id,
      Value<String> direccionInterna,
      Value<String> etapaId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CasasTableFilterComposer extends Composer<_$AppDatabase, $CasasTable> {
  $$CasasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direccionInterna => $composableBuilder(
    column: $table.direccionInterna,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etapaId => $composableBuilder(
    column: $table.etapaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CasasTableOrderingComposer
    extends Composer<_$AppDatabase, $CasasTable> {
  $$CasasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direccionInterna => $composableBuilder(
    column: $table.direccionInterna,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etapaId => $composableBuilder(
    column: $table.etapaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CasasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CasasTable> {
  $$CasasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direccionInterna => $composableBuilder(
    column: $table.direccionInterna,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etapaId =>
      $composableBuilder(column: $table.etapaId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CasasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CasasTable,
          Casa,
          $$CasasTableFilterComposer,
          $$CasasTableOrderingComposer,
          $$CasasTableAnnotationComposer,
          $$CasasTableCreateCompanionBuilder,
          $$CasasTableUpdateCompanionBuilder,
          (Casa, BaseReferences<_$AppDatabase, $CasasTable, Casa>),
          Casa,
          PrefetchHooks Function()
        > {
  $$CasasTableTableManager(_$AppDatabase db, $CasasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CasasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CasasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CasasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> direccionInterna = const Value.absent(),
                Value<String> etapaId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CasasCompanion(
                id: id,
                direccionInterna: direccionInterna,
                etapaId: etapaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String direccionInterna,
                required String etapaId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CasasCompanion.insert(
                id: id,
                direccionInterna: direccionInterna,
                etapaId: etapaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CasasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CasasTable,
      Casa,
      $$CasasTableFilterComposer,
      $$CasasTableOrderingComposer,
      $$CasasTableAnnotationComposer,
      $$CasasTableCreateCompanionBuilder,
      $$CasasTableUpdateCompanionBuilder,
      (Casa, BaseReferences<_$AppDatabase, $CasasTable, Casa>),
      Casa,
      PrefetchHooks Function()
    >;
typedef $$ResidentesTableCreateCompanionBuilder =
    ResidentesCompanion Function({
      required String id,
      required String nombre,
      required String telefono,
      Value<String?> email,
      required String tenantId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ResidentesTableUpdateCompanionBuilder =
    ResidentesCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> telefono,
      Value<String?> email,
      Value<String> tenantId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ResidentesTableFilterComposer
    extends Composer<_$AppDatabase, $ResidentesTable> {
  $$ResidentesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
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

class $$ResidentesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResidentesTable> {
  $$ResidentesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
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

class $$ResidentesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResidentesTable> {
  $$ResidentesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ResidentesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResidentesTable,
          Residente,
          $$ResidentesTableFilterComposer,
          $$ResidentesTableOrderingComposer,
          $$ResidentesTableAnnotationComposer,
          $$ResidentesTableCreateCompanionBuilder,
          $$ResidentesTableUpdateCompanionBuilder,
          (
            Residente,
            BaseReferences<_$AppDatabase, $ResidentesTable, Residente>,
          ),
          Residente,
          PrefetchHooks Function()
        > {
  $$ResidentesTableTableManager(_$AppDatabase db, $ResidentesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResidentesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResidentesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResidentesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> telefono = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResidentesCompanion(
                id: id,
                nombre: nombre,
                telefono: telefono,
                email: email,
                tenantId: tenantId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String telefono,
                Value<String?> email = const Value.absent(),
                required String tenantId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ResidentesCompanion.insert(
                id: id,
                nombre: nombre,
                telefono: telefono,
                email: email,
                tenantId: tenantId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ResidentesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResidentesTable,
      Residente,
      $$ResidentesTableFilterComposer,
      $$ResidentesTableOrderingComposer,
      $$ResidentesTableAnnotationComposer,
      $$ResidentesTableCreateCompanionBuilder,
      $$ResidentesTableUpdateCompanionBuilder,
      (Residente, BaseReferences<_$AppDatabase, $ResidentesTable, Residente>),
      Residente,
      PrefetchHooks Function()
    >;
typedef $$TenenciasTableCreateCompanionBuilder =
    TenenciasCompanion Function({
      required String id,
      required String residenteId,
      required String casaId,
      required DateTime fechaInicio,
      Value<DateTime?> fechaFin,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TenenciasTableUpdateCompanionBuilder =
    TenenciasCompanion Function({
      Value<String> id,
      Value<String> residenteId,
      Value<String> casaId,
      Value<DateTime> fechaInicio,
      Value<DateTime?> fechaFin,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TenenciasTableFilterComposer
    extends Composer<_$AppDatabase, $TenenciasTable> {
  $$TenenciasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get casaId => $composableBuilder(
    column: $table.casaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaFin => $composableBuilder(
    column: $table.fechaFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TenenciasTableOrderingComposer
    extends Composer<_$AppDatabase, $TenenciasTable> {
  $$TenenciasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get casaId => $composableBuilder(
    column: $table.casaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaFin => $composableBuilder(
    column: $table.fechaFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TenenciasTableAnnotationComposer
    extends Composer<_$AppDatabase, $TenenciasTable> {
  $$TenenciasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get casaId =>
      $composableBuilder(column: $table.casaId, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaFin =>
      $composableBuilder(column: $table.fechaFin, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TenenciasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TenenciasTable,
          Tenencia,
          $$TenenciasTableFilterComposer,
          $$TenenciasTableOrderingComposer,
          $$TenenciasTableAnnotationComposer,
          $$TenenciasTableCreateCompanionBuilder,
          $$TenenciasTableUpdateCompanionBuilder,
          (Tenencia, BaseReferences<_$AppDatabase, $TenenciasTable, Tenencia>),
          Tenencia,
          PrefetchHooks Function()
        > {
  $$TenenciasTableTableManager(_$AppDatabase db, $TenenciasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TenenciasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TenenciasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TenenciasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> residenteId = const Value.absent(),
                Value<String> casaId = const Value.absent(),
                Value<DateTime> fechaInicio = const Value.absent(),
                Value<DateTime?> fechaFin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenenciasCompanion(
                id: id,
                residenteId: residenteId,
                casaId: casaId,
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String residenteId,
                required String casaId,
                required DateTime fechaInicio,
                Value<DateTime?> fechaFin = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TenenciasCompanion.insert(
                id: id,
                residenteId: residenteId,
                casaId: casaId,
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TenenciasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TenenciasTable,
      Tenencia,
      $$TenenciasTableFilterComposer,
      $$TenenciasTableOrderingComposer,
      $$TenenciasTableAnnotationComposer,
      $$TenenciasTableCreateCompanionBuilder,
      $$TenenciasTableUpdateCompanionBuilder,
      (Tenencia, BaseReferences<_$AppDatabase, $TenenciasTable, Tenencia>),
      Tenencia,
      PrefetchHooks Function()
    >;
typedef $$UsuariosTableCreateCompanionBuilder =
    UsuariosCompanion Function({
      required String id,
      required String email,
      required String nombre,
      required String rol,
      Value<String?> residenteId,
      required String tenantId,
      required bool activo,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UsuariosTableUpdateCompanionBuilder =
    UsuariosCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> nombre,
      Value<String> rol,
      Value<String?> residenteId,
      Value<String> tenantId,
      Value<bool> activo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UsuariosTableFilterComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
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

class $$UsuariosTableOrderingComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
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

class $$UsuariosTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  GeneratedColumn<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsuariosTable,
          Usuario,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
          Usuario,
          PrefetchHooks Function()
        > {
  $$UsuariosTableTableManager(_$AppDatabase db, $UsuariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsuariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsuariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsuariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<String?> residenteId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                id: id,
                email: email,
                nombre: nombre,
                rol: rol,
                residenteId: residenteId,
                tenantId: tenantId,
                activo: activo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String nombre,
                required String rol,
                Value<String?> residenteId = const Value.absent(),
                required String tenantId,
                required bool activo,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                id: id,
                email: email,
                nombre: nombre,
                rol: rol,
                residenteId: residenteId,
                tenantId: tenantId,
                activo: activo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsuariosTable,
      Usuario,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
      Usuario,
      PrefetchHooks Function()
    >;
typedef $$AsignacionesEtapaTableCreateCompanionBuilder =
    AsignacionesEtapaCompanion Function({
      required String id,
      required String usuarioId,
      required String etapaId,
      required String tenantId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AsignacionesEtapaTableUpdateCompanionBuilder =
    AsignacionesEtapaCompanion Function({
      Value<String> id,
      Value<String> usuarioId,
      Value<String> etapaId,
      Value<String> tenantId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AsignacionesEtapaTableFilterComposer
    extends Composer<_$AppDatabase, $AsignacionesEtapaTable> {
  $$AsignacionesEtapaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etapaId => $composableBuilder(
    column: $table.etapaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AsignacionesEtapaTableOrderingComposer
    extends Composer<_$AppDatabase, $AsignacionesEtapaTable> {
  $$AsignacionesEtapaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etapaId => $composableBuilder(
    column: $table.etapaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AsignacionesEtapaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AsignacionesEtapaTable> {
  $$AsignacionesEtapaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<String> get etapaId =>
      $composableBuilder(column: $table.etapaId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AsignacionesEtapaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AsignacionesEtapaTable,
          AsignacionesEtapaData,
          $$AsignacionesEtapaTableFilterComposer,
          $$AsignacionesEtapaTableOrderingComposer,
          $$AsignacionesEtapaTableAnnotationComposer,
          $$AsignacionesEtapaTableCreateCompanionBuilder,
          $$AsignacionesEtapaTableUpdateCompanionBuilder,
          (
            AsignacionesEtapaData,
            BaseReferences<
              _$AppDatabase,
              $AsignacionesEtapaTable,
              AsignacionesEtapaData
            >,
          ),
          AsignacionesEtapaData,
          PrefetchHooks Function()
        > {
  $$AsignacionesEtapaTableTableManager(
    _$AppDatabase db,
    $AsignacionesEtapaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AsignacionesEtapaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AsignacionesEtapaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AsignacionesEtapaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<String> etapaId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AsignacionesEtapaCompanion(
                id: id,
                usuarioId: usuarioId,
                etapaId: etapaId,
                tenantId: tenantId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String usuarioId,
                required String etapaId,
                required String tenantId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AsignacionesEtapaCompanion.insert(
                id: id,
                usuarioId: usuarioId,
                etapaId: etapaId,
                tenantId: tenantId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AsignacionesEtapaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AsignacionesEtapaTable,
      AsignacionesEtapaData,
      $$AsignacionesEtapaTableFilterComposer,
      $$AsignacionesEtapaTableOrderingComposer,
      $$AsignacionesEtapaTableAnnotationComposer,
      $$AsignacionesEtapaTableCreateCompanionBuilder,
      $$AsignacionesEtapaTableUpdateCompanionBuilder,
      (
        AsignacionesEtapaData,
        BaseReferences<
          _$AppDatabase,
          $AsignacionesEtapaTable,
          AsignacionesEtapaData
        >,
      ),
      AsignacionesEtapaData,
      PrefetchHooks Function()
    >;
typedef $$TarifasTableCreateCompanionBuilder =
    TarifasCompanion Function({
      required String id,
      required String tenantId,
      required String proyectoId,
      required String frecuencia,
      required int monto,
      required String fechaVigencia,
      required bool activa,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TarifasTableUpdateCompanionBuilder =
    TarifasCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> proyectoId,
      Value<String> frecuencia,
      Value<int> monto,
      Value<String> fechaVigencia,
      Value<bool> activa,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TarifasTableFilterComposer
    extends Composer<_$AppDatabase, $TarifasTable> {
  $$TarifasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaVigencia => $composableBuilder(
    column: $table.fechaVigencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activa => $composableBuilder(
    column: $table.activa,
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

class $$TarifasTableOrderingComposer
    extends Composer<_$AppDatabase, $TarifasTable> {
  $$TarifasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaVigencia => $composableBuilder(
    column: $table.fechaVigencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activa => $composableBuilder(
    column: $table.activa,
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

class $$TarifasTableAnnotationComposer
    extends Composer<_$AppDatabase, $TarifasTable> {
  $$TarifasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get fechaVigencia => $composableBuilder(
    column: $table.fechaVigencia,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activa =>
      $composableBuilder(column: $table.activa, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TarifasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TarifasTable,
          Tarifa,
          $$TarifasTableFilterComposer,
          $$TarifasTableOrderingComposer,
          $$TarifasTableAnnotationComposer,
          $$TarifasTableCreateCompanionBuilder,
          $$TarifasTableUpdateCompanionBuilder,
          (Tarifa, BaseReferences<_$AppDatabase, $TarifasTable, Tarifa>),
          Tarifa,
          PrefetchHooks Function()
        > {
  $$TarifasTableTableManager(_$AppDatabase db, $TarifasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TarifasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TarifasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TarifasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> proyectoId = const Value.absent(),
                Value<String> frecuencia = const Value.absent(),
                Value<int> monto = const Value.absent(),
                Value<String> fechaVigencia = const Value.absent(),
                Value<bool> activa = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TarifasCompanion(
                id: id,
                tenantId: tenantId,
                proyectoId: proyectoId,
                frecuencia: frecuencia,
                monto: monto,
                fechaVigencia: fechaVigencia,
                activa: activa,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String proyectoId,
                required String frecuencia,
                required int monto,
                required String fechaVigencia,
                required bool activa,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TarifasCompanion.insert(
                id: id,
                tenantId: tenantId,
                proyectoId: proyectoId,
                frecuencia: frecuencia,
                monto: monto,
                fechaVigencia: fechaVigencia,
                activa: activa,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TarifasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TarifasTable,
      Tarifa,
      $$TarifasTableFilterComposer,
      $$TarifasTableOrderingComposer,
      $$TarifasTableAnnotationComposer,
      $$TarifasTableCreateCompanionBuilder,
      $$TarifasTableUpdateCompanionBuilder,
      (Tarifa, BaseReferences<_$AppDatabase, $TarifasTable, Tarifa>),
      Tarifa,
      PrefetchHooks Function()
    >;
typedef $$MontosPredefinidosTableCreateCompanionBuilder =
    MontosPredefinidosCompanion Function({
      required String id,
      required String tenantId,
      required String proyectoId,
      required int monto,
      required String descripcion,
      required bool activo,
      required int orden,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MontosPredefinidosTableUpdateCompanionBuilder =
    MontosPredefinidosCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> proyectoId,
      Value<int> monto,
      Value<String> descripcion,
      Value<bool> activo,
      Value<int> orden,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MontosPredefinidosTableFilterComposer
    extends Composer<_$AppDatabase, $MontosPredefinidosTable> {
  $$MontosPredefinidosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
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

class $$MontosPredefinidosTableOrderingComposer
    extends Composer<_$AppDatabase, $MontosPredefinidosTable> {
  $$MontosPredefinidosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
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

class $$MontosPredefinidosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MontosPredefinidosTable> {
  $$MontosPredefinidosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MontosPredefinidosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MontosPredefinidosTable,
          MontosPredefinido,
          $$MontosPredefinidosTableFilterComposer,
          $$MontosPredefinidosTableOrderingComposer,
          $$MontosPredefinidosTableAnnotationComposer,
          $$MontosPredefinidosTableCreateCompanionBuilder,
          $$MontosPredefinidosTableUpdateCompanionBuilder,
          (
            MontosPredefinido,
            BaseReferences<
              _$AppDatabase,
              $MontosPredefinidosTable,
              MontosPredefinido
            >,
          ),
          MontosPredefinido,
          PrefetchHooks Function()
        > {
  $$MontosPredefinidosTableTableManager(
    _$AppDatabase db,
    $MontosPredefinidosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MontosPredefinidosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MontosPredefinidosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MontosPredefinidosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> proyectoId = const Value.absent(),
                Value<int> monto = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MontosPredefinidosCompanion(
                id: id,
                tenantId: tenantId,
                proyectoId: proyectoId,
                monto: monto,
                descripcion: descripcion,
                activo: activo,
                orden: orden,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String proyectoId,
                required int monto,
                required String descripcion,
                required bool activo,
                required int orden,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MontosPredefinidosCompanion.insert(
                id: id,
                tenantId: tenantId,
                proyectoId: proyectoId,
                monto: monto,
                descripcion: descripcion,
                activo: activo,
                orden: orden,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MontosPredefinidosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MontosPredefinidosTable,
      MontosPredefinido,
      $$MontosPredefinidosTableFilterComposer,
      $$MontosPredefinidosTableOrderingComposer,
      $$MontosPredefinidosTableAnnotationComposer,
      $$MontosPredefinidosTableCreateCompanionBuilder,
      $$MontosPredefinidosTableUpdateCompanionBuilder,
      (
        MontosPredefinido,
        BaseReferences<
          _$AppDatabase,
          $MontosPredefinidosTable,
          MontosPredefinido
        >,
      ),
      MontosPredefinido,
      PrefetchHooks Function()
    >;
typedef $$PlanesDeCobroTableCreateCompanionBuilder =
    PlanesDeCobroCompanion Function({
      required String id,
      required String residenteId,
      required String tenantId,
      required String proyectoId,
      required String frecuencia,
      required String fechaActivacion,
      required bool activa,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlanesDeCobroTableUpdateCompanionBuilder =
    PlanesDeCobroCompanion Function({
      Value<String> id,
      Value<String> residenteId,
      Value<String> tenantId,
      Value<String> proyectoId,
      Value<String> frecuencia,
      Value<String> fechaActivacion,
      Value<bool> activa,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlanesDeCobroTableFilterComposer
    extends Composer<_$AppDatabase, $PlanesDeCobroTable> {
  $$PlanesDeCobroTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaActivacion => $composableBuilder(
    column: $table.fechaActivacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activa => $composableBuilder(
    column: $table.activa,
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

class $$PlanesDeCobroTableOrderingComposer
    extends Composer<_$AppDatabase, $PlanesDeCobroTable> {
  $$PlanesDeCobroTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaActivacion => $composableBuilder(
    column: $table.fechaActivacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activa => $composableBuilder(
    column: $table.activa,
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

class $$PlanesDeCobroTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlanesDeCobroTable> {
  $$PlanesDeCobroTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get proyectoId => $composableBuilder(
    column: $table.proyectoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fechaActivacion => $composableBuilder(
    column: $table.fechaActivacion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activa =>
      $composableBuilder(column: $table.activa, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlanesDeCobroTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlanesDeCobroTable,
          PlanesDeCobroData,
          $$PlanesDeCobroTableFilterComposer,
          $$PlanesDeCobroTableOrderingComposer,
          $$PlanesDeCobroTableAnnotationComposer,
          $$PlanesDeCobroTableCreateCompanionBuilder,
          $$PlanesDeCobroTableUpdateCompanionBuilder,
          (
            PlanesDeCobroData,
            BaseReferences<
              _$AppDatabase,
              $PlanesDeCobroTable,
              PlanesDeCobroData
            >,
          ),
          PlanesDeCobroData,
          PrefetchHooks Function()
        > {
  $$PlanesDeCobroTableTableManager(_$AppDatabase db, $PlanesDeCobroTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanesDeCobroTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanesDeCobroTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanesDeCobroTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> residenteId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> proyectoId = const Value.absent(),
                Value<String> frecuencia = const Value.absent(),
                Value<String> fechaActivacion = const Value.absent(),
                Value<bool> activa = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanesDeCobroCompanion(
                id: id,
                residenteId: residenteId,
                tenantId: tenantId,
                proyectoId: proyectoId,
                frecuencia: frecuencia,
                fechaActivacion: fechaActivacion,
                activa: activa,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String residenteId,
                required String tenantId,
                required String proyectoId,
                required String frecuencia,
                required String fechaActivacion,
                required bool activa,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlanesDeCobroCompanion.insert(
                id: id,
                residenteId: residenteId,
                tenantId: tenantId,
                proyectoId: proyectoId,
                frecuencia: frecuencia,
                fechaActivacion: fechaActivacion,
                activa: activa,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanesDeCobroTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlanesDeCobroTable,
      PlanesDeCobroData,
      $$PlanesDeCobroTableFilterComposer,
      $$PlanesDeCobroTableOrderingComposer,
      $$PlanesDeCobroTableAnnotationComposer,
      $$PlanesDeCobroTableCreateCompanionBuilder,
      $$PlanesDeCobroTableUpdateCompanionBuilder,
      (
        PlanesDeCobroData,
        BaseReferences<_$AppDatabase, $PlanesDeCobroTable, PlanesDeCobroData>,
      ),
      PlanesDeCobroData,
      PrefetchHooks Function()
    >;
typedef $$CobrosTableCreateCompanionBuilder =
    CobrosCompanion Function({
      required String id,
      required String residenteId,
      required String tenantId,
      Value<String?> tarifaId,
      required String concepto,
      required int monto,
      required int montoPagado,
      required String periodoInicio,
      required String periodoFin,
      required String fechaVencimiento,
      required String estado,
      required bool notificacionEnviada,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CobrosTableUpdateCompanionBuilder =
    CobrosCompanion Function({
      Value<String> id,
      Value<String> residenteId,
      Value<String> tenantId,
      Value<String?> tarifaId,
      Value<String> concepto,
      Value<int> monto,
      Value<int> montoPagado,
      Value<String> periodoInicio,
      Value<String> periodoFin,
      Value<String> fechaVencimiento,
      Value<String> estado,
      Value<bool> notificacionEnviada,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CobrosTableFilterComposer
    extends Composer<_$AppDatabase, $CobrosTable> {
  $$CobrosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tarifaId => $composableBuilder(
    column: $table.tarifaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concepto => $composableBuilder(
    column: $table.concepto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montoPagado => $composableBuilder(
    column: $table.montoPagado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodoInicio => $composableBuilder(
    column: $table.periodoInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodoFin => $composableBuilder(
    column: $table.periodoFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaVencimiento => $composableBuilder(
    column: $table.fechaVencimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificacionEnviada => $composableBuilder(
    column: $table.notificacionEnviada,
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

class $$CobrosTableOrderingComposer
    extends Composer<_$AppDatabase, $CobrosTable> {
  $$CobrosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tarifaId => $composableBuilder(
    column: $table.tarifaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concepto => $composableBuilder(
    column: $table.concepto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montoPagado => $composableBuilder(
    column: $table.montoPagado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodoInicio => $composableBuilder(
    column: $table.periodoInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodoFin => $composableBuilder(
    column: $table.periodoFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaVencimiento => $composableBuilder(
    column: $table.fechaVencimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificacionEnviada => $composableBuilder(
    column: $table.notificacionEnviada,
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

class $$CobrosTableAnnotationComposer
    extends Composer<_$AppDatabase, $CobrosTable> {
  $$CobrosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get tarifaId =>
      $composableBuilder(column: $table.tarifaId, builder: (column) => column);

  GeneratedColumn<String> get concepto =>
      $composableBuilder(column: $table.concepto, builder: (column) => column);

  GeneratedColumn<int> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<int> get montoPagado => $composableBuilder(
    column: $table.montoPagado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodoInicio => $composableBuilder(
    column: $table.periodoInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodoFin => $composableBuilder(
    column: $table.periodoFin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fechaVencimiento => $composableBuilder(
    column: $table.fechaVencimiento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<bool> get notificacionEnviada => $composableBuilder(
    column: $table.notificacionEnviada,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CobrosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CobrosTable,
          Cobro,
          $$CobrosTableFilterComposer,
          $$CobrosTableOrderingComposer,
          $$CobrosTableAnnotationComposer,
          $$CobrosTableCreateCompanionBuilder,
          $$CobrosTableUpdateCompanionBuilder,
          (Cobro, BaseReferences<_$AppDatabase, $CobrosTable, Cobro>),
          Cobro,
          PrefetchHooks Function()
        > {
  $$CobrosTableTableManager(_$AppDatabase db, $CobrosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CobrosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CobrosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CobrosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> residenteId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> tarifaId = const Value.absent(),
                Value<String> concepto = const Value.absent(),
                Value<int> monto = const Value.absent(),
                Value<int> montoPagado = const Value.absent(),
                Value<String> periodoInicio = const Value.absent(),
                Value<String> periodoFin = const Value.absent(),
                Value<String> fechaVencimiento = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<bool> notificacionEnviada = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CobrosCompanion(
                id: id,
                residenteId: residenteId,
                tenantId: tenantId,
                tarifaId: tarifaId,
                concepto: concepto,
                monto: monto,
                montoPagado: montoPagado,
                periodoInicio: periodoInicio,
                periodoFin: periodoFin,
                fechaVencimiento: fechaVencimiento,
                estado: estado,
                notificacionEnviada: notificacionEnviada,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String residenteId,
                required String tenantId,
                Value<String?> tarifaId = const Value.absent(),
                required String concepto,
                required int monto,
                required int montoPagado,
                required String periodoInicio,
                required String periodoFin,
                required String fechaVencimiento,
                required String estado,
                required bool notificacionEnviada,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CobrosCompanion.insert(
                id: id,
                residenteId: residenteId,
                tenantId: tenantId,
                tarifaId: tarifaId,
                concepto: concepto,
                monto: monto,
                montoPagado: montoPagado,
                periodoInicio: periodoInicio,
                periodoFin: periodoFin,
                fechaVencimiento: fechaVencimiento,
                estado: estado,
                notificacionEnviada: notificacionEnviada,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CobrosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CobrosTable,
      Cobro,
      $$CobrosTableFilterComposer,
      $$CobrosTableOrderingComposer,
      $$CobrosTableAnnotationComposer,
      $$CobrosTableCreateCompanionBuilder,
      $$CobrosTableUpdateCompanionBuilder,
      (Cobro, BaseReferences<_$AppDatabase, $CobrosTable, Cobro>),
      Cobro,
      PrefetchHooks Function()
    >;
typedef $$PagosTableCreateCompanionBuilder =
    PagosCompanion Function({
      required String id,
      required String clientPaymentId,
      required String tenantId,
      Value<String?> cobroId,
      Value<String?> serverId,
      Value<String?> solicitudId,
      required int monto,
      required String fechaPago,
      required String cobradorId,
      required String residenteId,
      Value<DateTime?> fechaSync,
      required String syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PagosTableUpdateCompanionBuilder =
    PagosCompanion Function({
      Value<String> id,
      Value<String> clientPaymentId,
      Value<String> tenantId,
      Value<String?> cobroId,
      Value<String?> serverId,
      Value<String?> solicitudId,
      Value<int> monto,
      Value<String> fechaPago,
      Value<String> cobradorId,
      Value<String> residenteId,
      Value<DateTime?> fechaSync,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PagosTableFilterComposer extends Composer<_$AppDatabase, $PagosTable> {
  $$PagosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientPaymentId => $composableBuilder(
    column: $table.clientPaymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cobroId => $composableBuilder(
    column: $table.cobroId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solicitudId => $composableBuilder(
    column: $table.solicitudId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cobradorId => $composableBuilder(
    column: $table.cobradorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaSync => $composableBuilder(
    column: $table.fechaSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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

class $$PagosTableOrderingComposer
    extends Composer<_$AppDatabase, $PagosTable> {
  $$PagosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientPaymentId => $composableBuilder(
    column: $table.clientPaymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cobroId => $composableBuilder(
    column: $table.cobroId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solicitudId => $composableBuilder(
    column: $table.solicitudId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaPago => $composableBuilder(
    column: $table.fechaPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cobradorId => $composableBuilder(
    column: $table.cobradorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaSync => $composableBuilder(
    column: $table.fechaSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
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

class $$PagosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagosTable> {
  $$PagosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientPaymentId => $composableBuilder(
    column: $table.clientPaymentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get cobroId =>
      $composableBuilder(column: $table.cobroId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get solicitudId => $composableBuilder(
    column: $table.solicitudId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get fechaPago =>
      $composableBuilder(column: $table.fechaPago, builder: (column) => column);

  GeneratedColumn<String> get cobradorId => $composableBuilder(
    column: $table.cobradorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get residenteId => $composableBuilder(
    column: $table.residenteId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaSync =>
      $composableBuilder(column: $table.fechaSync, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PagosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagosTable,
          Pago,
          $$PagosTableFilterComposer,
          $$PagosTableOrderingComposer,
          $$PagosTableAnnotationComposer,
          $$PagosTableCreateCompanionBuilder,
          $$PagosTableUpdateCompanionBuilder,
          (Pago, BaseReferences<_$AppDatabase, $PagosTable, Pago>),
          Pago,
          PrefetchHooks Function()
        > {
  $$PagosTableTableManager(_$AppDatabase db, $PagosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientPaymentId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> cobroId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> solicitudId = const Value.absent(),
                Value<int> monto = const Value.absent(),
                Value<String> fechaPago = const Value.absent(),
                Value<String> cobradorId = const Value.absent(),
                Value<String> residenteId = const Value.absent(),
                Value<DateTime?> fechaSync = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagosCompanion(
                id: id,
                clientPaymentId: clientPaymentId,
                tenantId: tenantId,
                cobroId: cobroId,
                serverId: serverId,
                solicitudId: solicitudId,
                monto: monto,
                fechaPago: fechaPago,
                cobradorId: cobradorId,
                residenteId: residenteId,
                fechaSync: fechaSync,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientPaymentId,
                required String tenantId,
                Value<String?> cobroId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String?> solicitudId = const Value.absent(),
                required int monto,
                required String fechaPago,
                required String cobradorId,
                required String residenteId,
                Value<DateTime?> fechaSync = const Value.absent(),
                required String syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PagosCompanion.insert(
                id: id,
                clientPaymentId: clientPaymentId,
                tenantId: tenantId,
                cobroId: cobroId,
                serverId: serverId,
                solicitudId: solicitudId,
                monto: monto,
                fechaPago: fechaPago,
                cobradorId: cobradorId,
                residenteId: residenteId,
                fechaSync: fechaSync,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PagosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagosTable,
      Pago,
      $$PagosTableFilterComposer,
      $$PagosTableOrderingComposer,
      $$PagosTableAnnotationComposer,
      $$PagosTableCreateCompanionBuilder,
      $$PagosTableUpdateCompanionBuilder,
      (Pago, BaseReferences<_$AppDatabase, $PagosTable, Pago>),
      Pago,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProyectosTableTableManager get proyectos =>
      $$ProyectosTableTableManager(_db, _db.proyectos);
  $$EtapasTableTableManager get etapas =>
      $$EtapasTableTableManager(_db, _db.etapas);
  $$CasasTableTableManager get casas =>
      $$CasasTableTableManager(_db, _db.casas);
  $$ResidentesTableTableManager get residentes =>
      $$ResidentesTableTableManager(_db, _db.residentes);
  $$TenenciasTableTableManager get tenencias =>
      $$TenenciasTableTableManager(_db, _db.tenencias);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$AsignacionesEtapaTableTableManager get asignacionesEtapa =>
      $$AsignacionesEtapaTableTableManager(_db, _db.asignacionesEtapa);
  $$TarifasTableTableManager get tarifas =>
      $$TarifasTableTableManager(_db, _db.tarifas);
  $$MontosPredefinidosTableTableManager get montosPredefinidos =>
      $$MontosPredefinidosTableTableManager(_db, _db.montosPredefinidos);
  $$PlanesDeCobroTableTableManager get planesDeCobro =>
      $$PlanesDeCobroTableTableManager(_db, _db.planesDeCobro);
  $$CobrosTableTableManager get cobros =>
      $$CobrosTableTableManager(_db, _db.cobros);
  $$PagosTableTableManager get pagos =>
      $$PagosTableTableManager(_db, _db.pagos);
}
