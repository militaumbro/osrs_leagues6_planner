import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

// Paleta de cores por seção — cíclica
const _kPalette = [
  Color(0xFFFF6D00), // deep orange
  Color(0xFF26C6DA), // cyan
  Color(0xFFAB47BC), // purple
  Color(0xFFFFCA28), // amber
  Color(0xFF66BB6A), // green
  Color(0xFF42A5F5), // blue
  Color(0xFFEC407A), // pink
  Color(0xFF26A69A), // teal
  Color(0xFFEF5350), // red
  Color(0xFF7E57C2), // deep purple
  Color(0xFF29B6F6), // light blue
  Color(0xFFD4E157), // lime
];

class HomeScreen extends StatefulWidget {
  final List<GuideRoute> routes;
  final StorageService storage;

  const HomeScreen({super.key, required this.routes, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _routeIdx = 0;
  int _selectedIdx = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final Map<String, bool> _completedIds = {};
  double _fontScale = 1.5;
  late final Set<String> _sharedIds; // IDs that appear in 2+ routes (by ID only, tips ignored)

  List<GuideSection> get _currentSections => widget.routes[_routeIdx].sections;

  Color _sectionColor(int idx) => _kPalette[idx % _kPalette.length];

  /// Populate _completedIds from task objects (already loaded by main.dart)
  /// and propagate to ALL routes so cross-route completion is in sync.
  @override
  void initState() {
    super.initState();
    // Compute shared IDs: IDs that appear in more than one route (compare by ID only, tips ignored).
    final idRouteCount = <String, int>{};
    for (final route in widget.routes) {
      final routeIds = <String>{};
      for (final section in route.sections) {
        for (final task in section.tasks) {
          routeIds.add(task.id);
        }
      }
      for (final id in routeIds) {
        idRouteCount[id] = (idRouteCount[id] ?? 0) + 1;
      }
    }
    _sharedIds = {
      for (final e in idRouteCount.entries)
        if (e.value > 1) e.key
    };

    for (final route in widget.routes) {
      for (final section in route.sections) {
        for (final task in section.tasks) {
          if (task.isCompleted) _completedIds[task.id] = true;
        }
      }
    }
    _syncTasks();
  }

  /// Push _completedIds state to every task object across all routes.
  void _syncTasks() {
    for (final route in widget.routes) {
      for (final section in route.sections) {
        for (final task in section.tasks) {
          task.isCompleted = _completedIds[task.id] ?? false;
        }
      }
    }
  }

  /// Called by TaskPanel / search after a task is toggled on the current route.
  void _onTaskToggled() {
    // Re-derive _completedIds from the current route's task states.
    for (final section in _currentSections) {
      for (final task in section.tasks) {
        _completedIds[task.id] = task.isCompleted;
      }
    }
    // Propagate to the other route's task objects.
    _syncTasks();
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _totalTasks =>
      _currentSections.fold(0, (s, sec) => s + sec.tasks.length);
  int get _completedTasks =>
      _currentSections.fold(0, (s, sec) => s + sec.completedCount);
  int get _totalPoints => _currentSections.fold(
      0,
      (s, sec) =>
          s +
          sec.tasks
              .where((t) => t.isCompleted)
              .fold(0, (ps, t) => ps + t.points));

  bool get _isSearching => _searchQuery.isNotEmpty;

  List<int> get _filteredIndices {
    if (!_isSearching) return List.generate(_currentSections.length, (i) => i);
    final q = _searchQuery.toLowerCase();
    return [
      for (var i = 0; i < _currentSections.length; i++)
        if (_currentSections[i].name.toLowerCase().contains(q) ||
            _currentSections[i].tasks.any((t) => t.name.toLowerCase().contains(q)))
          i
    ];
  }

  List<({int sectionIdx, GuideTask task})> get _matchingTasks {
    final q = _searchQuery.toLowerCase();
    final result = <({int sectionIdx, GuideTask task})>[];
    for (var i = 0; i < _currentSections.length; i++) {
      for (final t in _currentSections[i].tasks) {
        if (t.name.toLowerCase().contains(q) ||
            _currentSections[i].name.toLowerCase().contains(q)) {
          result.add((sectionIdx: i, task: t));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalTasks == 0 ? 0.0 : _completedTasks / _totalTasks;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Column(
        children: [
          _buildTitleBar(progress),
          if (widget.routes.length > 1) _buildRouteTabs(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 262, child: _buildLeftPanel()),
                Container(width: 1, color: const Color(0xFF232323)),
                Expanded(child: _buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Route tabs ─────────────────────────────────────────────────────────────
  Widget _buildRouteTabs() {
    return Container(
      height: 30,
      color: const Color(0xFF0C0C0C),
      child: Row(
        children: [
          for (var i = 0; i < widget.routes.length; i++)
            InkWell(
              onTap: i == _routeIdx
                  ? null
                  : () => setState(() {
                        _routeIdx = i;
                        _selectedIdx = 0;
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }),
              hoverColor: const Color(0xFF181818),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: i == _routeIdx
                          ? const Color(0xFFFF6D00)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  widget.routes[i].name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == _routeIdx
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color:
                        i == _routeIdx ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'Completion is shared between routes',
              style: TextStyle(fontSize: 9, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTitleBar(double progress) {
    return Container(
      height: 46,
      color: const Color(0xFF161616),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Leagues 6',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 20),
          // Progress bar + stats
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: const Color(0xFFFF6D00),
                    backgroundColor: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '$_completedTasks / $_totalTasks  •  ${(progress * 100).toStringAsFixed(1)}%',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentSections.where((s) => s.completedCount == s.tasks.length && s.tasks.isNotEmpty).length}/${_currentSections.length} sections',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Points chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6D00).withAlpha(20),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFFF6D00).withAlpha(55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 11, color: Color(0xFFFF6D00)),
                const SizedBox(width: 4),
                Text(
                  '$_totalPoints pts',
                  style: const TextStyle(
                    color: Color(0xFFFF6D00),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Font size controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.text_decrease,
                    size: 14, color: Colors.grey[600]),
                tooltip: 'Decrease font size',
                onPressed: _fontScale > 0.8
                    ? () => setState(
                        () => _fontScale =
                            (_fontScale - 0.1).clamp(0.8, 1.6))
                    : null,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 26, minHeight: 26),
              ),
              Text(
                '${(_fontScale * 100).round()}%',
                style: TextStyle(fontSize: 9, color: Colors.grey[700]),
              ),
              IconButton(
                icon: Icon(Icons.text_increase,
                    size: 14, color: Colors.grey[600]),
                tooltip: 'Increase font size',
                onPressed: _fontScale < 1.6
                    ? () => setState(
                        () => _fontScale =
                            (_fontScale + 0.1).clamp(0.8, 1.6))
                    : null,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 26, minHeight: 26),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 17, color: Colors.grey[700]),
            tooltip: 'Reset progress',
            onPressed: _confirmReset,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }

  // ── Left panel ─────────────────────────────────────────────────────────────
  Widget _buildLeftPanel() {
    final indices = _filteredIndices;
    return Container(
      color: const Color(0xFF111111),
      child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search task or section...',
                hintStyle:
                    TextStyle(color: Colors.grey[700], fontSize: 12),
                prefixIcon:
                    Icon(Icons.search, size: 15, color: Colors.grey[700]),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: Icon(Icons.close,
                            size: 13, color: Colors.grey[700]),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF1C1C1C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Sections
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: indices.length,
              itemBuilder: (ctx, i) {
                final idx = indices[i];
                final sec = _currentSections[idx];
                final color = _sectionColor(idx);
                final isSelected = idx == _selectedIdx && !_isSearching;
                return _SideSection(
                  section: sec,
                  color: color,
                  isSelected: isSelected,
                  sharedIds: _sharedIds,
                  onTap: () => setState(() {
                    _selectedIdx = idx;
                    if (_isSearching) {
                      _searchCtrl.clear();
                      _searchQuery = '';
                    }
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Right panel ────────────────────────────────────────────────────────────
  Widget _buildRightPanel() {
    if (_isSearching) return _buildSearchResults();
    return _TaskPanel(
      key: ValueKey('${_routeIdx}_$_selectedIdx'),
      section: _currentSections[_selectedIdx],
      color: _sectionColor(_selectedIdx),
      storage: widget.storage,
      fontScale: _fontScale,
      sharedIds: _sharedIds,
      onTaskToggled: _onTaskToggled,
    );
  }

  Widget _buildSearchResults() {
    final matches = _matchingTasks;
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'No tasks found',
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
      );
    }
    final doneCount = matches.where((m) => m.task.isCompleted).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
          color: const Color(0xFF131313),
          child: Row(
            children: [
              Text(
                '${matches.length} tasks',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              Text(
                '  —  $doneCount completed',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFF1E1E1E)),
        Expanded(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(_fontScale)),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: matches.length,
              itemBuilder: (ctx, i) {
                final m = matches[i];
                return _SearchTaskRow(
                  task: m.task,
                  section: _currentSections[m.sectionIdx],
                  color: _sectionColor(m.sectionIdx),
                  onToggle: () {
                    m.task.isCompleted = !m.task.isCompleted;
                    widget.storage.toggleTask(m.task.id, m.task.isCompleted);
                    _onTaskToggled();
                  },
                  onSectionTap: () => setState(() {
                    _selectedIdx = m.sectionIdx;
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset progress?'),
        content:
            const Text('Unmark all tasks. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.storage.clearAll();
              _completedIds.clear();
              _syncTasks();
              Navigator.pop(ctx);
              setState(() {});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seção no painel esquerdo
// ─────────────────────────────────────────────────────────────────────────────
class _SideSection extends StatelessWidget {
  final GuideSection section;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Set<String> sharedIds;

  const _SideSection({
    required this.section,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.sharedIds,
  });

  @override
  Widget build(BuildContext context) {
    final completed = section.completedCount;
    final total = section.tasks.length;
    final allDone = completed == total && total > 0;
    final c = allDone ? Colors.green : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier divider
        if (section.tierInfo != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 1),
            child: Row(
              children: [
                Expanded(
                    child: Container(height: 1, color: const Color(0xFF232323))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    section.tierInfo!.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                    child: Container(height: 1, color: const Color(0xFF232323))),
              ],
            ),
          ),
        // Row
        Material(
          color: isSelected ? const Color(0xFF1C1C1C) : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: const Color(0xFF181818),
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border:
                          Border(left: BorderSide(color: c, width: 3)),
                    )
                  : null,
              padding: EdgeInsets.fromLTRB(
                  isSelected ? 9 : 12, 8, 10, 8),
              child: Row(
                children: [
                  if (!isSelected)
                    Container(
                      width: 3,
                      height: 28,
                      margin: const EdgeInsets.only(right: 9),
                      decoration: BoxDecoration(
                        color: c.withAlpha(allDone ? 120 : 70),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: allDone
                                ? Colors.grey[700]
                                : isSelected
                                    ? Colors.white
                                    : Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: section.progress,
                                  minHeight: 2,
                                  color: c,
                                  backgroundColor: const Color(0xFF252525),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$completed/$total',
                              style: TextStyle(
                                fontSize: 9,
                                color: allDone
                                    ? Colors.green[800]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Builder(builder: (_) {
                          final uniqueCount = section.tasks
                              .where((t) => !sharedIds.contains(t.id))
                              .length;
                          if (uniqueCount == 0 || uniqueCount == total) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '$uniqueCount unique · ${total - uniqueCount} shared',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xFF3A3A3A),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painel direito: lista de tasks da seção selecionada
// ─────────────────────────────────────────────────────────────────────────────
class _TaskPanel extends StatefulWidget {
  final GuideSection section;
  final Color color;
  final StorageService storage;
  final VoidCallback onTaskToggled;
  final double fontScale;
  final Set<String> sharedIds;

  const _TaskPanel({
    super.key,
    required this.section,
    required this.color,
    required this.storage,
    required this.onTaskToggled,
    required this.fontScale,
    required this.sharedIds,
  });

  @override
  State<_TaskPanel> createState() => _TaskPanelState();
}

class _TaskPanelState extends State<_TaskPanel> {
  bool _notesExpanded = false;
  bool _pendingFirst = false;

  List<GuideTask> get _tasks {
    if (!_pendingFirst) return widget.section.tasks;
    final p = widget.section.tasks.where((t) => !t.isCompleted).toList();
    final d = widget.section.tasks.where((t) => t.isCompleted).toList();
    return [...p, ...d];
  }

  void _toggle(GuideTask task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      widget.storage.toggleTask(task.id, task.isCompleted);
    });
    widget.onTaskToggled();
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
    final allDone = completed == total && total > 0;
    final c = allDone ? Colors.green : widget.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: const Color(0xFF131313),
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color accent
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          section.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (section.subtitle != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            section.subtitle!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 3,
                              color: c,
                              backgroundColor: const Color(0xFF252525),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$completed/$total',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                        Text(
                          '  (${(progress * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Pts chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: c.withAlpha(18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: c.withAlpha(55)),
                ),
                child: Text(
                  '$pts pts',
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  _pendingFirst
                      ? Icons.filter_list_off
                      : Icons.filter_list,
                  size: 15,
                  color: Colors.grey[700],
                ),
                tooltip:
                    _pendingFirst ? 'Original order' : 'Pending first',
                onPressed: () =>
                    setState(() => _pendingFirst = !_pendingFirst),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 26, minHeight: 26),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 15, color: Colors.grey[700]),
                onSelected: (v) {
                  setState(() {
                    final check = v == 'mark_all';
                    for (final t in section.tasks) {
                      t.isCompleted = check;
                      widget.storage.toggleTask(t.id, check);
                    }
                  });
                  widget.onTaskToggled();
                },
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 26, minHeight: 26),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'mark_all', child: Text('Mark all')),
                  const PopupMenuItem(
                      value: 'unmark_all', child: Text('Unmark all')),
                ],
              ),
            ],
          ),
        ),

        // Notes
        if (section.notes.isNotEmpty)
          InkWell(
            onTap: () => setState(() => _notesExpanded = !_notesExpanded),
            hoverColor: const Color(0xFF0E1420),
            child: Container(
              color: const Color(0xFF0D1219),
              padding: const EdgeInsets.fromLTRB(20, 5, 16, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 12, color: Color(0xFF3A6A9A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Route notes',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _notesExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 13,
                              color: Colors.blue[900],
                            ),
                          ],
                        ),
                        if (_notesExpanded) ...[
                          const SizedBox(height: 4),
                          ...section.notes.map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '• $n',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        Container(height: 1, color: const Color(0xFF1C1C1C)),

        // Task list
        Expanded(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(widget.fontScale)),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: _tasks.length,
              itemBuilder: (ctx, i) => _TaskRow(
                key: ValueKey(_tasks[i].id),
                task: _tasks[i],
                isShared: widget.sharedIds.contains(_tasks[i].id),
                onToggle: () => _toggle(_tasks[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task row compacta — dicas inline após o nome
// ─────────────────────────────────────────────────────────────────────────────
class _TaskRow extends StatelessWidget {
  final GuideTask task;
  final VoidCallback onToggle;
  final bool isShared;

  const _TaskRow({super.key, required this.task, required this.onToggle, this.isShared = false});

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    final diffColor = AppTheme.difficultyColor(task.difficulty.label);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            hoverColor: const Color(0xFF161616),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  // Diff bar
                  Container(
                    width: 2,
                    height: 14,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFF242424) : diffColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 110),
                    width: 15,
                    height: 15,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFFFF6D00)
                          : Colors.transparent,
                      border: Border.all(
                        color: done
                            ? const Color(0xFFFF6D00)
                            : const Color(0xFF3C3C3C),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                  // Nome + dicas na mesma linha (RichText usa todo o espaço disponível)
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: task.name,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  done ? const Color(0xFF404040) : Colors.white,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              decorationColor: const Color(0xFF505050),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (task.tips.isNotEmpty)
                            TextSpan(
                              text: '    ${task.tips.join('  ·  ')}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: done
                                    ? const Color(0xFF282828)
                                    : const Color(0xFF404040),
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shared indicator: tiny link icon when task exists in other routes too (matched by ID, tips ignored)
                  if (isShared && !done)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.link, size: 10, color: Colors.grey[800]),
                    ),
                  // Points
                  Text(
                    '${task.points}',
                    style: TextStyle(
                      fontSize: 10,
                      color: done ? const Color(0xFF2E2E2E) : diffColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(height: 1, color: const Color(0xFF171717)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task row no resultado de busca — dicas inline, label de seção clicável
// ─────────────────────────────────────────────────────────────────────────────
class _SearchTaskRow extends StatelessWidget {
  final GuideTask task;
  final GuideSection section;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onSectionTap;

  const _SearchTaskRow({
    required this.task,
    required this.section,
    required this.color,
    required this.onToggle,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;
    final diffColor = AppTheme.difficultyColor(task.difficulty.label);
    final c = color;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            hoverColor: const Color(0xFF161616),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 6),
              child: Row(
                children: [
                  // Section color bar
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFF242424) : c,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 110),
                    width: 15,
                    height: 15,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: done
                          ? const Color(0xFFFF6D00)
                          : Colors.transparent,
                      border: Border.all(
                        color: done
                            ? const Color(0xFFFF6D00)
                            : const Color(0xFF3C3C3C),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 10, color: Colors.white)
                        : null,
                  ),
                  // Nome + dicas na mesma linha, seção abaixo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: task.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: done
                                      ? const Color(0xFF404040)
                                      : Colors.white,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: const Color(0xFF505050),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (task.tips.isNotEmpty)
                                TextSpan(
                                  text: '    ${task.tips.join('  ·  ')}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: done
                                        ? const Color(0xFF282828)
                                        : const Color(0xFF404040),
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: onSectionTap,
                            child: Text(
                              section.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: c.withAlpha(done ? 60 : 140),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Points
                  Text(
                    '${task.points}',
                    style: TextStyle(
                      fontSize: 10,
                      color: done ? const Color(0xFF2E2E2E) : diffColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(height: 1, color: const Color(0xFF171717)),
      ],
    );
  }
}
