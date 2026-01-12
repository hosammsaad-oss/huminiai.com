import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingResultsScreen extends StatefulWidget {
  final String productName;
  final double budget;

  const ShoppingResultsScreen({
    super.key, 
    required this.productName, 
    required this.budget
  });

  @override
  State<ShoppingResultsScreen> createState() => _ShoppingResultsScreenState();
}

class _ShoppingResultsScreenState extends State<ShoppingResultsScreen> {
  
  /// دالة تشغيل المتصفح - تم إصلاح خطأ تعريف المتغير
  Future<void> _startAutomatedPurchase(BuildContext context, String url, String siteName) async {
    try {
      // 1. جلب البيانات من الذاكرة
      final prefs = await SharedPreferences.getInstance();
      final String name = prefs.getString('humini_user_name') ?? "";
      final String phone = prefs.getString('humini_user_phone') ?? "";
      final String address = prefs.getString('humini_user_address') ?? "";
      final String city = prefs.getString('humini_user_city') ?? "";

      // 2. تعريف الـ controller أولاً لحل مشكلة الـ Reference
      final WebViewController controller = WebViewController();

      // 3. ضبط الإعدادات بشكل منفصل
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // الآن يمكن استخدام controller هنا بأمان
            controller.runJavaScript('''
              (function() {
                setTimeout(function() {
                  // تمييز أزرار الشراء
                  const buySelectors = ['#add-to-cart-button', '[id*="add-to-cart"]', '.add-to-cart', 'button:contains("إضافة")'];
                  buySelectors.forEach(sel => {
                    let btn = document.querySelector(sel);
                    if(btn) {
                      btn.style.border = "5px solid #6B4EFF";
                      btn.style.boxShadow = "0 0 20px #6B4EFF";
                    }
                  });

                  // تعبئة البيانات تلقائياً
                  const inputs = document.querySelectorAll('input, textarea');
                  inputs.forEach(input => {
                    const attr = (input.name + input.id).toLowerCase();
                    if (attr.includes('name')) input.value = "$name";
                    if (attr.includes('phone')) input.value = "$phone";
                    if (attr.includes('city')) input.value = "$city";
                    if (attr.includes('address')) input.value = "$address";
                  });
                }, 2500);
              })();
            ''');
          },
        ),
      );

      // 4. تحميل الرابط
      await controller.loadRequest(Uri.parse(url));

      // 5. عرض النافذة
      if (!mounted) return;
      _showWebviewModal(context, controller, siteName);
      
    } catch (e) {
      debugPrint("Error starting purchase: $e");
    }
  }

  void _showWebviewModal(BuildContext context, WebViewController controller, String siteName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            _buildModalHandle(siteName),
            Expanded(child: WebViewWidget(controller: controller)),
            _buildModalFooter(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final encodedProduct = Uri.encodeComponent(widget.productName);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("تحليل هوميني الذكي", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeaderSummary(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _buildResultCard(
                    site: "أمازون السعودية", 
                    price: (widget.budget * 0.85).toInt(), 
                    isBest: true, 
                    description: "أفضل سعر وأسرع شحن متوفر",
                    url: "https://www.amazon.sa/s?k=$encodedProduct"
                  ),
                  _buildResultCard(
                    site: "نون (Noon)", 
                    price: (widget.budget * 0.90).toInt(), 
                    isBest: false, 
                    description: "خيارات تقسيط متنوعة",
                    url: "https://www.noon.com/saudi-ar/search/?q=$encodedProduct"
                  ),
                  _buildResultCard(
                    site: "حراج", 
                    price: (widget.budget * 0.50).toInt(), 
                    isBest: false, 
                    description: "بحث في السلع المستعملة",
                    url: "https://haraj.com.sa/search/$encodedProduct"
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF6B4EFF)),
              const SizedBox(width: 10),
              Text("وكيل الشراء الذكي نشط", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text("اختر المتجر المناسب وسيقوم هوميني بتجهيز كل شيء لك.", style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildResultCard({required String site, required int price, required bool isBest, required String description, required String url}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isBest ? Border.all(color: const Color(0xFF6B4EFF), width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(site, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            subtitle: Text(description),
            trailing: Text("~$price ريال", style: GoogleFonts.poppins(color: const Color(0xFF6B4EFF), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async => await _startAutomatedPurchase(context, url, site),
                icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                label: const Text("تجهيز السلة والبيانات", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBest ? const Color(0xFF6B4EFF) : Colors.black87, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalHandle(String site) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 10),
          Text("مساعد هوميني نشط في $site", style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModalFooter() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[100]!))),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF6B4EFF)),
          const SizedBox(width: 10),
          Expanded(child: Text("الوكيل سيقوم بتعبئة بياناتك تلقائياً عند الانتقال للدفع.", style: GoogleFonts.tajawal(fontSize: 11))),
        ],
      ),
    );
  }
}