// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http;

// class TestHomeScreen extends StatefulWidget {
//   const TestHomeScreen({super.key});

//   @override
//   State<TestHomeScreen> createState() => _TestHomeScreenState();
// }

// class _TestHomeScreenState extends State<TestHomeScreen> {
//   double amount = 300;
//   Map<String, dynamic>? paymentIntentData;

//   showPaymentSheet() async {
//     try {
//       await Stripe.instance
//           .presentPaymentSheet()
//           .then((newValue) {
//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(const SnackBar(content: Text("Payment Successful")));
//             paymentIntentData = null;
//           })
//           .onError((error, stackTrace) {
//             if (kDebugMode) {
//               print("STACK TRACE ERROR: $error");
//             }
//           });
//     } on StripeException catch (e) {
//       if (kDebugMode) {
//         print("STRIPE EXCEPTION : ${e.error.localizedMessage}");
//       }

//       showDialog(
//         context: context,
//         builder: (c) => const AlertDialog(content: Text("Cancled by user")),
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print("ERROR IN SHOW PAYMENT SHEET: $e");
//       }
//     }
//   }

//   createPaymentIntent(amountToBeCharge, currency) async {
//     try {
//       Map<String, dynamic> paymentInfo = {
//         'amount': int.parse((amountToBeCharge * 100).toString()),
//         'currency': currency,
//         'payment_method_types[]': 'card',
//       };

//       var responseOfStripeAPI = await http.post(
//         Uri.parse('https://api.stripe.com/v1/payment_intents'),
//         headers: {
//           'Authorization': 'Bearer $SECRET_Key',
//           'Content-Type': 'application/x-www-form-urlencoded',
//         },
//         body: paymentInfo,
//       );

//       if (kDebugMode) {
//         print("RESPONSE FROM STRIPE API : ${responseOfStripeAPI.body}");
//       }

//       return jsonDecode(responseOfStripeAPI.body);
//     } catch (e) {
//       if (kDebugMode) {
//         print("ERROR IN CREATE PAYMENT INTENT : $e");
//       }
//     }
//   }

//   paymentSheetInitialization(amountToBeCharge, currency) async {
//     try {
//       paymentIntentData = await createPaymentIntent(amountToBeCharge, currency);

//       await Stripe.instance
//           .initPaymentSheet(
//             paymentSheetParameters: SetupPaymentSheetParameters(
//               allowsDelayedPaymentMethods: true,
//               paymentIntentClientSecret: paymentIntentData!['client_secret'],
//               style: ThemeMode.dark,
//               merchantDisplayName: 'Company Name',
//             ),
//           )
//           .then((value) {
//             if (kDebugMode) {
//               print("Payment sheet initialized");
//             }
//           });

//       showPaymentSheet();
//     } catch (errorMsg, e) {
//       if (kDebugMode) {
//         print("Error in payment sheet initialization : $e");
//       }
//       print("Error in payment sheet initialization : $errorMsg");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Payment Integration',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.blue,
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             const DrawerHeader(
//               decoration: BoxDecoration(color: Colors.blue),
//               child: Text('Drawer Header'),
//             ),
//             ListTile(
//               title: const Text('Item 1'),
//               onTap: () {
//                 // Update the state of the app
//                 // ...
//               },
//             ),
//             ListTile(
//               title: const Text('Item 2'),
//               onTap: () {
//                 // Update the state of the app
//                 // ...
//               },
//             ),
//           ],
//         ),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             ElevatedButton(
//               onPressed: () {
//                 paymentSheetInitialization(amount, "USD");
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
//               child: Text(
//                 'PAYNOW ${amount.toString()}',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
