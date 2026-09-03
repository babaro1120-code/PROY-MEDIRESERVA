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
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: showBack
                                  ? IconButton(
                                      onPressed: onBack ??
                                          () => Navigator.pop(context),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new,
                                        size: 20,
                                        color: kMediText,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: kMediDark,
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: kMediBlue,
                                      fontSize: 11.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 34),
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
          Icon(icon, size: 20.2),
          const SizedBox(width: 7.8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 15.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (outlined) {
      return SizedBox(
        height: 46,
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
      height: 46,
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
                    fontSize: 12.8,
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
          Icon(icon, color: kMediBlue, size: 23),
          const SizedBox(width: 11.7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: kMediMuted)),
                const SizedBox(height: 2.6),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 15.2,
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
