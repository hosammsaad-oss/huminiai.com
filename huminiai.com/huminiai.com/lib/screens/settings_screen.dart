
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // إضافة مكتبة التخزين
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // القيم الافتراضية
  TimeOfDay _startTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSavedSettings(); // تحميل الإعدادات المحفوظة عند فتح الصفحة
  }

  // دالة لتحميل الساعات المحفوظة من ذاكرة الهاتف
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startTime = TimeOfDay(
        hour: prefs.getInt('sleep_start_hour') ?? 23,
        minute: 0,
      );
      _endTime = TimeOfDay(
        hour: prefs.getInt('sleep_end_hour') ?? 7,
        minute: 0,
      );
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      // استدعاء الدالة من الـ Service لحفظ التوقيت الجديد
      await NotificationService.updateSleepSettings(_startTime.hour, _endTime.hour);
      
      // إظهار تأكيد للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ مواعيد السكون بنجاح")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الإعدادات"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "خصوصية الوكيل (هوميني)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 15),
          Card(
            elevation: 0,
            color: Colors.blueGrey.withOpacity(0.1),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
                  title: const Text("وقت بدء السكون"),
                  trailing: Text(_startTime.format(context)),
                  onTap: () => _selectTime(context, true),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                  title: const Text("وقت استيقاظ الوكيل"),
                  trailing: Text(_endTime.format(context)),
                  onTap: () => _selectTime(context, false),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "خلال هذه الفترة، لن يقوم هوميني بتحليل أي إشعارات خارجية لضمان هدوئك.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}