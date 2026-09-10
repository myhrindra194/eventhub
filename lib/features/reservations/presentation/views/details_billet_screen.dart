import 'package:flutter/material.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/qr_code_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/navigation_provider.dart';
import '../../../home/presentation/widgets/custom_bottom_nav_bar.dart';

class DetailsBilletScreen extends ConsumerWidget {
  final String ticketId;

  const DetailsBilletScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(title: 'Ticket Details', subtitle: 'Your entry code'),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrCodeWidget(data: ticketId),
                  const SizedBox(height: 24),
                  Text(
                    'Ticket #$ticketId',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'Back to Home',
                    height: 50,
                    onPressed: () {
                      ref.read(navigationIndexProvider.notifier).state = 0;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }
}
