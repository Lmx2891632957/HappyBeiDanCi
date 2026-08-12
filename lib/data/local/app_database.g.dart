// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AudioPacksTable extends AudioPacks
    with TableInfo<$AudioPacksTable, AudioPackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordbookIdMeta = const VerificationMeta(
    'wordbookId',
  );
  @override
  late final GeneratedColumn<int> wordbookId = GeneratedColumn<int>(
    'wordbook_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSizeMeta = const VerificationMeta(
    'totalSize',
  );
  @override
  late final GeneratedColumn<int> totalSize = GeneratedColumn<int>(
    'total_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedSizeMeta = const VerificationMeta(
    'downloadedSize',
  );
  @override
  late final GeneratedColumn<int> downloadedSize = GeneratedColumn<int>(
    'downloaded_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileCountMeta = const VerificationMeta(
    'fileCount',
  );
  @override
  late final GeneratedColumn<int> fileCount = GeneratedColumn<int>(
    'file_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordbookId,
    version,
    status,
    totalSize,
    downloadedSize,
    fileCount,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_packs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioPackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wordbook_id')) {
      context.handle(
        _wordbookIdMeta,
        wordbookId.isAcceptableOrUnknown(data['wordbook_id']!, _wordbookIdMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_size')) {
      context.handle(
        _totalSizeMeta,
        totalSize.isAcceptableOrUnknown(data['total_size']!, _totalSizeMeta),
      );
    }
    if (data.containsKey('downloaded_size')) {
      context.handle(
        _downloadedSizeMeta,
        downloadedSize.isAcceptableOrUnknown(
          data['downloaded_size']!,
          _downloadedSizeMeta,
        ),
      );
    }
    if (data.containsKey('file_count')) {
      context.handle(
        _fileCountMeta,
        fileCount.isAcceptableOrUnknown(data['file_count']!, _fileCountMeta),
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
  Set<GeneratedColumn> get $primaryKey => {wordbookId};
  @override
  AudioPackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioPackRow(
      wordbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wordbook_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_size'],
      ),
      downloadedSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_size'],
      ),
      fileCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_count'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $AudioPacksTable createAlias(String alias) {
    return $AudioPacksTable(attachedDatabase, alias);
  }
}

class AudioPackRow extends DataClass implements Insertable<AudioPackRow> {
  final int wordbookId;
  final String version;
  final String status;
  final int? totalSize;
  final int? downloadedSize;
  final int? fileCount;
  final int? updatedAt;
  const AudioPackRow({
    required this.wordbookId,
    required this.version,
    required this.status,
    this.totalSize,
    this.downloadedSize,
    this.fileCount,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wordbook_id'] = Variable<int>(wordbookId);
    map['version'] = Variable<String>(version);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || totalSize != null) {
      map['total_size'] = Variable<int>(totalSize);
    }
    if (!nullToAbsent || downloadedSize != null) {
      map['downloaded_size'] = Variable<int>(downloadedSize);
    }
    if (!nullToAbsent || fileCount != null) {
      map['file_count'] = Variable<int>(fileCount);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  AudioPacksCompanion toCompanion(bool nullToAbsent) {
    return AudioPacksCompanion(
      wordbookId: Value(wordbookId),
      version: Value(version),
      status: Value(status),
      totalSize: totalSize == null && nullToAbsent
          ? const Value.absent()
          : Value(totalSize),
      downloadedSize: downloadedSize == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedSize),
      fileCount: fileCount == null && nullToAbsent
          ? const Value.absent()
          : Value(fileCount),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory AudioPackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioPackRow(
      wordbookId: serializer.fromJson<int>(json['wordbookId']),
      version: serializer.fromJson<String>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      totalSize: serializer.fromJson<int?>(json['totalSize']),
      downloadedSize: serializer.fromJson<int?>(json['downloadedSize']),
      fileCount: serializer.fromJson<int?>(json['fileCount']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordbookId': serializer.toJson<int>(wordbookId),
      'version': serializer.toJson<String>(version),
      'status': serializer.toJson<String>(status),
      'totalSize': serializer.toJson<int?>(totalSize),
      'downloadedSize': serializer.toJson<int?>(downloadedSize),
      'fileCount': serializer.toJson<int?>(fileCount),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  AudioPackRow copyWith({
    int? wordbookId,
    String? version,
    String? status,
    Value<int?> totalSize = const Value.absent(),
    Value<int?> downloadedSize = const Value.absent(),
    Value<int?> fileCount = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
  }) => AudioPackRow(
    wordbookId: wordbookId ?? this.wordbookId,
    version: version ?? this.version,
    status: status ?? this.status,
    totalSize: totalSize.present ? totalSize.value : this.totalSize,
    downloadedSize: downloadedSize.present
        ? downloadedSize.value
        : this.downloadedSize,
    fileCount: fileCount.present ? fileCount.value : this.fileCount,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  AudioPackRow copyWithCompanion(AudioPacksCompanion data) {
    return AudioPackRow(
      wordbookId: data.wordbookId.present
          ? data.wordbookId.value
          : this.wordbookId,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      totalSize: data.totalSize.present ? data.totalSize.value : this.totalSize,
      downloadedSize: data.downloadedSize.present
          ? data.downloadedSize.value
          : this.downloadedSize,
      fileCount: data.fileCount.present ? data.fileCount.value : this.fileCount,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioPackRow(')
          ..write('wordbookId: $wordbookId, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('totalSize: $totalSize, ')
          ..write('downloadedSize: $downloadedSize, ')
          ..write('fileCount: $fileCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    wordbookId,
    version,
    status,
    totalSize,
    downloadedSize,
    fileCount,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioPackRow &&
          other.wordbookId == this.wordbookId &&
          other.version == this.version &&
          other.status == this.status &&
          other.totalSize == this.totalSize &&
          other.downloadedSize == this.downloadedSize &&
          other.fileCount == this.fileCount &&
          other.updatedAt == this.updatedAt);
}

class AudioPacksCompanion extends UpdateCompanion<AudioPackRow> {
  final Value<int> wordbookId;
  final Value<String> version;
  final Value<String> status;
  final Value<int?> totalSize;
  final Value<int?> downloadedSize;
  final Value<int?> fileCount;
  final Value<int?> updatedAt;
  const AudioPacksCompanion({
    this.wordbookId = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.totalSize = const Value.absent(),
    this.downloadedSize = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AudioPacksCompanion.insert({
    this.wordbookId = const Value.absent(),
    required String version,
    required String status,
    this.totalSize = const Value.absent(),
    this.downloadedSize = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : version = Value(version),
       status = Value(status);
  static Insertable<AudioPackRow> custom({
    Expression<int>? wordbookId,
    Expression<String>? version,
    Expression<String>? status,
    Expression<int>? totalSize,
    Expression<int>? downloadedSize,
    Expression<int>? fileCount,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (wordbookId != null) 'wordbook_id': wordbookId,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (totalSize != null) 'total_size': totalSize,
      if (downloadedSize != null) 'downloaded_size': downloadedSize,
      if (fileCount != null) 'file_count': fileCount,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AudioPacksCompanion copyWith({
    Value<int>? wordbookId,
    Value<String>? version,
    Value<String>? status,
    Value<int?>? totalSize,
    Value<int?>? downloadedSize,
    Value<int?>? fileCount,
    Value<int?>? updatedAt,
  }) {
    return AudioPacksCompanion(
      wordbookId: wordbookId ?? this.wordbookId,
      version: version ?? this.version,
      status: status ?? this.status,
      totalSize: totalSize ?? this.totalSize,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      fileCount: fileCount ?? this.fileCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordbookId.present) {
      map['wordbook_id'] = Variable<int>(wordbookId.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalSize.present) {
      map['total_size'] = Variable<int>(totalSize.value);
    }
    if (downloadedSize.present) {
      map['downloaded_size'] = Variable<int>(downloadedSize.value);
    }
    if (fileCount.present) {
      map['file_count'] = Variable<int>(fileCount.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioPacksCompanion(')
          ..write('wordbookId: $wordbookId, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('totalSize: $totalSize, ')
          ..write('downloadedSize: $downloadedSize, ')
          ..write('fileCount: $fileCount, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyStatsTable extends DailyStats
    with TableInfo<$DailyStatsTable, DailyStatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newCountMeta = const VerificationMeta(
    'newCount',
  );
  @override
  late final GeneratedColumn<int> newCount = GeneratedColumn<int>(
    'new_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<int> completed = GeneratedColumn<int>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    newCount,
    reviewCount,
    correctCount,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('new_count')) {
      context.handle(
        _newCountMeta,
        newCount.isAcceptableOrUnknown(data['new_count']!, _newCountMeta),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DailyStatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStatRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      newCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_count'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $DailyStatsTable createAlias(String alias) {
    return $DailyStatsTable(attachedDatabase, alias);
  }
}

class DailyStatRow extends DataClass implements Insertable<DailyStatRow> {
  final String day;
  final int newCount;
  final int reviewCount;
  final int correctCount;
  final int completed;
  const DailyStatRow({
    required this.day,
    required this.newCount,
    required this.reviewCount,
    required this.correctCount,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['new_count'] = Variable<int>(newCount);
    map['review_count'] = Variable<int>(reviewCount);
    map['correct_count'] = Variable<int>(correctCount);
    map['completed'] = Variable<int>(completed);
    return map;
  }

  DailyStatsCompanion toCompanion(bool nullToAbsent) {
    return DailyStatsCompanion(
      day: Value(day),
      newCount: Value(newCount),
      reviewCount: Value(reviewCount),
      correctCount: Value(correctCount),
      completed: Value(completed),
    );
  }

  factory DailyStatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStatRow(
      day: serializer.fromJson<String>(json['day']),
      newCount: serializer.fromJson<int>(json['newCount']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      completed: serializer.fromJson<int>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'newCount': serializer.toJson<int>(newCount),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'completed': serializer.toJson<int>(completed),
    };
  }

  DailyStatRow copyWith({
    String? day,
    int? newCount,
    int? reviewCount,
    int? correctCount,
    int? completed,
  }) => DailyStatRow(
    day: day ?? this.day,
    newCount: newCount ?? this.newCount,
    reviewCount: reviewCount ?? this.reviewCount,
    correctCount: correctCount ?? this.correctCount,
    completed: completed ?? this.completed,
  );
  DailyStatRow copyWithCompanion(DailyStatsCompanion data) {
    return DailyStatRow(
      day: data.day.present ? data.day.value : this.day,
      newCount: data.newCount.present ? data.newCount.value : this.newCount,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatRow(')
          ..write('day: $day, ')
          ..write('newCount: $newCount, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(day, newCount, reviewCount, correctCount, completed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStatRow &&
          other.day == this.day &&
          other.newCount == this.newCount &&
          other.reviewCount == this.reviewCount &&
          other.correctCount == this.correctCount &&
          other.completed == this.completed);
}

class DailyStatsCompanion extends UpdateCompanion<DailyStatRow> {
  final Value<String> day;
  final Value<int> newCount;
  final Value<int> reviewCount;
  final Value<int> correctCount;
  final Value<int> completed;
  final Value<int> rowid;
  const DailyStatsCompanion({
    this.day = const Value.absent(),
    this.newCount = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyStatsCompanion.insert({
    required String day,
    this.newCount = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<DailyStatRow> custom({
    Expression<String>? day,
    Expression<int>? newCount,
    Expression<int>? reviewCount,
    Expression<int>? correctCount,
    Expression<int>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (newCount != null) 'new_count': newCount,
      if (reviewCount != null) 'review_count': reviewCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyStatsCompanion copyWith({
    Value<String>? day,
    Value<int>? newCount,
    Value<int>? reviewCount,
    Value<int>? correctCount,
    Value<int>? completed,
    Value<int>? rowid,
  }) {
    return DailyStatsCompanion(
      day: day ?? this.day,
      newCount: newCount ?? this.newCount,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (newCount.present) {
      map['new_count'] = Variable<int>(newCount.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (completed.present) {
      map['completed'] = Variable<int>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsCompanion(')
          ..write('day: $day, ')
          ..write('newCount: $newCount, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wordbookIdMeta = const VerificationMeta(
    'wordbookId',
  );
  @override
  late final GeneratedColumn<int> wordbookId = GeneratedColumn<int>(
    'wordbook_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<double> intervalDays = GeneratedColumn<double>(
    'interval_days',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    wordbookId,
    wordId,
    rating,
    reviewedAt,
    intervalDays,
    stability,
    difficulty,
    sessionId,
    sessionType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('wordbook_id')) {
      context.handle(
        _wordbookIdMeta,
        wordbookId.isAcceptableOrUnknown(data['wordbook_id']!, _wordbookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordbookIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
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
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      wordbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wordbook_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviewed_at'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interval_days'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLogRow extends DataClass implements Insertable<ReviewLogRow> {
  final int id;
  final int userId;
  final int wordbookId;
  final int wordId;
  final int rating;
  final int reviewedAt;
  final double? intervalDays;
  final double? stability;
  final double? difficulty;
  final String? sessionId;
  final String sessionType;
  const ReviewLogRow({
    required this.id,
    required this.userId,
    required this.wordbookId,
    required this.wordId,
    required this.rating,
    required this.reviewedAt,
    this.intervalDays,
    this.stability,
    this.difficulty,
    this.sessionId,
    required this.sessionType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['wordbook_id'] = Variable<int>(wordbookId);
    map['word_id'] = Variable<int>(wordId);
    map['rating'] = Variable<int>(rating);
    map['reviewed_at'] = Variable<int>(reviewedAt);
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<double>(intervalDays);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['session_type'] = Variable<String>(sessionType);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      wordbookId: Value(wordbookId),
      wordId: Value(wordId),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      sessionType: Value(sessionType),
    );
  }

  factory ReviewLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      wordbookId: serializer.fromJson<int>(json['wordbookId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewedAt: serializer.fromJson<int>(json['reviewedAt']),
      intervalDays: serializer.fromJson<double?>(json['intervalDays']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'wordbookId': serializer.toJson<int>(wordbookId),
      'wordId': serializer.toJson<int>(wordId),
      'rating': serializer.toJson<int>(rating),
      'reviewedAt': serializer.toJson<int>(reviewedAt),
      'intervalDays': serializer.toJson<double?>(intervalDays),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'sessionId': serializer.toJson<String?>(sessionId),
      'sessionType': serializer.toJson<String>(sessionType),
    };
  }

  ReviewLogRow copyWith({
    int? id,
    int? userId,
    int? wordbookId,
    int? wordId,
    int? rating,
    int? reviewedAt,
    Value<double?> intervalDays = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    String? sessionType,
  }) => ReviewLogRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    wordbookId: wordbookId ?? this.wordbookId,
    wordId: wordId ?? this.wordId,
    rating: rating ?? this.rating,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    sessionType: sessionType ?? this.sessionType,
  );
  ReviewLogRow copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLogRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      wordbookId: data.wordbookId.present
          ? data.wordbookId.value
          : this.wordbookId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('wordbookId: $wordbookId, ')
          ..write('wordId: $wordId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionType: $sessionType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    wordbookId,
    wordId,
    rating,
    reviewedAt,
    intervalDays,
    stability,
    difficulty,
    sessionId,
    sessionType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.wordbookId == this.wordbookId &&
          other.wordId == this.wordId &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt &&
          other.intervalDays == this.intervalDays &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.sessionId == this.sessionId &&
          other.sessionType == this.sessionType);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLogRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> wordbookId;
  final Value<int> wordId;
  final Value<int> rating;
  final Value<int> reviewedAt;
  final Value<double?> intervalDays;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<String?> sessionId;
  final Value<String> sessionType;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.wordbookId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sessionType = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    required int wordbookId,
    required int wordId,
    required int rating,
    required int reviewedAt,
    this.intervalDays = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.sessionId = const Value.absent(),
    required String sessionType,
  }) : wordbookId = Value(wordbookId),
       wordId = Value(wordId),
       rating = Value(rating),
       reviewedAt = Value(reviewedAt),
       sessionType = Value(sessionType);
  static Insertable<ReviewLogRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? wordbookId,
    Expression<int>? wordId,
    Expression<int>? rating,
    Expression<int>? reviewedAt,
    Expression<double>? intervalDays,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<String>? sessionId,
    Expression<String>? sessionType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (wordbookId != null) 'wordbook_id': wordbookId,
      if (wordId != null) 'word_id': wordId,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (sessionId != null) 'session_id': sessionId,
      if (sessionType != null) 'session_type': sessionType,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? wordbookId,
    Value<int>? wordId,
    Value<int>? rating,
    Value<int>? reviewedAt,
    Value<double?>? intervalDays,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<String?>? sessionId,
    Value<String>? sessionType,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      wordbookId: wordbookId ?? this.wordbookId,
      wordId: wordId ?? this.wordId,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      intervalDays: intervalDays ?? this.intervalDays,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      sessionId: sessionId ?? this.sessionId,
      sessionType: sessionType ?? this.sessionType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (wordbookId.present) {
      map['wordbook_id'] = Variable<int>(wordbookId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<int>(reviewedAt.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<double>(intervalDays.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('wordbookId: $wordbookId, ')
          ..write('wordId: $wordId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionType: $sessionType')
          ..write(')'))
        .toString();
  }
}

class $SessionItemsTable extends SessionItems
    with TableInfo<$SessionItemsTable, SessionItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requeueLeftMeta = const VerificationMeta(
    'requeueLeft',
  );
  @override
  late final GeneratedColumn<int> requeueLeft = GeneratedColumn<int>(
    'requeue_left',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, wordId, seq, requeueLeft];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('requeue_left')) {
      context.handle(
        _requeueLeftMeta,
        requeueLeft.isAcceptableOrUnknown(
          data['requeue_left']!,
          _requeueLeftMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, wordId};
  @override
  SessionItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionItemRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      requeueLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}requeue_left'],
      )!,
    );
  }

  @override
  $SessionItemsTable createAlias(String alias) {
    return $SessionItemsTable(attachedDatabase, alias);
  }
}

class SessionItemRow extends DataClass implements Insertable<SessionItemRow> {
  final String sessionId;
  final int wordId;
  final int seq;
  final int requeueLeft;
  const SessionItemRow({
    required this.sessionId,
    required this.wordId,
    required this.seq,
    required this.requeueLeft,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['word_id'] = Variable<int>(wordId);
    map['seq'] = Variable<int>(seq);
    map['requeue_left'] = Variable<int>(requeueLeft);
    return map;
  }

  SessionItemsCompanion toCompanion(bool nullToAbsent) {
    return SessionItemsCompanion(
      sessionId: Value(sessionId),
      wordId: Value(wordId),
      seq: Value(seq),
      requeueLeft: Value(requeueLeft),
    );
  }

  factory SessionItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionItemRow(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      seq: serializer.fromJson<int>(json['seq']),
      requeueLeft: serializer.fromJson<int>(json['requeueLeft']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'wordId': serializer.toJson<int>(wordId),
      'seq': serializer.toJson<int>(seq),
      'requeueLeft': serializer.toJson<int>(requeueLeft),
    };
  }

  SessionItemRow copyWith({
    String? sessionId,
    int? wordId,
    int? seq,
    int? requeueLeft,
  }) => SessionItemRow(
    sessionId: sessionId ?? this.sessionId,
    wordId: wordId ?? this.wordId,
    seq: seq ?? this.seq,
    requeueLeft: requeueLeft ?? this.requeueLeft,
  );
  SessionItemRow copyWithCompanion(SessionItemsCompanion data) {
    return SessionItemRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      seq: data.seq.present ? data.seq.value : this.seq,
      requeueLeft: data.requeueLeft.present
          ? data.requeueLeft.value
          : this.requeueLeft,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionItemRow(')
          ..write('sessionId: $sessionId, ')
          ..write('wordId: $wordId, ')
          ..write('seq: $seq, ')
          ..write('requeueLeft: $requeueLeft')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, wordId, seq, requeueLeft);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionItemRow &&
          other.sessionId == this.sessionId &&
          other.wordId == this.wordId &&
          other.seq == this.seq &&
          other.requeueLeft == this.requeueLeft);
}

class SessionItemsCompanion extends UpdateCompanion<SessionItemRow> {
  final Value<String> sessionId;
  final Value<int> wordId;
  final Value<int> seq;
  final Value<int> requeueLeft;
  final Value<int> rowid;
  const SessionItemsCompanion({
    this.sessionId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.seq = const Value.absent(),
    this.requeueLeft = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionItemsCompanion.insert({
    required String sessionId,
    required int wordId,
    required int seq,
    this.requeueLeft = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       wordId = Value(wordId),
       seq = Value(seq);
  static Insertable<SessionItemRow> custom({
    Expression<String>? sessionId,
    Expression<int>? wordId,
    Expression<int>? seq,
    Expression<int>? requeueLeft,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (wordId != null) 'word_id': wordId,
      if (seq != null) 'seq': seq,
      if (requeueLeft != null) 'requeue_left': requeueLeft,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionItemsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? wordId,
    Value<int>? seq,
    Value<int>? requeueLeft,
    Value<int>? rowid,
  }) {
    return SessionItemsCompanion(
      sessionId: sessionId ?? this.sessionId,
      wordId: wordId ?? this.wordId,
      seq: seq ?? this.seq,
      requeueLeft: requeueLeft ?? this.requeueLeft,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (requeueLeft.present) {
      map['requeue_left'] = Variable<int>(requeueLeft.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionItemsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('wordId: $wordId, ')
          ..write('seq: $seq, ')
          ..write('requeueLeft: $requeueLeft, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionType,
    createdAt,
    updatedAt,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
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
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final String sessionType;
  final int createdAt;
  final int updatedAt;
  final int position;
  const SessionRow({
    required this.id,
    required this.sessionType,
    required this.createdAt,
    required this.updatedAt,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_type'] = Variable<String>(sessionType);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['position'] = Variable<int>(position);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      sessionType: Value(sessionType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      position: Value(position),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionType': serializer.toJson<String>(sessionType),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'position': serializer.toJson<int>(position),
    };
  }

  SessionRow copyWith({
    String? id,
    String? sessionType,
    int? createdAt,
    int? updatedAt,
    int? position,
  }) => SessionRow(
    id: id ?? this.id,
    sessionType: sessionType ?? this.sessionType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    position: position ?? this.position,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('sessionType: $sessionType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionType, createdAt, updatedAt, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.sessionType == this.sessionType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.position == this.position);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<String> sessionType;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> position;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String sessionType,
    required int createdAt,
    required int updatedAt,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionType = Value(sessionType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<String>? sessionType,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionType != null) 'session_type': sessionType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionType,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      sessionType: sessionType ?? this.sessionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionType: $sessionType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
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
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserWordsTable extends UserWords
    with TableInfo<$UserWordsTable, UserWordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wordbookIdMeta = const VerificationMeta(
    'wordbookId',
  );
  @override
  late final GeneratedColumn<int> wordbookId = GeneratedColumn<int>(
    'wordbook_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewAtMeta = const VerificationMeta(
    'lastReviewAt',
  );
  @override
  late final GeneratedColumn<int> lastReviewAt = GeneratedColumn<int>(
    'last_review_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRatingMeta = const VerificationMeta(
    'lastRating',
  );
  @override
  late final GeneratedColumn<int> lastRating = GeneratedColumn<int>(
    'last_rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elapsedDaysMeta = const VerificationMeta(
    'elapsedDays',
  );
  @override
  late final GeneratedColumn<double> elapsedDays = GeneratedColumn<double>(
    'elapsed_days',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledDaysMeta = const VerificationMeta(
    'scheduledDays',
  );
  @override
  late final GeneratedColumn<double> scheduledDays = GeneratedColumn<double>(
    'scheduled_days',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    wordbookId,
    wordId,
    state,
    status,
    dueDate,
    stability,
    difficulty,
    reps,
    lapses,
    lastReviewAt,
    lastRating,
    elapsedDays,
    scheduledDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserWordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('wordbook_id')) {
      context.handle(
        _wordbookIdMeta,
        wordbookId.isAcceptableOrUnknown(data['wordbook_id']!, _wordbookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordbookIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('last_review_at')) {
      context.handle(
        _lastReviewAtMeta,
        lastReviewAt.isAcceptableOrUnknown(
          data['last_review_at']!,
          _lastReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('last_rating')) {
      context.handle(
        _lastRatingMeta,
        lastRating.isAcceptableOrUnknown(data['last_rating']!, _lastRatingMeta),
      );
    }
    if (data.containsKey('elapsed_days')) {
      context.handle(
        _elapsedDaysMeta,
        elapsedDays.isAcceptableOrUnknown(
          data['elapsed_days']!,
          _elapsedDaysMeta,
        ),
      );
    }
    if (data.containsKey('scheduled_days')) {
      context.handle(
        _scheduledDaysMeta,
        scheduledDays.isAcceptableOrUnknown(
          data['scheduled_days']!,
          _scheduledDaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, wordbookId, wordId};
  @override
  UserWordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWordRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      wordbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wordbook_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      lastReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_review_at'],
      ),
      lastRating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_rating'],
      ),
      elapsedDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elapsed_days'],
      ),
      scheduledDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scheduled_days'],
      ),
    );
  }

  @override
  $UserWordsTable createAlias(String alias) {
    return $UserWordsTable(attachedDatabase, alias);
  }
}

class UserWordRow extends DataClass implements Insertable<UserWordRow> {
  final int userId;
  final int wordbookId;
  final int wordId;
  final String state;
  final String status;
  final int? dueDate;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final int? lastReviewAt;
  final int? lastRating;
  final double? elapsedDays;
  final double? scheduledDays;
  const UserWordRow({
    required this.userId,
    required this.wordbookId,
    required this.wordId,
    required this.state,
    required this.status,
    this.dueDate,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    this.lastReviewAt,
    this.lastRating,
    this.elapsedDays,
    this.scheduledDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['wordbook_id'] = Variable<int>(wordbookId);
    map['word_id'] = Variable<int>(wordId);
    map['state'] = Variable<String>(state);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(dueDate);
    }
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || lastReviewAt != null) {
      map['last_review_at'] = Variable<int>(lastReviewAt);
    }
    if (!nullToAbsent || lastRating != null) {
      map['last_rating'] = Variable<int>(lastRating);
    }
    if (!nullToAbsent || elapsedDays != null) {
      map['elapsed_days'] = Variable<double>(elapsedDays);
    }
    if (!nullToAbsent || scheduledDays != null) {
      map['scheduled_days'] = Variable<double>(scheduledDays);
    }
    return map;
  }

  UserWordsCompanion toCompanion(bool nullToAbsent) {
    return UserWordsCompanion(
      userId: Value(userId),
      wordbookId: Value(wordbookId),
      wordId: Value(wordId),
      state: Value(state),
      status: Value(status),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      stability: Value(stability),
      difficulty: Value(difficulty),
      reps: Value(reps),
      lapses: Value(lapses),
      lastReviewAt: lastReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewAt),
      lastRating: lastRating == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRating),
      elapsedDays: elapsedDays == null && nullToAbsent
          ? const Value.absent()
          : Value(elapsedDays),
      scheduledDays: scheduledDays == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDays),
    );
  }

  factory UserWordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWordRow(
      userId: serializer.fromJson<int>(json['userId']),
      wordbookId: serializer.fromJson<int>(json['wordbookId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      state: serializer.fromJson<String>(json['state']),
      status: serializer.fromJson<String>(json['status']),
      dueDate: serializer.fromJson<int?>(json['dueDate']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      lastReviewAt: serializer.fromJson<int?>(json['lastReviewAt']),
      lastRating: serializer.fromJson<int?>(json['lastRating']),
      elapsedDays: serializer.fromJson<double?>(json['elapsedDays']),
      scheduledDays: serializer.fromJson<double?>(json['scheduledDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'wordbookId': serializer.toJson<int>(wordbookId),
      'wordId': serializer.toJson<int>(wordId),
      'state': serializer.toJson<String>(state),
      'status': serializer.toJson<String>(status),
      'dueDate': serializer.toJson<int?>(dueDate),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'lastReviewAt': serializer.toJson<int?>(lastReviewAt),
      'lastRating': serializer.toJson<int?>(lastRating),
      'elapsedDays': serializer.toJson<double?>(elapsedDays),
      'scheduledDays': serializer.toJson<double?>(scheduledDays),
    };
  }

  UserWordRow copyWith({
    int? userId,
    int? wordbookId,
    int? wordId,
    String? state,
    String? status,
    Value<int?> dueDate = const Value.absent(),
    double? stability,
    double? difficulty,
    int? reps,
    int? lapses,
    Value<int?> lastReviewAt = const Value.absent(),
    Value<int?> lastRating = const Value.absent(),
    Value<double?> elapsedDays = const Value.absent(),
    Value<double?> scheduledDays = const Value.absent(),
  }) => UserWordRow(
    userId: userId ?? this.userId,
    wordbookId: wordbookId ?? this.wordbookId,
    wordId: wordId ?? this.wordId,
    state: state ?? this.state,
    status: status ?? this.status,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    lastReviewAt: lastReviewAt.present ? lastReviewAt.value : this.lastReviewAt,
    lastRating: lastRating.present ? lastRating.value : this.lastRating,
    elapsedDays: elapsedDays.present ? elapsedDays.value : this.elapsedDays,
    scheduledDays: scheduledDays.present
        ? scheduledDays.value
        : this.scheduledDays,
  );
  UserWordRow copyWithCompanion(UserWordsCompanion data) {
    return UserWordRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      wordbookId: data.wordbookId.present
          ? data.wordbookId.value
          : this.wordbookId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      state: data.state.present ? data.state.value : this.state,
      status: data.status.present ? data.status.value : this.status,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      lastReviewAt: data.lastReviewAt.present
          ? data.lastReviewAt.value
          : this.lastReviewAt,
      lastRating: data.lastRating.present
          ? data.lastRating.value
          : this.lastRating,
      elapsedDays: data.elapsedDays.present
          ? data.elapsedDays.value
          : this.elapsedDays,
      scheduledDays: data.scheduledDays.present
          ? data.scheduledDays.value
          : this.scheduledDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWordRow(')
          ..write('userId: $userId, ')
          ..write('wordbookId: $wordbookId, ')
          ..write('wordId: $wordId, ')
          ..write('state: $state, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewAt: $lastReviewAt, ')
          ..write('lastRating: $lastRating, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    wordbookId,
    wordId,
    state,
    status,
    dueDate,
    stability,
    difficulty,
    reps,
    lapses,
    lastReviewAt,
    lastRating,
    elapsedDays,
    scheduledDays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWordRow &&
          other.userId == this.userId &&
          other.wordbookId == this.wordbookId &&
          other.wordId == this.wordId &&
          other.state == this.state &&
          other.status == this.status &&
          other.dueDate == this.dueDate &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.lastReviewAt == this.lastReviewAt &&
          other.lastRating == this.lastRating &&
          other.elapsedDays == this.elapsedDays &&
          other.scheduledDays == this.scheduledDays);
}

class UserWordsCompanion extends UpdateCompanion<UserWordRow> {
  final Value<int> userId;
  final Value<int> wordbookId;
  final Value<int> wordId;
  final Value<String> state;
  final Value<String> status;
  final Value<int?> dueDate;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int?> lastReviewAt;
  final Value<int?> lastRating;
  final Value<double?> elapsedDays;
  final Value<double?> scheduledDays;
  final Value<int> rowid;
  const UserWordsCompanion({
    this.userId = const Value.absent(),
    this.wordbookId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.state = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
    this.lastRating = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.scheduledDays = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserWordsCompanion.insert({
    this.userId = const Value.absent(),
    required int wordbookId,
    required int wordId,
    required String state,
    required String status,
    this.dueDate = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
    this.lastRating = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.scheduledDays = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : wordbookId = Value(wordbookId),
       wordId = Value(wordId),
       state = Value(state),
       status = Value(status);
  static Insertable<UserWordRow> custom({
    Expression<int>? userId,
    Expression<int>? wordbookId,
    Expression<int>? wordId,
    Expression<String>? state,
    Expression<String>? status,
    Expression<int>? dueDate,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? lastReviewAt,
    Expression<int>? lastRating,
    Expression<double>? elapsedDays,
    Expression<double>? scheduledDays,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (wordbookId != null) 'wordbook_id': wordbookId,
      if (wordId != null) 'word_id': wordId,
      if (state != null) 'state': state,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (lastReviewAt != null) 'last_review_at': lastReviewAt,
      if (lastRating != null) 'last_rating': lastRating,
      if (elapsedDays != null) 'elapsed_days': elapsedDays,
      if (scheduledDays != null) 'scheduled_days': scheduledDays,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserWordsCompanion copyWith({
    Value<int>? userId,
    Value<int>? wordbookId,
    Value<int>? wordId,
    Value<String>? state,
    Value<String>? status,
    Value<int?>? dueDate,
    Value<double>? stability,
    Value<double>? difficulty,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int?>? lastReviewAt,
    Value<int?>? lastRating,
    Value<double?>? elapsedDays,
    Value<double?>? scheduledDays,
    Value<int>? rowid,
  }) {
    return UserWordsCompanion(
      userId: userId ?? this.userId,
      wordbookId: wordbookId ?? this.wordbookId,
      wordId: wordId ?? this.wordId,
      state: state ?? this.state,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      lastRating: lastRating ?? this.lastRating,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (wordbookId.present) {
      map['wordbook_id'] = Variable<int>(wordbookId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (lastReviewAt.present) {
      map['last_review_at'] = Variable<int>(lastReviewAt.value);
    }
    if (lastRating.present) {
      map['last_rating'] = Variable<int>(lastRating.value);
    }
    if (elapsedDays.present) {
      map['elapsed_days'] = Variable<double>(elapsedDays.value);
    }
    if (scheduledDays.present) {
      map['scheduled_days'] = Variable<double>(scheduledDays.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWordsCompanion(')
          ..write('userId: $userId, ')
          ..write('wordbookId: $wordbookId, ')
          ..write('wordId: $wordId, ')
          ..write('state: $state, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewAt: $lastReviewAt, ')
          ..write('lastRating: $lastRating, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordbookItemsTable extends WordbookItems
    with TableInfo<$WordbookItemsTable, WordbookItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordbookItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordbookIdMeta = const VerificationMeta(
    'wordbookId',
  );
  @override
  late final GeneratedColumn<int> wordbookId = GeneratedColumn<int>(
    'wordbook_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shuffledMeta = const VerificationMeta(
    'shuffled',
  );
  @override
  late final GeneratedColumn<int> shuffled = GeneratedColumn<int>(
    'shuffled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSkippedMeta = const VerificationMeta(
    'isSkipped',
  );
  @override
  late final GeneratedColumn<bool> isSkipped = GeneratedColumn<bool>(
    'is_skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordbookId,
    wordId,
    seq,
    shuffled,
    isSkipped,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wordbook_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordbookItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wordbook_id')) {
      context.handle(
        _wordbookIdMeta,
        wordbookId.isAcceptableOrUnknown(data['wordbook_id']!, _wordbookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordbookIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('shuffled')) {
      context.handle(
        _shuffledMeta,
        shuffled.isAcceptableOrUnknown(data['shuffled']!, _shuffledMeta),
      );
    } else if (isInserting) {
      context.missing(_shuffledMeta);
    }
    if (data.containsKey('is_skipped')) {
      context.handle(
        _isSkippedMeta,
        isSkipped.isAcceptableOrUnknown(data['is_skipped']!, _isSkippedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordbookId, wordId};
  @override
  WordbookItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordbookItemRow(
      wordbookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wordbook_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      shuffled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shuffled'],
      )!,
      isSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_skipped'],
      )!,
    );
  }

  @override
  $WordbookItemsTable createAlias(String alias) {
    return $WordbookItemsTable(attachedDatabase, alias);
  }
}

class WordbookItemRow extends DataClass implements Insertable<WordbookItemRow> {
  final int wordbookId;
  final int wordId;
  final int seq;
  final int shuffled;
  final bool isSkipped;
  const WordbookItemRow({
    required this.wordbookId,
    required this.wordId,
    required this.seq,
    required this.shuffled,
    required this.isSkipped,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wordbook_id'] = Variable<int>(wordbookId);
    map['word_id'] = Variable<int>(wordId);
    map['seq'] = Variable<int>(seq);
    map['shuffled'] = Variable<int>(shuffled);
    map['is_skipped'] = Variable<bool>(isSkipped);
    return map;
  }

  WordbookItemsCompanion toCompanion(bool nullToAbsent) {
    return WordbookItemsCompanion(
      wordbookId: Value(wordbookId),
      wordId: Value(wordId),
      seq: Value(seq),
      shuffled: Value(shuffled),
      isSkipped: Value(isSkipped),
    );
  }

  factory WordbookItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordbookItemRow(
      wordbookId: serializer.fromJson<int>(json['wordbookId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      seq: serializer.fromJson<int>(json['seq']),
      shuffled: serializer.fromJson<int>(json['shuffled']),
      isSkipped: serializer.fromJson<bool>(json['isSkipped']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordbookId': serializer.toJson<int>(wordbookId),
      'wordId': serializer.toJson<int>(wordId),
      'seq': serializer.toJson<int>(seq),
      'shuffled': serializer.toJson<int>(shuffled),
      'isSkipped': serializer.toJson<bool>(isSkipped),
    };
  }

  WordbookItemRow copyWith({
    int? wordbookId,
    int? wordId,
    int? seq,
    int? shuffled,
    bool? isSkipped,
  }) => WordbookItemRow(
    wordbookId: wordbookId ?? this.wordbookId,
    wordId: wordId ?? this.wordId,
    seq: seq ?? this.seq,
    shuffled: shuffled ?? this.shuffled,
    isSkipped: isSkipped ?? this.isSkipped,
  );
  WordbookItemRow copyWithCompanion(WordbookItemsCompanion data) {
    return WordbookItemRow(
      wordbookId: data.wordbookId.present
          ? data.wordbookId.value
          : this.wordbookId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      seq: data.seq.present ? data.seq.value : this.seq,
      shuffled: data.shuffled.present ? data.shuffled.value : this.shuffled,
      isSkipped: data.isSkipped.present ? data.isSkipped.value : this.isSkipped,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordbookItemRow(')
          ..write('wordbookId: $wordbookId, ')
          ..write('wordId: $wordId, ')
          ..write('seq: $seq, ')
          ..write('shuffled: $shuffled, ')
          ..write('isSkipped: $isSkipped')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordbookId, wordId, seq, shuffled, isSkipped);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordbookItemRow &&
          other.wordbookId == this.wordbookId &&
          other.wordId == this.wordId &&
          other.seq == this.seq &&
          other.shuffled == this.shuffled &&
          other.isSkipped == this.isSkipped);
}

class WordbookItemsCompanion extends UpdateCompanion<WordbookItemRow> {
  final Value<int> wordbookId;
  final Value<int> wordId;
  final Value<int> seq;
  final Value<int> shuffled;
  final Value<bool> isSkipped;
  final Value<int> rowid;
  const WordbookItemsCompanion({
    this.wordbookId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.seq = const Value.absent(),
    this.shuffled = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordbookItemsCompanion.insert({
    required int wordbookId,
    required int wordId,
    required int seq,
    required int shuffled,
    this.isSkipped = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : wordbookId = Value(wordbookId),
       wordId = Value(wordId),
       seq = Value(seq),
       shuffled = Value(shuffled);
  static Insertable<WordbookItemRow> custom({
    Expression<int>? wordbookId,
    Expression<int>? wordId,
    Expression<int>? seq,
    Expression<int>? shuffled,
    Expression<bool>? isSkipped,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordbookId != null) 'wordbook_id': wordbookId,
      if (wordId != null) 'word_id': wordId,
      if (seq != null) 'seq': seq,
      if (shuffled != null) 'shuffled': shuffled,
      if (isSkipped != null) 'is_skipped': isSkipped,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordbookItemsCompanion copyWith({
    Value<int>? wordbookId,
    Value<int>? wordId,
    Value<int>? seq,
    Value<int>? shuffled,
    Value<bool>? isSkipped,
    Value<int>? rowid,
  }) {
    return WordbookItemsCompanion(
      wordbookId: wordbookId ?? this.wordbookId,
      wordId: wordId ?? this.wordId,
      seq: seq ?? this.seq,
      shuffled: shuffled ?? this.shuffled,
      isSkipped: isSkipped ?? this.isSkipped,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordbookId.present) {
      map['wordbook_id'] = Variable<int>(wordbookId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (shuffled.present) {
      map['shuffled'] = Variable<int>(shuffled.value);
    }
    if (isSkipped.present) {
      map['is_skipped'] = Variable<bool>(isSkipped.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordbookItemsCompanion(')
          ..write('wordbookId: $wordbookId, ')
          ..write('wordId: $wordId, ')
          ..write('seq: $seq, ')
          ..write('shuffled: $shuffled, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordbooksTable extends Wordbooks
    with TableInfo<$WordbooksTable, WordbookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordbooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCountMeta = const VerificationMeta(
    'totalCount',
  );
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
    'total_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
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
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    level,
    totalCount,
    source,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wordbooks';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordbookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('total_count')) {
      context.handle(
        _totalCountMeta,
        totalCount.isAcceptableOrUnknown(data['total_count']!, _totalCountMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCountMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
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
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordbookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordbookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      totalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_count'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WordbooksTable createAlias(String alias) {
    return $WordbooksTable(attachedDatabase, alias);
  }
}

class WordbookRow extends DataClass implements Insertable<WordbookRow> {
  final int id;
  final String name;
  final String level;
  final int totalCount;
  final String source;
  final int sortOrder;
  final int createdAt;
  const WordbookRow({
    required this.id,
    required this.name,
    required this.level,
    required this.totalCount,
    required this.source,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['level'] = Variable<String>(level);
    map['total_count'] = Variable<int>(totalCount);
    map['source'] = Variable<String>(source);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  WordbooksCompanion toCompanion(bool nullToAbsent) {
    return WordbooksCompanion(
      id: Value(id),
      name: Value(name),
      level: Value(level),
      totalCount: Value(totalCount),
      source: Value(source),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory WordbookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordbookRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      level: serializer.fromJson<String>(json['level']),
      totalCount: serializer.fromJson<int>(json['totalCount']),
      source: serializer.fromJson<String>(json['source']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'level': serializer.toJson<String>(level),
      'totalCount': serializer.toJson<int>(totalCount),
      'source': serializer.toJson<String>(source),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  WordbookRow copyWith({
    int? id,
    String? name,
    String? level,
    int? totalCount,
    String? source,
    int? sortOrder,
    int? createdAt,
  }) => WordbookRow(
    id: id ?? this.id,
    name: name ?? this.name,
    level: level ?? this.level,
    totalCount: totalCount ?? this.totalCount,
    source: source ?? this.source,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  WordbookRow copyWithCompanion(WordbooksCompanion data) {
    return WordbookRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      level: data.level.present ? data.level.value : this.level,
      totalCount: data.totalCount.present
          ? data.totalCount.value
          : this.totalCount,
      source: data.source.present ? data.source.value : this.source,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordbookRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('totalCount: $totalCount, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, level, totalCount, source, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordbookRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.level == this.level &&
          other.totalCount == this.totalCount &&
          other.source == this.source &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class WordbooksCompanion extends UpdateCompanion<WordbookRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> level;
  final Value<int> totalCount;
  final Value<String> source;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  const WordbooksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.level = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.source = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WordbooksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String level,
    required int totalCount,
    required String source,
    this.sortOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       level = Value(level),
       totalCount = Value(totalCount),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<WordbookRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? level,
    Expression<int>? totalCount,
    Expression<String>? source,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (level != null) 'level': level,
      if (totalCount != null) 'total_count': totalCount,
      if (source != null) 'source': source,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WordbooksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? level,
    Value<int>? totalCount,
    Value<String>? source,
    Value<int>? sortOrder,
    Value<int>? createdAt,
  }) {
    return WordbooksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      totalCount: totalCount ?? this.totalCount,
      source: source ?? this.source,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordbooksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('totalCount: $totalCount, ')
          ..write('source: $source, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, WordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phoneticMeta = const VerificationMeta(
    'phonetic',
  );
  @override
  late final GeneratedColumn<String> phonetic = GeneratedColumn<String>(
    'phonetic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneticUkMeta = const VerificationMeta(
    'phoneticUk',
  );
  @override
  late final GeneratedColumn<String> phoneticUk = GeneratedColumn<String>(
    'phonetic_uk',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningsMeta = const VerificationMeta(
    'meanings',
  );
  @override
  late final GeneratedColumn<String> meanings = GeneratedColumn<String>(
    'meanings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examplesMeta = const VerificationMeta(
    'examples',
  );
  @override
  late final GeneratedColumn<String> examples = GeneratedColumn<String>(
    'examples',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootAffixMeta = const VerificationMeta(
    'rootAffix',
  );
  @override
  late final GeneratedColumn<String> rootAffix = GeneratedColumn<String>(
    'root_affix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioKeyMeta = const VerificationMeta(
    'audioKey',
  );
  @override
  late final GeneratedColumn<String> audioKey = GeneratedColumn<String>(
    'audio_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    phonetic,
    phoneticUk,
    meanings,
    examples,
    frequency,
    rootAffix,
    audioKey,
    audioUrl,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('phonetic')) {
      context.handle(
        _phoneticMeta,
        phonetic.isAcceptableOrUnknown(data['phonetic']!, _phoneticMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneticMeta);
    }
    if (data.containsKey('phonetic_uk')) {
      context.handle(
        _phoneticUkMeta,
        phoneticUk.isAcceptableOrUnknown(data['phonetic_uk']!, _phoneticUkMeta),
      );
    }
    if (data.containsKey('meanings')) {
      context.handle(
        _meaningsMeta,
        meanings.isAcceptableOrUnknown(data['meanings']!, _meaningsMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningsMeta);
    }
    if (data.containsKey('examples')) {
      context.handle(
        _examplesMeta,
        examples.isAcceptableOrUnknown(data['examples']!, _examplesMeta),
      );
    } else if (isInserting) {
      context.missing(_examplesMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('root_affix')) {
      context.handle(
        _rootAffixMeta,
        rootAffix.isAcceptableOrUnknown(data['root_affix']!, _rootAffixMeta),
      );
    }
    if (data.containsKey('audio_key')) {
      context.handle(
        _audioKeyMeta,
        audioKey.isAcceptableOrUnknown(data['audio_key']!, _audioKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_audioKeyMeta);
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
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
  WordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      phonetic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic'],
      )!,
      phoneticUk: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic_uk'],
      ),
      meanings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meanings'],
      )!,
      examples: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examples'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      rootAffix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_affix'],
      ),
      audioKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_key'],
      )!,
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class WordRow extends DataClass implements Insertable<WordRow> {
  final int id;
  final String word;
  final String phonetic;
  final String? phoneticUk;
  final String meanings;
  final String examples;
  final String frequency;
  final String? rootAffix;
  final String audioKey;
  final String? audioUrl;
  final int createdAt;
  const WordRow({
    required this.id,
    required this.word,
    required this.phonetic,
    this.phoneticUk,
    required this.meanings,
    required this.examples,
    required this.frequency,
    this.rootAffix,
    required this.audioKey,
    this.audioUrl,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['phonetic'] = Variable<String>(phonetic);
    if (!nullToAbsent || phoneticUk != null) {
      map['phonetic_uk'] = Variable<String>(phoneticUk);
    }
    map['meanings'] = Variable<String>(meanings);
    map['examples'] = Variable<String>(examples);
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || rootAffix != null) {
      map['root_affix'] = Variable<String>(rootAffix);
    }
    map['audio_key'] = Variable<String>(audioKey);
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      word: Value(word),
      phonetic: Value(phonetic),
      phoneticUk: phoneticUk == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneticUk),
      meanings: Value(meanings),
      examples: Value(examples),
      frequency: Value(frequency),
      rootAffix: rootAffix == null && nullToAbsent
          ? const Value.absent()
          : Value(rootAffix),
      audioKey: Value(audioKey),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      createdAt: Value(createdAt),
    );
  }

  factory WordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRow(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      phonetic: serializer.fromJson<String>(json['phonetic']),
      phoneticUk: serializer.fromJson<String?>(json['phoneticUk']),
      meanings: serializer.fromJson<String>(json['meanings']),
      examples: serializer.fromJson<String>(json['examples']),
      frequency: serializer.fromJson<String>(json['frequency']),
      rootAffix: serializer.fromJson<String?>(json['rootAffix']),
      audioKey: serializer.fromJson<String>(json['audioKey']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'phonetic': serializer.toJson<String>(phonetic),
      'phoneticUk': serializer.toJson<String?>(phoneticUk),
      'meanings': serializer.toJson<String>(meanings),
      'examples': serializer.toJson<String>(examples),
      'frequency': serializer.toJson<String>(frequency),
      'rootAffix': serializer.toJson<String?>(rootAffix),
      'audioKey': serializer.toJson<String>(audioKey),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  WordRow copyWith({
    int? id,
    String? word,
    String? phonetic,
    Value<String?> phoneticUk = const Value.absent(),
    String? meanings,
    String? examples,
    String? frequency,
    Value<String?> rootAffix = const Value.absent(),
    String? audioKey,
    Value<String?> audioUrl = const Value.absent(),
    int? createdAt,
  }) => WordRow(
    id: id ?? this.id,
    word: word ?? this.word,
    phonetic: phonetic ?? this.phonetic,
    phoneticUk: phoneticUk.present ? phoneticUk.value : this.phoneticUk,
    meanings: meanings ?? this.meanings,
    examples: examples ?? this.examples,
    frequency: frequency ?? this.frequency,
    rootAffix: rootAffix.present ? rootAffix.value : this.rootAffix,
    audioKey: audioKey ?? this.audioKey,
    audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
    createdAt: createdAt ?? this.createdAt,
  );
  WordRow copyWithCompanion(WordsCompanion data) {
    return WordRow(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      phonetic: data.phonetic.present ? data.phonetic.value : this.phonetic,
      phoneticUk: data.phoneticUk.present
          ? data.phoneticUk.value
          : this.phoneticUk,
      meanings: data.meanings.present ? data.meanings.value : this.meanings,
      examples: data.examples.present ? data.examples.value : this.examples,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      rootAffix: data.rootAffix.present ? data.rootAffix.value : this.rootAffix,
      audioKey: data.audioKey.present ? data.audioKey.value : this.audioKey,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRow(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phonetic: $phonetic, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('meanings: $meanings, ')
          ..write('examples: $examples, ')
          ..write('frequency: $frequency, ')
          ..write('rootAffix: $rootAffix, ')
          ..write('audioKey: $audioKey, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    word,
    phonetic,
    phoneticUk,
    meanings,
    examples,
    frequency,
    rootAffix,
    audioKey,
    audioUrl,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRow &&
          other.id == this.id &&
          other.word == this.word &&
          other.phonetic == this.phonetic &&
          other.phoneticUk == this.phoneticUk &&
          other.meanings == this.meanings &&
          other.examples == this.examples &&
          other.frequency == this.frequency &&
          other.rootAffix == this.rootAffix &&
          other.audioKey == this.audioKey &&
          other.audioUrl == this.audioUrl &&
          other.createdAt == this.createdAt);
}

class WordsCompanion extends UpdateCompanion<WordRow> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> phonetic;
  final Value<String?> phoneticUk;
  final Value<String> meanings;
  final Value<String> examples;
  final Value<String> frequency;
  final Value<String?> rootAffix;
  final Value<String> audioKey;
  final Value<String?> audioUrl;
  final Value<int> createdAt;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.phoneticUk = const Value.absent(),
    this.meanings = const Value.absent(),
    this.examples = const Value.absent(),
    this.frequency = const Value.absent(),
    this.rootAffix = const Value.absent(),
    this.audioKey = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String phonetic,
    this.phoneticUk = const Value.absent(),
    required String meanings,
    required String examples,
    required String frequency,
    this.rootAffix = const Value.absent(),
    required String audioKey,
    this.audioUrl = const Value.absent(),
    required int createdAt,
  }) : word = Value(word),
       phonetic = Value(phonetic),
       meanings = Value(meanings),
       examples = Value(examples),
       frequency = Value(frequency),
       audioKey = Value(audioKey),
       createdAt = Value(createdAt);
  static Insertable<WordRow> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? phonetic,
    Expression<String>? phoneticUk,
    Expression<String>? meanings,
    Expression<String>? examples,
    Expression<String>? frequency,
    Expression<String>? rootAffix,
    Expression<String>? audioKey,
    Expression<String>? audioUrl,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (phonetic != null) 'phonetic': phonetic,
      if (phoneticUk != null) 'phonetic_uk': phoneticUk,
      if (meanings != null) 'meanings': meanings,
      if (examples != null) 'examples': examples,
      if (frequency != null) 'frequency': frequency,
      if (rootAffix != null) 'root_affix': rootAffix,
      if (audioKey != null) 'audio_key': audioKey,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String>? phonetic,
    Value<String?>? phoneticUk,
    Value<String>? meanings,
    Value<String>? examples,
    Value<String>? frequency,
    Value<String?>? rootAffix,
    Value<String>? audioKey,
    Value<String?>? audioUrl,
    Value<int>? createdAt,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      phoneticUk: phoneticUk ?? this.phoneticUk,
      meanings: meanings ?? this.meanings,
      examples: examples ?? this.examples,
      frequency: frequency ?? this.frequency,
      rootAffix: rootAffix ?? this.rootAffix,
      audioKey: audioKey ?? this.audioKey,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (phonetic.present) {
      map['phonetic'] = Variable<String>(phonetic.value);
    }
    if (phoneticUk.present) {
      map['phonetic_uk'] = Variable<String>(phoneticUk.value);
    }
    if (meanings.present) {
      map['meanings'] = Variable<String>(meanings.value);
    }
    if (examples.present) {
      map['examples'] = Variable<String>(examples.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (rootAffix.present) {
      map['root_affix'] = Variable<String>(rootAffix.value);
    }
    if (audioKey.present) {
      map['audio_key'] = Variable<String>(audioKey.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('phonetic: $phonetic, ')
          ..write('phoneticUk: $phoneticUk, ')
          ..write('meanings: $meanings, ')
          ..write('examples: $examples, ')
          ..write('frequency: $frequency, ')
          ..write('rootAffix: $rootAffix, ')
          ..write('audioKey: $audioKey, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AudioPacksTable audioPacks = $AudioPacksTable(this);
  late final $DailyStatsTable dailyStats = $DailyStatsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $SessionItemsTable sessionItems = $SessionItemsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $UserWordsTable userWords = $UserWordsTable(this);
  late final $WordbookItemsTable wordbookItems = $WordbookItemsTable(this);
  late final $WordbooksTable wordbooks = $WordbooksTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final Index idxReviewLogsTime = Index(
    'idx_review_logs_time',
    'CREATE INDEX idx_review_logs_time ON review_logs (reviewed_at)',
  );
  late final Index idxSessionItems = Index(
    'idx_session_items',
    'CREATE INDEX idx_session_items ON session_items (session_id, seq)',
  );
  late final Index idxUserWordsDue = Index(
    'idx_user_words_due',
    'CREATE INDEX idx_user_words_due ON user_words (status, due_date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    audioPacks,
    dailyStats,
    reviewLogs,
    sessionItems,
    sessions,
    settings,
    userWords,
    wordbookItems,
    wordbooks,
    words,
    idxReviewLogsTime,
    idxSessionItems,
    idxUserWordsDue,
  ];
}

typedef $$AudioPacksTableCreateCompanionBuilder =
    AudioPacksCompanion Function({
      Value<int> wordbookId,
      required String version,
      required String status,
      Value<int?> totalSize,
      Value<int?> downloadedSize,
      Value<int?> fileCount,
      Value<int?> updatedAt,
    });
typedef $$AudioPacksTableUpdateCompanionBuilder =
    AudioPacksCompanion Function({
      Value<int> wordbookId,
      Value<String> version,
      Value<String> status,
      Value<int?> totalSize,
      Value<int?> downloadedSize,
      Value<int?> fileCount,
      Value<int?> updatedAt,
    });

class $$AudioPacksTableFilterComposer
    extends Composer<_$AppDatabase, $AudioPacksTable> {
  $$AudioPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedSize => $composableBuilder(
    column: $table.downloadedSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AudioPacksTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioPacksTable> {
  $$AudioPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSize => $composableBuilder(
    column: $table.totalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedSize => $composableBuilder(
    column: $table.downloadedSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AudioPacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioPacksTable> {
  $$AudioPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalSize =>
      $composableBuilder(column: $table.totalSize, builder: (column) => column);

  GeneratedColumn<int> get downloadedSize => $composableBuilder(
    column: $table.downloadedSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileCount =>
      $composableBuilder(column: $table.fileCount, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AudioPacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AudioPacksTable,
          AudioPackRow,
          $$AudioPacksTableFilterComposer,
          $$AudioPacksTableOrderingComposer,
          $$AudioPacksTableAnnotationComposer,
          $$AudioPacksTableCreateCompanionBuilder,
          $$AudioPacksTableUpdateCompanionBuilder,
          (
            AudioPackRow,
            BaseReferences<_$AppDatabase, $AudioPacksTable, AudioPackRow>,
          ),
          AudioPackRow,
          PrefetchHooks Function()
        > {
  $$AudioPacksTableTableManager(_$AppDatabase db, $AudioPacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioPacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordbookId = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> totalSize = const Value.absent(),
                Value<int?> downloadedSize = const Value.absent(),
                Value<int?> fileCount = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
              }) => AudioPacksCompanion(
                wordbookId: wordbookId,
                version: version,
                status: status,
                totalSize: totalSize,
                downloadedSize: downloadedSize,
                fileCount: fileCount,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> wordbookId = const Value.absent(),
                required String version,
                required String status,
                Value<int?> totalSize = const Value.absent(),
                Value<int?> downloadedSize = const Value.absent(),
                Value<int?> fileCount = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
              }) => AudioPacksCompanion.insert(
                wordbookId: wordbookId,
                version: version,
                status: status,
                totalSize: totalSize,
                downloadedSize: downloadedSize,
                fileCount: fileCount,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AudioPacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AudioPacksTable,
      AudioPackRow,
      $$AudioPacksTableFilterComposer,
      $$AudioPacksTableOrderingComposer,
      $$AudioPacksTableAnnotationComposer,
      $$AudioPacksTableCreateCompanionBuilder,
      $$AudioPacksTableUpdateCompanionBuilder,
      (
        AudioPackRow,
        BaseReferences<_$AppDatabase, $AudioPacksTable, AudioPackRow>,
      ),
      AudioPackRow,
      PrefetchHooks Function()
    >;
typedef $$DailyStatsTableCreateCompanionBuilder =
    DailyStatsCompanion Function({
      required String day,
      Value<int> newCount,
      Value<int> reviewCount,
      Value<int> correctCount,
      Value<int> completed,
      Value<int> rowid,
    });
typedef $$DailyStatsTableUpdateCompanionBuilder =
    DailyStatsCompanion Function({
      Value<String> day,
      Value<int> newCount,
      Value<int> reviewCount,
      Value<int> correctCount,
      Value<int> completed,
      Value<int> rowid,
    });

class $$DailyStatsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newCount => $composableBuilder(
    column: $table.newCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newCount => $composableBuilder(
    column: $table.newCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStatsTable> {
  $$DailyStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get newCount =>
      $composableBuilder(column: $table.newCount, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$DailyStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyStatsTable,
          DailyStatRow,
          $$DailyStatsTableFilterComposer,
          $$DailyStatsTableOrderingComposer,
          $$DailyStatsTableAnnotationComposer,
          $$DailyStatsTableCreateCompanionBuilder,
          $$DailyStatsTableUpdateCompanionBuilder,
          (
            DailyStatRow,
            BaseReferences<_$AppDatabase, $DailyStatsTable, DailyStatRow>,
          ),
          DailyStatRow,
          PrefetchHooks Function()
        > {
  $$DailyStatsTableTableManager(_$AppDatabase db, $DailyStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<int> newCount = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion(
                day: day,
                newCount: newCount,
                reviewCount: reviewCount,
                correctCount: correctCount,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                Value<int> newCount = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion.insert(
                day: day,
                newCount: newCount,
                reviewCount: reviewCount,
                correctCount: correctCount,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyStatsTable,
      DailyStatRow,
      $$DailyStatsTableFilterComposer,
      $$DailyStatsTableOrderingComposer,
      $$DailyStatsTableAnnotationComposer,
      $$DailyStatsTableCreateCompanionBuilder,
      $$DailyStatsTableUpdateCompanionBuilder,
      (
        DailyStatRow,
        BaseReferences<_$AppDatabase, $DailyStatsTable, DailyStatRow>,
      ),
      DailyStatRow,
      PrefetchHooks Function()
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      Value<int> userId,
      required int wordbookId,
      required int wordId,
      required int rating,
      required int reviewedAt,
      Value<double?> intervalDays,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<String?> sessionId,
      required String sessionType,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> wordbookId,
      Value<int> wordId,
      Value<int> rating,
      Value<int> reviewedAt,
      Value<double?> intervalDays,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<String?> sessionId,
      Value<String> sessionType,
    });

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLogRow,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (
            ReviewLogRow,
            BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLogRow>,
          ),
          ReviewLogRow,
          PrefetchHooks Function()
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> wordbookId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> reviewedAt = const Value.absent(),
                Value<double?> intervalDays = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                userId: userId,
                wordbookId: wordbookId,
                wordId: wordId,
                rating: rating,
                reviewedAt: reviewedAt,
                intervalDays: intervalDays,
                stability: stability,
                difficulty: difficulty,
                sessionId: sessionId,
                sessionType: sessionType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                required int wordbookId,
                required int wordId,
                required int rating,
                required int reviewedAt,
                Value<double?> intervalDays = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                required String sessionType,
              }) => ReviewLogsCompanion.insert(
                id: id,
                userId: userId,
                wordbookId: wordbookId,
                wordId: wordId,
                rating: rating,
                reviewedAt: reviewedAt,
                intervalDays: intervalDays,
                stability: stability,
                difficulty: difficulty,
                sessionId: sessionId,
                sessionType: sessionType,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLogRow,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (
        ReviewLogRow,
        BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLogRow>,
      ),
      ReviewLogRow,
      PrefetchHooks Function()
    >;
typedef $$SessionItemsTableCreateCompanionBuilder =
    SessionItemsCompanion Function({
      required String sessionId,
      required int wordId,
      required int seq,
      Value<int> requeueLeft,
      Value<int> rowid,
    });
typedef $$SessionItemsTableUpdateCompanionBuilder =
    SessionItemsCompanion Function({
      Value<String> sessionId,
      Value<int> wordId,
      Value<int> seq,
      Value<int> requeueLeft,
      Value<int> rowid,
    });

class $$SessionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionItemsTable> {
  $$SessionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requeueLeft => $composableBuilder(
    column: $table.requeueLeft,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionItemsTable> {
  $$SessionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requeueLeft => $composableBuilder(
    column: $table.requeueLeft,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionItemsTable> {
  $$SessionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get requeueLeft => $composableBuilder(
    column: $table.requeueLeft,
    builder: (column) => column,
  );
}

class $$SessionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionItemsTable,
          SessionItemRow,
          $$SessionItemsTableFilterComposer,
          $$SessionItemsTableOrderingComposer,
          $$SessionItemsTableAnnotationComposer,
          $$SessionItemsTableCreateCompanionBuilder,
          $$SessionItemsTableUpdateCompanionBuilder,
          (
            SessionItemRow,
            BaseReferences<_$AppDatabase, $SessionItemsTable, SessionItemRow>,
          ),
          SessionItemRow,
          PrefetchHooks Function()
        > {
  $$SessionItemsTableTableManager(_$AppDatabase db, $SessionItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> requeueLeft = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionItemsCompanion(
                sessionId: sessionId,
                wordId: wordId,
                seq: seq,
                requeueLeft: requeueLeft,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int wordId,
                required int seq,
                Value<int> requeueLeft = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionItemsCompanion.insert(
                sessionId: sessionId,
                wordId: wordId,
                seq: seq,
                requeueLeft: requeueLeft,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionItemsTable,
      SessionItemRow,
      $$SessionItemsTableFilterComposer,
      $$SessionItemsTableOrderingComposer,
      $$SessionItemsTableAnnotationComposer,
      $$SessionItemsTableCreateCompanionBuilder,
      $$SessionItemsTableUpdateCompanionBuilder,
      (
        SessionItemRow,
        BaseReferences<_$AppDatabase, $SessionItemsTable, SessionItemRow>,
      ),
      SessionItemRow,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String sessionType,
      required int createdAt,
      required int updatedAt,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> sessionType,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> position,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                sessionType: sessionType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionType,
                required int createdAt,
                required int updatedAt,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                sessionType: sessionType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, BaseReferences<_$AppDatabase, $SessionsTable, SessionRow>),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$UserWordsTableCreateCompanionBuilder =
    UserWordsCompanion Function({
      Value<int> userId,
      required int wordbookId,
      required int wordId,
      required String state,
      required String status,
      Value<int?> dueDate,
      Value<double> stability,
      Value<double> difficulty,
      Value<int> reps,
      Value<int> lapses,
      Value<int?> lastReviewAt,
      Value<int?> lastRating,
      Value<double?> elapsedDays,
      Value<double?> scheduledDays,
      Value<int> rowid,
    });
typedef $$UserWordsTableUpdateCompanionBuilder =
    UserWordsCompanion Function({
      Value<int> userId,
      Value<int> wordbookId,
      Value<int> wordId,
      Value<String> state,
      Value<String> status,
      Value<int?> dueDate,
      Value<double> stability,
      Value<double> difficulty,
      Value<int> reps,
      Value<int> lapses,
      Value<int?> lastReviewAt,
      Value<int?> lastRating,
      Value<double?> elapsedDays,
      Value<double?> scheduledDays,
      Value<int> rowid,
    });

class $$UserWordsTableFilterComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRating => $composableBuilder(
    column: $table.lastRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elapsedDays => $composableBuilder(
    column: $table.elapsedDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scheduledDays => $composableBuilder(
    column: $table.scheduledDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRating => $composableBuilder(
    column: $table.lastRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elapsedDays => $composableBuilder(
    column: $table.elapsedDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scheduledDays => $composableBuilder(
    column: $table.scheduledDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRating => $composableBuilder(
    column: $table.lastRating,
    builder: (column) => column,
  );

  GeneratedColumn<double> get elapsedDays => $composableBuilder(
    column: $table.elapsedDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get scheduledDays => $composableBuilder(
    column: $table.scheduledDays,
    builder: (column) => column,
  );
}

class $$UserWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserWordsTable,
          UserWordRow,
          $$UserWordsTableFilterComposer,
          $$UserWordsTableOrderingComposer,
          $$UserWordsTableAnnotationComposer,
          $$UserWordsTableCreateCompanionBuilder,
          $$UserWordsTableUpdateCompanionBuilder,
          (
            UserWordRow,
            BaseReferences<_$AppDatabase, $UserWordsTable, UserWordRow>,
          ),
          UserWordRow,
          PrefetchHooks Function()
        > {
  $$UserWordsTableTableManager(_$AppDatabase db, $UserWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<int> wordbookId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int?> lastReviewAt = const Value.absent(),
                Value<int?> lastRating = const Value.absent(),
                Value<double?> elapsedDays = const Value.absent(),
                Value<double?> scheduledDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserWordsCompanion(
                userId: userId,
                wordbookId: wordbookId,
                wordId: wordId,
                state: state,
                status: status,
                dueDate: dueDate,
                stability: stability,
                difficulty: difficulty,
                reps: reps,
                lapses: lapses,
                lastReviewAt: lastReviewAt,
                lastRating: lastRating,
                elapsedDays: elapsedDays,
                scheduledDays: scheduledDays,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                required int wordbookId,
                required int wordId,
                required String state,
                required String status,
                Value<int?> dueDate = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int?> lastReviewAt = const Value.absent(),
                Value<int?> lastRating = const Value.absent(),
                Value<double?> elapsedDays = const Value.absent(),
                Value<double?> scheduledDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserWordsCompanion.insert(
                userId: userId,
                wordbookId: wordbookId,
                wordId: wordId,
                state: state,
                status: status,
                dueDate: dueDate,
                stability: stability,
                difficulty: difficulty,
                reps: reps,
                lapses: lapses,
                lastReviewAt: lastReviewAt,
                lastRating: lastRating,
                elapsedDays: elapsedDays,
                scheduledDays: scheduledDays,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserWordsTable,
      UserWordRow,
      $$UserWordsTableFilterComposer,
      $$UserWordsTableOrderingComposer,
      $$UserWordsTableAnnotationComposer,
      $$UserWordsTableCreateCompanionBuilder,
      $$UserWordsTableUpdateCompanionBuilder,
      (
        UserWordRow,
        BaseReferences<_$AppDatabase, $UserWordsTable, UserWordRow>,
      ),
      UserWordRow,
      PrefetchHooks Function()
    >;
typedef $$WordbookItemsTableCreateCompanionBuilder =
    WordbookItemsCompanion Function({
      required int wordbookId,
      required int wordId,
      required int seq,
      required int shuffled,
      Value<bool> isSkipped,
      Value<int> rowid,
    });
typedef $$WordbookItemsTableUpdateCompanionBuilder =
    WordbookItemsCompanion Function({
      Value<int> wordbookId,
      Value<int> wordId,
      Value<int> seq,
      Value<int> shuffled,
      Value<bool> isSkipped,
      Value<int> rowid,
    });

class $$WordbookItemsTableFilterComposer
    extends Composer<_$AppDatabase, $WordbookItemsTable> {
  $$WordbookItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shuffled => $composableBuilder(
    column: $table.shuffled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordbookItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordbookItemsTable> {
  $$WordbookItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shuffled => $composableBuilder(
    column: $table.shuffled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordbookItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordbookItemsTable> {
  $$WordbookItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get wordbookId => $composableBuilder(
    column: $table.wordbookId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get shuffled =>
      $composableBuilder(column: $table.shuffled, builder: (column) => column);

  GeneratedColumn<bool> get isSkipped =>
      $composableBuilder(column: $table.isSkipped, builder: (column) => column);
}

class $$WordbookItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordbookItemsTable,
          WordbookItemRow,
          $$WordbookItemsTableFilterComposer,
          $$WordbookItemsTableOrderingComposer,
          $$WordbookItemsTableAnnotationComposer,
          $$WordbookItemsTableCreateCompanionBuilder,
          $$WordbookItemsTableUpdateCompanionBuilder,
          (
            WordbookItemRow,
            BaseReferences<_$AppDatabase, $WordbookItemsTable, WordbookItemRow>,
          ),
          WordbookItemRow,
          PrefetchHooks Function()
        > {
  $$WordbookItemsTableTableManager(_$AppDatabase db, $WordbookItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordbookItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordbookItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordbookItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordbookId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> shuffled = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordbookItemsCompanion(
                wordbookId: wordbookId,
                wordId: wordId,
                seq: seq,
                shuffled: shuffled,
                isSkipped: isSkipped,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int wordbookId,
                required int wordId,
                required int seq,
                required int shuffled,
                Value<bool> isSkipped = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordbookItemsCompanion.insert(
                wordbookId: wordbookId,
                wordId: wordId,
                seq: seq,
                shuffled: shuffled,
                isSkipped: isSkipped,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordbookItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordbookItemsTable,
      WordbookItemRow,
      $$WordbookItemsTableFilterComposer,
      $$WordbookItemsTableOrderingComposer,
      $$WordbookItemsTableAnnotationComposer,
      $$WordbookItemsTableCreateCompanionBuilder,
      $$WordbookItemsTableUpdateCompanionBuilder,
      (
        WordbookItemRow,
        BaseReferences<_$AppDatabase, $WordbookItemsTable, WordbookItemRow>,
      ),
      WordbookItemRow,
      PrefetchHooks Function()
    >;
typedef $$WordbooksTableCreateCompanionBuilder =
    WordbooksCompanion Function({
      Value<int> id,
      required String name,
      required String level,
      required int totalCount,
      required String source,
      Value<int> sortOrder,
      required int createdAt,
    });
typedef $$WordbooksTableUpdateCompanionBuilder =
    WordbooksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> level,
      Value<int> totalCount,
      Value<String> source,
      Value<int> sortOrder,
      Value<int> createdAt,
    });

class $$WordbooksTableFilterComposer
    extends Composer<_$AppDatabase, $WordbooksTable> {
  $$WordbooksTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordbooksTableOrderingComposer
    extends Composer<_$AppDatabase, $WordbooksTable> {
  $$WordbooksTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordbooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordbooksTable> {
  $$WordbooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get totalCount => $composableBuilder(
    column: $table.totalCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WordbooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordbooksTable,
          WordbookRow,
          $$WordbooksTableFilterComposer,
          $$WordbooksTableOrderingComposer,
          $$WordbooksTableAnnotationComposer,
          $$WordbooksTableCreateCompanionBuilder,
          $$WordbooksTableUpdateCompanionBuilder,
          (
            WordbookRow,
            BaseReferences<_$AppDatabase, $WordbooksTable, WordbookRow>,
          ),
          WordbookRow,
          PrefetchHooks Function()
        > {
  $$WordbooksTableTableManager(_$AppDatabase db, $WordbooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordbooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordbooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordbooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<int> totalCount = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => WordbooksCompanion(
                id: id,
                name: name,
                level: level,
                totalCount: totalCount,
                source: source,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String level,
                required int totalCount,
                required String source,
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
              }) => WordbooksCompanion.insert(
                id: id,
                name: name,
                level: level,
                totalCount: totalCount,
                source: source,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordbooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordbooksTable,
      WordbookRow,
      $$WordbooksTableFilterComposer,
      $$WordbooksTableOrderingComposer,
      $$WordbooksTableAnnotationComposer,
      $$WordbooksTableCreateCompanionBuilder,
      $$WordbooksTableUpdateCompanionBuilder,
      (
        WordbookRow,
        BaseReferences<_$AppDatabase, $WordbooksTable, WordbookRow>,
      ),
      WordbookRow,
      PrefetchHooks Function()
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required String word,
      required String phonetic,
      Value<String?> phoneticUk,
      required String meanings,
      required String examples,
      required String frequency,
      Value<String?> rootAffix,
      required String audioKey,
      Value<String?> audioUrl,
      required int createdAt,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<String> phonetic,
      Value<String?> phoneticUk,
      Value<String> meanings,
      Value<String> examples,
      Value<String> frequency,
      Value<String?> rootAffix,
      Value<String> audioKey,
      Value<String?> audioUrl,
      Value<int> createdAt,
    });

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examples => $composableBuilder(
    column: $table.examples,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootAffix => $composableBuilder(
    column: $table.rootAffix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioKey => $composableBuilder(
    column: $table.audioKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examples => $composableBuilder(
    column: $table.examples,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootAffix => $composableBuilder(
    column: $table.rootAffix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioKey => $composableBuilder(
    column: $table.audioKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get phonetic =>
      $composableBuilder(column: $table.phonetic, builder: (column) => column);

  GeneratedColumn<String> get phoneticUk => $composableBuilder(
    column: $table.phoneticUk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meanings =>
      $composableBuilder(column: $table.meanings, builder: (column) => column);

  GeneratedColumn<String> get examples =>
      $composableBuilder(column: $table.examples, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get rootAffix =>
      $composableBuilder(column: $table.rootAffix, builder: (column) => column);

  GeneratedColumn<String> get audioKey =>
      $composableBuilder(column: $table.audioKey, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          WordRow,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (WordRow, BaseReferences<_$AppDatabase, $WordsTable, WordRow>),
          WordRow,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> phonetic = const Value.absent(),
                Value<String?> phoneticUk = const Value.absent(),
                Value<String> meanings = const Value.absent(),
                Value<String> examples = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String?> rootAffix = const Value.absent(),
                Value<String> audioKey = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                word: word,
                phonetic: phonetic,
                phoneticUk: phoneticUk,
                meanings: meanings,
                examples: examples,
                frequency: frequency,
                rootAffix: rootAffix,
                audioKey: audioKey,
                audioUrl: audioUrl,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                required String phonetic,
                Value<String?> phoneticUk = const Value.absent(),
                required String meanings,
                required String examples,
                required String frequency,
                Value<String?> rootAffix = const Value.absent(),
                required String audioKey,
                Value<String?> audioUrl = const Value.absent(),
                required int createdAt,
              }) => WordsCompanion.insert(
                id: id,
                word: word,
                phonetic: phonetic,
                phoneticUk: phoneticUk,
                meanings: meanings,
                examples: examples,
                frequency: frequency,
                rootAffix: rootAffix,
                audioKey: audioKey,
                audioUrl: audioUrl,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      WordRow,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (WordRow, BaseReferences<_$AppDatabase, $WordsTable, WordRow>),
      WordRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AudioPacksTableTableManager get audioPacks =>
      $$AudioPacksTableTableManager(_db, _db.audioPacks);
  $$DailyStatsTableTableManager get dailyStats =>
      $$DailyStatsTableTableManager(_db, _db.dailyStats);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$SessionItemsTableTableManager get sessionItems =>
      $$SessionItemsTableTableManager(_db, _db.sessionItems);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$UserWordsTableTableManager get userWords =>
      $$UserWordsTableTableManager(_db, _db.userWords);
  $$WordbookItemsTableTableManager get wordbookItems =>
      $$WordbookItemsTableTableManager(_db, _db.wordbookItems);
  $$WordbooksTableTableManager get wordbooks =>
      $$WordbooksTableTableManager(_db, _db.wordbooks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
}
