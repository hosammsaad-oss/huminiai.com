import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        const SnackBar(content: Text("من فضلك ادخل اسم المنتج أولاً")),
      );
      return;
    }
    
    setState(() => _isSearching = true);
    
    // محاكاة عملية البحث (مدة 3 ثواني)
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("طلب شراء ذكي", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ماذا تريد أن تشتري اليوم؟", 
                  style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _productController,
                decoration: InputDecoration(
                  hintText: "مثلاً: بلايستيشن 5، آيفون، سماعات..",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF6B4EFF)),
                ),
              ),
              const SizedBox(height: 30),
              Text("حدد ميزانيتك القصوى: ${_budget.toInt()} ريال", 
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              Slider(
                value: _budget,
                min: 100,
                max: 20000,
                divisions: 200,
                activeColor: const Color(0xFF6B4EFF),
                onChanged: (val) => setState(() => _budget = val),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _startHunting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: _isSearching 
                    ? const SizedBox(width: 20, height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch, color: Colors.white),
                  label: Text(
                    _isSearching ? "جاري تشغيل الوكيل وبحث المواقع..." : "أطلق الوكيل للبحث",
                    style: GoogleFonts.tajawal(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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