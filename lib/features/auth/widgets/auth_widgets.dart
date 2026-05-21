import 'package:flutter/material.dart';
import 'package:focusguard/core/theme/app_theme.dart';

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.12)),
    );
  }
}

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.type = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark, obscure;
  final TextInputType type;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final tp  = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final tt  = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final bg4 = isDark ? FGColors.bg4         : FGColorsLight.bg4;
    final b2  = isDark ? FGColors.border2     : FGColorsLight.border2;
    final p   = isDark ? FGColors.purple      : FGColorsLight.purple;
    final err = isDark ? FGColors.red         : FGColorsLight.red;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: tp),
      cursorColor: p,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tt, fontSize: 14),
        filled: true,
        fillColor: bg4,
        prefixIcon: Icon(icon, color: tt, size: 18),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: FGRadius.md, borderSide: BorderSide(color: b2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: FGRadius.md,
            borderSide: BorderSide(color: p, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: FGRadius.md, borderSide: BorderSide(color: err)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: FGRadius.md,
            borderSide: BorderSide(color: err, width: 1.5)),
        errorStyle: TextStyle(
            fontFamily: 'DM Sans', fontSize: 11, color: err),
      ),
      validator: validator,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.15)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: FGRadius.md,
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white)))
            : Center(
                child: Text(label,
                    style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3))),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, required this.isDark});
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? FGColors.redGlow : const Color(0x0FE53E3E),
        borderRadius: FGRadius.md,
        border: Border.all(
            color: isDark ? FGColors.redBorder : FGColorsLight.redBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline_rounded,
            color: isDark ? FGColors.red : FGColorsLight.red, size: 16),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: isDark ? FGColors.red : FGColorsLight.red,
                    height: 1.4))),
      ]),
    );
  }
}

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, required this.isDark, required this.p, required this.pL});
  final bool isDark;
  final Color p, pL;

  @override
  Widget build(BuildContext context) {
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final tt = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    return Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          borderRadius: FGRadius.xl,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p, pL],
          ),
          boxShadow: [
            BoxShadow(
                color: p.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 44, height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
        ]),
      ),
      const SizedBox(height: 14),
      RichText(
          text: TextSpan(
        style: const TextStyle(
            fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800),
        children: [
          TextSpan(text: 'Stay', style: TextStyle(color: p)),
          TextSpan(text: 'Off', style: TextStyle(color: tp)),
        ],
      )),
      const SizedBox(height: 4),
      Text('Stay off. Stay focused.',
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: tt,
              letterSpacing: 0.2)),
    ]);
  }
}

class AuthLogoSmall extends StatelessWidget {
  const AuthLogoSmall({super.key, required this.isDark, required this.p, required this.pL});
  final bool isDark;
  final Color p, pL;

  @override
  Widget build(BuildContext context) {
    final tp = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          borderRadius: FGRadius.md,
          gradient: LinearGradient(
              colors: [p, pL],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 10),
      RichText(
          text: TextSpan(
        style: const TextStyle(
            fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800),
        children: [
          TextSpan(text: 'Stay', style: TextStyle(color: p)),
          TextSpan(text: 'Off', style: TextStyle(color: tp)),
        ],
      )),
    ]);
  }
}