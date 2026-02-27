import 'package:firebase_core/firebase_core.dart';
import 'package:emmi_management/firebase_options.dart';
import 'package:emmi_management/Providers/Product/ProductProvider.dart';
import 'package:emmi_management/Providers/BillProvider.dart';
import 'package:emmi_management/Providers/Qubiq/QubiqProvider.dart';
import 'package:emmi_management/Providers/Ads/AdsProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Providers/AuthProvider.dart';
import 'Providers/Marketing/SchoolVisitProvider.dart';
import 'Providers/User_provider.dart';
import 'Screens/Login/LoginScreen.dart';
import 'Screens/RolesPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();
  await authProvider.loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SchoolVisitProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => QubiqProvider()),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: (auth.token != null && auth.token!.isNotEmpty)
              ? RolesPage()
              : LoginScreenLight(),
        );
      },
    );
  }
}
