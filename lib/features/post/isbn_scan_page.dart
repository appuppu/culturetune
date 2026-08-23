import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/providers.dart';
import '../../core/api/book_repository.dart';
import '../../core/data/post_draft.dart';
import '../../core/models/culture_category.dart';
import '../../core/models/culture_detail.dart';
import '../../core/theme/tokens.dart';
import 'finish_page.dart';

/// 本: ISBNバーコードスキャン(EAN-13, 978/979) + 手入力フォールバック
class IsbnScanPage extends ConsumerStatefulWidget {
  const IsbnScanPage({super.key});

  @override
  ConsumerState<IsbnScanPage> createState() => _IsbnScanPageState();
}

class _IsbnScanPageState extends ConsumerState<IsbnScanPage> {
  final _scanController = MobileScannerController(
    formats: [BarcodeFormat.ean13],
  );
  final _manualController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _scanController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _lookup(String isbn) async {
    if (_busy) return;
    setState(() => _busy = true);
    await _scanController.stop();

    final book = await ref.read(bookRepositoryProvider).fetchByIsbn(isbn);
    if (!mounted) return;

    if (book == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ISBN $isbn の本が見つからなかった…')));
      setState(() => _busy = false);
      await _scanController.start();
      return;
    }

    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinishPage(
          draft: PostDraft(
            category: CultureCategory.book,
            title: book.title,
            subtitle: book.author,
            thumbUrl: book.coverUrl,
            externalId: 'isbn:${book.isbn}',
            detail: BookDetail(
              isbn: book.isbn,
              author: book.author,
              publisher: book.publisher,
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    await _scanController.start();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      // 書籍JANの1段目(ISBN-13)のみ拾う
      if (code != null &&
          code.length == 13 &&
          (code.startsWith('978') || code.startsWith('979'))) {
        _lookup(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本のバーコードをスキャン')),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CTRadius.card),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scanController,
                    onDetect: _onDetect,
                    errorBuilder: (_, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'カメラを起動できないよ\n(${error.errorCode.name})\n下のISBN手入力を使ってね',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: CTColors.textSub),
                        ),
                      ),
                    ),
                  ),
                  if (_busy)
                    const ColoredBox(
                      color: Colors.black38,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  // スキャン枠ガイド
                  Center(
                    child: Container(
                      width: 260,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: CTColors.mint, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'ISBNを手入力(978…)',
                        filled: true,
                        fillColor: CTColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CTRadius.card),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final isbn = BookRepository.normalizeIsbn(
                        _manualController.text,
                      );
                      if (isbn != null) _lookup(isbn);
                    },
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
