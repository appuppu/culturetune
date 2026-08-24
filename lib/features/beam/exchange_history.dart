import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/app_database.dart';
import '../../core/models/culture_category.dart';
import '../../core/theme/tokens.dart';
import 'beam_profile_provider.dart';

/// 交換履歴(新しい順)。交換タブとシール帳タブで共用
final exchangeHistoryProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(databaseProvider).watchBeams(),
);

/// 交換のやり取りログを記録する。
/// cardIdには「なにを交換したか」のラベルを入れる(例: シール帳「8月の旅」)
Future<void> recordExchange(
  WidgetRef ref, {
  required BeamDirection direction,
  required String peerName,
  String? peerColor,
  required String label,
  String? pageId,
}) async {
  final db = ref.read(databaseProvider);
  await db.insertBeam(
    BeamsCompanion.insert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      direction: direction,
      peerName: peerName,
      peerColor: Value(peerColor),
      cardId: label,
      pageId: Value(pageId),
      beamedAt: DateTime.now(),
    ),
  );
}

/// 交換履歴シート(だれと・なにを・いつ・どっち向き)。
/// pageIdを渡すとそのシール帳のやり取りだけに絞る
void showExchangeHistorySheet(BuildContext context, {String? pageId}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        var list = ref.watch(exchangeHistoryProvider).valueOrNull ?? [];
        if (pageId != null) {
          list = [
            for (final b in list)
              if (b.pageId == pageId) b,
          ];
        }
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  pageId == null ? '交換のきろく' : 'このシール帳のきろく',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                  child: Text(
                    pageId == null ? 'まだ交換履歴がないよ' : 'このシール帳はまだ交換してないよ',
                    style: TextStyle(color: CTColors.textSub),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final b = list[i];
                      final isSent = b.direction == BeamDirection.sent;
                      // cardIdが交換内容ラベル(旧データはIDなので日付だけ出す)
                      final label = b.cardId.contains('シール') ? b.cardId : null;
                      final date =
                          '${b.beamedAt.year}/${b.beamedAt.month}/${b.beamedAt.day}';
                      return ListTile(
                        leading: BeamAvatar(
                          name: b.peerName,
                          color: colorFromHex(b.peerColor),
                          radius: 16,
                        ),
                        title: Text(
                          b.peerName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          label == null ? date : '$label · $date',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          isSent
                              ? Icons.call_made_rounded
                              : Icons.call_received_rounded,
                          size: 18,
                          color: isSent ? CTColors.primary : CTColors.mint,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
