import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';

class PaymentDSLHandler extends DSLHandler {
  @override
  String get type => 'payment';

  @override
  int get version => 1;

  @override
  DSLRenderResult render(Event event, DSLMessage msg) {
    final amount        = msg.get<int>('amount') ?? 0;
    final currency      = msg.get<String>('currency') ?? 'PKR';
    final orderId       = msg.get<String>('order_id') ?? '';
    final paymentUrl    = msg.get<String>('payment_url') ?? '';
    final customerName  = msg.get<String>('customer_name') ?? '';

    return DSLRenderResult(
      widget: _PaymentCard(
        amount: amount,
        currency: currency,
        orderId: orderId,
        paymentUrl: paymentUrl,
        customerName: customerName,
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final int amount;
  final String currency;
  final String orderId;
  final String paymentUrl;
  final String customerName;

  const _PaymentCard({
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.paymentUrl,
    required this.customerName,
  });

  Future<void> _openPayment(BuildContext context) async {
    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment page')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor    = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final titleColor   = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtitleColor = const Color(0xFFC9C9C9);
    final btnBg        = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final btnText      = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
      width: 193.52,
      padding: const EdgeInsets.all(12.61),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15.14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ─────────────────────────────────────────────
          Text(
            '💳 Payment Due',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$currency $amount',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Complete your payment',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 8),

          // ── Divider ───────────────────────────────────────────
          Container(
            height: 0.60,
            color: subtitleColor.withOpacity(0.5),
          ),

          const SizedBox(height: 8),

          // ── Pay Now Button ────────────────────────────────────
          GestureDetector(
            onTap: () => _openPayment(context),
            child: Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: subtitleColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pay Now',
                    style: TextStyle(
                      color: btnText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_circle_right,
                    color: btnText,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}














// import 'package:flutter/material.dart';
// import 'package:matrix/matrix.dart';

// import '../models/dsl_handler.dart';
// import '../models/dsl_message.dart';
// import '../models/dsl_render_result.dart';

// class PaymentDSLHandler extends DSLHandler {
//   @override
//   String get type => 'payment';

//   @override
//   int get version => 1;

//   @override
//   DSLRenderResult render(Event event, DSLMessage msg) {
//     final amount        = msg.get<int>('amount') ?? 0;
//     final currency      = msg.get<String>('currency') ?? 'PKR';
//     final orderId       = msg.get<String>('order_id') ?? '';
//     final customerName  = msg.get<String>('customer_name') ?? '';

//     return DSLRenderResult(
//       widget: _PaymentCard(
//         amount: amount,
//         currency: currency,
//         orderId: orderId,
//         customerName: customerName,
//       ),
//     );
//   }
// }

// class _PaymentCard extends StatelessWidget {
//   final int amount;
//   final String currency;
//   final String orderId;
//   final String customerName;

//   const _PaymentCard({
//     required this.amount,
//     required this.currency,
//     required this.orderId,
//     required this.customerName,
//   });

//   void _openPaymentSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) => _WalletFirstPaymentSheet(
//         amount: amount,
//         currency: currency,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme  = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     final cardColor     = isDark ? Colors.white : const Color(0xFF1F1F1F);
//     final titleColor    = isDark ? const Color(0xFF1A1A1A) : Colors.white;
//     final subtitleColor = const Color(0xFFC9C9C9);
//     final btnBg         = isDark ? const Color(0xFF1A1A1A) : Colors.white;
//     final btnText       = isDark ? Colors.white : const Color(0xFF1A1A1A);

//     return Container(
//       width: 200,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '💳 Payment Due',
//             style: TextStyle(
//               color: titleColor,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '$currency $amount',
//             style: TextStyle(
//               color: titleColor,
//               fontWeight: FontWeight.bold,
//               fontSize: 18,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             'Complete your payment',
//             style: TextStyle(
//               color: subtitleColor,
//               fontSize: 10,
//             ),
//           ),
//           const SizedBox(height: 10),

//           GestureDetector(
//             onTap: () => _openPaymentSheet(context),
//             child: Container(
//               height: 34,
//               decoration: BoxDecoration(
//                 color: btnBg,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Center(
//                 child: Text(
//                   'Pay Now',
//                   style: TextStyle(
//                     color: btnText,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _WalletFirstPaymentSheet extends StatefulWidget {
//   final int amount;
//   final String currency;

//   const _WalletFirstPaymentSheet({
//     required this.amount,
//     required this.currency,
//   });

//   @override
//   State<_WalletFirstPaymentSheet> createState() =>
//       _WalletFirstPaymentSheetState();
// }

// class _WalletFirstPaymentSheetState
//     extends State<_WalletFirstPaymentSheet> {

//   String? selectedMethod;

//   final phoneController = TextEditingController();
//   final cardController = TextEditingController();
//   final expiryController = TextEditingController();
//   final cvvController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//         left: 16,
//         right: 16,
//         top: 20,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [

//           Text(
//             "Pay PKR ${widget.amount}",
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),

//           const SizedBox(height: 16),

//           _methodTile('jazzcash', '📱 JazzCash'),
//           _methodTile('easypaisa', '📲 Easypaisa'),
//           _methodTile('card', '💳 Card'),

//           const SizedBox(height: 16),

//           if (selectedMethod == 'jazzcash')
//             _walletForm("JazzCash"),

//           if (selectedMethod == 'easypaisa')
//             _walletForm("Easypaisa"),

//           if (selectedMethod == 'card')
//             _cardForm(),

//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _methodTile(String value, String title) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: Radio<String>(
//         value: value,
//         groupValue: selectedMethod,
//         onChanged: (val) {
//           setState(() {
//             selectedMethod = val;
//           });
//         },
//       ),
//       title: Text(title),
//     );
//   }

//   Widget _walletForm(String name) {
//     return Column(
//       children: [
//         TextField(
//           controller: phoneController,
//           keyboardType: TextInputType.phone,
//           decoration: InputDecoration(
//             labelText: "$name Number",
//             border: const OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 12),

//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _handlePay,
//             child: Text("Pay with $name"),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _cardForm() {
//     return Column(
//       children: [
//         TextField(
//           controller: cardController,
//           decoration: const InputDecoration(
//             labelText: "Card Number",
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 10),

//         Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: expiryController,
//                 decoration: const InputDecoration(
//                   labelText: "MM/YY",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: TextField(
//                 controller: cvvController,
//                 decoration: const InputDecoration(
//                   labelText: "CVV",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 12),

//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: _handlePay,
//             child: const Text("Pay with Card"),
//           ),
//         ),
//       ],
//     );
//   }

//   void _handlePay() {
//     Navigator.pop(context);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Processing ${selectedMethod ?? ''} payment..."),
//       ),
//     );

//     // 👉 NEXT: call your backend API here
//   }
// }