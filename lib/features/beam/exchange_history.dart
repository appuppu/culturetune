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
}) async {
  final db = ref.read(databaseProvider);
  await db.insertBeam(
    BeamsCompanion.insert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      direction: direction,
      peerName: peerName,
      peerColor: Value(peerColor),
      cardId: label,
      beamedAt: DateTime.now(),
    ),
  );
}

/// 交換履歴シート(だれと・なにを・いつ・どっち向き)
void showExchangeHistorySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: CTColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CTRadius.sheet)),
    ),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final list = ref.watch(exchangeHistoryProvider).valueOrNull ?? [];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  '交換のきろく',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                  child: Text(
                    'まだ交換履歴がないよ',
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
