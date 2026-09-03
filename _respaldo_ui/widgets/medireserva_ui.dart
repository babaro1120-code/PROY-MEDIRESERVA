import 'package:flutter/material.dart';

const kMediBlue = Color(0xFF075BD8);
const kMediDark = Color(0xFF122B6B);
const kMediText = Color(0xFF16284A);
const kMediMuted = Color(0xFF5B6A80);
const kMediBg = Color(0xFFF5F8FC);

class MediReservaPage extends StatelessWidget {
  const MediReservaPage({
    super.key,
    required this.title,
    required this.step,
    required this.child,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final String step;
  final Widget child;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMediBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 43,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (showBack)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  onPressed:
                                      onBack ?? () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 17,
                                    color: kMediText,
                                  ),
                                ),
                              ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: kMediDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step,
                                  style: const TextStyle(
                                    color: kMediBlue,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MediButton extends StatelessWidget {
  const MediButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (outlined) {
      return SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: kMediBlue,
            side: const BorderSide(color: Color(0xFF9FC1F4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kMediBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: child,
      ),
    );
  }
}

class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final n = index + 1;
          final active = n <= current;
          return Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? kMediBlue : const Color(0xFFF0F3F7),
                  border: Border.all(
                    color: active ? kMediBlue : const Color(0xFFDDE3EC),
                  ),
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : kMediText,
                  ),
                ),
              ),
              if (n < 6)
                Container(
                  width: 18,
                  height: 1,
                  color: const Color(0xFFDDE3EC),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EDF3))),
      ),
      child: Row(
        children: [
          Icon(icon, color: kMediBlue, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 7.5, color: kMediMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 9.5,
                      color: kMediText,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
