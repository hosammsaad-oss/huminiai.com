import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- التعريفات العامة ---

enum UserMood { happy, stressed, tired, focused, neutral }
enum UserContext { home, work, morning, unknown }

class ContextState {
  final UserContext currentContext;
  final String suggestion;
  final bool isVisible;
  final double? workLat;
  final double? workLong;
  final int energyLevel; // من 0 إلى 100
  final UserMood mood;

  ContextState({
    this.currentContext = UserContext.unknown,
    this.suggestion = "",
    this.isVisible = false,
    this.workLat,
    this.workLong,
    this.energyLevel = 100,
    this.mood = UserMood.neutral,
  });

  // دالة copyWith لتسهيل التحديث دون حذف البيانات الأخرى
  ContextState copyWith({
    UserContext? currentContext,
    String? suggestion,
    bool? isVisible,
    double? workLat,
    double? workLong,
    int? energyLevel,
    UserMood? mood,
  }) {
    return ContextState(
      currentContext: currentContext ?? this.currentContext,
      suggestion: suggestion ?? this.suggestion,
      isVisible: isVisible ?? this.isVisible,
      workLat: workLat ?? this.workLat,
      workLong: workLong ?? this.workLong,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
    );
  }
}

// --- المتحكم في الحالة ---

class ContextNotifier extends StateNotifier<ContextState> {
  ContextNotifier() : super(ContextState()) {
    _loadSavedLocation();
    _analyzeSleepAndEnergy(); // تحليل الطاقة عند بدء التشغيل
    _initLocationTracking();
  }

  // تحديث المزاج (تم إصلاح مكانها داخل الكلاس)
  void updateMood(UserMood newMood) {
    state = state.copyWith(mood: newMood);
  }

  // --- منطق تحليل النوم والطاقة ---
  Future<void> _analyzeSleepAndEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // جلب آخر وقت كان فيه المستخدم نشطاً
    final lastSeenStr = prefs.getString('last_active_time');
    if (lastSeenStr != null) {
      final lastSeen = DateTime.parse(lastSeenStr);
      final sleepDuration = now.difference(lastSeen).inHours;

      String sleepSuggestion = "";
      int energy = 100;

      if (now.hour >= 5 && now.hour <= 10) { // نحن في وقت الصباح
        if (sleepDuration < 6) {
          energy = 40;
          sleepSuggestion = "😴 يبدو أن نومك كان قصيراً ($sleepDuration ساعات). خذ الأمور بهدوء اليوم.";
        } else {
          energy = 90;
          sleepSuggestion = "☀️ صباح الخير! نمت بشكل جيد ($sleepDuration ساعات). يومك مليء بالطاقة!";
        }

        state = state.copyWith(
          currentContext: UserContext.morning,
          suggestion: sleepSuggestion,
          isVisible: true,
          energyLevel: energy,
        );
      }
    }
    
    // تحديث وقت النشاط الحالي
    await prefs.setString('last_active_time', now.toIso8601String());
  }

  // --- منطق حفظ الموقع ---
  Future<void> saveCurrentLocationAsWork() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('work_lat', position.latitude);
      await prefs.setDouble('work_long', position.longitude);

      state = state.copyWith(
        workLat: position.latitude,
        workLong: position.longitude,
        isVisible: false,
      );
    } catch (e) {
      // التعامل مع أخطاء الأذونات
    }
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('work_lat');
    double? lon = prefs.getDouble('work_long');
    if (lat != null && lon != null) {
      state = state.copyWith(workLat: lat, workLong: lon);
    }
  }

  // --- تتبع الموقع المستمر ---
  void _initLocationTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 50
      ),
    ).listen((Position position) {
      final savedLat = state.workLat;
      final savedLong = state.workLong;

      if (savedLat != null && savedLong != null) {
        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, savedLat, savedLong
        );
        if (distance < 200) {
          state = state.copyWith(
            currentContext: UserContext.work,
            suggestion: "📍 أنت في العمل.. هل نبدأ بالمهام الأكثر أهمية؟",
            isVisible: true,
          );
        }
      }
    });
  }

  // إخفاء البانر الذكي
  void dismiss() => state = state.copyWith(isVisible: false);
}

// --- المزود (Provider) ---
final contextProvider = StateNotifierProvider<ContextNotifier, ContextState>((ref) => ContextNotifier());