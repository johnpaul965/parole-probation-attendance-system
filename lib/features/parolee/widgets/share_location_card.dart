import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:last/core/theme/app_colors.dart';
import 'package:last/features/auth/providers/auth_provider.dart';
import 'package:last/features/tracking/providers/phone_location_provider.dart';

class ShareLocationCard extends StatelessWidget {
  const ShareLocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final gps = context.watch<PhoneLocationProvider>();
    if (user == null) return const SizedBox.shrink();

    final last = gps.lastSentAt;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE LOCATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Share this phone’s GPS with your assigned officer. Tracking works while the app is open. This is not an ESP32 ankle monitor.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share live location', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                gps.isSharing
                    ? (last == null
                        ? 'Sharing… waiting for GPS'
                        : 'Last sent ${DateFormat('h:mm a').format(last)}')
                    : 'Off — your officer cannot see phone GPS',
                style: const TextStyle(fontSize: 12),
              ),
              value: gps.isSharing,
              onChanged: gps.isBusy
                  ? null
                  : (on) => gps.setSharing(enabled: on, paroleeId: user.id),
            ),
            if (gps.isBusy) const LinearProgressIndicator(),
            if (gps.error != null) ...[
              const SizedBox(height: 8),
              Text(gps.error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
