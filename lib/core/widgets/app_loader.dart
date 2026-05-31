import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.sColor),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: const TextStyle(color: AppColors.onSurfaceMuted)),
          ],
        ],
      ),
    );
  }
}
