part of '../verification_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.database,
    required this.keyStorage,
  });
  final AppDatabase database;
  final KeyStorage keyStorage;
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}
