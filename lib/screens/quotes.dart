import 'package:flutter/material.dart';
import '../logic.dart';
import '../profile.dart';
import '../quotes_data.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> quoteDialog(BuildContext context, {Map<String, dynamic>? quote}) async {
  await Navigator.push(context, MaterialPageRoute(builder: (_) => QuoteEditor(quote: quote)));
}

const _cardRadius = BorderRadius.only(
  topLeft: Radius.circular(28),
  topRight: Radius.circular(28),
  bottomRight: Radius.circular(28),
  bottomLeft: Radius.circular(8),
);

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  static const _bg = [C.mint, C.ice, C.white];

  @override
  Widget build(BuildContext context) {
    return LiveData<Rows>(loader: () => Repo.list('gato_quotes'), builder: _content);
  }

  Widget _content(BuildContext context, Rows all) {
    final now = DateTime.now();
    final greeting = quoteGreetings[hourCount(now) % quoteGreetings.length];
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
      children: [
        Text('Quotes', style: disp(36)),
        CatCard(
          left: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(color: C.lime, borderRadius: _cardRadius),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ValueListenableBuilder<String?>(
                valueListenable: Profile.name,
                builder: (_, n, __) => Text('Hi ${n ?? 'there'}', style: txt(13, color: C.green, w: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Text(greeting, style: disp(26, color: C.green).copyWith(height: 1.3)),
            ]),
          ),
        ),
        if (all.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Tap + to save your first quote.', style: txt(14, color: C.muted)),
          )
        else
          Text('${all.length} saved', style: txt(14, color: C.muted)),
        for (var i = 0; i < all.length; i++) _card(context, all[i], i),
      ],
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> q, int i) {
    final source = (q['source'] as String?) ?? '';
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
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(color: _bg[i % 3], borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              dirText(q['text'] as String, disp(18, color: C.green).copyWith(height: 1.4)),
              if (source.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: dirText(source, txt(12, color: C.green)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class QuoteEditor extends StatefulWidget {
  final Map<String, dynamic>? quote;
  const QuoteEditor({super.key, this.quote});
  @override
  State<QuoteEditor> createState() => _QuoteEditorState();
}

class _QuoteEditorState extends State<QuoteEditor> {
  late final TextEditingController _text;
  late final TextEditingController _source;
  bool _skip = false, _failed = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: (widget.quote?['text'] as String?) ?? '');
    _source = TextEditingController(text: (widget.quote?['source'] as String?) ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!_skip && !_failed) {
      final t = _text.text.trim();
      if (t.isNotEmpty) {
        try {
          await Repo.save('gato_quotes', {'text': t, 'source': _source.text.trim()}, id: widget.quote?['id'] as String?);
        } catch (_) {
          _failed = true;
          if (mounted) toast(context, "Couldn't save. Go back again to discard.");
          return;
        }
      }
    }
    if (mounted) {
      _skip = true;
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final id = widget.quote?['id'] as String?;
    if (id != null && await confirm(context, 'Delete this quote?')) {
      try {
        await Repo.remove('gato_quotes', id);
      } catch (_) {
        if (mounted) toast(context, "Couldn't delete.");
        return;
      }
      _skip = true;
      if (mounted) Navigator.pop(context);
    }
  }

  TextDirection _dir(String s) => isRtl(s) ? TextDirection.rtl : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Screen(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              CircleBtn(Icons.arrow_back_rounded, label: 'Back', onTap: _close),
              Row(children: [
                if (widget.quote != null) ...[
                  CircleBtn(Icons.delete_outline_rounded, label: 'Delete', onTap: _delete),
                  const SizedBox(width: 10),
                ],
                GestureDetector(
                  onTap: _close,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: C.lime, borderRadius: BorderRadius.circular(22)),
                    child: Text('Save', style: txt(15, color: C.green, w: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              children: [
                CatCard(
                  left: false,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 260),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: const BoxDecoration(color: C.lime, borderRadius: _cardRadius),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('”', style: disp(60, color: op(C.green, .35)).copyWith(height: .9)),
                      TextField(
                        controller: _text,
                        onChanged: (_) => setState(() {}),
                        minLines: 5,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textDirection: _dir(_text.text),
                        cursorColor: C.green,
                        style: disp(22, color: C.green).copyWith(height: 1.4),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Write the quote…',
                          hintStyle: disp(22, color: op(C.green, .45)).copyWith(height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ),
                Glass(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, color: C.muted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _source,
                        onChanged: (_) => setState(() {}),
                        textDirection: _dir(_source.text),
                        cursorColor: C.lime,
                        style: txt(16),
                        decoration: InputDecoration.collapsed(hintText: 'Add source', hintStyle: txt(16, color: C.muted)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
