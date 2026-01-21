import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/context_service.dart';

class SmartContextBanner extends ConsumerWidget {
  const SmartContextBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextState = ref.watch(contextProvider);

    if (!contextState.isVisible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF6B4EFF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6B4EFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              contextState.suggestion,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(contextProvider.notifier).dismiss(),
          )
        ],
      ),
    );
  }
}