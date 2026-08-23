import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/data/post_draft.dart';
import '../../core/models/culture_category.dart';
import '../../core/models/culture_detail.dart';
import '../../core/platform/local_search.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/candy_button.dart';
import 'finish_page.dart';

/// ご飯: 写真(正方形クロップ) + 店名(iOSは店舗検索) + 推しメニュー + 位置
class FoodPostPage extends StatefulWidget {
  const FoodPostPage({super.key});

  @override
  State<FoodPostPage> createState() => _FoodPostPageState();
}

class _FoodPostPageState extends State<FoodPostPage> {
  final _picker = ImagePicker();
  final _store = TextEditingController();
  final _menu = TextEditingController();
  final _price = TextEditingController();
  String? _imagePath;
  bool _pinLocation = false;
  Position? _position;
  bool _locating = false;

  /// 店舗検索で選んだお店(選択中は現在地ピンの代わりにこちらを使う)
  PlaceResult? _selectedPlace;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void dispose() {
    _store.dispose();
    _menu.dispose();
    _price.dispose();
    super.dispose();
  }

  /// 撮影/選択 → カードに合う正方形フレームへクロップ
  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (file == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '写真をフレームに合わせる',
          toolbarColor: CTColors.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: '写真をフレームに合わせる',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped != null && mounted) {
      setState(() => _imagePath = cropped.path);
    }
  }

  Future<Position?> _currentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _toggleLocation(bool on) async {
    if (!on) {
      setState(() {
        _pinLocation = false;
        _position = null;
      });
      return;
    }
    setState(() => _locating = true);
    try {
      final pos = await _currentPosition();
      if (pos == null) throw '位置情報の許可がないよ';
      if (!mounted) return;
      setState(() {
        _pinLocation = true;
        _position = pos;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('現在地を取得できなかった ($e)')));
      setState(() => _pinLocation = false);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openStoreSearch() async {
    final selected = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CTColors.bgBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (_) => _StoreSearchSheet(initialQuery: _store.text),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedPlace = selected;
        _store.text = selected.name;
        // 店舗を選んだら現在地ピンは不要になる
        _pinLocation = false;
        _position = null;
      });
    }
  }

  void _next() {
    final menu = _menu.text.trim();
    final store = _store.text.trim();
    final lat = _selectedPlace?.lat ?? _position?.latitude;
    final lng = _selectedPlace?.lng ?? _position?.longitude;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinishPage(
          draft: PostDraft(
            category: CultureCategory.food,
            title: menu.isNotEmpty ? menu : store,
            subtitle: menu.isNotEmpty && store.isNotEmpty ? store : null,
            localImagePath: _imagePath,
            lat: lat,
            lng: lng,
            placeName: store.isNotEmpty ? store : null,
            detail: FoodDetail(
              storeName: store.isNotEmpty ? store : null,
              menuName: menu.isNotEmpty ? menu : null,
              priceYen: int.tryParse(_price.text.trim()),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canNext =
        _menu.text.trim().isNotEmpty || _store.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('ご飯を登録')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // カードと同じ正方形フレームで写真を見せる
            Center(
              child: GestureDetector(
                onTap: () => _showPickSheet(),
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: CTColors.peach.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(CTRadius.card),
                    border: Border.all(color: CTColors.peach, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            CTRadius.inner(CTRadius.card, 2),
                          ),
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                size: 40,
                                color: CTColors.peach,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'タップして写真を追加',
                                style: TextStyle(color: CTColors.textSub),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _menu,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: '推しメニュー名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _store,
              onChanged: (_) => setState(() {
                // 手入力し直したら店舗選択は解除
                if (_selectedPlace != null &&
                    _store.text != _selectedPlace!.name) {
                  _selectedPlace = null;
                }
              }),
              decoration: InputDecoration(
                labelText: '店名',
                suffixIcon: LocalSearch.isSupported
                    ? IconButton(
                        icon: const Icon(Icons.search_rounded),
                        tooltip: 'お店を検索',
                        onPressed: _openStoreSearch,
                      )
                    : null,
              ),
            ),
            if (_selectedPlace != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: CTColors.mint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(CTRadius.card),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: CTColors.textMain,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_selectedPlace!.name}\n${_selectedPlace!.address}',
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _selectedPlace = null),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '値段(円・任意)'),
            ),
            // 店舗を選んでいる間は現在地ピンは不要なので隠す
            if (_isIOS && _selectedPlace == null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('現在地をマップにピン留め'),
                subtitle: _position != null
                    ? const Text('取得できたよ!', style: TextStyle(fontSize: 12))
                    : null,
                value: _pinLocation,
                onChanged: _locating ? null : _toggleLocation,
                activeTrackColor: CTColors.primary,
              ),
            ],
            const SizedBox(height: 20),
            CandyButton(label: 'つぎへ', onPressed: canNext ? _next : null),
          ],
        ),
      ),
    );
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CTRadius.sheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('カメラで撮る'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('ライブラリから選ぶ'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS限定: MKLocalSearchでお店をインクリメンタル検索するシート
class _StoreSearchSheet extends StatefulWidget {
  const _StoreSearchSheet({required this.initialQuery});

  final String initialQuery;

  @override
  State<_StoreSearchSheet> createState() => _StoreSearchSheetState();
}

class _StoreSearchSheetState extends State<_StoreSearchSheet> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  List<PlaceResult> _results = [];
  bool _loading = false;
  Position? _position;

  @override
  void initState() {
    super.initState();
    // 周辺検索を優先するため現在地をベストエフォートで取得
    Geolocator.getLastKnownPosition().then((pos) {
      _position = pos;
    });
    if (widget.initialQuery.trim().isNotEmpty) _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await LocalSearch.search(
      query,
      lat: _position?.latitude,
      lng: _position?.longitude,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // キーボード分持ち上げる
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'お店の名前で検索…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: CTColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CTRadius.card),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final place = _results[i];
                    return ListTile(
                      leading: Icon(Icons.place_rounded, color: CTColors.peach),
                      title: Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => Navigator.pop(context, place),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
