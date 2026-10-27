import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'models/job_models.dart';
import 'services/auth_service.dart';
import 'services/firestore_recruiting_service.dart';
import 'services/european_locations_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EasyJobApp());
}

class EasyJobApp extends StatelessWidget {
  const EasyJobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyJob — Ricerca Lavoro & Recruiting 1-Click',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E60ED),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E60ED),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E60ED), width: 2),
          ),
        ),
      ),
      home: const EasyJobMainShell(),
    );
  }
}

class EasyJobMainShell extends StatefulWidget {
  const EasyJobMainShell({super.key});

  @override
  State<EasyJobMainShell> createState() => _EasyJobMainShellState();
}

class _EasyJobMainShellState extends State<EasyJobMainShell> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final FirestoreRecruitingService _firestoreService =
      FirestoreRecruitingService();
  final MapController _mapController = MapController();

  User? _currentUser;
  bool _isDemoLoggedIn = true;
  bool _isFirestoreConnected = false;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<JobOffer>>? _jobsSubscription;
  StreamSubscription<List<JobApplication>>? _applicationsSubscription;

  // Filtri Annunci
  double _maxDistanceKm = 300.0;
  String _searchQuery = '';
  String _selectedCategory = 'Tutte';

  // Stato per la mappa e card carousel
  int _selectedMapJobIndex = 0;
  late final PageController _mapPageController;
  bool _isLocatingGps = false;

  // Curriculum & Dati Personali
  CloudResume _cloudResume = CloudResume(
    userId: 'user-giovanni-messina',
    fullName: 'Giovanni Messina',
    email: 'giovannimessina96@gmail.com',
    phone: '+39 348 712 9045',
    birthDate: '15/06/1996',
    locationCity: 'Milano',
    userLat: 45.4642,
    userLon: 9.1900,
    photoUrl: '',
    headline: 'Senior Flutter & Full-Stack Cloud Architect',
    summary:
        'Ingegnere del software specializzato in app mobile in Flutter/Dart, Cloud Firestore e architetture scalabili.',
    skills:
        'Flutter, Dart, Cloud Firestore, Firebase Auth, Google Meet API, REST, Clean Architecture',
    experience:
        '• Tech Lead Mobile @ FinTech Milano (2023 - Presente)\n• Senior Flutter Developer @ Digital Studio (2020 - 2023)',
    education:
        'Laurea Magistrale in Ingegneria Informatica — Politecnico di Milano',
    portfolioUrl: 'https://github.com/giovannimessina-dev',
    updatedAt: DateTime.now(),
  );

  // Annunci distribuiti in diverse città d'Italia per testare il filtro geografico
  final List<JobOffer> _seedJobs = [
    JobOffer(
      id: 'job-flutter-milano-01',
      title: 'Senior Flutter Mobile Engineer',
      company: 'SatisCloud FinTech',
      locationName: 'Milano — Porta Nuova',
      latitude: 45.4842,
      longitude: 9.1905,
      salaryRange: '€52.000 - €68.000',
      contractType: 'Ibrido',
      category: 'Mobile & Flutter',
      description:
          'Sviluppo della super-app bancaria in Flutter con architettura BLoC/Clean Arch, sincronizzazione real-time su Cloud Firestore.',
      requirements:
          'Flutter, Dart, Firebase Firestore, OAuth2, Test Automatizzati',
      recruiterId: 'recruiter-fintech-1',
      recruiterName: 'Elena Visconti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
    JobOffer(
      id: 'job-cloud-milano-02',
      title: 'Cloud & Firebase Solutions Architect',
      company: 'Velasca Digital Hub',
      locationName: 'Milano — Isola',
      latitude: 45.4878,
      longitude: 9.1882,
      salaryRange: '€58.000 - €75.000',
      contractType: 'Full-time',
      category: 'Cloud & Backend',
      description:
          'Progettazione di backend serverless su Firestore Enterprise e integrazione Google Workspace APIs.',
      requirements: 'Firestore Security Rules, GCP, TypeScript, CI/CD',
      recruiterId: 'recruiter-hub-2',
      recruiterName: 'Elena Visconti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
    JobOffer(
      id: 'job-product-torino-03',
      title: 'Lead Product Designer Mobile',
      company: 'Orion Mobility Lab',
      locationName: 'Torino — OGR Tech',
      latitude: 45.0668,
      longitude: 7.6612,
      salaryRange: '€45.000 - €58.000',
      contractType: 'Ibrido',
      category: 'Design & UX',
      description:
          'Design System cross-platform Figma-to-Flutter e prototipazione interattiva per app di mobilità connessa.',
      requirements: 'Figma, Design Systems, Mobile UI/UX, Flutter Tokens',
      recruiterId: 'recruiter-torino-3',
      recruiterName: 'Marco Rinaldi',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now(),
    ),
    JobOffer(
      id: 'job-ai-bologna-04',
      title: 'AI & Data Platform Engineer',
      company: 'AlmaMed BioTech',
      locationName: 'Bologna — Distretto Navile',
      latitude: 44.5112,
      longitude: 11.3398,
      salaryRange: '€50.000 - €64.000',
      contractType: 'Remoto',
      category: 'AI & Data Science',
      description:
          'Pipeline predittive e cruscotti analitici esposti tramite API veloci e scalabili per l\'analisi clinica.',
      requirements: 'Python, TypeScript, Cloud NoSQL, Data Pipelines',
      recruiterId: 'recruiter-bologna-4',
      recruiterName: 'Chiara Moretti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    JobOffer(
      id: 'job-flutter-roma-05',
      title: 'Flutter Cross-Platform Developer',
      company: 'Capitolium Smart Gov',
      locationName: 'Roma — EUR',
      latitude: 41.8318,
      longitude: 12.4697,
      salaryRange: '€42.000 - €54.000',
      contractType: 'Ibrido',
      category: 'Mobile & Flutter',
      description:
          'Applicazioni civiche con geolocalizzazione avanzata, mappe interattive e notifiche push push personalizzate.',
      requirements: 'Flutter, flutter_map, Firebase Messaging, Clean Code',
      recruiterId: 'recruiter-gov-5',
      recruiterName: 'Lorenzo Conti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
    JobOffer(
      id: 'job-frontend-firenze-06',
      title: 'Frontend & Mobile UI Engineer',
      company: 'Arno Luxury Commerce',
      locationName: 'Firenze — Centro Storico',
      latitude: 43.7731,
      longitude: 11.2560,
      salaryRange: '€44.000 - €56.000',
      contractType: 'Full-time',
      category: 'Frontend & Web',
      description:
          'Interfacce editoriali per ecommerce di lusso con micro-animazioni fluide e altissime performance.',
      requirements: 'TypeScript, Flutter Web, UI Animation, REST',
      recruiterId: 'recruiter-firenze-6',
      recruiterName: 'Elena Visconti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now(),
    ),
    JobOffer(
      id: 'job-security-napoli-07',
      title: 'Mobile Security Engineer',
      company: 'Partenope Cyber Tech',
      locationName: 'Napoli — Centro Direzionale',
      latitude: 40.8518,
      longitude: 14.2681,
      salaryRange: '€46.000 - €60.000',
      contractType: 'Ibrido',
      category: 'Cloud & Backend',
      description:
          'Audit di sicurezza, hardening di app mobile Flutter e protezione endpoint API e token OAuth.',
      requirements: 'Android/iOS Security, Reverse Engineering, OWASP Mobile',
      recruiterId: 'recruiter-napoli-7',
      recruiterName: 'Gennaro Esposito',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now(),
    ),
  ];

  List<JobOffer> _jobs = [];
  List<JobApplication> _applications = [];
  final List<String> _pushNotificationsLog = [
    'Benvenuto su EasyJob! Notifiche e sincronizzazione Firestore attive.',
  ];

  String get effectiveUserId =>
      _currentUser?.uid ??
      (_isDemoLoggedIn ? 'user-giovanni-messina' : _cloudResume.userId);
  String get effectiveUserName =>
      _currentUser?.displayName ??
      (_isDemoLoggedIn ? _cloudResume.fullName : 'Ospite');
  String get effectiveUserEmail =>
      _currentUser?.email ??
      (_isDemoLoggedIn ? _cloudResume.email : 'candidato@easyjob.it');
  bool get isAuthenticated => _currentUser != null || _isDemoLoggedIn;

  @override
  void initState() {
    super.initState();
    _mapPageController = PageController(viewportFraction: 0.88);
    _jobs = List.from(_seedJobs);
    _initFirebaseAndSync();
  }

  @override
  void dispose() {
    _mapPageController.dispose();
    _authSubscription?.cancel();
    _jobsSubscription?.cancel();
    _applicationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initFirebaseAndSync() async {
    final bool connected = await _firestoreService.verifyConnection();
    if (mounted) setState(() => _isFirestoreConnected = connected);

    await _firestoreService.seedInitialJobsIfEmpty(_seedJobs);

    _jobsSubscription = _firestoreService.watchJobs().listen((firestoreJobs) {
      if (mounted && firestoreJobs.isNotEmpty) {
        setState(() => _jobs = firestoreJobs);
      }
    }, onError: (err) {
      debugPrint('Firestore Jobs Stream Note: $err');
    });

    // Carica profilo iniziale dell'utente
    final savedResume =
        await _firestoreService.getCloudResume(effectiveUserId);
    if (savedResume != null && mounted) {
      setState(() => _cloudResume = savedResume);
    }

    _listenApplications();

    _authSubscription = _authService.authStateChanges.listen((user) async {
      if (mounted) {
        setState(() {
          _currentUser = user;
          if (user != null) _isDemoLoggedIn = false;
        });
      }
      if (user != null) {
        _listenApplications();
        final remote = await _firestoreService.getCloudResume(user.uid);
        if (remote != null && mounted) {
          setState(() => _cloudResume = remote);
        }
      }
    });
  }

  bool get _isRecruiterMode => _cloudResume.role == 'recruiter';
  String _recruiterStatusFilter = 'Tutte';

  void _listenApplications() {
    _applicationsSubscription?.cancel();
    final filter = _isRecruiterMode ? null : effectiveUserId;
    _applicationsSubscription = _firestoreService
        .watchApplications(candidateId: filter)
        .listen((apps) {
      if (mounted) {
        setState(() => _applications = apps);
      }
    }, onError: (err) {
      debugPrint('Applications Stream Note: $err');
    });
  }

  Future<void> _toggleRole() async {
    final newRole = _isRecruiterMode ? 'candidate' : 'recruiter';
    setState(() {
      _cloudResume = _cloudResume.copyWith(role: newRole);
      _selectedIndex = 0;
    });
    _listenApplications();
    await _firestoreService.saveCloudResume(_cloudResume);
    _emitPushBanner(
      'Ruolo Aggiornato',
      newRole == 'recruiter'
          ? 'Modalità Recruiter attivata: gestione ATS, candidati e creazione annunci.'
          : 'Modalità Candidato attivata: offerte, mappa e candidature.',
    );
  }

  void _emitPushBanner(String title, String body) {
    setState(() {
      _pushNotificationsLog.insert(0, '$title — $body');
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        content: Text('🔔 $title: $body'),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final userCred = await _authService.signInWithGoogle();
      if (userCred != null) {
        setState(() => _isDemoLoggedIn = false);
        _emitPushBanner(
          'Login Riuscito',
          'Benvenuto ${userCred.user?.displayName ?? "Utente"}!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showAuthTroubleshootingDialog(e.toString());
    }
  }

  void _showAuthTroubleshootingDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1E60ED)),
            SizedBox(width: 8),
            Text('Accesso EasyJob'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nota accesso: $error',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'Puoi utilizzare l\'accesso diretto per utilizzare subito l\'app con il tuo profilo EasyJob e sincronizzazione su Firestore.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isDemoLoggedIn = true);
            },
            child: const Text('Usa Profilo Giovanni Messina'),
          ),
        ],
      ),
    );
  }

  /// Calcola i lavori filtrati in base alla ricerca, categoria e posizione dell'utente
  List<JobOffer> get _filteredJobs {
    final jobs = _jobs.where((job) {
      if (job.status == 'closed') return false;
      if (_selectedCategory != 'Tutte' && job.category != _selectedCategory) {
        return false;
      }
      final dist = job.distanceFromKm(_cloudResume.userLat, _cloudResume.userLon);
      if (dist > _maxDistanceKm) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = job.title.toLowerCase().contains(q);
        final matchesComp = job.company.toLowerCase().contains(q);
        final matchesReq = job.requirements.toLowerCase().contains(q);
        final matchesLoc = job.locationName.toLowerCase().contains(q);
        if (!matchesTitle && !matchesComp && !matchesReq && !matchesLoc) {
          return false;
        }
      }
      return true;
    }).toList();

    // Ordina i lavori dal più vicino al più lontano rispetto alla posizione dell'utente
    jobs.sort((a, b) {
      final distA = a.distanceFromKm(_cloudResume.userLat, _cloudResume.userLon);
      final distB = b.distanceFromKm(_cloudResume.userLat, _cloudResume.userLon);
      return distA.compareTo(distB);
    });

    return jobs;
  }

  /// Modale Candidatura 1-Click
  Future<void> _openOneClickApplyModal(JobOffer job) async {
    final TextEditingController notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final hasProfilePdf = _cloudResume.cvPdfName.isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFF1E60ED),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${job.company} · ${job.locationName}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  const Text(
                    'Curriculum Vitae allegato (Formato PDF):',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  // Box Stato CV PDF
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasProfilePdf
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasProfilePdf
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFFDC2626),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasProfilePdf
                                    ? _cloudResume.cvPdfName
                                    : 'Nessun CV PDF nel profilo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                hasProfilePdf
                                    ? '${_cloudResume.cvPdfSize} • Pronto per l\'invio al recruiter'
                                    : 'Carica il tuo file PDF prima di inviare',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasProfilePdf
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _pickAndUploadPdfResume();
                            setModalState(() {});
                          },
                          child: Text(hasProfilePdf ? 'Cambia' : 'Carica PDF'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Messaggio opzionale per il Recruiter',
                      hintText:
                          'Es: Disponibile da subito per colloquio conoscitivo.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final String finalCvTitle = _cloudResume.cvPdfName.isNotEmpty
                            ? _cloudResume.cvPdfName
                            : 'Curriculum_${effectiveUserName.replaceAll(' ', '_')}.pdf';
                        final String finalCvContent = _cloudResume.cvPdfBase64.isNotEmpty
                            ? _cloudResume.cvPdfBase64
                            : 'CV formato PDF ($finalCvTitle)';

                        final newApp = JobApplication(
                          id: 'app-${DateTime.now().millisecondsSinceEpoch}',
                          jobId: job.id,
                          jobTitle: job.title,
                          company: job.company,
                          candidateId: effectiveUserId,
                          candidateName: effectiveUserName,
                          candidateEmail: effectiveUserEmail,
                          recruiterId: job.recruiterId,
                          recruiterEmail: job.recruiterEmail,
                          cvSource: 'pdf',
                          cvTitle: finalCvTitle,
                          cvContent: finalCvContent,
                          candidateNotes: notesCtrl.text.trim(),
                          status: 'in_review',
                          employerResponse: '',
                          meetLink: '',
                          interviewDate: '',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        try {
                          await _firestoreService.submitOneClickApplication(
                            job: job,
                            candidateId: effectiveUserId,
                            candidateName: effectiveUserName,
                            candidateEmail: effectiveUserEmail,
                            cvSource: 'pdf',
                            cvTitle: newApp.cvTitle,
                            cvContent: newApp.cvContent,
                            candidateNotes: newApp.candidateNotes,
                          );
                        } catch (e) {
                          debugPrint('Firestore submit application note: $e');
                        }

                        setState(() => _applications.insert(0, newApp));
                        if (ctx.mounted) Navigator.pop(ctx);
                        _emitPushBanner(
                          'Candidatura Inviata 🚀',
                          'Hai applicato a "${job.title}" con il tuo CV PDF (Firestore Sincronizzato).',
                        );
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Conferma Candidatura 1-Click',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo_square.png',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'EasyJob',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
                color: Color(0xFF1E60ED),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isRecruiterMode) ...[
            // Selettore Rapido Città Utente nell'AppBar (solo per Candidato)
            ActionChip(
              avatar: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF1E60ED),
                size: 16,
              ),
              label: Text(
                _cloudResume.locationCity,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1E60ED),
                ),
              ),
              backgroundColor: const Color(0xFFEEF4FF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => _openCitySelectorDialog(),
            ),
            const SizedBox(width: 4),
            ActionChip(
              avatar: const Icon(
                Icons.person_rounded,
                color: Color(0xFF1E60ED),
                size: 16,
              ),
              label: const Text(
                'Candidato',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1E60ED),
                ),
              ),
              backgroundColor: const Color(0xFFEEF4FF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              tooltip: 'Tocca per passare a vista Recruiter',
              onPressed: _toggleRole,
            ),
          ] else ...[
            ActionChip(
              avatar: const Icon(
                Icons.business_center_rounded,
                color: Color(0xFF7C3AED),
                size: 16,
              ),
              label: const Text(
                'Recruiter ATS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF7C3AED),
                ),
              ),
              backgroundColor: const Color(0xFFF5F3FF),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              tooltip: 'Tocca per passare a vista Candidato',
              onPressed: _toggleRole,
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Nuovo Annuncio',
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFF7C3AED)),
              onPressed: () => _openCreateJobDialog(),
            ),
          ],
          IconButton(
            tooltip: _isFirestoreConnected ? 'Firestore OK' : 'Connessione...',
            icon: Icon(
              _isFirestoreConnected
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_queue_rounded,
              color: _isFirestoreConnected
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFirestoreConnected
                      ? 'Cloud Firestore Connesso (findmyjob-510711)'
                      : 'Connessione Firestore in corso...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Notifiche (${_pushNotificationsLog.length})',
            onPressed: () => _openNotificationsDialog(),
            icon: Badge(
              label: Text('${_pushNotificationsLog.length}'),
              child: const Icon(Icons.notifications_outlined, size: 22),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isRecruiterMode
          ? IndexedStack(
              index: _selectedIndex.clamp(0, 2),
              children: [
                _buildRecruiterAtsView(),
                _buildRecruiterJobsView(),
                _buildProfileView(),
              ],
            )
          : IndexedStack(
              index: _selectedIndex.clamp(0, 3),
              children: [
                _buildJobsFeedView(),
                _buildInteractiveMapView(),
                _buildApplicationsView(),
                _buildProfileView(),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: NavigationBar(
          selectedIndex: _isRecruiterMode
              ? _selectedIndex.clamp(0, 2)
              : _selectedIndex.clamp(0, 3),
          onDestinationSelected: (idx) {
            setState(() => _selectedIndex = idx);
            if (!_isRecruiterMode && idx == 1 && _filteredJobs.isNotEmpty) {
              // Centra la mappa sul primo lavoro
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final firstJob = _filteredJobs.first;
                _mapController.move(
                  LatLng(firstJob.latitude, firstJob.longitude),
                  11.5,
                );
              });
            }
          },
          backgroundColor: Colors.white,
          indicatorColor: _isRecruiterMode
              ? const Color(0xFFF5F3FF)
              : const Color(0xFFEEF4FF),
          destinations: _isRecruiterMode
              ? const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon:
                        Icon(Icons.dashboard_rounded, color: Color(0xFF7C3AED)),
                    label: 'Dashboard ATS',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.post_add_outlined),
                    selectedIcon:
                        Icon(Icons.post_add_rounded, color: Color(0xFF7C3AED)),
                    label: 'I Miei Annunci',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon:
                        Icon(Icons.person_rounded, color: Color(0xFF7C3AED)),
                    label: 'Profilo',
                  ),
                ]
              : const [
                  NavigationDestination(
                    icon: Icon(Icons.work_outline_rounded),
                    selectedIcon:
                        Icon(Icons.work_rounded, color: Color(0xFF1E60ED)),
                    label: 'Offerte',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon:
                        Icon(Icons.map_rounded, color: Color(0xFF1E60ED)),
                    label: 'Mappa',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment_turned_in,
                        color: Color(0xFF1E60ED)),
                    label: 'Candidature',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon:
                        Icon(Icons.person_rounded, color: Color(0xFF1E60ED)),
                    label: 'Profilo',
                  ),
                ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. SCHEDA ANNUNCI (JOB FEED)
  // ==========================================
  Widget _buildJobsFeedView() {
    final jobs = _filteredJobs;
    final categories = [
      'Tutte',
      'Mobile & Flutter',
      'Cloud & Backend',
      'Design & UX',
      'AI & Data Science',
      'Frontend & Web'
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Greeting Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E60ED), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x331E60ED),
                blurRadius: 12,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ciao, ${_cloudResume.fullName.split(' ').first} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Offerte geolocalizzate vicino a ${_cloudResume.locationCity}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _selectedIndex = 3),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: _cloudResume.photoUrl.isNotEmpty
                          ? (_cloudResume.photoUrl.startsWith('http')
                              ? NetworkImage(_cloudResume.photoUrl)
                              : FileImage(File(_cloudResume.photoUrl))
                                  as ImageProvider)
                          : null,
                      child: _cloudResume.photoUrl.isEmpty
                          ? const Icon(Icons.person, color: Color(0xFF1E60ED))
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Barra Ricerca
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
            hintText: 'Cerca ruolo, azienda o competenza...',
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Filtro Categorie (Chip orizzontali)
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSel = _selectedCategory == cat;
              return FilterChip(
                selected: isSel,
                label: Text(cat),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF1E60ED),
                showCheckmark: false,
                side: BorderSide(
                  color: isSel ? const Color(0xFF1E60ED) : const Color(0xFFCBD5E1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) => setState(() => _selectedCategory = cat),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Filtro Raggio Distanza
        Row(
          children: [
            const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF1E60ED)),
            const SizedBox(width: 6),
            Text(
              'Raggio: ${_maxDistanceKm.round()} km da ${_cloudResume.locationCity}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const Spacer(),
            Text(
              '${jobs.length} annunci',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _maxDistanceKm,
          min: 10,
          max: 800,
          divisions: 79,
          activeColor: const Color(0xFF1E60ED),
          onChanged: (v) => setState(() => _maxDistanceKm = v),
        ),

        if (jobs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nessun annuncio trovato nei filtri attuali.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aumenta il raggio km o cambia la tua città di residenza nel Profilo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

        // Lista Annunci
        ...jobs.map((job) {
          final dist =
              job.distanceFromKm(_cloudResume.userLat, _cloudResume.userLon);
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Center(
                          child: Text(
                            job.company.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E60ED),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job.company,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildBadge(
                        '📍 $dist km da te',
                        const Color(0xFFEEF4FF),
                        const Color(0xFF1E60ED),
                      ),
                      _buildBadge(
                        job.locationName,
                        const Color(0xFFF1F5F9),
                        const Color(0xFF475569),
                      ),
                      _buildBadge(
                        job.contractType,
                        const Color(0xFFF0FDF4),
                        const Color(0xFF16A34A),
                      ),
                      _buildBadge(
                        job.salaryRange,
                        const Color(0xFFFEF3C7),
                        const Color(0xFFD97706),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    job.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openOneClickApplyModal(job),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Candidati con 1 Clic'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // 2. SCHEDA MAPPA INTERATTIVA (OPENSTREETMAP)
  // ==========================================
  Widget _buildInteractiveMapView() {
    final jobs = _filteredJobs;

    return Stack(
      children: [
        // Mappa OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                LatLng(_cloudResume.userLat, _cloudResume.userLon),
            initialZoom: 10.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.findmyjob.find_my_job',
            ),
            MarkerLayer(
              markers: [
                // Marker Posizione Utente
                Marker(
                  point: LatLng(_cloudResume.userLat, _cloudResume.userLon),
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E60ED),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x661E60ED),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_pin_circle_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                // Marker Offerte di Lavoro: SOLAMENTE L'ICONA DELLA VALIGETTA
                ...jobs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final job = entry.value;
                  final isSelected = _selectedMapJobIndex == idx;

                  return Marker(
                    point: LatLng(job.latitude, job.longitude),
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMapJobIndex = idx);
                        if (_mapPageController.hasClients) {
                          _mapPageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                        _mapController.move(
                          LatLng(job.latitude, job.longitude),
                          12.0,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E60ED)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E60ED),
                            width: isSelected ? 2.5 : 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0x661E60ED)
                                  : const Color(0x33000000),
                              blurRadius: isSelected ? 12 : 6,
                              spreadRadius: isSelected ? 2 : 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.work_rounded,
                            size: isSelected ? 24 : 20,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E60ED),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Barra di Ricerca Città Europea e Geolocalizzazione GPS
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openCitySelectorDialog(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.travel_explore_rounded,
                            color: Color(0xFF1E60ED),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _cloudResume.locationCity.isNotEmpty
                                      ? _cloudResume.locationCity
                                      : 'Cerca città in Europa...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Tocca per scegliere o scrivere una città',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bottone GPS Real-Time
                          Material(
                            color: const Color(0xFF1E60ED),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _isLocatingGps ? null : _geolocateRealTime,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isLocatingGps)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.my_location_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'GPS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Pillole informative: Offerte & Centra Posizione
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.work_rounded,
                          size: 14,
                          color: Color(0xFF1E60ED),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${jobs.length} offerte nell\'area',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _mapController.move(
                        LatLng(_cloudResume.userLat, _cloudResume.userLon),
                        11.5,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.center_focus_strong_rounded,
                            size: 14,
                            color: Color(0xFF1E60ED),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Centra Mappa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E60ED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Pulsante Flottante GPS in tempo reale
        Positioned(
          bottom: jobs.isNotEmpty ? 195 : 24,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'map_gps_realtime_fab',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E60ED),
            elevation: 4,
            onPressed: _isLocatingGps ? null : _geolocateRealTime,
            child: _isLocatingGps
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 20),
          ),
        ),

        // Carosello inferiore con le card delle anteprime
        if (jobs.isNotEmpty)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            height: 175,
            child: PageView.builder(
              controller: _mapPageController,
              itemCount: jobs.length,
              onPageChanged: (idx) {
                setState(() => _selectedMapJobIndex = idx);
                final job = jobs[idx];
                _mapController.move(
                  LatLng(job.latitude, job.longitude),
                  12.5,
                );
              },
              itemBuilder: (ctx, idx) {
                final job = jobs[idx];
                final dist = job.distanceFromKm(
                    _cloudResume.userLat, _cloudResume.userLon);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: _selectedMapJobIndex == idx
                          ? const Color(0xFF1E60ED)
                          : const Color(0xFFE2E8F0),
                      width: _selectedMapJobIndex == idx ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _buildBadge(
                              '📍 $dist km',
                              const Color(0xFFEEF4FF),
                              const Color(0xFF1E60ED),
                            ),
                          ],
                        ),
                        Text(
                          '${job.company} · ${job.locationName}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _buildBadge(
                              job.salaryRange,
                              const Color(0xFFFEF3C7),
                              const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            _buildBadge(
                              job.contractType,
                              const Color(0xFFF0FDF4),
                              const Color(0xFF16A34A),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: FilledButton.icon(
                            onPressed: () => _openOneClickApplyModal(job),
                            icon: const Icon(Icons.send_rounded, size: 14),
                            label: const Text('Candidati con 1 Clic'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ==========================================
  // 3. SCHEDA CANDIDATURE & ATS
  // ==========================================
  Widget _buildApplicationsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le tue Candidature 1-Click',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Avanzamento selezione, colloqui e risposte recruiter',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Aggiorna',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _listenApplications(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_applications.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Nessuna candidatura inviata finora.\nScegli un annuncio e premi "Candidati con 1 Clic"!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), height: 1.4),
              ),
            ),
          ),
        ..._applications.map((app) {
          final isInterview = app.status == 'interview_scheduled';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.jobTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(app.status),
                    ],
                  ),
                  Text(
                    app.company,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const Divider(height: 20),
                  Text(
                    'Curriculum utilizzato: ${app.cvTitle}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                  if (app.candidateNotes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: "${app.candidateNotes}"',
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (app.employerResponse.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_chat_read_rounded,
                              size: 16, color: Color(0xFF1E60ED)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Risposta Datore: ${app.employerResponse}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isInterview) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                app.interviewType == 'remote'
                                    ? Icons.videocam_rounded
                                    : Icons.location_on_rounded,
                                color: const Color(0xFF16A34A),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Colloquio Confermato (${app.interviewType == "remote" ? "Online" : "In Presenza"})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (app.interviewDate.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '📅 Data e Ora: ${app.interviewDate}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                          if (app.interviewLocation.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              app.interviewType == 'remote'
                                  ? '🔗 Link: ${app.interviewLocation}'
                                  : '🏢 Luogo: ${app.interviewLocation}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (app.interviewType == 'remote' && app.meetLink.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => launchUrl(Uri.parse(app.meetLink)),
                          icon: const Icon(Icons.video_call_rounded),
                          label: const Text('Partecipa al Colloquio Google Meet'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D58),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // 4. SCHEDA PROFILO & CV CLOUD
  // ==========================================
  Widget _buildProfileView() {
    final TextEditingController nameCtrl =
        TextEditingController(text: _cloudResume.fullName);
    final TextEditingController phoneCtrl =
        TextEditingController(text: _cloudResume.phone);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Foto & Nome Utente
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF1E60ED),
                backgroundImage: _cloudResume.photoUrl.isNotEmpty
                    ? (_cloudResume.photoUrl.startsWith('http')
                        ? NetworkImage(_cloudResume.photoUrl)
                        : FileImage(File(_cloudResume.photoUrl))
                            as ImageProvider)
                    : null,
                child: _cloudResume.photoUrl.isEmpty
                    ? Text(
                        _cloudResume.fullName.isNotEmpty
                            ? _cloudResume.fullName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _openPhotoPickerModal(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E60ED),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                _cloudResume.fullName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                _cloudResume.email,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // CARD SWITCH RUOLO: CANDIDATO <-> RECRUITER
        Card(
          color: _isRecruiterMode ? const Color(0xFFF5F3FF) : const Color(0xFFEEF4FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isRecruiterMode ? const Color(0xFFC4B5FD) : const Color(0xFFBFDBFE),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isRecruiterMode
                              ? Icons.business_center_rounded
                              : Icons.person_pin_rounded,
                          color: _isRecruiterMode
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF1E60ED),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRecruiterMode
                              ? 'Modalità Recruiter Attiva'
                              : 'Modalità Candidato Attiva',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isRecruiterMode
                                ? const Color(0xFF6D28D9)
                                : const Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                    _buildBadge(
                      _isRecruiterMode ? 'RECRUITER' : 'CANDIDATO',
                      _isRecruiterMode
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF1E60ED),
                      Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecruiterMode
                      ? 'In questa vista accedi al gestionale ATS, statistiche candidati, convocazione colloqui e pubblicazione nuovi annunci.'
                      : 'In questa vista cerchi offerte, consulti la mappa interattiva con card anteprima e ti candidi con 1 clic.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _isRecruiterMode
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF1E60ED),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _toggleRole,
                    icon: Icon(_isRecruiterMode
                        ? Icons.person_search_rounded
                        : Icons.business_center_rounded),
                    label: Text(
                      _isRecruiterMode
                          ? 'Passa a Vista Candidato'
                          : 'Passa a Vista Recruiter (Gestionale ATS)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_currentUser == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E60ED), Color(0xFF0F3BBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E60ED).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sincronizza con Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Accedi con il tuo account Google per sincronizzare il profilo e le candidature in Cloud Firestore.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.login_rounded, color: Color(0xFF1E60ED)),
                    label: const Text(
                      'Accedi con Google',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // SEZIONE 1: Dati Personali e Geografici
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: Color(0xFF1E60ED)),
                    SizedBox(width: 8),
                    Text(
                      'Dati Personali & Residenza',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Data di Nascita
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome e Cognome *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                // Data di Nascita
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.cake_rounded, color: Color(0xFF1E60ED)),
                  title: const Text('Data di Nascita',
                      style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    _cloudResume.birthDate,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => _pickBirthDate(),
                    child: const Text('Modifica'),
                  ),
                ),
                const SizedBox(height: 8),
                // Luogo di Residenza
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_city_rounded,
                      color: Color(0xFF1E60ED)),
                  title: const Text(
                      'Città di Residenza / Ricerca (Tutta Europa)',
                      style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '${_cloudResume.locationCity} (Lat: ${_cloudResume.userLat.toStringAsFixed(2)}, Lon: ${_cloudResume.userLon.toStringAsFixed(2)})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E60ED),
                    ),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => _openCitySelectorDialog(),
                    child: const Text('Cerca Città'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Numero di Telefono',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // SEZIONE 2: Curriculum Vitae in Formato PDF
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _cloudResume.cvPdfName.isNotEmpty
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFDC2626),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Curriculum Vitae (PDF)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Carica il tuo file PDF per le candidature',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_cloudResume.cvPdfName.isNotEmpty)
                      _buildBadge(
                        'PDF ATTIVO',
                        const Color(0xFFDCFCE7),
                        const Color(0xFF16A34A),
                      ),
                  ],
                ),
                const Divider(height: 24),
                if (_cloudResume.cvPdfName.isNotEmpty) ...[
                  // Box del file PDF attualmente caricato
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFFDC2626),
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cloudResume.cvPdfName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_cloudResume.cvPdfSize.isNotEmpty ? _cloudResume.cvPdfSize : "File PDF"} • Allegato a tutte le candidature',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626)),
                          tooltip: 'Rimuovi CV',
                          onPressed: _removePdfResume,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _pickAndUploadPdfResume,
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: const Text('Sostituisci PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _openPdfPreviewModal(
                              fileName: _cloudResume.cvPdfName,
                              base64Data: _cloudResume.cvPdfBase64,
                              filePath: _cloudResume.cvPdfPath,
                            );
                          },
                          icon: const Icon(Icons.visibility_rounded, size: 18),
                          label: const Text('Visualizza CV'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Box Nessun CV caricato
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: Color(0xFFDC2626),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Nessun Curriculum PDF Caricato',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Carica il tuo file PDF per candidarti alle offerte con 1 Clic',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E60ED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _pickAndUploadPdfResume,
                          icon: const Icon(Icons.attach_file_rounded),
                          label: const Text(
                            'Carica CV in formato PDF',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Pulsante di Salvataggio Dati Profilo
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () async {
              final updated = _cloudResume.copyWith(
                fullName: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                updatedAt: DateTime.now(),
              );

              setState(() => _cloudResume = updated);
              await _firestoreService.saveCloudResume(updated);

              _emitPushBanner(
                'Profilo Salvato',
                'Dati personali sincronizzati con successo su Firestore.',
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text(
              'Salva Dati Profilo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              await _authService.signOut();
              setState(() {
                _currentUser = null;
                _isDemoLoggedIn = false;
              });
              _emitPushBanner('Sessione terminata', 'Disconnessione completata.');
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Disconnetti Account',
                style: TextStyle(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Caricamento CV PDF dal File System con persistenza Firestore
  Future<void> _pickAndUploadPdfResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final String fileName = file.name;
        final String filePath = file.path ?? '';
        final int fileSizeBytes = file.size;
        final String sizeStr = fileSizeBytes > 1024 * 1024
            ? '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';

        String base64Str = '';
        if (file.bytes != null) {
          base64Str = base64Encode(file.bytes!);
        } else if (filePath.isNotEmpty) {
          final bytes = await File(filePath).readAsBytes();
          base64Str = base64Encode(bytes);
        }

        final updatedResume = _cloudResume.copyWith(
          cvPdfName: fileName,
          cvPdfPath: filePath,
          cvPdfBase64: base64Str,
          cvPdfSize: sizeStr,
          updatedAt: DateTime.now(),
        );

        setState(() {
          _cloudResume = updatedResume;
        });

        // Sincronizza su Firestore se la connessione è attiva
        await _firestoreService.saveCloudResume(updatedResume);

        if (mounted) {
          _emitPushBanner(
            'Curriculum PDF Caricato 📄',
            '$fileName ($sizeStr) è pronto ed attivo per tutte le tue candidature!',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PDF "$fileName" caricato con successo!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossibile selezionare il file PDF: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  /// Rimozione del CV PDF dal Profilo
  Future<void> _removePdfResume() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovere il CV PDF?'),
        content: const Text(
          'Sei sicuro di voler rimuovere il curriculum PDF caricato?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedResume = _cloudResume.copyWith(
        cvPdfName: '',
        cvPdfPath: '',
        cvPdfBase64: '',
        cvPdfSize: '',
        updatedAt: DateTime.now(),
      );
      setState(() {
        _cloudResume = updatedResume;
      });
      await _firestoreService.saveCloudResume(updatedResume);
      _emitPushBanner('CV Rimosso', 'Il tuo curriculum PDF è stato rimosso.');
    }
  }

  /// Anteprima Documento CV PDF
  void _openPdfPreviewModal({
    required String fileName,
    required String base64Data,
    required String filePath,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFFDC2626), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anteprima Documento PDF',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          fileName.isNotEmpty ? fileName : 'Curriculum.pdf',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded,
                      color: Color(0xFFDC2626), size: 54),
                  const SizedBox(height: 12),
                  Text(
                    fileName.isNotEmpty ? fileName : 'Curriculum_Vitae.pdf',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Documento CV formattato in standard PDF.\nPronto per essere esaminato dai recruiter ATS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E60ED),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _emitPushBanner(
                    'Documento PDF',
                    'File $fileName verificato con successo.',
                  );
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Chiudi Anteprima',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modale Selezione / Modifica Foto Profilo
  Future<void> _openPhotoPickerModal() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Foto Profilo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFF1E60ED)),
              title: const Text('Scegli immagine dal dispositivo'),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (res != null && res.files.single.path != null) {
                  final path = res.files.single.path!;
                  setState(() {
                    _cloudResume = _cloudResume.copyWith(photoUrl: path);
                  });
                  await _firestoreService.saveCloudResume(_cloudResume);
                  _emitPushBanner('Foto Profilo', 'Immagine aggiornata dal dispositivo.');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_pin_rounded,
                  color: Color(0xFF10B981)),
              title: const Text('Usa Avatar Professionale preimpostato'),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() {
                  _cloudResume = _cloudResume.copyWith(
                    photoUrl:
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
                  );
                });
                await _firestoreService.saveCloudResume(_cloudResume);
                _emitPushBanner('Avatar Aggiornato', 'Avatar professionale applicato.');
              },
            ),
            if (_cloudResume.photoUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Rimuovi foto profilo',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() {
                    _cloudResume = _cloudResume.copyWith(photoUrl: '');
                  });
                  await _firestoreService.saveCloudResume(_cloudResume);
                  _emitPushBanner('Foto Rimossa', 'Ripristinato avatar iniziale.');
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GEOLOCALIZZAZIONE GPS IN TEMPO REALE
  // ==========================================
  Future<void> _geolocateRealTime() async {
    setState(() => _isLocatingGps = true);
    _emitPushBanner(
      'Geolocalizzazione GPS 🛰️',
      'Rilevamento coordinate in tempo reale dal dispositivo...',
    );

    try {
      final pos = await EuropeanLocationsService.getCurrentRealTimeLocation();
      if (!mounted) return;

      if (pos != null) {
        setState(() {
          _isLocatingGps = false;
          _cloudResume = _cloudResume.copyWith(
            userLat: pos.latitude,
            userLon: pos.longitude,
            locationCity: 'GPS Real-Time',
          );
        });

        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          13.0,
        );

        await _firestoreService.saveCloudResume(_cloudResume);

        _emitPushBanner(
          'Posizione Rilevata 🛰️',
          'GPS attivo (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}). Mappa e offerte allineate alla tua posizione reale!',
        );
      } else {
        setState(() => _isLocatingGps = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossibile rilevare la posizione GPS. Assicurati che i servizi di localizzazione e i permessi siano abilitati.',
              ),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  // ==========================================
  // AUTOCOMPILAZIONE CITTÀ IN TUTTA EUROPA
  // ==========================================
  Future<void> _openCitySelectorDialog({void Function(EuropeanCity)? onCityChosen}) async {
    final searchCtrl = TextEditingController();
    List<EuropeanCity> results =
        EuropeanLocationsService.kCuratedEuropeanCities.take(25).toList();
    bool isSearching = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void doSearch(String query) async {
            setModalState(() => isSearching = true);
            final res = await EuropeanLocationsService.searchEuropeanCities(query);
            if (ctx.mounted) {
              setModalState(() {
                results = res;
                isSearching = false;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.travel_explore_rounded,
                              color: Color(0xFF1E60ED), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Città in Tutta Europa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cerca qualsiasi comune, capitale o città europea con autocompilazione istantanea:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),

                  // Tasto Rapido Posizione GPS Real-Time
                  Card(
                    color: const Color(0xFFEEF4FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: _isLocatingGps
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.my_location_rounded,
                              color: Color(0xFF1E60ED)),
                      title: const Text(
                        'Usa la mia Posizione GPS in Tempo Reale',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const Text(
                        'Geolocalizzazione live con coordinate GPS del telefono',
                        style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _geolocateRealTime();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Barra di Ricerca ed Autocompletamento
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Scrivi una città europea...',
                      hintText:
                          'Es. Milano, Roma, Berlino, Parigi, Londra, Madrid...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF1E60ED)),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                searchCtrl.clear();
                                doSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) => doSearch(val),
                  ),
                  const SizedBox(height: 8),

                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),

                  // Risultati Autocompletamento
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Nessuna città trovata. Digita il nome della città (es. Amsterdam, Monaco, Lisbona, Varsavia...)',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final city = results[i];
                              final isCurrent =
                                  _cloudResume.locationCity == city.name;

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    city.countryCode.isNotEmpty
                                        ? city.countryCode
                                        : 'EU',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  city.name,
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isCurrent
                                        ? const Color(0xFF1E60ED)
                                        : const Color(0xFF0F172A),
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${city.country} • Lat: ${city.latitude.toStringAsFixed(2)}, Lon: ${city.longitude.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                trailing: isCurrent
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF1E60ED), size: 20)
                                    : const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12,
                                        color: Color(0xFFCBD5E1)),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  if (onCityChosen != null) {
                                    onCityChosen(city);
                                    return;
                                  }

                                  setState(() {
                                    _cloudResume = _cloudResume.copyWith(
                                      locationCity: city.name,
                                      userLat: city.latitude,
                                      userLon: city.longitude,
                                    );
                                  });

                                  _mapController.move(
                                    LatLng(city.latitude, city.longitude),
                                    11.5,
                                  );

                                  await _firestoreService
                                      .saveCloudResume(_cloudResume);

                                  _emitPushBanner(
                                    'Città Aggiornata 📍',
                                    'Nuovo centro: ${city.displayName}. Offerte e mappa orientate su questa sede!',
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DatePicker per Data di Nascita
  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1996, 6, 15),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final dateStr =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _cloudResume = _cloudResume.copyWith(birthDate: dateStr);
      });
      await _firestoreService.saveCloudResume(_cloudResume);
      _emitPushBanner('Data di Nascita', 'Aggiornata a $dateStr.');
    }
  }

  // Dialog Notifiche
  void _openNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF1E60ED)),
            SizedBox(width: 8),
            Text('Centro Notifiche'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _pushNotificationsLog.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(_pushNotificationsLog[i],
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VISTE RECRUITER ATS & GESTIONE ANNUNCI
  // ==========================================

  /// Vista 1 Recruiter: Dashboard ATS, Statistiche & Candidati
  Widget _buildRecruiterAtsView() {
    final total = _applications.length;
    final inReview =
        _applications.where((a) => a.status == 'in_review').length;
    final scheduled =
        _applications.where((a) => a.status == 'interview_scheduled').length;
    final accepted =
        _applications.where((a) => a.status == 'accepted').length;
    final rejected =
        _applications.where((a) => a.status == 'rejected').length;

    List<JobApplication> filteredApps = _applications;
    if (_recruiterStatusFilter != 'Tutte') {
      filteredApps = _applications
          .where((a) => a.status == _recruiterStatusFilter)
          .toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header ATS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Recruiter ATS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Gestione candidati, colloqui ed esiti in tempo reale',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openCreateJobDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuovo Annuncio'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Statistiche KPI Card Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildKpiCard('Candidature', '$total', Icons.groups_rounded,
                  const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
              const SizedBox(width: 8),
              _buildKpiCard('In Revisione', '$inReview',
                  Icons.hourglass_top_rounded, const Color(0xFFF59E0B),
                  const Color(0xFFFFFBEB)),
              const SizedBox(width: 8),
              _buildKpiCard('Colloqui', '$scheduled',
                  Icons.event_available_rounded, const Color(0xFF1E60ED),
                  const Color(0xFFEFF6FF)),
              const SizedBox(width: 8),
              _buildKpiCard('Assunti', '$accepted', Icons.verified_rounded,
                  const Color(0xFF10B981), const Color(0xFFECFDF5)),
              const SizedBox(width: 8),
              _buildKpiCard('Non Idonei', '$rejected', Icons.cancel_outlined,
                  const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filtri per Stato Candidatura
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChoiceChip('Tutte', 'Tutte ($total)'),
              const SizedBox(width: 6),
              _buildFilterChoiceChip('in_review', 'In Revisione ($inReview)'),
              const SizedBox(width: 6),
              _buildFilterChoiceChip(
                  'interview_scheduled', 'Colloqui ($scheduled)'),
              const SizedBox(width: 6),
              _buildFilterChoiceChip('accepted', 'Assunti ($accepted)'),
              const SizedBox(width: 6),
              _buildFilterChoiceChip('rejected', 'Non Idonei ($rejected)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filteredApps.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Nessuna candidatura presente con il filtro selezionato.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ...filteredApps.map((app) => _buildCandidateAtsCard(app)),
      ],
    );
  }

  Widget _buildCandidateAtsCard(JobApplication app) {
    final isInterview = app.status == 'interview_scheduled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF7C3AED),
                  child: Text(
                    app.candidateName.isNotEmpty
                        ? app.candidateName.substring(0, 1).toUpperCase()
                        : 'C',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.candidateName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${app.candidateEmail} · Candidato per: ${app.jobTitle}',
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(app.status),
              ],
            ),
            const Divider(height: 20),

            // Dettagli CV & Note
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'CV: ${app.cvTitle}',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
                TextButton(
                  onPressed: () => _openCandidateCvDetailSheet(app),
                  child: const Text('Vedi Dettagli CV'),
                ),
              ],
            ),

            if (app.candidateNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nota Candidato: "${app.candidateNotes}"',
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            // Se il colloquio è fissato, mostra il box di riepilogo
            if (isInterview) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          app.interviewType == 'remote'
                              ? Icons.videocam_rounded
                              : Icons.business_rounded,
                          color: const Color(0xFF1E60ED),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Colloquio Fissato (${app.interviewType == "remote" ? "Da Remoto" : "Di Persona"})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (app.interviewDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📅 Data: ${app.interviewDate}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (app.interviewLocation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        app.interviewType == 'remote'
                            ? '🔗 Link Google Meet: ${app.interviewLocation}'
                            : '🏢 Luogo: ${app.interviewLocation}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Pulsanti di Azione Recruiter
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _openInterviewSchedulingDialog(app),
                  icon: const Icon(Icons.event_available_rounded, size: 16),
                  label: Text(
                      isInterview ? 'Modifica Colloquio' : 'Accetta & Fissa Colloquio'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () async {
                    await _firestoreService.respondToCandidateApplication(
                      application: app,
                      decision: 'accepted',
                      employerResponse:
                          'Gentile ${app.candidateName}, la tua candidatura è stata accettata! Benvenuto nel nostro team.',
                      oauthAccessToken: _authService.accessToken,
                    );
                    _emitPushBanner(
                      'Candidato Assunto',
                      'Hai accettato la candidatura di ${app.candidateName} per ${app.jobTitle}.',
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Assumi'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () async {
                    await _firestoreService.respondToCandidateApplication(
                      application: app,
                      decision: 'rejected',
                      employerResponse:
                          'Gentile ${app.candidateName}, ti ringraziamo per l\'interesse dimostrato, ma abbiamo optato per altri profili.',
                      oauthAccessToken: _authService.accessToken,
                    );
                    _emitPushBanner(
                      'Esito Inviato',
                      'Candidatura di ${app.candidateName} scartata con invio mail.',
                    );
                  },
                  icon: const Icon(Icons.highlight_off_rounded, size: 16),
                  label: const Text('Scarta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Vista 2 Recruiter: Gestione Annunci di Lavoro & Creazione Nuovi Annunci
  Widget _buildRecruiterJobsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestione Annunci Aziendali',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_jobs.length} annunci pubblicati su Mappa e Feed',
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
              onPressed: () => _openCreateJobDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crea Annuncio'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._jobs.map((job) {
          final applicantsCount =
              _applications.where((a) => a.jobId == job.id).length;
          final isOpen = job.status == 'open';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${job.company} · ${job.locationName}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildBadge(
                        isOpen ? 'Attivo' : 'Chiuso',
                        isOpen
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        isOpen
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChipTag(job.category, Icons.category_outlined),
                      _buildChipTag(job.contractType, Icons.schedule_outlined),
                      _buildChipTag(job.salaryRange, Icons.euro_rounded),
                      _buildChipTag(
                        '$applicantsCount Candidature',
                        Icons.people_outline_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coordinate: ${job.latitude.toStringAsFixed(3)}, ${job.longitude.toStringAsFixed(3)}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final updated = JobOffer(
                            id: job.id,
                            title: job.title,
                            company: job.company,
                            locationName: job.locationName,
                            latitude: job.latitude,
                            longitude: job.longitude,
                            salaryRange: job.salaryRange,
                            contractType: job.contractType,
                            category: job.category,
                            description: job.description,
                            requirements: job.requirements,
                            recruiterId: job.recruiterId,
                            recruiterName: job.recruiterName,
                            recruiterEmail: job.recruiterEmail,
                            status: isOpen ? 'closed' : 'open',
                            createdAt: job.createdAt,
                            updatedAt: DateTime.now(),
                          );
                          setState(() {
                            final idx =
                                _jobs.indexWhere((j) => j.id == job.id);
                            if (idx != -1) _jobs[idx] = updated;
                          });
                          _firestoreService.publishNewJobOffer(
                            job: updated,
                            senderUid: effectiveUserId,
                          );
                          _emitPushBanner(
                            'Stato Annuncio',
                            'L\'annuncio "${job.title}" è ora ${isOpen ? "chiuso" : "riaperto"}.',
                          );
                        },
                        icon: Icon(
                          isOpen
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 16,
                        ),
                        label: Text(isOpen
                            ? 'Metti in pausa'
                            : 'Riapri annuncio'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Dialog Convocazione Colloquio Recruiter (Google Meet o Sede Fisica + Email Automatica)
  Future<void> _openInterviewSchedulingDialog(JobApplication app) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    TimeOfDay selectedTime = const TimeOfDay(hour: 15, minute: 30);
    String interviewType = 'remote'; // 'remote' or 'in_person'
    final TextEditingController locationCtrl = TextEditingController(
      text: 'Sede EasyJob, Via Montenapoleone 8, Milano — Piano 3',
    );
    final TextEditingController messageCtrl = TextEditingController(
      text:
          'Gentile ${app.candidateName}, siamo rimasti molto colpiti dalla tua candidatura per ${app.jobTitle} e desideriamo invitarti a un colloquio conoscitivo.',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dateStr =
              '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
          final timeStr =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF7C3AED),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Convocazione a Colloquio',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Candidato: ${app.candidateName} (${app.candidateEmail})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Data e Ora del Colloquio',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(dateStr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(timeStr),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. Modalità del Colloquio',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'remote',
                        label: Text('Da Remoto (Google Meet)'),
                        icon: Icon(Icons.videocam_rounded),
                      ),
                      ButtonSegment(
                        value: 'in_person',
                        label: Text('Di Persona (Luogo Fisico)'),
                        icon: Icon(Icons.business_rounded),
                      ),
                    ],
                    selected: {interviewType},
                    onSelectionChanged: (val) {
                      setModalState(() => interviewType = val.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (interviewType == 'remote')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.link_rounded, color: Color(0xFF1E60ED)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Verrà generato automaticamente un link protetto di Google Meet e inviato via email al candidato.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF1E40AF)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Indirizzo o Sede del Colloquio *',
                        hintText:
                            'Es. Sede EasyJob, Via Montenapoleone 8, Milano — Piano 3',
                        prefixIcon: Icon(Icons.place_rounded),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    '3. Messaggio per il Candidato',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Inserisci le note o indicazioni per il colloquio...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verrà inviata una notifica email automatica a ${app.candidateEmail} con data, ora e luogo.',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final String finalDate = '$dateStr alle $timeStr';
                        final String finalLoc = interviewType == 'remote'
                            ? ''
                            : locationCtrl.text.trim();

                        final locationResult =
                            await _firestoreService.scheduleInterview(
                          application: app,
                          interviewDate: finalDate,
                          interviewType: interviewType,
                          locationOrMeet: finalLoc,
                          customMessage: messageCtrl.text.trim(),
                          oauthAccessToken: _authService.accessToken,
                        );

                        _emitPushBanner(
                          'Colloquio Fissato',
                          'Convocazione inviata a ${app.candidateEmail} per $finalDate ($locationResult).',
                        );
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Invia Convocazione & Email Automatica',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Dialog Creazione Nuovo Annuncio di Lavoro per Recruiter
  Future<void> _openCreateJobDialog() async {
    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController(
      text: _cloudResume.fullName.isNotEmpty
          ? '${_cloudResume.fullName} Srl'
          : 'EasyJob Tech Hub',
    );
    final salaryCtrl = TextEditingController(text: '€45.000 - €60.000');
    final descCtrl = TextEditingController(
      text:
          'Ricerchiamo una figura motivata con spiccata competenza tecnica per inserirsi in un contesto dinamico e in rapida crescita.',
    );
    final reqCtrl = TextEditingController(
      text: 'Flutter, Dart, Cloud Firestore, REST APIs, Git',
    );
    CityLocation selectedCity = kItalianCities.first;
    String selectedCategory = 'Mobile & Flutter';
    String selectedContract = 'Full-time';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_business_rounded,
                            color: Color(0xFF7C3AED)),
                        SizedBox(width: 8),
                        Text(
                          'Crea Nuovo Annuncio',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titolo Posizione *',
                    hintText: 'Es. Senior Flutter Mobile Engineer',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome Azienda *',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                // Selettore Città con Coordinate
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Città / Sede Annuncio *',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            Text(
                              '${selectedCity.name} (${selectedCity.region})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _openCitySelectorDialog(
                            onCityChosen: (euroCity) {
                              setDialogState(() {
                                selectedCity = euroCity.toCityLocation();
                              });
                            },
                          );
                        },
                        child: const Text('Cerca in Europa'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Categoria
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    'Mobile & Flutter',
                    'Cloud & Backend',
                    'AI & Data Science',
                    'Design & UI/UX',
                    'Frontend & Web',
                  ]
                      .map((cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: salaryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'RAL / Compenso',
                          hintText: '€40.000 - €55.000',
                          prefixIcon: Icon(Icons.euro_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedContract,
                        decoration: const InputDecoration(
                          labelText: 'Contratto',
                          prefixIcon: Icon(Icons.schedule_outlined),
                        ),
                        items: ['Full-time', 'Ibrido', 'Remoto', 'Part-time']
                            .map((ct) =>
                                DropdownMenuItem(value: ct, child: Text(ct)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedContract = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione dell\'Annuncio *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reqCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Competenze & Requisiti richiesti',
                    hintText: 'Flutter, Git, REST API...',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Inserisci il titolo dell\'annuncio')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      final newJob = JobOffer(
                        id: 'job-${DateTime.now().millisecondsSinceEpoch}',
                        title: titleCtrl.text.trim(),
                        company: companyCtrl.text.trim(),
                        locationName: selectedCity.name,
                        latitude: selectedCity.latitude,
                        longitude: selectedCity.longitude,
                        salaryRange: salaryCtrl.text.trim(),
                        contractType: selectedContract,
                        category: selectedCategory,
                        description: descCtrl.text.trim(),
                        requirements: reqCtrl.text.trim(),
                        recruiterId: effectiveUserId,
                        recruiterName: _cloudResume.fullName.isNotEmpty
                            ? _cloudResume.fullName
                            : 'Recruiter EasyJob',
                        recruiterEmail: _cloudResume.email.isNotEmpty
                            ? _cloudResume.email
                            : 'recruiter@easyjob.it',
                        status: 'open',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      setState(() {
                        _jobs.insert(0, newJob);
                      });

                      await _firestoreService.publishNewJobOffer(
                        job: newJob,
                        senderUid: effectiveUserId,
                      );

                      _emitPushBanner(
                        'Annuncio Pubblicato',
                        '"${newJob.title}" è ora visibile a tutti i candidati su Feed e Mappa!',
                      );
                    },
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: const Text(
                      'Pubblica Annuncio su Cloud Firestore',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Scheda Dettaglio CV del Candidato
  void _openCandidateCvDetailSheet(JobApplication app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFFDC2626), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CV: ${app.candidateName}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          app.candidateEmail,
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              'Posizione richiesta: ${app.jobTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded,
                      color: Color(0xFFDC2626), size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.cvTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Documento PDF ufficiale del candidato',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                ),
                onPressed: () {
                  _openPdfPreviewModal(
                    fileName: app.cvTitle,
                    base64Data: app.cvContent,
                    filePath: '',
                  );
                },
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Visualizza Documento PDF'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openInterviewSchedulingDialog(app);
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text(
                  'Fissa Colloquio con questo Candidato',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COMPONENTI UI ACCESSORI
  // ==========================================

  Widget _buildKpiCard(
      String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChoiceChip(String statusKey, String label) {
    final isSelected = _recruiterStatusFilter == statusKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: const Color(0xFF7C3AED),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _recruiterStatusFilter = statusKey);
        }
      },
    );
  }

  Widget _buildChipTag(String label, IconData icon, {Color? color}) {
    final c = color ?? const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFFEF3C7);
    Color text = const Color(0xFFD97706);
    String label = 'In revisione';

    if (status == 'interview_scheduled') {
      bg = const Color(0xFFEEF4FF);
      text = const Color(0xFF1E60ED);
      label = 'Colloquio Fissato 📅';
    } else if (status == 'accepted') {
      bg = const Color(0xFFF0FDF4);
      text = const Color(0xFF16A34A);
      label = 'Assunto 🎉';
    } else if (status == 'rejected') {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFDC2626);
      label = 'Non idoneo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
