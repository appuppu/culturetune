import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/thumb_image.dart';
import '../detail/culture_modal.dart';
import 'photo_pin.dart';

final foodItemsProvider = StreamProvider.autoDispose((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchItems(category: CultureCategory.food);
});

/// ご飯マップ。iOSはMapKitのピン留めマップ、Androidはリスト+外部マップ起動。
class FoodMapPage extends ConsumerWidget {
  const FoodMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(foodItemsProvider).valueOrNull ?? [];
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(title: const Text('ご飯マップ')),
      body: items.isEmpty
          ? Center(
              child: Text(
                'まだご飯カードがないよ',
                style: TextStyle(color: CTColors.textSub),
              ),
            )
          : isIOS
          ? _IosMap(items: items)
          : _FoodList(items: items),
    );
  }
}

class _IosMap extends ConsumerWidget {
  const _IosMap({required this.items});

  final List<CultureItem> items;

  Color _moodColor(CultureItem item) {
    final hex = item.moodColor;
    if (hex == null || !hex.startsWith('#')) return item.category.color;
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? item.category.color : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedItems = items
        .where((i) => i.lat != null && i.lng != null)
        .toList();

    if (pinnedItems.isEmpty) {
      // 位置情報付きカードがなければリスト表示にフォールバック
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CTColors.lemon.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(CTRadius.card),
            ),
            child: const Text(
              '登録時にお店を検索するか「現在地をピン留め」をオンにするとここに出るよ',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(child: _FoodList(items: items)),
        ],
      );
    }

    final repo = ref.watch(itemRepositoryProvider);
    return FutureBuilder<Set<Annotation>>(
      // 写真を丸く型どったカード色のピンを非同期で生成する
      future: () async {
        final annotations = <Annotation>{};
        for (final item in pinnedItems) {
          final color = _moodColor(item);
          final bytes = await buildPhotoPinBytes(item, color, repo);
          annotations.add(
            Annotation(
              annotationId: AnnotationId(item.id),
              position: LatLng(item.lat!, item.lng!),
              icon: BitmapDescriptor.fromBytes(bytes),
              anchor: const Offset(0.5, 1),
              onTap: () => openCultureItem(context, ref, item),
            ),
          );
        }
        return annotations;
      }(),
      builder: (context, snapshot) {
        final first = pinnedItems.first;
        return Stack(
          children: [
            AppleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(first.lat!, first.lng!),
                zoom: 13,
              ),
              annotations: snapshot.data ?? const {},
            ),
            if (!snapshot.hasData)
              const Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}

/// Android(および位置なしiOS)向け: リスト+外部マップ起動
class _FoodList extends ConsumerWidget {
  const _FoodList({required this.items});

  final List<CultureItem> items;

  Future<void> _openMap(BuildContext context, CultureItem item) async {
    final Uri uri;
    if (item.lat != null && item.lng != null) {
      uri = Uri.parse(
        'geo:${item.lat},${item.lng}?q=${item.lat},${item.lng}'
        '(${Uri.encodeComponent(item.placeName ?? item.title)})',
      );
    } else if (item.placeName != null) {
      uri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(item.placeName!)}');
    } else {
      return;
    }
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('マップを開けなかった…')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final hasPlace =
            item.placeName != null || (item.lat != null && item.lng != null);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: SizedBox(
              width: 52,
              height: 52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ThumbImage(item: item),
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: item.placeName != null ? Text(item.placeName!) : null,
            trailing: hasPlace
                ? IconButton(
                    icon: Icon(Icons.map_rounded, color: CTColors.peach),
                    onPressed: () => _openMap(context, item),
                    tooltip: 'マップで開く',
                  )
                : null,
            onTap: () => openCultureItem(context, ref, item),
          ),
        );
      },
    );
  }
}
