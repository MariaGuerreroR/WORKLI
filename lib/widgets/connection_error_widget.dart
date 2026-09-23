import 'package:flutter/material.dart';

import '../utils/constants.dart';

class ConnectionErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;

  const ConnectionErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'No hay conexión con el servidor',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: AppDimens.spaceLg),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.spaceSm),
            const Text(
              'Verifica que el servidor esté en ejecución e inténtalo de nuevo.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.spaceLg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
