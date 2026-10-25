import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF080A18);
const panel = Color(0xFF11152B);
const purple = Color(0xFF743BFF);
const muted = Color(0xFFAAAED4);
const green = Color(0xFF00D6A0);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskFlowApp());
}

class TaskItem {
  TaskItem({required this.title, required this.category, required this.priority, this.done = false});
  String title;
  String category;
  String priority;
  bool done;

  Map<String, dynamic> toJson() => {
    'title': title, 'category': category, 'priority': priority, 'done': done,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? 'شخصي',
    priority: json['priority'] as String? ?? 'متوسطة',
    done: json['done'] as bool? ?? false,
  );
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'TaskFlow',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: purple, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const Directionality(textDirection: TextDirection.rtl, child: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TaskItem> tasks = [];
  final searchController = TextEditingController();
  bool loading = true;
  int tab = 0;
  String filter = 'الكل';

  @override
  void initState() { super.initState(); loadTasks(); }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('taskflow_tasks');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        tasks.addAll(decoded.map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {}
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('taskflow_tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  int get completed => tasks.where((t) => t.done).length;
  int get active => tasks.where((t) => !t.done).length;

  List<TaskItem> get visibleTasks {
    final q = searchController.text.trim().toLowerCase();
    return tasks.where((t) {
      final filterOk = filter == 'الكل' || (filter == 'قيد التنفيذ' && !t.done) || (filter == 'المكتملة' && t.done);
      return filterOk && t.title.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> showTaskDialog({TaskItem? task}) async {
    final controller = TextEditingController(text: task?.title ?? '');
    String category = task?.category ?? 'شخصي';
    String priority = task?.priority ?? 'متوسطة';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
        backgroundColor: panel,
        title: Text(task == null ? 'إضافة مهمة' : 'تعديل المهمة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'اسم المهمة', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category, decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
            items: ['شخصي','دراسة','عمل','صحة','منزل'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setDialog(() => category = v ?? category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: priority, decoration: const InputDecoration(labelText: 'الأولوية', border: OutlineInputBorder()),
            items: ['منخفضة','متوسطة','عالية'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setDialog(() => priority = v ?? priority),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: purple),
            onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(ctx, true); },
            child: const Text('حفظ'),
          ),
        ],
      )),
    );
    if (result == true) {
      setState(() {
        if (task == null) {
          tasks.insert(0, TaskItem(title: controller.text.trim(), category: category, priority: priority));
        } else {
          task.title = controller.text.trim(); task.category = category; task.priority = priority;
        }
      });
      await saveTasks();
    }
    controller.dispose();
  }

  Future<void> deleteTask(TaskItem task) async {
    setState(() => tasks.remove(task));
    await saveTasks();
  }

  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: loading ? const Center(child: CircularProgressIndicator()) : tab == 2 ? buildStats() : tab == 3 ? buildSettings() : buildHome()),
    floatingActionButton: tab >= 2 ? null : FloatingActionButton(
      backgroundColor: purple, onPressed: () => showTaskDialog(), child: const Icon(Icons.add, size: 30),
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: const Color(0xFF0B0E20), indicatorColor: purple.withValues(alpha: .25),
      selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'المهام'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'الإحصائيات'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'الإعدادات'),
      ],
    ),
  );

  Widget buildHome() {
    final list = visibleTasks;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 90), children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.done_all, color: Colors.white, size: 29)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TaskFlow', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          Text('نظّم يومك بذكاء', style: TextStyle(color: muted)),
        ])),
        IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد إشعارات جديدة'))), icon: const Icon(Icons.notifications_none, color: muted)),
      ]),
      const SizedBox(height: 22),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF3920A5), Color(0xFF171A42)]),
        borderRadius: BorderRadius.circular(22), border: Border.all(color: purple.withValues(alpha: .55)),
      ), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('مرحباً بك 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8), Text('خطوة صغيرة اليوم، إنجاز كبير غداً.', style: TextStyle(color: Color(0xFFD4D0FF), fontSize: 15)),
      ])),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: statCard('كل المهام', '${tasks.length}', Icons.assignment_outlined, const Color(0xFF6C7BFF))),
        const SizedBox(width: 8), Expanded(child: statCard('قيد التنفيذ', '$active', Icons.schedule, const Color(0xFFFFB52E))),
        const SizedBox(width: 8), Expanded(child: statCard('المكتملة', '$completed', Icons.check_circle_outline, green)),
      ]),
      const SizedBox(height: 22),
      TextField(controller: searchController, onChanged: (_) => setState(() {}), decoration: InputDecoration(
        hintText: 'ابحث عن مهمة...', prefixIcon: const Icon(Icons.search, color: muted), filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      )),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: ['الكل','قيد التنفيذ','المكتملة'].map((v) => ChoiceChip(
        label: Text(v), selected: filter == v, selectedColor: purple, backgroundColor: panel,
        onSelected: (_) => setState(() => filter = v),
      )).toList()),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('مهامي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('${list.length} مهام', style: const TextStyle(color: muted)),
      ]),
      const SizedBox(height: 10),
      if (list.isEmpty) Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)), child: const Column(children: [
        Icon(Icons.inbox_outlined, size: 42, color: muted), SizedBox(height: 10),
        Text('لا توجد مهام هنا', style: TextStyle(color: muted)), Text('اضغط + لإضافة مهمة جديدة', style: TextStyle(color: muted, fontSize: 12)),
      ])) else ...list.map(buildTaskCard),
    ]);
  }

  Widget statCard(String title, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withValues(alpha: .35))),
    child: Column(children: [
      Icon(icon, color: color, size: 23), const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      Text(title, style: const TextStyle(color: muted, fontSize: 11)),
    ]),
  );

  Widget buildTaskCard(TaskItem task) {
    final c = task.priority == 'عالية' ? const Color(0xFFFF426D) : task.priority == 'متوسطة' ? const Color(0xFFFFB52E) : green;
    return Container(margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.all(12), decoration: BoxDecoration(
      color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2A3155)),
    ), child: Row(children: [
      IconButton(onPressed: () async { setState(() => task.done = !task.done); await saveTasks(); },
        icon: Icon(task.done ? Icons.check_circle : Icons.circle_outlined, color: task.done ? green : muted, size: 27)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: task.done ? TextDecoration.lineThrough : null, color: task.done ? muted : Colors.white)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 5, children: [
          tag(task.category, const Color(0xFF8975FF)), tag(task.priority, c),
          if (task.done) tag('مكتملة', green),
        ]),
      ])),
      PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') showTaskDialog(task: task); if (v == 'delete') deleteTask(task); },
        itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))]),
    ]));
  }

  Widget tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .65))),
    child: Text(label, style: TextStyle(color: color, fontSize: 11)),
  );

  Widget buildStats() {
    final p = tasks.isEmpty ? 0.0 : completed / tasks.length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('الإحصائيات', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('تابع تقدّمك وإنجازاتك', style: TextStyle(color: muted)),
      const SizedBox(height: 22),
      statCard('إجمالي المهام', '${tasks.length}', Icons.assignment_outlined, const Color(0xFF6C7BFF)),
      const SizedBox(height: 12), statCard('المهام المكتملة', '$completed', Icons.check_circle_outline, green),
      const SizedBox(height: 12), statCard('المهام المتبقية', '$active', Icons.schedule, const Color(0xFFFFB52E)),
      const SizedBox(height: 22),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('نسبة الإنجاز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18), LinearProgressIndicator(value: p, minHeight: 10, borderRadius: BorderRadius.circular(10), color: green, backgroundColor: const Color(0xFF2A3155)),
        const SizedBox(height: 10), Text('${(p * 100).round()}% من مهامك مكتملة', style: const TextStyle(color: muted)),
      ])),
    ]);
  }

  Widget buildSettings() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('الإعدادات', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
    const SizedBox(height: 20),
    const ListTile(leading: CircleAvatar(backgroundColor: purple, child: Icon(Icons.person_outline, color: Colors.white)), title: Text('مستخدم TaskFlow'), subtitle: Text('نظّم يومك بذكاء')),
    const SizedBox(height: 8),
    const ListTile(leading: Icon(Icons.palette_outlined, color: purple), title: Text('المظهر'), subtitle: Text('الوضع الداكن')),
    const ListTile(leading: Icon(Icons.storage_outlined, color: green), title: Text('حفظ البيانات'), subtitle: Text('تُحفظ مهامك على هذا الجهاز')),
    ListTile(
      leading: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFFF426D)),
      title: const Text('حذف جميع المهام'),
      onTap: () async {
        final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: panel, title: const Text('حذف جميع المهام؟'),
          content: const Text('لا يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف الكل')),
          ],
        ));
        if (ok == true) { setState(() => tasks.clear()); await saveTasks(); }
      },
    ),
    const SizedBox(height: 30),
    const Center(child: Text('TaskFlow • الإصدار 1.0.0', style: TextStyle(color: muted))),
  ]);
}