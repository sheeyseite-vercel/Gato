import 'package:flutter/material.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> quoteDialog(BuildContext context, {Map<String, dynamic>? quote}) async {
  final text = TextEditingController(text: (quote?['text'] as String?) ?? '');
  final source = TextEditingController(text: (quote?['source'] as String?) ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: C.deep,
      title: Text(quote == null ? 'New quote' : 'Edit quote', style: txt(17, w: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: text,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'The quote'),
          style: txt(16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: source,
          decoration: const InputDecoration(hintText: 'Source (optional)'),
          style: txt(16),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: txt(14, color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Save', style: txt(14, color: C.lime, w: FontWeight.w700))),
      ],
    ),
  );
  final t = text.text.trim(), s = source.text.trim();
  text.dispose();
  source.dispose();
  if (ok != true || t.isEmpty) return;
  try {
    await Repo.save('gato_quotes', {'text': t, 'source': s}, id: quote?['id'] as String?);
  } catch (_) {
    if (context.mounted) toast(context, "Couldn't save the quote.");
  }
}

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});
  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  bool _favOnly = false;

  static const _bg = [C.mint, C.ice, C.white];

  @override
  Widget build(BuildContext context) {
    return LiveData<Rows>(loader: () => Repo.list('gato_quotes'), builder: _content);
  }

  Widget _content(BuildContext context, Rows all) {
    final list = _favOnly ? all.where((q) => q['favorite'] == true).toList() : all;
    Map<String, dynamic>? featured;
    for (final q in all) {
      if (q['favorite'] == true) {
        featured = q;
        break;
      }
    }
    featured ??= all.isNotEmpty ? all.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
      children: [
        Text('Quotes', style: disp(36)),
        if (featured != null)
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 54),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: C.lime,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Featured', style: txt(12, color: C.green, w: FontWeight.w700)),
                const SizedBox(height: 4),
                dirText(featured['text'] as String, disp(24, color: C.green).copyWith(height: 1.35)),
                if ((featured['source'] as String? ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(featured['source'] as String, style: txt(13, color: C.green)),
                  ),
              ]),
            ),
            const Positioned(top: 11, left: 30, child: CatPeek()),
          ])
        else
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(children: [
              const CatLogo(size: 96),
              const SizedBox(height: 14),
              Text('No quotes yet.', style: disp(20)),
              const SizedBox(height: 4),
              Text('Tap + to save one, or save a line from your journal.', textAlign: TextAlign.center, style: txt(14, color: C.muted)),
            ]),
          ),
        const SizedBox(height: 16),
        Row(children: [
          GChip('All', selected: !_favOnly, onTap: () => setState(() => _favOnly = false)),
          const SizedBox(width: 8),
          GChip('Favorites', selected: _favOnly, onTap: () => setState(() => _favOnly = true)),
        ]),
        for (var i = 0; i < list.length; i++) _card(context, list[i], i),
      ],
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> q, int i) {
    final fav = q['favorite'] == true;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Dismissible(
        key: ValueKey(q['id']),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.delete_outline_rounded, color: C.green),
        ),
        confirmDismiss: (_) async {
          if (await confirm(context, 'Delete this quote?')) {
            try {
              await Repo.remove('gato_quotes', q['id'] as String);
            } catch (_) {
              if (context.mounted) toast(context, "Couldn't delete.");
            }
          }
          return false;
        },
        child: GestureDetector(
          onTap: () => quoteDialog(context, quote: q),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
            decoration: BoxDecoration(color: _bg[i % 3], borderRadius: BorderRadius.circular(24)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  dirText(q['text'] as String, disp(18, color: C.green).copyWith(height: 1.4)),
                  if ((q['source'] as String? ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(q['source'] as String, style: txt(12, color: C.green)),
                    ),
                ]),
              ),
              IconButton(
                tooltip: fav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () async {
                  try {
                    await Repo.save('gato_quotes', {'favorite': !fav}, id: q['id'] as String);
                  } catch (_) {
                    if (context.mounted) toast(context, "Couldn't update.");
                  }
                },
                icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: fav ? C.orange : C.green),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
