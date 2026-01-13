import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async'; // ضروري لعمل الـ Timer والـ Future
import 'shopping_results_screen.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final TextEditingController _productController = TextEditingController();
  double _budget = 1000;
  bool _isSearching = false;

  void _startHunting() {
    if (_productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("من فضلك ادخل اسم المنتج أولاً", textAlign: TextAlign.center),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isSearching = true);
    
    // محاكاة عملية البحث (مدة 3 ثواني)
    // هنا يتصل التطبيق بمحركات البحث لجلب أفضل الأسعار
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _isSearching = false);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShoppingResultsScreen(
            productName: _productController.text,
            budget: _budget,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _productController.dispose(); // تنظيف الذاكرة عند إغلاق الصفحة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("طلب شراء ذكي", 
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text("ماذا تريد أن تشتري اليوم؟", 
                  style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text("سيقوم الوكيل الذكي بالبحث في المتاجر الموثوقة فوراً.",
                  style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey)),
              
              const SizedBox(height: 25),
              
              // حقل إدخال المنتج
              TextField(
                controller: _productController,
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  hintText: "مثلاً: بلايستيشن 5، آيفون، سماعات..",
                  hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 1),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6B4EFF)),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // قسم الميزانية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("حدد ميزانيتك القصوى:", 
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("${_budget.toInt()} ريال", 
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, 
                          color: const Color(0xFF6B4EFF)
                        )),
                  ),
                ],
              ),
              
              Slider(
                value: _budget,
                min: 100,
                max: 20000,
                divisions: 199, // تعديل ليعطي قفزات بـ 100 ريال تقريباً
                activeColor: const Color(0xFF6B4EFF),
                inactiveColor: Colors.grey[200],
                onChanged: (val) => setState(() => _budget = val),
              ),
              
              const Spacer(),
              
              // زر إطلاق الوكيل
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _startHunting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: const Color(0xFF6B4EFF).withOpacity(0.4),
                  ),
                  icon: _isSearching 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : const Icon(Icons.rocket_launch, color: Colors.white),
                  label: Text(
                    _isSearching ? "جاري تشغيل الوكيل وبحث المواقع..." : "أطلق الوكيل للبحث",
                    style: GoogleFonts.tajawal(
                      color: Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}