// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CultureItemsTable extends CultureItems
    with TableInfo<$CultureItemsTable, CultureItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CultureItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CultureCategory, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CultureCategory>($CultureItemsTable.$convertercategory);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbUrlMeta = const VerificationMeta(
    'thumbUrl',
  );
  @override
  late final GeneratedColumn<String> thumbUrl = GeneratedColumn<String>(
    'thumb_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oshiLevelMeta = const VerificationMeta(
    'oshiLevel',
  );
  @override
  late final GeneratedColumn<int> oshiLevel = GeneratedColumn<int>(
    'oshi_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _moodTagsMeta = const VerificationMeta(
    'moodTags',
  );
  @override
  late final GeneratedColumn<String> moodTags = GeneratedColumn<String>(
    'mood_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _moodColorMeta = const VerificationMeta(
    'moodColor',
  );
  @override
  late final GeneratedColumn<String> moodColor = GeneratedColumn<String>(
    'mood_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeNameMeta = const VerificationMeta(
    'placeName',
  );
  @override
  late final GeneratedColumn<String> placeName = GeneratedColumn<String>(
    'place_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(CardSource.self.name),
      ).withConverter<CardSource>($CultureItemsTable.$convertersource);
  static const VerificationMeta _beamFromMeta = const VerificationMeta(
    'beamFrom',
  );
  @override
  late final GeneratedColumn<String> beamFrom = GeneratedColumn<String>(
    'beam_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beamFromColorMeta = const VerificationMeta(
    'beamFromColor',
  );
  @override
  late final GeneratedColumn<String> beamFromColor = GeneratedColumn<String>(
    'beam_from_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pinnedOrderMeta = const VerificationMeta(
    'pinnedOrder',
  );
  @override
  late final GeneratedColumn<int> pinnedOrder = GeneratedColumn<int>(
    'pinned_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _consumedAtMeta = const VerificationMeta(
    'consumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
    'consumed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    title,
    subtitle,
    thumbPath,
    thumbUrl,
    externalId,
    url,
    memo,
    oshiLevel,
    moodTags,
    moodColor,
    detailJson,
    lat,
    lng,
    placeName,
    source,
    beamFrom,
    beamFromColor,
    isFavorite,
    pinnedOrder,
    createdAt,
    consumedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'culture_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CultureItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    }
    if (data.containsKey('thumb_url')) {
      context.handle(
        _thumbUrlMeta,
        thumbUrl.isAcceptableOrUnknown(data['thumb_url']!, _thumbUrlMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('oshi_level')) {
      context.handle(
        _oshiLevelMeta,
        oshiLevel.isAcceptableOrUnknown(data['oshi_level']!, _oshiLevelMeta),
      );
    }
    if (data.containsKey('mood_tags')) {
      context.handle(
        _moodTagsMeta,
        moodTags.isAcceptableOrUnknown(data['mood_tags']!, _moodTagsMeta),
      );
    }
    if (data.containsKey('mood_color')) {
      context.handle(
        _moodColorMeta,
        moodColor.isAcceptableOrUnknown(data['mood_color']!, _moodColorMeta),
      );
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('place_name')) {
      context.handle(
        _placeNameMeta,
        placeName.isAcceptableOrUnknown(data['place_name']!, _placeNameMeta),
      );
    }
    if (data.containsKey('beam_from')) {
      context.handle(
        _beamFromMeta,
        beamFrom.isAcceptableOrUnknown(data['beam_from']!, _beamFromMeta),
      );
    }
    if (data.containsKey('beam_from_color')) {
      context.handle(
        _beamFromColorMeta,
        beamFromColor.isAcceptableOrUnknown(
          data['beam_from_color']!,
          _beamFromColorMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('pinned_order')) {
      context.handle(
        _pinnedOrderMeta,
        pinnedOrder.isAcceptableOrUnknown(
          data['pinned_order']!,
          _pinnedOrderMeta,
        ),
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
    if (data.containsKey('consumed_at')) {
      context.handle(
        _consumedAtMeta,
        consumedAt.isAcceptableOrUnknown(data['consumed_at']!, _consumedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CultureItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CultureItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: $CultureItemsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      ),
      thumbUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_url'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      oshiLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}oshi_level'],
      )!,
      moodTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood_tags'],
      )!,
      moodColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood_color'],
      ),
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      placeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_name'],
      ),
      source: $CultureItemsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      beamFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beam_from'],
      ),
      beamFromColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beam_from_color'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      pinnedOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pinned_order'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      consumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consumed_at'],
      ),
    );
  }

  @override
  $CultureItemsTable createAlias(String alias) {
    return $CultureItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CultureCategory, String, String>
  $convertercategory = const EnumNameConverter<CultureCategory>(
    CultureCategory.values,
  );
  static JsonTypeConverter2<CardSource, String, String> $convertersource =
      const EnumNameConverter<CardSource>(CardSource.values);
}

