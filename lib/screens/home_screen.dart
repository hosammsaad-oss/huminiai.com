import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:confetti/confetti.dart';
import '../widgets/smart_banner.dart';
import '../services/context_service.dart'; 

import '../providers/chat_provider.dart';
import '../providers/life_provider.dart';
import '../providers/goals_provider.dart'; 
import '../main.dart'; 
import 'analytics_screen.dart'; 
import 'goals_screen.dart'; 
import 'profile_screen.dart'; 

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatProvider);
    final tasks = ref.watch(lifeProvider);
    final goals = ref.watch(goalsProvider); 
    final contextState = ref.watch(contextProvider); 

    return Scaffold(
      drawer: _buildLifeManagerDrawer(context, tasks),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF6B4EFF),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "HUMINI AI", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SmartContextBanner(),
                
                // --- شريط مستوى الطاقة ---
                if (contextState.energyLevel < 100)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             Icon(Icons.bolt, size: 14, color: contextState.energyLevel < 50 ? Colors.orange : Colors.green),
                             const SizedBox(width: 4),
                             Text("مستوى الحيوية المتوقع: ${contextState.energyLevel}%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: contextState.energyLevel / 100,
                            minHeight: 3,
                            backgroundColor: Colors.grey[200],
                            color: contextState.energyLevel < 50 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- الميزة الجديدة: محدد الحالة المزاجية (Mood Selector) ---
                _buildMoodSelector(),

                Expanded(
                  child: chatMessages.isEmpty 
                      ? _buildWelcomeHero() 
                      : _buildChatList(chatMessages),
                ),
                _buildInputArea(tasks, goals), 
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.purple, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء محدد المزاج
  Widget _buildMoodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.03),
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 0.5))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _moodIcon(Icons.sentiment_very_satisfied, Colors.green, UserMood.happy, "سعيد"),
          _moodIcon(Icons.psychology, Colors.purple, UserMood.focused, "مركز"),
          _moodIcon(Icons.sentiment_neutral, Colors.amber, UserMood.neutral, "عادي"),
          _moodIcon(Icons.sentiment_very_dissatisfied, Colors.redAccent, UserMood.stressed, "مضغوط"),
        ],
      ),
    );
  }

  Widget _moodIcon(IconData icon, Color color, UserMood mood, String label) {
    final currentMood = ref.watch(contextProvider).mood;
    bool isSelected = currentMood == mood;
    return GestureDetector(
      onTap: () => ref.read(contextProvider.notifier).updateMood(mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            Text(label, style: GoogleFonts.tajawal(fontSize: 10, color: isSelected ? color : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(List<TaskModel> tasks, List<Goal> goals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildCircleIconButton(Icons.mic_none_rounded, () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ميزة التسجيل الصوتي قادمة قريباً")));
            }),
            const SizedBox(width: 8),
            _buildCircleIconButton(Icons.add_photo_alternate_outlined, () {
               ref.read(chatProvider.notifier).pickAndSendImage(tasks, goals);
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "اسأل هيومني عن حياتك...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: const Color(0xFF6B4EFF),
              radius: 24,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    ref.read(chatProvider.notifier).sendSmartMessage(_controller.text, tasks, goals);
                    _controller.clear();
                    _scrollToBottom();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6B4EFF).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF6B4EFF), size: 22),
      ),
    );
  }

  Widget _buildLifeManagerDrawer(BuildContext context, List<TaskModel> tasks) {
    final themeMode = ref.watch(themeProvider);
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final remaining = tasks.length - completedCount;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildDrawerHeader(progress, remaining, tasks.length),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildThemeTile(themeMode),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add_location_alt_rounded, color: Colors.green),
                    title: Text("تعيين موقعي الحالي كعمل", style: GoogleFonts.tajawal(fontWeight: FontWeight.w500)),
                    subtitle: const Text("سيقترح هيومني مهامك عند وصولك هنا", style: TextStyle(fontSize: 10)),
                    onTap: () async {
                      await ref.read(contextProvider.notifier).saveCurrentLocationAsWork();
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ تم حفظ الموقع!"), backgroundColor: Colors.green),
                      );
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text("مهامك اليومية", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  if (tasks.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("قائمة المهام فارغة")))
                  else
                    ...tasks.map((task) => _buildTaskItem(task)),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerTile(Icons.insights_rounded, "تحليلات الأداء", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
            _buildDrawerTile(Icons.track_changes_rounded, "الأهداف الإستراتيجية", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()))),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(double progress, int remaining, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B4EFF), Color(0xFF8E78FF)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 45),
                IconButton(
                  icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text("إدارة الحياة الذكية", style: GoogleFonts.tajawal(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("لديك $remaining مهام متبقية", style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: Colors.greenAccent,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        activeColor: const Color(0xFF6B4EFF),
        onChanged: (v) {
          ref.read(lifeProvider.notifier).toggleTask(task.id, task.isCompleted);
          if (v == true) _confettiController.play();
        },
      ),
      title: Text(task.title, style: GoogleFonts.tajawal(decoration: task.isCompleted ? TextDecoration.lineThrough : null, color: task.isCompleted ? Colors.grey : null)),
    );
  }

  Widget _buildChatList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(15),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        return Align(
          alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: m.isUser ? const Color(0xFF6B4EFF) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[200]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(m.isUser ? 18 : 0),
                bottomRight: Radius.circular(m.isUser ? 0 : 18),
              ),
            ),
            child: MarkdownBody(
              data: m.text,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.tajawal(color: m.isUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHero() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion_rounded, size: 80, color: const Color(0xFF6B4EFF).withOpacity(0.3)),
          const SizedBox(height: 20),
          Text("أهلاً بك في هيومني AI", style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("كيف يمكنني مساعدتك اليوم؟", style: GoogleFonts.tajawal(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildThemeTile(ThemeMode mode) {
    return ListTile(
      leading: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.orange),
      title: Text(mode == ThemeMode.dark ? "الوضع المضيء" : "الوضع الداكن", style: GoogleFonts.tajawal()),
      onTap: () => ref.read(themeProvider.notifier).state = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B4EFF)),
      title: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: Text("تسجيل الخروج", style: GoogleFonts.tajawal(color: Colors.redAccent)),
      onTap: () => FirebaseAuth.instance.signOut(),
    );
  }
}