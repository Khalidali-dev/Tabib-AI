import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tabib.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-initialize local SQLite clinical database
  await MedicineLocalDb.instance.init();

  runApp(const TabibApp());
}

/// Root Application Widget for Tabib - Offline Medical AI Doctor.
class TabibApp extends StatelessWidget {
  const TabibApp({super.key});

  @override
  Widget build(BuildContext context) {
    final modelDownloader = ModelDownloader();
    final inferenceService = MedicalInferenceService.instance;
    final medicineDb = MedicineLocalDb.instance;

    return MultiBlocProvider(
      providers: [
        BlocProvider<DownloadBloc>(
          create: (_) => DownloadBloc(modelDownloader: modelDownloader),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => ChatBloc(
            medicineDb: medicineDb,
            inferenceService: inferenceService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Tabib - Offline Medical AI Doctor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        home: kIsWeb ? const LandingPageScreen() : const GatewayScreen(),
      ),
    );
  }
}
