import 'package:flutter/material.dart';

import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isDanger;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDanger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: isDanger
            ? OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
              )
            : null,
        child: _buildChild(),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: isDanger
          ? ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            )
          : null,
      child: _buildChild(),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppConstants.paddingSM),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null && !isLoading
            ? LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null || isLoading
            ? Colors.grey.shade400
            : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: onPressed != null && !isLoading
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
              vertical: AppConstants.paddingMD,
            ),
            child: Center(child: _buildChild()),
          ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: AppConstants.paddingSM),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}