class CultureItem extends DataClass implements Insertable<CultureItem> {
  final String id;
  final CultureCategory category;
  final String title;
  final String? subtitle;
  final String? thumbPath;
  final String? thumbUrl;
  final String? externalId;
  final String? url;
  final String? memo;
  final int oshiLevel;
  final String moodTags;
  final String? moodColor;
  final String detailJson;
  final double? lat;
  final double? lng;
  final String? placeName;
  final CardSource source;
  final String? beamFrom;
  final String? beamFromColor;
  final bool isFavorite;
  final int? pinnedOrder;
  final DateTime createdAt;
  final DateTime? consumedAt;
  const CultureItem({
    required this.id,
    required this.category,
    required this.title,
    this.subtitle,
    this.thumbPath,
    this.thumbUrl,
    this.externalId,
    this.url,
    this.memo,
    required this.oshiLevel,
    required this.moodTags,
    this.moodColor,
    required this.detailJson,
    this.lat,
    this.lng,
    this.placeName,
    required this.source,
    this.beamFrom,
    this.beamFromColor,
    required this.isFavorite,
    this.pinnedOrder,
    required this.createdAt,
    this.consumedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['category'] = Variable<String>(
        $CultureItemsTable.$convertercategory.toSql(category),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || thumbPath != null) {
      map['thumb_path'] = Variable<String>(thumbPath);
    }
    if (!nullToAbsent || thumbUrl != null) {
      map['thumb_url'] = Variable<String>(thumbUrl);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['oshi_level'] = Variable<int>(oshiLevel);
    map['mood_tags'] = Variable<String>(moodTags);
    if (!nullToAbsent || moodColor != null) {
      map['mood_color'] = Variable<String>(moodColor);
    }
    map['detail_json'] = Variable<String>(detailJson);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || placeName != null) {
      map['place_name'] = Variable<String>(placeName);
    }
    {
      map['source'] = Variable<String>(
        $CultureItemsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || beamFrom != null) {
      map['beam_from'] = Variable<String>(beamFrom);
    }
    if (!nullToAbsent || beamFromColor != null) {
      map['beam_from_color'] = Variable<String>(beamFromColor);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || pinnedOrder != null) {
      map['pinned_order'] = Variable<int>(pinnedOrder);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || consumedAt != null) {
      map['consumed_at'] = Variable<DateTime>(consumedAt);
    }
    return map;
  }

  CultureItemsCompanion toCompanion(bool nullToAbsent) {
    return CultureItemsCompanion(
      id: Value(id),
      category: Value(category),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      thumbPath: thumbPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbPath),
      thumbUrl: thumbUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbUrl),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      oshiLevel: Value(oshiLevel),
      moodTags: Value(moodTags),
      moodColor: moodColor == null && nullToAbsent
          ? const Value.absent()
          : Value(moodColor),
      detailJson: Value(detailJson),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      placeName: placeName == null && nullToAbsent
          ? const Value.absent()
          : Value(placeName),
      source: Value(source),
      beamFrom: beamFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(beamFrom),
      beamFromColor: beamFromColor == null && nullToAbsent
          ? const Value.absent()
          : Value(beamFromColor),
      isFavorite: Value(isFavorite),
      pinnedOrder: pinnedOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedOrder),
      createdAt: Value(createdAt),
      consumedAt: consumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consumedAt),
    );
  }

  factory CultureItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CultureItem(
      id: serializer.fromJson<String>(json['id']),
      category: $CultureItemsTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      thumbPath: serializer.fromJson<String?>(json['thumbPath']),
      thumbUrl: serializer.fromJson<String?>(json['thumbUrl']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      url: serializer.fromJson<String?>(json['url']),
      memo: serializer.fromJson<String?>(json['memo']),
      oshiLevel: serializer.fromJson<int>(json['oshiLevel']),
      moodTags: serializer.fromJson<String>(json['moodTags']),
      moodColor: serializer.fromJson<String?>(json['moodColor']),
      detailJson: serializer.fromJson<String>(json['detailJson']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      placeName: serializer.fromJson<String?>(json['placeName']),
      source: $CultureItemsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      beamFrom: serializer.fromJson<String?>(json['beamFrom']),
      beamFromColor: serializer.fromJson<String?>(json['beamFromColor']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      pinnedOrder: serializer.fromJson<int?>(json['pinnedOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      consumedAt: serializer.fromJson<DateTime?>(json['consumedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(
        $CultureItemsTable.$convertercategory.toJson(category),
      ),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'thumbPath': serializer.toJson<String?>(thumbPath),
      'thumbUrl': serializer.toJson<String?>(thumbUrl),
      'externalId': serializer.toJson<String?>(externalId),
      'url': serializer.toJson<String?>(url),
      'memo': serializer.toJson<String?>(memo),
      'oshiLevel': serializer.toJson<int>(oshiLevel),
      'moodTags': serializer.toJson<String>(moodTags),
      'moodColor': serializer.toJson<String?>(moodColor),
      'detailJson': serializer.toJson<String>(detailJson),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'placeName': serializer.toJson<String?>(placeName),
      'source': serializer.toJson<String>(
        $CultureItemsTable.$convertersource.toJson(source),
      ),
      'beamFrom': serializer.toJson<String?>(beamFrom),
      'beamFromColor': serializer.toJson<String?>(beamFromColor),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'pinnedOrder': serializer.toJson<int?>(pinnedOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'consumedAt': serializer.toJson<DateTime?>(consumedAt),
    };
  }

  CultureItem copyWith({
    String? id,
    CultureCategory? category,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> thumbPath = const Value.absent(),
    Value<String?> thumbUrl = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    int? oshiLevel,
    String? moodTags,
    Value<String?> moodColor = const Value.absent(),
    String? detailJson,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<String?> placeName = const Value.absent(),
    CardSource? source,
    Value<String?> beamFrom = const Value.absent(),
    Value<String?> beamFromColor = const Value.absent(),
    bool? isFavorite,
    Value<int?> pinnedOrder = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> consumedAt = const Value.absent(),
  }) => CultureItem(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    thumbPath: thumbPath.present ? thumbPath.value : this.thumbPath,
    thumbUrl: thumbUrl.present ? thumbUrl.value : this.thumbUrl,
    externalId: externalId.present ? externalId.value : this.externalId,
    url: url.present ? url.value : this.url,
    memo: memo.present ? memo.value : this.memo,
    oshiLevel: oshiLevel ?? this.oshiLevel,
    moodTags: moodTags ?? this.moodTags,
    moodColor: moodColor.present ? moodColor.value : this.moodColor,
    detailJson: detailJson ?? this.detailJson,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    placeName: placeName.present ? placeName.value : this.placeName,
    source: source ?? this.source,
    beamFrom: beamFrom.present ? beamFrom.value : this.beamFrom,
    beamFromColor: beamFromColor.present
        ? beamFromColor.value
        : this.beamFromColor,
    isFavorite: isFavorite ?? this.isFavorite,
    pinnedOrder: pinnedOrder.present ? pinnedOrder.value : this.pinnedOrder,
    createdAt: createdAt ?? this.createdAt,
    consumedAt: consumedAt.present ? consumedAt.value : this.consumedAt,
  );
  CultureItem copyWithCompanion(CultureItemsCompanion data) {
    return CultureItem(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      thumbUrl: data.thumbUrl.present ? data.thumbUrl.value : this.thumbUrl,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      url: data.url.present ? data.url.value : this.url,
      memo: data.memo.present ? data.memo.value : this.memo,
      oshiLevel: data.oshiLevel.present ? data.oshiLevel.value : this.oshiLevel,
      moodTags: data.moodTags.present ? data.moodTags.value : this.moodTags,
      moodColor: data.moodColor.present ? data.moodColor.value : this.moodColor,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      placeName: data.placeName.present ? data.placeName.value : this.placeName,
      source: data.source.present ? data.source.value : this.source,
      beamFrom: data.beamFrom.present ? data.beamFrom.value : this.beamFrom,
      beamFromColor: data.beamFromColor.present
          ? data.beamFromColor.value
          : this.beamFromColor,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      pinnedOrder: data.pinnedOrder.present
          ? data.pinnedOrder.value
          : this.pinnedOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      consumedAt: data.consumedAt.present
          ? data.consumedAt.value
          : this.consumedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CultureItem(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('externalId: $externalId, ')
          ..write('url: $url, ')
          ..write('memo: $memo, ')
          ..write('oshiLevel: $oshiLevel, ')
          ..write('moodTags: $moodTags, ')
          ..write('moodColor: $moodColor, ')
          ..write('detailJson: $detailJson, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('placeName: $placeName, ')
          ..write('source: $source, ')
          ..write('beamFrom: $beamFrom, ')
          ..write('beamFromColor: $beamFromColor, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('pinnedOrder: $pinnedOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('consumedAt: $consumedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    category,
    title,
    subtitle,
    thumbPath,
    thumbUrl,
    externalId,
    url,
    memo,
    oshiLevel,
    moodTags,
    moodColor,
    detailJson,
    lat,
    lng,
    placeName,
    source,
    beamFrom,
    beamFromColor,
    isFavorite,
    pinnedOrder,
    createdAt,
    consumedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CultureItem &&
          other.id == this.id &&
          other.category == this.category &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.thumbPath == this.thumbPath &&
          other.thumbUrl == this.thumbUrl &&
          other.externalId == this.externalId &&
          other.url == this.url &&
          other.memo == this.memo &&
          other.oshiLevel == this.oshiLevel &&
          other.moodTags == this.moodTags &&
          other.moodColor == this.moodColor &&
          other.detailJson == this.detailJson &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.placeName == this.placeName &&
          other.source == this.source &&
          other.beamFrom == this.beamFrom &&
          other.beamFromColor == this.beamFromColor &&
          other.isFavorite == this.isFavorite &&
          other.pinnedOrder == this.pinnedOrder &&
          other.createdAt == this.createdAt &&
          other.consumedAt == this.consumedAt);
}

class CultureItemsCompanion extends UpdateCompanion<CultureItem> {
  final Value<String> id;
  final Value<CultureCategory> category;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<String?> thumbPath;
  final Value<String?> thumbUrl;
  final Value<String?> externalId;
  final Value<String?> url;
  final Value<String?> memo;
  final Value<int> oshiLevel;
  final Value<String> moodTags;
  final Value<String?> moodColor;
  final Value<String> detailJson;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String?> placeName;
  final Value<CardSource> source;
  final Value<String?> beamFrom;
  final Value<String?> beamFromColor;
  final Value<bool> isFavorite;
  final Value<int?> pinnedOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime?> consumedAt;
  final Value<int> rowid;
  const CultureItemsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.thumbUrl = const Value.absent(),
    this.externalId = const Value.absent(),
    this.url = const Value.absent(),
    this.memo = const Value.absent(),
    this.oshiLevel = const Value.absent(),
    this.moodTags = const Value.absent(),
    this.moodColor = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.placeName = const Value.absent(),
    this.source = const Value.absent(),
    this.beamFrom = const Value.absent(),
    this.beamFromColor = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.pinnedOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CultureItemsCompanion.insert({
    required String id,
    required CultureCategory category,
    required String title,
    this.subtitle = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.thumbUrl = const Value.absent(),
    this.externalId = const Value.absent(),
    this.url = const Value.absent(),
    this.memo = const Value.absent(),
    this.oshiLevel = const Value.absent(),
    this.moodTags = const Value.absent(),
    this.moodColor = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.placeName = const Value.absent(),
    this.source = const Value.absent(),
    this.beamFrom = const Value.absent(),
    this.beamFromColor = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.pinnedOrder = const Value.absent(),
    required DateTime createdAt,
    this.consumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<CultureItem> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? thumbPath,
    Expression<String>? thumbUrl,
    Expression<String>? externalId,
    Expression<String>? url,
    Expression<String>? memo,
    Expression<int>? oshiLevel,
    Expression<String>? moodTags,
    Expression<String>? moodColor,
    Expression<String>? detailJson,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? placeName,
    Expression<String>? source,
    Expression<String>? beamFrom,
    Expression<String>? beamFromColor,
    Expression<bool>? isFavorite,
    Expression<int>? pinnedOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? consumedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (thumbUrl != null) 'thumb_url': thumbUrl,
      if (externalId != null) 'external_id': externalId,
      if (url != null) 'url': url,
      if (memo != null) 'memo': memo,
      if (oshiLevel != null) 'oshi_level': oshiLevel,
      if (moodTags != null) 'mood_tags': moodTags,
      if (moodColor != null) 'mood_color': moodColor,
      if (detailJson != null) 'detail_json': detailJson,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (placeName != null) 'place_name': placeName,
      if (source != null) 'source': source,
      if (beamFrom != null) 'beam_from': beamFrom,
      if (beamFromColor != null) 'beam_from_color': beamFromColor,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (pinnedOrder != null) 'pinned_order': pinnedOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CultureItemsCompanion copyWith({
    Value<String>? id,
    Value<CultureCategory>? category,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<String?>? thumbPath,
    Value<String?>? thumbUrl,
    Value<String?>? externalId,
    Value<String?>? url,
    Value<String?>? memo,
    Value<int>? oshiLevel,
    Value<String>? moodTags,
    Value<String?>? moodColor,
    Value<String>? detailJson,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<String?>? placeName,
    Value<CardSource>? source,
    Value<String?>? beamFrom,
    Value<String?>? beamFromColor,
    Value<bool>? isFavorite,
    Value<int?>? pinnedOrder,
    Value<DateTime>? createdAt,
    Value<DateTime?>? consumedAt,
    Value<int>? rowid,
  }) {
    return CultureItemsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      thumbPath: thumbPath ?? this.thumbPath,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      externalId: externalId ?? this.externalId,
      url: url ?? this.url,
      memo: memo ?? this.memo,
      oshiLevel: oshiLevel ?? this.oshiLevel,
      moodTags: moodTags ?? this.moodTags,
      moodColor: moodColor ?? this.moodColor,
      detailJson: detailJson ?? this.detailJson,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      placeName: placeName ?? this.placeName,
      source: source ?? this.source,
      beamFrom: beamFrom ?? this.beamFrom,
      beamFromColor: beamFromColor ?? this.beamFromColor,
      isFavorite: isFavorite ?? this.isFavorite,
      pinnedOrder: pinnedOrder ?? this.pinnedOrder,
      createdAt: createdAt ?? this.createdAt,
      consumedAt: consumedAt ?? this.consumedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $CultureItemsTable.$convertercategory.toSql(category.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (thumbUrl.present) {
      map['thumb_url'] = Variable<String>(thumbUrl.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (oshiLevel.present) {
      map['oshi_level'] = Variable<int>(oshiLevel.value);
    }
    if (moodTags.present) {
      map['mood_tags'] = Variable<String>(moodTags.value);
    }
    if (moodColor.present) {
      map['mood_color'] = Variable<String>(moodColor.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (placeName.present) {
      map['place_name'] = Variable<String>(placeName.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $CultureItemsTable.$convertersource.toSql(source.value),
      );
    }
    if (beamFrom.present) {
      map['beam_from'] = Variable<String>(beamFrom.value);
    }
    if (beamFromColor.present) {
      map['beam_from_color'] = Variable<String>(beamFromColor.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (pinnedOrder.present) {
      map['pinned_order'] = Variable<int>(pinnedOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CultureItemsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('thumbUrl: $thumbUrl, ')
          ..write('externalId: $externalId, ')
          ..write('url: $url, ')
          ..write('memo: $memo, ')
          ..write('oshiLevel: $oshiLevel, ')
          ..write('moodTags: $moodTags, ')
          ..write('moodColor: $moodColor, ')
          ..write('detailJson: $detailJson, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('placeName: $placeName, ')
          ..write('source: $source, ')
          ..write('beamFrom: $beamFrom, ')
          ..write('beamFromColor: $beamFromColor, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('pinnedOrder: $pinnedOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BeamsTable extends Beams with TableInfo<$BeamsTable, Beam> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BeamDirection, String> direction =
      GeneratedColumn<String>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BeamDirection>($BeamsTable.$converterdirection);
  static const VerificationMeta _peerNameMeta = const VerificationMeta(
    'peerName',
  );
  @override
  late final GeneratedColumn<String> peerName = GeneratedColumn<String>(
    'peer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerColorMeta = const VerificationMeta(
    'peerColor',
  );
  @override
  late final GeneratedColumn<String> peerColor = GeneratedColumn<String>(
    'peer_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beamedAtMeta = const VerificationMeta(
    'beamedAt',
  );
  @override
  late final GeneratedColumn<DateTime> beamedAt = GeneratedColumn<DateTime>(
    'beamed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    direction,
    peerName,
    peerColor,
    cardId,
    beamedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beams';
  @override
  VerificationContext validateIntegrity(
    Insertable<Beam> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('peer_name')) {
      context.handle(
        _peerNameMeta,
        peerName.isAcceptableOrUnknown(data['peer_name']!, _peerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_peerNameMeta);
    }
    if (data.containsKey('peer_color')) {
      context.handle(
        _peerColorMeta,
        peerColor.isAcceptableOrUnknown(data['peer_color']!, _peerColorMeta),
      );
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('beamed_at')) {
      context.handle(
        _beamedAtMeta,
        beamedAt.isAcceptableOrUnknown(data['beamed_at']!, _beamedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_beamedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Beam map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Beam(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      direction: $BeamsTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      peerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_name'],
      )!,
      peerColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_color'],
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      beamedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}beamed_at'],
      )!,
    );
  }

  @override
  $BeamsTable createAlias(String alias) {
    return $BeamsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BeamDirection, String, String> $converterdirection =
      const EnumNameConverter<BeamDirection>(BeamDirection.values);
}

class Beam extends DataClass implements Insertable<Beam> {
  final String id;
  final BeamDirection direction;
  final String peerName;
  final String? peerColor;
  final String cardId;
  final DateTime beamedAt;
  const Beam({
    required this.id,
    required this.direction,
    required this.peerName,
    this.peerColor,
    required this.cardId,
    required this.beamedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['direction'] = Variable<String>(
        $BeamsTable.$converterdirection.toSql(direction),
      );
    }
    map['peer_name'] = Variable<String>(peerName);
    if (!nullToAbsent || peerColor != null) {
      map['peer_color'] = Variable<String>(peerColor);
    }
    map['card_id'] = Variable<String>(cardId);
    map['beamed_at'] = Variable<DateTime>(beamedAt);
    return map;
  }

  BeamsCompanion toCompanion(bool nullToAbsent) {
    return BeamsCompanion(
      id: Value(id),
      direction: Value(direction),
      peerName: Value(peerName),
      peerColor: peerColor == null && nullToAbsent
          ? const Value.absent()
          : Value(peerColor),
      cardId: Value(cardId),
      beamedAt: Value(beamedAt),
    );
  }

  factory Beam.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Beam(
      id: serializer.fromJson<String>(json['id']),
      direction: $BeamsTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      peerName: serializer.fromJson<String>(json['peerName']),
      peerColor: serializer.fromJson<String?>(json['peerColor']),
      cardId: serializer.fromJson<String>(json['cardId']),
      beamedAt: serializer.fromJson<DateTime>(json['beamedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'direction': serializer.toJson<String>(
        $BeamsTable.$converterdirection.toJson(direction),
      ),
      'peerName': serializer.toJson<String>(peerName),
      'peerColor': serializer.toJson<String?>(peerColor),
      'cardId': serializer.toJson<String>(cardId),
      'beamedAt': serializer.toJson<DateTime>(beamedAt),
    };
  }

  Beam copyWith({
    String? id,
    BeamDirection? direction,
    String? peerName,
    Value<String?> peerColor = const Value.absent(),
    String? cardId,
    DateTime? beamedAt,
  }) => Beam(
    id: id ?? this.id,
    direction: direction ?? this.direction,
    peerName: peerName ?? this.peerName,
    peerColor: peerColor.present ? peerColor.value : this.peerColor,
    cardId: cardId ?? this.cardId,
    beamedAt: beamedAt ?? this.beamedAt,
  );
  Beam copyWithCompanion(BeamsCompanion data) {
    return Beam(
      id: data.id.present ? data.id.value : this.id,
      direction: data.direction.present ? data.direction.value : this.direction,
      peerName: data.peerName.present ? data.peerName.value : this.peerName,
      peerColor: data.peerColor.present ? data.peerColor.value : this.peerColor,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      beamedAt: data.beamedAt.present ? data.beamedAt.value : this.beamedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Beam(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('peerName: $peerName, ')
          ..write('peerColor: $peerColor, ')
          ..write('cardId: $cardId, ')
          ..write('beamedAt: $beamedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, direction, peerName, peerColor, cardId, beamedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Beam &&
          other.id == this.id &&
          other.direction == this.direction &&
          other.peerName == this.peerName &&
          other.peerColor == this.peerColor &&
          other.cardId == this.cardId &&
          other.beamedAt == this.beamedAt);
}

class BeamsCompanion extends UpdateCompanion<Beam> {
  final Value<String> id;
  final Value<BeamDirection> direction;
  final Value<String> peerName;
  final Value<String?> peerColor;
  final Value<String> cardId;
  final Value<DateTime> beamedAt;
  final Value<int> rowid;
  const BeamsCompanion({
    this.id = const Value.absent(),
    this.direction = const Value.absent(),
    this.peerName = const Value.absent(),
    this.peerColor = const Value.absent(),
    this.cardId = const Value.absent(),
    this.beamedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BeamsCompanion.insert({
    required String id,
    required BeamDirection direction,
    required String peerName,
    this.peerColor = const Value.absent(),
    required String cardId,
    required DateTime beamedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       direction = Value(direction),
       peerName = Value(peerName),
       cardId = Value(cardId),
       beamedAt = Value(beamedAt);
  static Insertable<Beam> custom({
    Expression<String>? id,
    Expression<String>? direction,
    Expression<String>? peerName,
    Expression<String>? peerColor,
    Expression<String>? cardId,
    Expression<DateTime>? beamedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direction != null) 'direction': direction,
      if (peerName != null) 'peer_name': peerName,
      if (peerColor != null) 'peer_color': peerColor,
      if (cardId != null) 'card_id': cardId,
      if (beamedAt != null) 'beamed_at': beamedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BeamsCompanion copyWith({
    Value<String>? id,
    Value<BeamDirection>? direction,
    Value<String>? peerName,
    Value<String?>? peerColor,
    Value<String>? cardId,
    Value<DateTime>? beamedAt,
    Value<int>? rowid,
  }) {
    return BeamsCompanion(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      peerName: peerName ?? this.peerName,
      peerColor: peerColor ?? this.peerColor,
      cardId: cardId ?? this.cardId,
      beamedAt: beamedAt ?? this.beamedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $BeamsTable.$converterdirection.toSql(direction.value),
      );
    }
    if (peerName.present) {
      map['peer_name'] = Variable<String>(peerName.value);
    }
    if (peerColor.present) {
      map['peer_color'] = Variable<String>(peerColor.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (beamedAt.present) {
      map['beamed_at'] = Variable<DateTime>(beamedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeamsCompanion(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('peerName: $peerName, ')
          ..write('peerColor: $peerColor, ')
          ..write('cardId: $cardId, ')
          ..write('beamedAt: $beamedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StickersTable extends Stickers with TableInfo<$StickersTable, Sticker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StickersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StickerTexture, String> texture =
      GeneratedColumn<String>(
        'texture',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(StickerTexture.normal.name),
      ).withConverter<StickerTexture>($StickersTable.$convertertexture);
  static const VerificationMeta _creatorNameMeta = const VerificationMeta(
    'creatorName',
  );
  @override
  late final GeneratedColumn<String> creatorName = GeneratedColumn<String>(
    'creator_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creatorColorMeta = const VerificationMeta(
    'creatorColor',
  );
  @override
  late final GeneratedColumn<String> creatorColor = GeneratedColumn<String>(
    'creator_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(CardSource.self.name),
      ).withConverter<CardSource>($StickersTable.$convertersource);
  static const VerificationMeta _linkedItemIdMeta = const VerificationMeta(
    'linkedItemId',
  );
  @override
  late final GeneratedColumn<String> linkedItemId = GeneratedColumn<String>(
    'linked_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawPathMeta = const VerificationMeta(
    'rawPath',
  );
  @override
  late final GeneratedColumn<String> rawPath = GeneratedColumn<String>(
    'raw_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawIsCutoutMeta = const VerificationMeta(
    'rawIsCutout',
  );
  @override
  late final GeneratedColumn<bool> rawIsCutout = GeneratedColumn<bool>(
    'raw_is_cutout',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("raw_is_cutout" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _borderColorMeta = const VerificationMeta(
    'borderColor',
  );
  @override
  late final GeneratedColumn<String> borderColor = GeneratedColumn<String>(
    'border_color',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imagePath,
    texture,
    creatorName,
    creatorColor,
    source,
    linkedItemId,
    audioPath,
    rawPath,
    rawIsCutout,
    borderColor,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stickers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sticker> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('creator_name')) {
      context.handle(
        _creatorNameMeta,
        creatorName.isAcceptableOrUnknown(
          data['creator_name']!,
          _creatorNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creatorNameMeta);
    }
    if (data.containsKey('creator_color')) {
      context.handle(
        _creatorColorMeta,
        creatorColor.isAcceptableOrUnknown(
          data['creator_color']!,
          _creatorColorMeta,
        ),
      );
    }
    if (data.containsKey('linked_item_id')) {
      context.handle(
        _linkedItemIdMeta,
        linkedItemId.isAcceptableOrUnknown(
          data['linked_item_id']!,
          _linkedItemIdMeta,
        ),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('raw_path')) {
      context.handle(
        _rawPathMeta,
        rawPath.isAcceptableOrUnknown(data['raw_path']!, _rawPathMeta),
      );
    }
    if (data.containsKey('raw_is_cutout')) {
      context.handle(
        _rawIsCutoutMeta,
        rawIsCutout.isAcceptableOrUnknown(
          data['raw_is_cutout']!,
          _rawIsCutoutMeta,
        ),
      );
    }
    if (data.containsKey('border_color')) {
      context.handle(
        _borderColorMeta,
        borderColor.isAcceptableOrUnknown(
          data['border_color']!,
          _borderColorMeta,
        ),
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
  Sticker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sticker(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      texture: $StickersTable.$convertertexture.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}texture'],
        )!,
      ),
      creatorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_name'],
      )!,
      creatorColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_color'],
      ),
      source: $StickersTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      linkedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_item_id'],
      ),
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      rawPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_path'],
      ),
      rawIsCutout: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}raw_is_cutout'],
      )!,
      borderColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}border_color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StickersTable createAlias(String alias) {
    return $StickersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StickerTexture, String, String> $convertertexture =
      const EnumNameConverter<StickerTexture>(StickerTexture.values);
  static JsonTypeConverter2<CardSource, String, String> $convertersource =
      const EnumNameConverter<CardSource>(CardSource.values);
}

class Sticker extends DataClass implements Insertable<Sticker> {
  final String id;
  final String imagePath;
  final StickerTexture texture;
  final String creatorName;
  final String? creatorColor;
  final CardSource source;
  final String? linkedItemId;
  final String? audioPath;
  final String? rawPath;
  final bool rawIsCutout;
  final String? borderColor;
  final DateTime createdAt;
  const Sticker({
    required this.id,
    required this.imagePath,
    required this.texture,
    required this.creatorName,
    this.creatorColor,
    required this.source,
    this.linkedItemId,
    this.audioPath,
    this.rawPath,
    required this.rawIsCutout,
    this.borderColor,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['image_path'] = Variable<String>(imagePath);
    {
      map['texture'] = Variable<String>(
        $StickersTable.$convertertexture.toSql(texture),
      );
    }
    map['creator_name'] = Variable<String>(creatorName);
    if (!nullToAbsent || creatorColor != null) {
      map['creator_color'] = Variable<String>(creatorColor);
    }
    {
      map['source'] = Variable<String>(
        $StickersTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || linkedItemId != null) {
      map['linked_item_id'] = Variable<String>(linkedItemId);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    if (!nullToAbsent || rawPath != null) {
      map['raw_path'] = Variable<String>(rawPath);
    }
    map['raw_is_cutout'] = Variable<bool>(rawIsCutout);
    if (!nullToAbsent || borderColor != null) {
      map['border_color'] = Variable<String>(borderColor);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StickersCompanion toCompanion(bool nullToAbsent) {
    return StickersCompanion(
      id: Value(id),
      imagePath: Value(imagePath),
      texture: Value(texture),
      creatorName: Value(creatorName),
      creatorColor: creatorColor == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorColor),
      source: Value(source),
      linkedItemId: linkedItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedItemId),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      rawPath: rawPath == null && nullToAbsent
          ? const Value.absent()
          : Value(rawPath),
      rawIsCutout: Value(rawIsCutout),
      borderColor: borderColor == null && nullToAbsent
          ? const Value.absent()
          : Value(borderColor),
      createdAt: Value(createdAt),
    );
  }

  factory Sticker.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sticker(
      id: serializer.fromJson<String>(json['id']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      texture: $StickersTable.$convertertexture.fromJson(
        serializer.fromJson<String>(json['texture']),
      ),
      creatorName: serializer.fromJson<String>(json['creatorName']),
      creatorColor: serializer.fromJson<String?>(json['creatorColor']),
      source: $StickersTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      linkedItemId: serializer.fromJson<String?>(json['linkedItemId']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      rawPath: serializer.fromJson<String?>(json['rawPath']),
      rawIsCutout: serializer.fromJson<bool>(json['rawIsCutout']),
      borderColor: serializer.fromJson<String?>(json['borderColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'imagePath': serializer.toJson<String>(imagePath),
      'texture': serializer.toJson<String>(
        $StickersTable.$convertertexture.toJson(texture),
      ),
      'creatorName': serializer.toJson<String>(creatorName),
      'creatorColor': serializer.toJson<String?>(creatorColor),
      'source': serializer.toJson<String>(
        $StickersTable.$convertersource.toJson(source),
      ),
      'linkedItemId': serializer.toJson<String?>(linkedItemId),
      'audioPath': serializer.toJson<String?>(audioPath),
      'rawPath': serializer.toJson<String?>(rawPath),
      'rawIsCutout': serializer.toJson<bool>(rawIsCutout),
      'borderColor': serializer.toJson<String?>(borderColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sticker copyWith({
    String? id,
    String? imagePath,
    StickerTexture? texture,
    String? creatorName,
    Value<String?> creatorColor = const Value.absent(),
    CardSource? source,
    Value<String?> linkedItemId = const Value.absent(),
    Value<String?> audioPath = const Value.absent(),
    Value<String?> rawPath = const Value.absent(),
    bool? rawIsCutout,
    Value<String?> borderColor = const Value.absent(),
    DateTime? createdAt,
  }) => Sticker(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    texture: texture ?? this.texture,
    creatorName: creatorName ?? this.creatorName,
    creatorColor: creatorColor.present ? creatorColor.value : this.creatorColor,
    source: source ?? this.source,
    linkedItemId: linkedItemId.present ? linkedItemId.value : this.linkedItemId,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    rawPath: rawPath.present ? rawPath.value : this.rawPath,
    rawIsCutout: rawIsCutout ?? this.rawIsCutout,
    borderColor: borderColor.present ? borderColor.value : this.borderColor,
    createdAt: createdAt ?? this.createdAt,
  );
  Sticker copyWithCompanion(StickersCompanion data) {
    return Sticker(
      id: data.id.present ? data.id.value : this.id,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      texture: data.texture.present ? data.texture.value : this.texture,
      creatorName: data.creatorName.present
          ? data.creatorName.value
          : this.creatorName,
      creatorColor: data.creatorColor.present
          ? data.creatorColor.value
          : this.creatorColor,
      source: data.source.present ? data.source.value : this.source,
      linkedItemId: data.linkedItemId.present
          ? data.linkedItemId.value
          : this.linkedItemId,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      rawPath: data.rawPath.present ? data.rawPath.value : this.rawPath,
      rawIsCutout: data.rawIsCutout.present
          ? data.rawIsCutout.value
          : this.rawIsCutout,
      borderColor: data.borderColor.present
          ? data.borderColor.value
          : this.borderColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sticker(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('texture: $texture, ')
          ..write('creatorName: $creatorName, ')
          ..write('creatorColor: $creatorColor, ')
          ..write('source: $source, ')
          ..write('linkedItemId: $linkedItemId, ')
          ..write('audioPath: $audioPath, ')
          ..write('rawPath: $rawPath, ')
          ..write('rawIsCutout: $rawIsCutout, ')
          ..write('borderColor: $borderColor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    imagePath,
    texture,
    creatorName,
    creatorColor,
    source,
    linkedItemId,
    audioPath,
    rawPath,
    rawIsCutout,
    borderColor,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sticker &&
          other.id == this.id &&
          other.imagePath == this.imagePath &&
          other.texture == this.texture &&
          other.creatorName == this.creatorName &&
          other.creatorColor == this.creatorColor &&
          other.source == this.source &&
          other.linkedItemId == this.linkedItemId &&
          other.audioPath == this.audioPath &&
          other.rawPath == this.rawPath &&
          other.rawIsCutout == this.rawIsCutout &&
          other.borderColor == this.borderColor &&
          other.createdAt == this.createdAt);
}

class StickersCompanion extends UpdateCompanion<Sticker> {
  final Value<String> id;
  final Value<String> imagePath;
  final Value<StickerTexture> texture;
  final Value<String> creatorName;
  final Value<String?> creatorColor;
  final Value<CardSource> source;
  final Value<String?> linkedItemId;
  final Value<String?> audioPath;
  final Value<String?> rawPath;
  final Value<bool> rawIsCutout;
  final Value<String?> borderColor;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StickersCompanion({
    this.id = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.texture = const Value.absent(),
    this.creatorName = const Value.absent(),
    this.creatorColor = const Value.absent(),
    this.source = const Value.absent(),
    this.linkedItemId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.rawPath = const Value.absent(),
    this.rawIsCutout = const Value.absent(),
    this.borderColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickersCompanion.insert({
    required String id,
    required String imagePath,
    this.texture = const Value.absent(),
    required String creatorName,
    this.creatorColor = const Value.absent(),
    this.source = const Value.absent(),
    this.linkedItemId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.rawPath = const Value.absent(),
    this.rawIsCutout = const Value.absent(),
    this.borderColor = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       imagePath = Value(imagePath),
       creatorName = Value(creatorName),
       createdAt = Value(createdAt);
  static Insertable<Sticker> custom({
    Expression<String>? id,
    Expression<String>? imagePath,
    Expression<String>? texture,
    Expression<String>? creatorName,
    Expression<String>? creatorColor,
    Expression<String>? source,
    Expression<String>? linkedItemId,
    Expression<String>? audioPath,
    Expression<String>? rawPath,
    Expression<bool>? rawIsCutout,
    Expression<String>? borderColor,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imagePath != null) 'image_path': imagePath,
      if (texture != null) 'texture': texture,
      if (creatorName != null) 'creator_name': creatorName,
      if (creatorColor != null) 'creator_color': creatorColor,
      if (source != null) 'source': source,
      if (linkedItemId != null) 'linked_item_id': linkedItemId,
      if (audioPath != null) 'audio_path': audioPath,
      if (rawPath != null) 'raw_path': rawPath,
      if (rawIsCutout != null) 'raw_is_cutout': rawIsCutout,
      if (borderColor != null) 'border_color': borderColor,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickersCompanion copyWith({
    Value<String>? id,
    Value<String>? imagePath,
    Value<StickerTexture>? texture,
    Value<String>? creatorName,
    Value<String?>? creatorColor,
    Value<CardSource>? source,
    Value<String?>? linkedItemId,
    Value<String?>? audioPath,
    Value<String?>? rawPath,
    Value<bool>? rawIsCutout,
    Value<String?>? borderColor,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StickersCompanion(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      texture: texture ?? this.texture,
      creatorName: creatorName ?? this.creatorName,
      creatorColor: creatorColor ?? this.creatorColor,
      source: source ?? this.source,
      linkedItemId: linkedItemId ?? this.linkedItemId,
      audioPath: audioPath ?? this.audioPath,
      rawPath: rawPath ?? this.rawPath,
      rawIsCutout: rawIsCutout ?? this.rawIsCutout,
      borderColor: borderColor ?? this.borderColor,
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
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (texture.present) {
      map['texture'] = Variable<String>(
        $StickersTable.$convertertexture.toSql(texture.value),
      );
    }
    if (creatorName.present) {
      map['creator_name'] = Variable<String>(creatorName.value);
    }
    if (creatorColor.present) {
      map['creator_color'] = Variable<String>(creatorColor.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $StickersTable.$convertersource.toSql(source.value),
      );
    }
    if (linkedItemId.present) {
      map['linked_item_id'] = Variable<String>(linkedItemId.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (rawPath.present) {
      map['raw_path'] = Variable<String>(rawPath.value);
    }
    if (rawIsCutout.present) {
      map['raw_is_cutout'] = Variable<bool>(rawIsCutout.value);
    }
    if (borderColor.present) {
      map['border_color'] = Variable<String>(borderColor.value);
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
    return (StringBuffer('StickersCompanion(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('texture: $texture, ')
          ..write('creatorName: $creatorName, ')
          ..write('creatorColor: $creatorColor, ')
          ..write('source: $source, ')
          ..write('linkedItemId: $linkedItemId, ')
          ..write('audioPath: $audioPath, ')
          ..write('rawPath: $rawPath, ')
          ..write('rawIsCutout: $rawIsCutout, ')
          ..write('borderColor: $borderColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StickerPagesTable extends StickerPages
    with TableInfo<$StickerPagesTable, StickerPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StickerPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bgColorMeta = const VerificationMeta(
    'bgColor',
  );
  @override
  late final GeneratedColumn<String> bgColor = GeneratedColumn<String>(
    'bg_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bgImagePathMeta = const VerificationMeta(
    'bgImagePath',
  );
  @override
  late final GeneratedColumn<String> bgImagePath = GeneratedColumn<String>(
    'bg_image_path',
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
    title,
    bgColor,
    bgImagePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sticker_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<StickerPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('bg_color')) {
      context.handle(
        _bgColorMeta,
        bgColor.isAcceptableOrUnknown(data['bg_color']!, _bgColorMeta),
      );
    }
    if (data.containsKey('bg_image_path')) {
      context.handle(
        _bgImagePathMeta,
        bgImagePath.isAcceptableOrUnknown(
          data['bg_image_path']!,
          _bgImagePathMeta,
        ),
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
  StickerPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StickerPage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      bgColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bg_color'],
      ),
      bgImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bg_image_path'],
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
  $StickerPagesTable createAlias(String alias) {
    return $StickerPagesTable(attachedDatabase, alias);
  }
}

class StickerPage extends DataClass implements Insertable<StickerPage> {
  final String id;
  final String title;
  final String? bgColor;
  final String? bgImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StickerPage({
    required this.id,
    required this.title,
    this.bgColor,
    this.bgImagePath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || bgColor != null) {
      map['bg_color'] = Variable<String>(bgColor);
    }
    if (!nullToAbsent || bgImagePath != null) {
      map['bg_image_path'] = Variable<String>(bgImagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StickerPagesCompanion toCompanion(bool nullToAbsent) {
    return StickerPagesCompanion(
      id: Value(id),
      title: Value(title),
      bgColor: bgColor == null && nullToAbsent
          ? const Value.absent()
          : Value(bgColor),
      bgImagePath: bgImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(bgImagePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StickerPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StickerPage(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      bgColor: serializer.fromJson<String?>(json['bgColor']),
      bgImagePath: serializer.fromJson<String?>(json['bgImagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'bgColor': serializer.toJson<String?>(bgColor),
      'bgImagePath': serializer.toJson<String?>(bgImagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StickerPage copyWith({
    String? id,
    String? title,
    Value<String?> bgColor = const Value.absent(),
    Value<String?> bgImagePath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StickerPage(
    id: id ?? this.id,
    title: title ?? this.title,
    bgColor: bgColor.present ? bgColor.value : this.bgColor,
    bgImagePath: bgImagePath.present ? bgImagePath.value : this.bgImagePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StickerPage copyWithCompanion(StickerPagesCompanion data) {
    return StickerPage(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      bgColor: data.bgColor.present ? data.bgColor.value : this.bgColor,
      bgImagePath: data.bgImagePath.present
          ? data.bgImagePath.value
          : this.bgImagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StickerPage(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('bgColor: $bgColor, ')
          ..write('bgImagePath: $bgImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, bgColor, bgImagePath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StickerPage &&
          other.id == this.id &&
          other.title == this.title &&
          other.bgColor == this.bgColor &&
          other.bgImagePath == this.bgImagePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StickerPagesCompanion extends UpdateCompanion<StickerPage> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> bgColor;
  final Value<String?> bgImagePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StickerPagesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.bgColor = const Value.absent(),
    this.bgImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickerPagesCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.bgColor = const Value.absent(),
    this.bgImagePath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StickerPage> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? bgColor,
    Expression<String>? bgImagePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (bgColor != null) 'bg_color': bgColor,
      if (bgImagePath != null) 'bg_image_path': bgImagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickerPagesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? bgColor,
    Value<String?>? bgImagePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StickerPagesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      bgColor: bgColor ?? this.bgColor,
      bgImagePath: bgImagePath ?? this.bgImagePath,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (bgColor.present) {
      map['bg_color'] = Variable<String>(bgColor.value);
    }
    if (bgImagePath.present) {
      map['bg_image_path'] = Variable<String>(bgImagePath.value);
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
    return (StringBuffer('StickerPagesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('bgColor: $bgColor, ')
          ..write('bgImagePath: $bgImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PageElementsTable extends PageElements
    with TableInfo<$PageElementsTable, PageElement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageElementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PageElementType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(PageElementType.sticker.name),
      ).withConverter<PageElementType>($PageElementsTable.$convertertype);
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<double> scale = GeneratedColumn<double>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _zMeta = const VerificationMeta('z');
  @override
  late final GeneratedColumn<int> z = GeneratedColumn<int>(
    'z',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    type,
    refId,
    payload,
    x,
    y,
    scale,
    rotation,
    z,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_elements';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageElement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('z')) {
      context.handle(_zMeta, z.isAcceptableOrUnknown(data['z']!, _zMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PageElement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageElement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      type: $PageElementsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scale'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      z: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}z'],
      )!,
    );
  }

  @override
  $PageElementsTable createAlias(String alias) {
    return $PageElementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PageElementType, String, String> $convertertype =
      const EnumNameConverter<PageElementType>(PageElementType.values);
}

class PageElement extends DataClass implements Insertable<PageElement> {
  final String id;
  final String pageId;
  final PageElementType type;
  final String? refId;
  final String payload;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int z;
  const PageElement({
    required this.id,
    required this.pageId,
    required this.type,
    this.refId,
    required this.payload,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.z,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    {
      map['type'] = Variable<String>(
        $PageElementsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<String>(refId);
    }
    map['payload'] = Variable<String>(payload);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['scale'] = Variable<double>(scale);
    map['rotation'] = Variable<double>(rotation);
    map['z'] = Variable<int>(z);
    return map;
  }

  PageElementsCompanion toCompanion(bool nullToAbsent) {
    return PageElementsCompanion(
      id: Value(id),
      pageId: Value(pageId),
      type: Value(type),
      refId: refId == null && nullToAbsent
          ? const Value.absent()
          : Value(refId),
      payload: Value(payload),
      x: Value(x),
      y: Value(y),
      scale: Value(scale),
      rotation: Value(rotation),
      z: Value(z),
    );
  }

  factory PageElement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageElement(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      type: $PageElementsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      refId: serializer.fromJson<String?>(json['refId']),
      payload: serializer.fromJson<String>(json['payload']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      scale: serializer.fromJson<double>(json['scale']),
      rotation: serializer.fromJson<double>(json['rotation']),
      z: serializer.fromJson<int>(json['z']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'type': serializer.toJson<String>(
        $PageElementsTable.$convertertype.toJson(type),
      ),
      'refId': serializer.toJson<String?>(refId),
      'payload': serializer.toJson<String>(payload),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'scale': serializer.toJson<double>(scale),
      'rotation': serializer.toJson<double>(rotation),
      'z': serializer.toJson<int>(z),
    };
  }

  PageElement copyWith({
    String? id,
    String? pageId,
    PageElementType? type,
    Value<String?> refId = const Value.absent(),
    String? payload,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? z,
  }) => PageElement(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    type: type ?? this.type,
    refId: refId.present ? refId.value : this.refId,
    payload: payload ?? this.payload,
    x: x ?? this.x,
    y: y ?? this.y,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    z: z ?? this.z,
  );
  PageElement copyWithCompanion(PageElementsCompanion data) {
    return PageElement(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      type: data.type.present ? data.type.value : this.type,
      refId: data.refId.present ? data.refId.value : this.refId,
      payload: data.payload.present ? data.payload.value : this.payload,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      scale: data.scale.present ? data.scale.value : this.scale,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      z: data.z.present ? data.z.value : this.z,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageElement(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('type: $type, ')
          ..write('refId: $refId, ')
          ..write('payload: $payload, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('scale: $scale, ')
          ..write('rotation: $rotation, ')
          ..write('z: $z')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, pageId, type, refId, payload, x, y, scale, rotation, z);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageElement &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.type == this.type &&
          other.refId == this.refId &&
          other.payload == this.payload &&
          other.x == this.x &&
          other.y == this.y &&
          other.scale == this.scale &&
          other.rotation == this.rotation &&
          other.z == this.z);
}

class PageElementsCompanion extends UpdateCompanion<PageElement> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<PageElementType> type;
  final Value<String?> refId;
  final Value<String> payload;
  final Value<double> x;
  final Value<double> y;
  final Value<double> scale;
  final Value<double> rotation;
  final Value<int> z;
  final Value<int> rowid;
  const PageElementsCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.type = const Value.absent(),
    this.refId = const Value.absent(),
    this.payload = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.scale = const Value.absent(),
    this.rotation = const Value.absent(),
    this.z = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PageElementsCompanion.insert({
    required String id,
    required String pageId,
    this.type = const Value.absent(),
    this.refId = const Value.absent(),
    this.payload = const Value.absent(),
    required double x,
    required double y,
    this.scale = const Value.absent(),
    this.rotation = const Value.absent(),
    this.z = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       x = Value(x),
       y = Value(y);
  static Insertable<PageElement> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? type,
    Expression<String>? refId,
    Expression<String>? payload,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? scale,
    Expression<double>? rotation,
    Expression<int>? z,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (type != null) 'type': type,
      if (refId != null) 'ref_id': refId,
      if (payload != null) 'payload': payload,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (scale != null) 'scale': scale,
      if (rotation != null) 'rotation': rotation,
      if (z != null) 'z': z,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PageElementsCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<PageElementType>? type,
    Value<String?>? refId,
    Value<String>? payload,
    Value<double>? x,
    Value<double>? y,
    Value<double>? scale,
    Value<double>? rotation,
    Value<int>? z,
    Value<int>? rowid,
  }) {
    return PageElementsCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      type: type ?? this.type,
      refId: refId ?? this.refId,
      payload: payload ?? this.payload,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      z: z ?? this.z,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $PageElementsTable.$convertertype.toSql(type.value),
      );
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (scale.present) {
      map['scale'] = Variable<double>(scale.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (z.present) {
      map['z'] = Variable<int>(z.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageElementsCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('type: $type, ')
          ..write('refId: $refId, ')
          ..write('payload: $payload, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('scale: $scale, ')
          ..write('rotation: $rotation, ')
          ..write('z: $z, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CultureItemsTable cultureItems = $CultureItemsTable(this);
  late final $BeamsTable beams = $BeamsTable(this);
  late final $StickersTable stickers = $StickersTable(this);
  late final $StickerPagesTable stickerPages = $StickerPagesTable(this);
  late final $PageElementsTable pageElements = $PageElementsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cultureItems,
    beams,
    stickers,
    stickerPages,
    pageElements,
  ];
}

typedef $$CultureItemsTableCreateCompanionBuilder =
    CultureItemsCompanion Function({
      required String id,
      required CultureCategory category,
      required String title,
      Value<String?> subtitle,
      Value<String?> thumbPath,
      Value<String?> thumbUrl,
      Value<String?> externalId,
      Value<String?> url,
      Value<String?> memo,
      Value<int> oshiLevel,
      Value<String> moodTags,
      Value<String?> moodColor,
      Value<String> detailJson,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> placeName,
      Value<CardSource> source,
      Value<String?> beamFrom,
      Value<String?> beamFromColor,
      Value<bool> isFavorite,
      Value<int?> pinnedOrder,
      required DateTime createdAt,
      Value<DateTime?> consumedAt,
      Value<int> rowid,
    });
typedef $$CultureItemsTableUpdateCompanionBuilder =
    CultureItemsCompanion Function({
      Value<String> id,
      Value<CultureCategory> category,
      Value<String> title,
      Value<String?> subtitle,
      Value<String?> thumbPath,
      Value<String?> thumbUrl,
      Value<String?> externalId,
      Value<String?> url,
      Value<String?> memo,
      Value<int> oshiLevel,
      Value<String> moodTags,
      Value<String?> moodColor,
      Value<String> detailJson,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> placeName,
      Value<CardSource> source,
      Value<String?> beamFrom,
      Value<String?> beamFromColor,
      Value<bool> isFavorite,
      Value<int?> pinnedOrder,
      Value<DateTime> createdAt,
      Value<DateTime?> consumedAt,
      Value<int> rowid,
    });

class $$CultureItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CultureItemsTable> {
  $$CultureItemsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<CultureCategory, CultureCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbUrl => $composableBuilder(
    column: $table.thumbUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get oshiLevel => $composableBuilder(
    column: $table.oshiLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moodTags => $composableBuilder(
    column: $table.moodTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moodColor => $composableBuilder(
    column: $table.moodColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardSource, CardSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get beamFrom => $composableBuilder(
    column: $table.beamFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beamFromColor => $composableBuilder(
    column: $table.beamFromColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pinnedOrder => $composableBuilder(
    column: $table.pinnedOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CultureItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CultureItemsTable> {
  $$CultureItemsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbUrl => $composableBuilder(
    column: $table.thumbUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get oshiLevel => $composableBuilder(
    column: $table.oshiLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moodTags => $composableBuilder(
    column: $table.moodTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moodColor => $composableBuilder(
    column: $table.moodColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beamFrom => $composableBuilder(
    column: $table.beamFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beamFromColor => $composableBuilder(
    column: $table.beamFromColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pinnedOrder => $composableBuilder(
    column: $table.pinnedOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CultureItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CultureItemsTable> {
  $$CultureItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CultureCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<String> get thumbUrl =>
      $composableBuilder(column: $table.thumbUrl, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<int> get oshiLevel =>
      $composableBuilder(column: $table.oshiLevel, builder: (column) => column);

  GeneratedColumn<String> get moodTags =>
      $composableBuilder(column: $table.moodTags, builder: (column) => column);

  GeneratedColumn<String> get moodColor =>
      $composableBuilder(column: $table.moodColor, builder: (column) => column);

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get beamFrom =>
      $composableBuilder(column: $table.beamFrom, builder: (column) => column);

  GeneratedColumn<String> get beamFromColor => $composableBuilder(
    column: $table.beamFromColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pinnedOrder => $composableBuilder(
    column: $table.pinnedOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
    column: $table.consumedAt,
    builder: (column) => column,
  );
}

class $$CultureItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CultureItemsTable,
          CultureItem,
          $$CultureItemsTableFilterComposer,
          $$CultureItemsTableOrderingComposer,
          $$CultureItemsTableAnnotationComposer,
          $$CultureItemsTableCreateCompanionBuilder,
          $$CultureItemsTableUpdateCompanionBuilder,
          (
            CultureItem,
            BaseReferences<_$AppDatabase, $CultureItemsTable, CultureItem>,
          ),
          CultureItem,
          PrefetchHooks Function()
        > {
  $$CultureItemsTableTableManager(_$AppDatabase db, $CultureItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CultureItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CultureItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CultureItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<CultureCategory> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<String?> thumbUrl = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> oshiLevel = const Value.absent(),
                Value<String> moodTags = const Value.absent(),
                Value<String?> moodColor = const Value.absent(),
                Value<String> detailJson = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> placeName = const Value.absent(),
                Value<CardSource> source = const Value.absent(),
                Value<String?> beamFrom = const Value.absent(),
                Value<String?> beamFromColor = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int?> pinnedOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CultureItemsCompanion(
                id: id,
                category: category,
                title: title,
                subtitle: subtitle,
                thumbPath: thumbPath,
                thumbUrl: thumbUrl,
                externalId: externalId,
                url: url,
                memo: memo,
                oshiLevel: oshiLevel,
                moodTags: moodTags,
                moodColor: moodColor,
                detailJson: detailJson,
                lat: lat,
                lng: lng,
                placeName: placeName,
                source: source,
                beamFrom: beamFrom,
                beamFromColor: beamFromColor,
                isFavorite: isFavorite,
                pinnedOrder: pinnedOrder,
                createdAt: createdAt,
                consumedAt: consumedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required CultureCategory category,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> thumbPath = const Value.absent(),
                Value<String?> thumbUrl = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> oshiLevel = const Value.absent(),
                Value<String> moodTags = const Value.absent(),
                Value<String?> moodColor = const Value.absent(),
                Value<String> detailJson = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> placeName = const Value.absent(),
                Value<CardSource> source = const Value.absent(),
                Value<String?> beamFrom = const Value.absent(),
                Value<String?> beamFromColor = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int?> pinnedOrder = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> consumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CultureItemsCompanion.insert(
                id: id,
                category: category,
                title: title,
                subtitle: subtitle,
                thumbPath: thumbPath,
                thumbUrl: thumbUrl,
                externalId: externalId,
                url: url,
                memo: memo,
                oshiLevel: oshiLevel,
                moodTags: moodTags,
                moodColor: moodColor,
                detailJson: detailJson,
                lat: lat,
                lng: lng,
                placeName: placeName,
                source: source,
                beamFrom: beamFrom,
                beamFromColor: beamFromColor,
                isFavorite: isFavorite,
                pinnedOrder: pinnedOrder,
                createdAt: createdAt,
                consumedAt: consumedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CultureItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CultureItemsTable,
      CultureItem,
      $$CultureItemsTableFilterComposer,
      $$CultureItemsTableOrderingComposer,
      $$CultureItemsTableAnnotationComposer,
      $$CultureItemsTableCreateCompanionBuilder,
      $$CultureItemsTableUpdateCompanionBuilder,
      (
        CultureItem,
        BaseReferences<_$AppDatabase, $CultureItemsTable, CultureItem>,
      ),
      CultureItem,
      PrefetchHooks Function()
    >;
typedef $$BeamsTableCreateCompanionBuilder =
    BeamsCompanion Function({
      required String id,
      required BeamDirection direction,
      required String peerName,
      Value<String?> peerColor,
      required String cardId,
      required DateTime beamedAt,
      Value<int> rowid,
    });
typedef $$BeamsTableUpdateCompanionBuilder =
    BeamsCompanion Function({
      Value<String> id,
      Value<BeamDirection> direction,
      Value<String> peerName,
      Value<String?> peerColor,
      Value<String> cardId,
      Value<DateTime> beamedAt,
      Value<int> rowid,
    });

class $$BeamsTableFilterComposer extends Composer<_$AppDatabase, $BeamsTable> {
  $$BeamsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<BeamDirection, BeamDirection, String>
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get peerName => $composableBuilder(
    column: $table.peerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerColor => $composableBuilder(
    column: $table.peerColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get beamedAt => $composableBuilder(
    column: $table.beamedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $BeamsTable> {
  $$BeamsTableOrderingComposer({
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

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerName => $composableBuilder(
    column: $table.peerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerColor => $composableBuilder(
    column: $table.peerColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get beamedAt => $composableBuilder(
    column: $table.beamedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeamsTable> {
  $$BeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BeamDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get peerName =>
      $composableBuilder(column: $table.peerName, builder: (column) => column);

  GeneratedColumn<String> get peerColor =>
      $composableBuilder(column: $table.peerColor, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<DateTime> get beamedAt =>
      $composableBuilder(column: $table.beamedAt, builder: (column) => column);
}

class $$BeamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeamsTable,
          Beam,
          $$BeamsTableFilterComposer,
          $$BeamsTableOrderingComposer,
          $$BeamsTableAnnotationComposer,
          $$BeamsTableCreateCompanionBuilder,
          $$BeamsTableUpdateCompanionBuilder,
          (Beam, BaseReferences<_$AppDatabase, $BeamsTable, Beam>),
          Beam,
          PrefetchHooks Function()
        > {
  $$BeamsTableTableManager(_$AppDatabase db, $BeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<BeamDirection> direction = const Value.absent(),
                Value<String> peerName = const Value.absent(),
                Value<String?> peerColor = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<DateTime> beamedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeamsCompanion(
                id: id,
                direction: direction,
                peerName: peerName,
                peerColor: peerColor,
                cardId: cardId,
                beamedAt: beamedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required BeamDirection direction,
                required String peerName,
                Value<String?> peerColor = const Value.absent(),
                required String cardId,
                required DateTime beamedAt,
                Value<int> rowid = const Value.absent(),
              }) => BeamsCompanion.insert(
                id: id,
                direction: direction,
                peerName: peerName,
                peerColor: peerColor,
                cardId: cardId,
                beamedAt: beamedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeamsTable,
      Beam,
      $$BeamsTableFilterComposer,
      $$BeamsTableOrderingComposer,
      $$BeamsTableAnnotationComposer,
      $$BeamsTableCreateCompanionBuilder,
      $$BeamsTableUpdateCompanionBuilder,
      (Beam, BaseReferences<_$AppDatabase, $BeamsTable, Beam>),
      Beam,
      PrefetchHooks Function()
    >;
typedef $$StickersTableCreateCompanionBuilder =
    StickersCompanion Function({
      required String id,
      required String imagePath,
      Value<StickerTexture> texture,
      required String creatorName,
      Value<String?> creatorColor,
      Value<CardSource> source,
      Value<String?> linkedItemId,
      Value<String?> audioPath,
      Value<String?> rawPath,
      Value<bool> rawIsCutout,
      Value<String?> borderColor,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$StickersTableUpdateCompanionBuilder =
    StickersCompanion Function({
      Value<String> id,
      Value<String> imagePath,
      Value<StickerTexture> texture,
      Value<String> creatorName,
      Value<String?> creatorColor,
      Value<CardSource> source,
      Value<String?> linkedItemId,
      Value<String?> audioPath,
      Value<String?> rawPath,
      Value<bool> rawIsCutout,
      Value<String?> borderColor,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$StickersTableFilterComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableFilterComposer({
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

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StickerTexture, StickerTexture, String>
  get texture => $composableBuilder(
    column: $table.texture,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorColor => $composableBuilder(
    column: $table.creatorColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardSource, CardSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get linkedItemId => $composableBuilder(
    column: $table.linkedItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawPath => $composableBuilder(
    column: $table.rawPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rawIsCutout => $composableBuilder(
    column: $table.rawIsCutout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StickersTableOrderingComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableOrderingComposer({
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

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get texture => $composableBuilder(
    column: $table.texture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorColor => $composableBuilder(
    column: $table.creatorColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedItemId => $composableBuilder(
    column: $table.linkedItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawPath => $composableBuilder(
    column: $table.rawPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rawIsCutout => $composableBuilder(
    column: $table.rawIsCutout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StickersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StickersTable> {
  $$StickersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StickerTexture, String> get texture =>
      $composableBuilder(column: $table.texture, builder: (column) => column);

  GeneratedColumn<String> get creatorName => $composableBuilder(
    column: $table.creatorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creatorColor => $composableBuilder(
    column: $table.creatorColor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CardSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get linkedItemId => $composableBuilder(
    column: $table.linkedItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get rawPath =>
      $composableBuilder(column: $table.rawPath, builder: (column) => column);

  GeneratedColumn<bool> get rawIsCutout => $composableBuilder(
    column: $table.rawIsCutout,
    builder: (column) => column,
  );

  GeneratedColumn<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StickersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StickersTable,
          Sticker,
          $$StickersTableFilterComposer,
          $$StickersTableOrderingComposer,
          $$StickersTableAnnotationComposer,
          $$StickersTableCreateCompanionBuilder,
          $$StickersTableUpdateCompanionBuilder,
          (Sticker, BaseReferences<_$AppDatabase, $StickersTable, Sticker>),
          Sticker,
          PrefetchHooks Function()
        > {
  $$StickersTableTableManager(_$AppDatabase db, $StickersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StickersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StickersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StickersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<StickerTexture> texture = const Value.absent(),
                Value<String> creatorName = const Value.absent(),
                Value<String?> creatorColor = const Value.absent(),
                Value<CardSource> source = const Value.absent(),
                Value<String?> linkedItemId = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String?> rawPath = const Value.absent(),
                Value<bool> rawIsCutout = const Value.absent(),
                Value<String?> borderColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StickersCompanion(
                id: id,
                imagePath: imagePath,
                texture: texture,
                creatorName: creatorName,
                creatorColor: creatorColor,
                source: source,
                linkedItemId: linkedItemId,
                audioPath: audioPath,
                rawPath: rawPath,
                rawIsCutout: rawIsCutout,
                borderColor: borderColor,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String imagePath,
                Value<StickerTexture> texture = const Value.absent(),
                required String creatorName,
                Value<String?> creatorColor = const Value.absent(),
                Value<CardSource> source = const Value.absent(),
                Value<String?> linkedItemId = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<String?> rawPath = const Value.absent(),
                Value<bool> rawIsCutout = const Value.absent(),
                Value<String?> borderColor = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StickersCompanion.insert(
                id: id,
                imagePath: imagePath,
                texture: texture,
                creatorName: creatorName,
                creatorColor: creatorColor,
                source: source,
                linkedItemId: linkedItemId,
                audioPath: audioPath,
                rawPath: rawPath,
                rawIsCutout: rawIsCutout,
                borderColor: borderColor,
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

typedef $$StickersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StickersTable,
      Sticker,
      $$StickersTableFilterComposer,
      $$StickersTableOrderingComposer,
      $$StickersTableAnnotationComposer,
      $$StickersTableCreateCompanionBuilder,
      $$StickersTableUpdateCompanionBuilder,
      (Sticker, BaseReferences<_$AppDatabase, $StickersTable, Sticker>),
      Sticker,
      PrefetchHooks Function()
    >;
typedef $$StickerPagesTableCreateCompanionBuilder =
    StickerPagesCompanion Function({
      required String id,
      Value<String> title,
      Value<String?> bgColor,
      Value<String?> bgImagePath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StickerPagesTableUpdateCompanionBuilder =
    StickerPagesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> bgColor,
      Value<String?> bgImagePath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StickerPagesTableFilterComposer
    extends Composer<_$AppDatabase, $StickerPagesTable> {
  $$StickerPagesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bgColor => $composableBuilder(
    column: $table.bgColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bgImagePath => $composableBuilder(
    column: $table.bgImagePath,
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

class $$StickerPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $StickerPagesTable> {
  $$StickerPagesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bgColor => $composableBuilder(
    column: $table.bgColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bgImagePath => $composableBuilder(
    column: $table.bgImagePath,
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

class $$StickerPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StickerPagesTable> {
  $$StickerPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get bgColor =>
      $composableBuilder(column: $table.bgColor, builder: (column) => column);

  GeneratedColumn<String> get bgImagePath => $composableBuilder(
    column: $table.bgImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StickerPagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StickerPagesTable,
          StickerPage,
          $$StickerPagesTableFilterComposer,
          $$StickerPagesTableOrderingComposer,
          $$StickerPagesTableAnnotationComposer,
          $$StickerPagesTableCreateCompanionBuilder,
          $$StickerPagesTableUpdateCompanionBuilder,
          (
            StickerPage,
            BaseReferences<_$AppDatabase, $StickerPagesTable, StickerPage>,
          ),
          StickerPage,
          PrefetchHooks Function()
        > {
  $$StickerPagesTableTableManager(_$AppDatabase db, $StickerPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StickerPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StickerPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StickerPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> bgColor = const Value.absent(),
                Value<String?> bgImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StickerPagesCompanion(
                id: id,
                title: title,
                bgColor: bgColor,
                bgImagePath: bgImagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<String?> bgColor = const Value.absent(),
                Value<String?> bgImagePath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StickerPagesCompanion.insert(
                id: id,
                title: title,
                bgColor: bgColor,
                bgImagePath: bgImagePath,
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

typedef $$StickerPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StickerPagesTable,
      StickerPage,
      $$StickerPagesTableFilterComposer,
      $$StickerPagesTableOrderingComposer,
      $$StickerPagesTableAnnotationComposer,
      $$StickerPagesTableCreateCompanionBuilder,
      $$StickerPagesTableUpdateCompanionBuilder,
      (
        StickerPage,
        BaseReferences<_$AppDatabase, $StickerPagesTable, StickerPage>,
      ),
      StickerPage,
      PrefetchHooks Function()
    >;
typedef $$PageElementsTableCreateCompanionBuilder =
    PageElementsCompanion Function({
      required String id,
      required String pageId,
      Value<PageElementType> type,
      Value<String?> refId,
      Value<String> payload,
      required double x,
      required double y,
      Value<double> scale,
      Value<double> rotation,
      Value<int> z,
      Value<int> rowid,
    });
typedef $$PageElementsTableUpdateCompanionBuilder =
    PageElementsCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<PageElementType> type,
      Value<String?> refId,
      Value<String> payload,
      Value<double> x,
      Value<double> y,
      Value<double> scale,
      Value<double> rotation,
      Value<int> z,
      Value<int> rowid,
    });

class $$PageElementsTableFilterComposer
    extends Composer<_$AppDatabase, $PageElementsTable> {
  $$PageElementsTableFilterComposer({
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

  ColumnFilters<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PageElementType, PageElementType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PageElementsTableOrderingComposer
    extends Composer<_$AppDatabase, $PageElementsTable> {
  $$PageElementsTableOrderingComposer({
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

  ColumnOrderings<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PageElementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageElementsTable> {
  $$PageElementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PageElementType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<int> get z =>
      $composableBuilder(column: $table.z, builder: (column) => column);
}

class $$PageElementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PageElementsTable,
          PageElement,
          $$PageElementsTableFilterComposer,
          $$PageElementsTableOrderingComposer,
          $$PageElementsTableAnnotationComposer,
          $$PageElementsTableCreateCompanionBuilder,
          $$PageElementsTableUpdateCompanionBuilder,
          (
            PageElement,
            BaseReferences<_$AppDatabase, $PageElementsTable, PageElement>,
          ),
          PageElement,
          PrefetchHooks Function()
        > {
  $$PageElementsTableTableManager(_$AppDatabase db, $PageElementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageElementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageElementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageElementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<PageElementType> type = const Value.absent(),
                Value<String?> refId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> scale = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<int> z = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageElementsCompanion(
                id: id,
                pageId: pageId,
                type: type,
                refId: refId,
                payload: payload,
                x: x,
                y: y,
                scale: scale,
                rotation: rotation,
                z: z,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                Value<PageElementType> type = const Value.absent(),
                Value<String?> refId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                required double x,
                required double y,
                Value<double> scale = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<int> z = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PageElementsCompanion.insert(
                id: id,
                pageId: pageId,
                type: type,
                refId: refId,
                payload: payload,
                x: x,
                y: y,
                scale: scale,
                rotation: rotation,
                z: z,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PageElementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PageElementsTable,
      PageElement,
      $$PageElementsTableFilterComposer,
      $$PageElementsTableOrderingComposer,
      $$PageElementsTableAnnotationComposer,
      $$PageElementsTableCreateCompanionBuilder,
      $$PageElementsTableUpdateCompanionBuilder,
      (
        PageElement,
        BaseReferences<_$AppDatabase, $PageElementsTable, PageElement>,
      ),
      PageElement,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CultureItemsTableTableManager get cultureItems =>
      $$CultureItemsTableTableManager(_db, _db.cultureItems);
  $$BeamsTableTableManager get beams =>
      $$BeamsTableTableManager(_db, _db.beams);
  $$StickersTableTableManager get stickers =>
      $$StickersTableTableManager(_db, _db.stickers);
  $$StickerPagesTableTableManager get stickerPages =>
      $$StickerPagesTableTableManager(_db, _db.stickerPages);
  $$PageElementsTableTableManager get pageElements =>
      $$PageElementsTableTableManager(_db, _db.pageElements);
}
