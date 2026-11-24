import 'package:flutter/material.dart';
import '../logic.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

const _noteColors = <String, Color>{
  'lime': C.lime,
  'mint': C.signal,
  'ice': C.ice,
  'orange': C.orange,
  'white': C.white,
};

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LiveData<Rows>(loader: () => Repo.list('gato_notes'), builder: _content);
  }

  Widget _content(BuildContext context, Rows all) {
    final notes = [...all];
    notes.sort((a, b) {
      final pa = a['pinned'] == true ? 0 : 1;
      final pb = b['pinned'] == true ? 0 : 1;
      if (pa != pb) return pa.compareTo(pb);
      return (b['created_at'] as String).compareTo(a['created_at'] as String);
    });
    final left = <Widget>[], right = <Widget>[];
    for (var i = 0; i < notes.length; i++) {
      final card = NoteCard(note: notes[i], tilt: i.isEven ? -.017 : .017);
      (i.isEven ? left : right).add(Padding(padding: const EdgeInsets.only(bottom: 12), child: card));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
      children: [
        Text('Notes', style: disp(36)),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(children: [
              const CatLogo(size: 96),
              const SizedBox(height: 14),
              Text('No notes yet.', style: disp(20)),
              const SizedBox(height: 4),
              Text('Tap + to jot something down.', style: txt(14, color: C.muted)),
            ]),
          ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(top: 20), child: Column(children: right))),
        ]),
      ],
    );
  }
}

class NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final double tilt;
  const NoteCard({super.key, required this.note, this.tilt = 0});

  Future<void> _toggleLine(BuildContext context, int index) async {
    final lines = (note['body'] as String? ?? '').split('\n');
    final l = lines[index];
    lines[index] = l.startsWith('[x] ') ? '[ ] ${l.substring(4)}' : '[x] ${l.substring(4)}';
    try {
      await Repo.save('gato_notes', {'body': lines.join('\n')}, id: note['id'] as String);
    } catch (_) {
      if (context.mounted) toast(context, "Couldn't update.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _noteColors[note['color']] ?? C.lime;
    final title = note['title'] as String? ?? '';
    final lines = (note['body'] as String? ?? '').split('\n');
    return Transform.rotate(
      angle: tilt,
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditor(note: note))),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: dirText(title.isEmpty ? 'Untitled' : title, disp(18, color: C.green), maxLines: 2)),
              if (note['pinned'] == true) const Icon(Icons.push_pin_rounded, size: 16, color: C.green),
            ]),
            for (var i = 0; i < lines.length && i < 8; i++)
              if (lines[i].trim().isNotEmpty) _line(context, lines[i], i),
          ]),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String l, int i) {
    final isCheck = l.startsWith('[ ] ') || l.startsWith('[x] ');
    if (!isCheck) {
      return Padding(padding: const EdgeInsets.only(top: 6), child: dirText(l, txt(14, color: C.green)));
    }
    final done = l.startsWith('[x] ');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => _toggleLine(context, i),
          child: Icon(done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 20, color: C.green),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: dirText(
            l.substring(4),
            txt(14, color: C.green).copyWith(decoration: done ? TextDecoration.lineThrough : null),
          ),
        ),
      ]),
    );
  }
}

class NoteEditor extends StatefulWidget {
  final Map<String, dynamic>? note;
  const NoteEditor({super.key, this.note});
  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late String _color;
  late bool _pinned;
  late final DateTime _date;
  bool _skip = false, _failed = false;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _title = TextEditingController(text: (n?['title'] as String?) ?? '');
    _body = TextEditingController(text: (n?['body'] as String?) ?? '');
    _color = (n?['color'] as String?) ?? 'lime';
    _pinned = n?['pinned'] == true;
    _date = DateTime.tryParse('${n?['created_at'] ?? ''}')?.toLocal() ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!_skip && !_failed) {
      final t = _title.text.trim(), b = _body.text.trim();
      if (t.isNotEmpty || b.isNotEmpty) {
        try {
          await Repo.save(
            'gato_notes',
            {
              'title': t,
              'body': b,
              'color': _color,
              'pinned': _pinned,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            id: widget.note?['id'] as String?,
          );
        } catch (_) {
          _failed = true;
          if (mounted) toast(context, "Couldn't save. Check your connection, or go back again to discard.");
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
    final id = widget.note?['id'] as String?;
    if (id == null) {
      _skip = true;
      Navigator.pop(context);
      return;
    }
    if (await confirm(context, 'Delete this note?')) {
      try {
        await Repo.remove('gato_notes', id);
        _skip = true;
        if (mounted) Navigator.pop(context);
      } catch (_) {
        if (mounted) toast(context, "Couldn't delete. Try again.");
      }
    }
  }

  void _checkbox() {
    final t = _body.text;
    final sel = _body.selection;
    final i = (sel.isValid && sel.start >= 0) ? sel.start : t.length;
    final prefix = (i == 0 || t[i - 1] == '\n') ? '[ ] ' : '\n[ ] ';
    _body.value = TextEditingValue(
      text: t.replaceRange(i, i, prefix),
      selection: TextSelection.collapsed(offset: i + prefix.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bg = _noteColors[_color] ?? C.lime;
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
                CircleBtn(_pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    label: 'Pin', onTap: () => setState(() => _pinned = !_pinned)),
                const SizedBox(width: 10),
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
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 360),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(shortDate(_date), style: txt(12, color: op(C.green, .6), w: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _title,
                      onChanged: (_) => setState(() {}),
                      textDirection: isRtlText(_title.text),
                      cursorColor: C.green,
                      style: disp(24, color: C.green),
                      decoration: InputDecoration.collapsed(hintText: 'Title', hintStyle: disp(24, color: op(C.green, .45))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _body,
                      onChanged: (_) => setState(() {}),
                      minLines: 10,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textDirection: isRtlText(_body.text),
                      cursorColor: C.green,
                      style: txt(16, color: C.green).copyWith(height: 1.5),
                      decoration: InputDecoration.collapsed(hintText: 'Write a note…', hintStyle: txt(16, color: op(C.green, .45))),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final e in _noteColors.entries)
                    GestureDetector(
                      onTap: () => setState(() => _color = e.key),
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: e.value,
                          border: Border.all(color: _color == e.key ? C.white : Colors.transparent, width: 3),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
          ),
          PillBar(children: [
            IconButton(tooltip: 'Add checkbox', onPressed: _checkbox, icon: const Icon(Icons.check_box_outlined, color: C.muted)),
            IconButton(tooltip: 'Delete', onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded, color: C.muted)),
          ]),
        ]),
      ),
    );
  }
}

TextDirection isRtlText(String s) {
  for (final r in s.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFDFF) || (r >= 0xFE70 && r <= 0xFEFF)) return TextDirection.rtl;
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}
