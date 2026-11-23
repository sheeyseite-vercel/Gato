import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../logic.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'voice.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LiveData<Rows>(loader: Repo.entries, builder: _content);
  }

  Widget _content(BuildContext context, Rows entries) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
      children: [
        Text('Journal', style: disp(36)),
        Text('${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}', style: txt(14, color: C.muted)),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(children: [
              const CatLogo(size: 96),
              const SizedBox(height: 14),
              Text('Your first page is waiting.', style: disp(20), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Tap + to write an entry.', style: txt(14, color: C.muted)),
            ]),
          ),
        for (final e in entries) _card(context, e),
      ],
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> e) {
    final date = DateTime.tryParse(e['entry_date'] as String) ?? DateTime.now();
    final mood = moodById(e['mood'] as String?);
    final title = (e['title'] as String? ?? '');
    final bodyText = (e['body'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryEditor(entry: e))),
        child: Glass(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 52,
              child: Column(children: [
                Text(DateFormat('d').format(date), style: disp(30, color: C.lime)),
                Text(DateFormat('MMM').format(date), style: txt(12, color: C.muted)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                dirText(title.isEmpty ? 'Untitled' : title, disp(18), maxLines: 1),
                if (bodyText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: dirText(bodyText, txt(14, color: C.muted), maxLines: 2),
                  ),
              ]),
            ),
            if (mood != null) MoodFace(mood, size: 32),
          ]),
        ),
      ),
    );
  }
}

class EntryEditor extends StatefulWidget {
  final Map<String, dynamic>? entry;
  final String? initialMood;
  const EntryEditor({super.key, this.entry, this.initialMood});

  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late String? _mood;
  late final List<String> _tags;
  late final DateTime _date;
  bool _skip = false, _failed = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _title = TextEditingController(text: (e?['title'] as String?) ?? '');
    _body = TextEditingController(text: (e?['body'] as String?) ?? '');
    _mood = (e?['mood'] as String?) ?? widget.initialMood;
    _tags = List<String>.from((e?['tags'] as List?) ?? const []);
    _date = e != null ? (DateTime.tryParse(e['entry_date'] as String) ?? DateTime.now()) : DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _title.text.trim(), b = _body.text.trim();
    if (t.isEmpty && b.isEmpty) return;
    await Repo.save(
      'gato_entries',
      {
        'title': t,
        'body': b,
        'mood': _mood,
        'tags': _tags,
        'entry_date': dkey(_date),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      id: widget.entry?['id'] as String?,
    );
  }

  Future<void> _close() async {
    if (!_skip && !_failed) {
      try {
        await _save();
      } catch (_) {
        _failed = true;
        if (mounted) toast(context, "Couldn't save. Check your connection, or go back again to discard.");
        return;
      }
    }
    if (mounted) {
      _skip = true;
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final id = widget.entry?['id'] as String?;
    if (id == null) {
      _skip = true;
      Navigator.pop(context);
      return;
    }
    if (await confirm(context, 'Delete this entry?')) {
      try {
        await Repo.remove('gato_entries', id);
        _skip = true;
        if (mounted) Navigator.pop(context);
      } catch (_) {
        if (mounted) toast(context, "Couldn't delete. Try again.");
      }
    }
  }

  void _bullet() {
    final t = _body.text;
    final sel = _body.selection;
    final i = (sel.isValid && sel.start >= 0) ? sel.start : t.length;
    final prefix = (i == 0 || t[i - 1] == '\n') ? '• ' : '\n• ';
    _body.value = TextEditingValue(
      text: t.replaceRange(i, i, prefix),
      selection: TextSelection.collapsed(offset: i + prefix.length),
    );
    setState(() {});
  }

  Future<void> _addTag() async {
    final t = await askText(context, 'Add a tag', hint: 'e.g. gratitude');
    if (t == null) return;
    final clean = t.replaceAll('#', '').trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) setState(() => _tags.add(clean));
  }

