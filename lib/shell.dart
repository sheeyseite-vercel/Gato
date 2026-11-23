import 'package:flutter/material.dart';
import 'gate.dart';
import 'screens/home.dart';
import 'screens/journal.dart';
import 'screens/notes.dart';
import 'screens/quotes.dart';
import 'screens/voice.dart';
import 'theme.dart';
import 'widgets.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Pending.action.addListener(_pending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pending());
  }

  @override
  void dispose() {
    Pending.action.removeListener(_pending);
    super.dispose();
  }

  void _pending() {
    final a = Pending.action.value;
    if (a == null || !mounted) return;
    Pending.action.value = null;
    _create(a);
  }

  void _create(String kind) {
    switch (kind) {
      case 'entry':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryEditor()));
        break;
      case 'voice':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceScreen()));
        break;
      case 'note':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditor()));
        break;
      case 'quote':
        quoteDialog(context);
        break;
    }
  }

  void _sheet() {
    Widget tile(IconData i, String t, String kind, Color c) => ListTile(
          leading: CircleAvatar(backgroundColor: c, child: Icon(i, color: C.green)),
          title: Text(t, style: txt(16, w: FontWeight.w700)),
          onTap: () {
            Navigator.pop(context);
            _create(kind);
          },
        );
    showModalBottomSheet(
      context: context,
      backgroundColor: C.deep,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            tile(Icons.edit_note_rounded, 'New entry', 'entry', C.lime),
            tile(Icons.mic_rounded, 'Voice memo', 'voice', C.orange),
            tile(Icons.sticky_note_2_outlined, 'New note', 'note', C.ice),
            tile(Icons.format_quote_rounded, 'New quote', 'quote', C.mint),
          ]),
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int i) {
    final on = _tab == i;
    return InkResponse(
      onTap: () => setState(() => _tab = i),
      child: SizedBox(
        width: 60,
        height: 52,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: on ? C.lime : C.muted, size: 24),
          const SizedBox(height: 2),
          Text(label, style: txt(11, color: on ? C.lime : C.muted)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.green,
      body: Backdrop(
        child: SafeArea(
          bottom: false,
          child: Stack(children: [
            IndexedStack(index: _tab, children: const [
              HomeScreen(),
              JournalScreen(),
              QuotesScreen(),
              NotesScreen(),
            ]),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom,
              child: PillBar(children: [
                _nav(Icons.home_rounded, 'Home', 0),
                _nav(Icons.menu_book_rounded, 'Journal', 1),
                InkResponse(
                  onTap: _sheet,
                  child: Semantics(
                    button: true,
                    label: 'Add',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: C.green, size: 32),
                    ),
                  ),
                ),
                _nav(Icons.format_quote_rounded, 'Quotes', 2),
                _nav(Icons.sticky_note_2_outlined, 'Notes', 3),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
