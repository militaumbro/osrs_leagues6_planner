import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SectionScreen extends StatefulWidget {
  final GuideSection section;
  final StorageService storage;

  const SectionScreen({
    super.key,
    required this.section,
    required this.storage,
  });

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  bool _pendingFirst = false;
  bool _notesExpanded = false;

  List<GuideTask> get _sortedTasks {
    if (!_pendingFirst) return widget.section.tasks;
    final pending = widget.section.tasks.where((t) => !t.isCompleted).toList();
    final done = widget.section.tasks.where((t) => t.isCompleted).toList();
    return [...pending, ...done];
  }

  void _toggleTask(GuideTask task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      widget.storage.toggleTask(task.id, task.isCompleted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final completed = section.completedCount;
    final total = section.tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;
    final pts = section.tasks
        .where((t) => t.isCompleted)
        .fold(0, (sum, t) => sum + t.points);
    final allDone = completed == total;

    return Scaffold(
      appBar: AppBar(
        title: Text(section.name),
        actions: [
          // Toggle sort
          IconButton(
            icon: Icon(
              _pendingFirst ? Icons.filter_list_off : Icons.filter_list,
              size: 22,
            ),
            tooltip: _pendingFirst ? 'Ordem original' : 'Pendentes primeiro',
            onPressed: () => setState(() => _pendingFirst = !_pendingFirst),
          ),
          // Batch menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            onSelected: (value) {
              setState(() {
                final check = value == 'mark_all';
                for (final t in widget.section.tasks) {
                  t.isCompleted = check;
                  widget.storage.toggleTask(t.id, check);
                }
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'mark_all', child: Text('Marcar todas')),
              const PopupMenuItem(value: 'unmark_all', child: Text('Desmarcar todas')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress bar ──────────────────────────────────────
          Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$completed / $total',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${(progress * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          color: allDone
                              ? Colors.green
                              : const Color(0xFFFF6D00),
                          backgroundColor: const Color(0xFF3A3A3A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6D00).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF6D00).withAlpha(60),
                    ),
                  ),
                  child: Text(
                    '$pts pts',
                    style: const TextStyle(
                      color: Color(0xFFFF6D00),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Notes (collapsible) ───────────────────────────────
          if (section.notes.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _notesExpanded = !_notesExpanded),
              child: Container(
                color: const Color(0xFF1A2A3A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Color(0xFF64B5F6)),
                        const SizedBox(width: 6),
                        const Text(
                          'Notas da rota',
                          style: TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _notesExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: const Color(0xFF64B5F6),
                        ),
                      ],
                    ),
                    if (_notesExpanded) ...[
                      const SizedBox(height: 6),
                      ...section.notes.map((n) => Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '• $n',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),

          // ── Task list ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              itemCount: _sortedTasks.length,
              itemBuilder: (ctx, i) {
                final task = _sortedTasks[i];
                return _TaskTile(
                  key: ValueKey(task.id),
                  task: task,
                  onToggle: () => _toggleTask(task),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task tile com dicas expandíveis inline
// ─────────────────────────────────────────────────────────────────────────────
class _TaskTile extends StatefulWidget {
  final GuideTask task;
  final VoidCallback onToggle;

  const _TaskTile({super.key, required this.task, required this.onToggle});

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _tipsOpen = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final diffColor = AppTheme.difficultyColor(task.difficulty.label);
    final hasTips = task.tips.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Main row ────────────────────────────────────────
            InkWell(
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  children: [
                    // Difficulty dot
                    Container(
                      width: 3,
                      height: 28,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? Colors.grey[700]
                            : diffColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Custom checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? const Color(0xFFFF6D00)
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? const Color(0xFFFF6D00)
                              : Colors.grey[600]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),

                    // Name
                    Expanded(
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: task.isCompleted
                              ? Colors.grey[600]
                              : Colors.white,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.grey[600],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Points badge
                    Text(
                      '${task.points}',
                      style: TextStyle(
                        color: task.isCompleted
                            ? Colors.grey[700]
                            : diffColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Tips toggle icon
                    if (hasTips) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            setState(() => _tipsOpen = !_tipsOpen),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            _tipsOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: _tipsOpen
                                ? const Color(0xFFFF6D00)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Tips panel (inline) ──────────────────────────────
            if (hasTips && _tipsOpen)
              Container(
                width: double.infinity,
                color: const Color(0xFF1C1C1C),
                padding: const EdgeInsets.fromLTRB(44, 6, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: task.tips
                      .map((tip) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('→ ',
                                    style: TextStyle(
                                      color: Color(0xFFFF6D00),
                                      fontSize: 12,
                                    )),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
