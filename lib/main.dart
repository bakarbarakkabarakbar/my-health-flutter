import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:flutter/material.dart';
import 'package:myhealth/Screens/testtt/test.dart';
import 'package:myhealth/Screens/welcome_screen.dart';
import 'package:myhealth/components/sign_method.dart';
import 'package:myhealth/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => SignProvider(),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'myHealth',
            theme: ThemeData(
                colorScheme: ColorScheme(
                    primary: kBlack,
                    primaryVariant: kBlack,
                    secondary: kYellow,
                    secondaryVariant: kYellow,
                    surface: kYellow,
                    background: kYellow,
                    error: kRed,
                    onPrimary: kBlack,
                    onSecondary: kYellow,
                    onSurface: kYellow,
                    onBackground: kYellow,
                    onError: kRed,
                    brightness: Brightness.dark)),
            home: WelcomeScreen()),
      );
}