  Future<void> _saveQuote() async {
    final sel = _body.selection;
    var text = (sel.isValid && !sel.isCollapsed) ? sel.textInside(_body.text).trim() : '';
    if (text.isEmpty) {
      for (final line in _body.text.split('\n')) {
        if (line.trim().isNotEmpty) {
          text = line.replaceFirst('• ', '').trim();
          break;
        }
      }
    }
    if (text.isEmpty) {
      toast(context, 'Select some text first.');
      return;
    }
    try {
      await Repo.save('gato_quotes', {'text': text, 'source': 'From my journal · ${DateFormat('MMM d').format(_date)}'});
      if (mounted) toast(context, 'Saved to Quotes');
    } catch (_) {
      if (mounted) toast(context, "Couldn't save the quote.");
    }
  }

  static const _tagColors = [C.mint, C.ice, C.mint];

  @override
  Widget build(BuildContext context) {
    final titleRtl = isRtl(_title.text);
    final bodyRtl = isRtl(_body.text);
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
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              children: [
                Row(children: [
                  Text(DateFormat('d').format(_date), style: disp(64, color: C.lime).copyWith(height: 1)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(DateFormat('EEEE').format(_date), style: disp(20)),
                    Text(DateFormat('MMMM yyyy').format(_date), style: txt(13, color: C.muted)),
                  ]),
                ]),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  for (final m in moodList)
                    InkResponse(
                      onTap: () => setState(() => _mood = _mood == m.id ? null : m.id),
                      child: SizedBox(
                        width: 64,
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _mood == m.id ? C.white : Colors.transparent, width: 2),
                            ),
                            child: Opacity(opacity: _mood == null || _mood == m.id ? 1 : .55, child: MoodFace(m, size: 38)),
                          ),
                          const SizedBox(height: 4),
                          Text(m.label, style: txt(12)),
                        ]),
                      ),
                    ),
                ]),
                const SizedBox(height: 50),
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 340),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                    decoration: const BoxDecoration(
                      color: C.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(8),
                        bottomLeft: Radius.circular(28),
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      TextField(
                        controller: _title,
                        onChanged: (_) => setState(() {}),
                        textDirection: titleRtl ? TextDirection.rtl : TextDirection.ltr,
                        cursorColor: C.green,
                        style: disp(24, color: C.green),
                        decoration: InputDecoration.collapsed(
                            hintText: 'Title of your day', hintStyle: disp(24, color: op(C.green, .4))),
                      ),
                      const SizedBox(height: 12),
                      CustomPaint(
                        painter: RuledPainter(),
                        child: TextField(
                          controller: _body,
                          onChanged: (_) => setState(() {}),
                          minLines: 9,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textDirection: bodyRtl ? TextDirection.rtl : TextDirection.ltr,
                          cursorColor: C.green,
                          style: txt(17, color: C.green).copyWith(height: 32 / 17),
                          decoration: InputDecoration.collapsed(
                              hintText: "Write what's on your mind…",
                              hintStyle: txt(17, color: op(C.green, .4)).copyWith(height: 32 / 17)),
                        ),
                      ),
                    ]),
                  ),
                  const Positioned(top: -43, right: 30, child: CatPeek()),
                ]),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < _tags.length; i++)
                    GestureDetector(
                      onLongPress: () => setState(() => _tags.removeAt(i)),
                      child: Transform.rotate(
                        angle: i.isEven ? -.03 : .026,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: _tagColors[i % 3], borderRadius: BorderRadius.circular(20)),
                          child: Text('#${_tags[i]}', style: disp(14, color: C.green)),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: _addTag,
                    child: Transform.rotate(
                      angle: -.017,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(20)),
                        child: Text('+ tag', style: disp(14, color: C.green)),
                      ),
                    ),
                  ),
                ]),
                if (_tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Long-press a tag to remove it.', style: txt(12, color: C.muted)),
                  ),
              ],
            ),
          ),
          PillBar(children: [
            IconButton(tooltip: 'Bullet', onPressed: _bullet, icon: const Icon(Icons.format_list_bulleted_rounded, color: C.muted)),
            IconButton(tooltip: 'Save as quote', onPressed: _saveQuote, icon: const Icon(Icons.format_quote_rounded, color: C.muted)),
            IconButton(tooltip: 'Delete', onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded, color: C.muted)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceScreen())),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle),
                child: const Icon(Icons.mic_rounded, color: C.green),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
