import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/life_provider.dart';
import 'stats_dashboard.dart';
import '../services/notification_service.dart'; // تأكد أن المسار يؤدي إلى مجلد services لديك

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(lifeProvider);
    // استدعاء التنبيه ليعمل في الخلفية بناءً على عدد المهام المتبقية
    final pendingTasks = tasks.where((t) => !t.isCompleted).length;
    NotificationService.scheduleTaskReminder(pendingTasks);
    // حساب نسبة الإنجاز الإجمالية للمؤشر العلوي
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final double progress = totalCount == 0 ? 0 : completedCount / totalCount;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "مخطط الإنجاز",
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF6B4EFF),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.tajawal(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "تطور"),
              Tab(text: "التزام"),
              Tab(text: "سرعة"),
              // يمكنك إضافة "تواصل" و "دقة" إذا أردت تبويبات أكثر
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.grey[50]),
          child: Column(
            children: [
              // --- 1. بطاقة ملخص الإنجاز العلوية (القابلة للضغط) ---
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsDashboard()),
                ),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4EFF), Color(0xFF8E74FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4EFF).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "مستوى الإنجاز العام",
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "اضغط لعرض لوحة القيادة والتحليل 📊",
                            style: GoogleFonts.tajawal(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                              strokeWidth: 6,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- 2. محتوى التبويبات (TabBarView) ---
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTaskCategory(context, ref, tasks, "تطور"),
                    _buildTaskCategory(context, ref, tasks, "التزام"),
                    _buildTaskCategory(context, ref, tasks, "سرعة"),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF6B4EFF),
          onPressed: () => _showAddTaskDialog(context, ref),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // دالة عرض نافذة إضافة المهمة
  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String selectedCategory = 'daily';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              "إضافة مهمة جديدة",
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "ما هي مهمتك القادمة؟",
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'تطور', child: Text("تطور")),
                    DropdownMenuItem(value: 'التزام', child: Text("التزام")),
                    DropdownMenuItem(value: 'سرعة', child: Text("سرعة")),
                    DropdownMenuItem(value: 'تواصل', child: Text("تواصل")),
                    DropdownMenuItem(value: 'دقة', child: Text("دقة")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      selectedCategory = val!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EFF),
                ),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    ref
                        .read(lifeProvider.notifier)
                        .addTask(controller.text, category: selectedCategory);
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "إضافة",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة بناء قائمة المهام لكل قسم
  Widget _buildTaskCategory(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    String type,
  ) {
    final filteredTasks = tasks.where((t) => t.category == type).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            Text(
              "لا توجد مهام في هذا القسم",
              style: GoogleFonts.tajawal(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];

        return Dismissible(
          key: Key(task.id),
          direction: DismissDirection.startToEnd,
          onDismissed: (direction) {
            ref.read(lifeProvider.notifier).deleteTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "تم حذف: ${task.title}",
                  style: GoogleFonts.tajawal(),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Checkbox(
                value: task.isCompleted,
                activeColor: const Color(0xFF6B4EFF),
                onChanged: (_) => ref
                    .read(lifeProvider.notifier)
                    .toggleTask(task.id, task.isCompleted),
              ),
              title: Text(
                task.title,
                style: GoogleFonts.tajawal(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.isCompleted ? Colors.grey : Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.chevron_left, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
