import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

class SearchBarWidget extends StatefulWidget {
  final CodeController codeController;
  final VoidCallback onClose;

  const SearchBarWidget({
    super.key,
    required this.codeController,
    required this.onClose,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  int _currentMatch = 0;
  int _totalMatches = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateMatches);
  }

  void _updateMatches() {
    final query = _controller.text;
    if (query.isEmpty) {
      setState(() {
        _totalMatches = 0;
        _currentMatch = 0;
      });
      return;
    }

    final text = widget.codeController.text;
    int count = 0;
    int start = 0;
    while (true) {
      final idx = text.indexOf(query, start);
      if (idx == -1) break;
      count++;
      start = idx + query.length;
    }

    setState(() {
      _totalMatches = count;
      _currentMatch = count > 0 ? 1 : 0;
    });
  }

  void _next() {
    if (_totalMatches == 0) return;
    final query = _controller.text;
    final text = widget.codeController.text;
    final currentOffset = widget.codeController.selection.baseOffset;
    final start = text.indexOf(query, currentOffset + 1);
    if (start != -1) {
      widget.codeController.selection = TextSelection.collapsed(offset: start);
      setState(() => _currentMatch++);
    } else {
      final first = text.indexOf(query);
      if (first != -1) {
        widget.codeController.selection =
            TextSelection.collapsed(offset: first);
        setState(() => _currentMatch = 1);
      }
    }
  }

  void _previous() {
    if (_totalMatches == 0) return;
    final query = _controller.text;
    final text = widget.codeController.text;
    final currentOffset = widget.codeController.selection.baseOffset;

    int prev = -1;
    int start = 0;
    int idx = 0;
    while (true) {
      final found = text.indexOf(query, start);
      if (found == -1 || found >= currentOffset) break;
      prev = found;
      start = found + query.length;
      idx++;
    }

    if (prev != -1) {
      widget.codeController.selection = TextSelection.collapsed(offset: prev);
      setState(() => _currentMatch = idx);
    } else {
      final last = text.lastIndexOf(query);
      if (last != -1) {
        widget.codeController.selection =
            TextSelection.collapsed(offset: last);
        setState(() => _currentMatch = _totalMatches);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1E1E1E),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                hintText: 'Search...',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF666666)
                      : const Color(0xFF999999),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFFFFFFF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _totalMatches > 0
                ? '$_currentMatch of $_totalMatches'
                : 'No results',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF999999)
                  : const Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 8),
          _iconButton(Icons.chevron_left, 'Previous', _previous),
          _iconButton(Icons.chevron_right, 'Next', _next),
          const Spacer(),
          _iconButton(Icons.close, 'Close', widget.onClose),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
