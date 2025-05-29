import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final bool isLoading;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: backgroundColor ?? theme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: isLoading ? null : onPressed,
          child:
              isLoading
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? theme.primaryColor,
                      ),
                    ),
                  )
                  : Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  text,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
