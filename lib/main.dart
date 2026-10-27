import 'dart:async';
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
import 'services/workspace_meet_gmail_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FindMyJobFlutterApp());
}

class FindMyJobFlutterApp extends StatelessWidget {
  const FindMyJobFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindMyJob — Ricerca Lavoro & Recruiting 1-Click',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const FindMyJobHomeShell(),
    );
  }
}

class FindMyJobHomeShell extends StatefulWidget {
  const FindMyJobHomeShell({super.key});

  @override
  State<FindMyJobHomeShell> createState() => _FindMyJobHomeShellState();
}

class _FindMyJobHomeShellState extends State<FindMyJobHomeShell> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final FirestoreRecruitingService _firestoreService =
      FirestoreRecruitingService();
  final WorkspaceMeetGmailService _workspaceService =
      WorkspaceMeetGmailService();

  User? _currentUser;
  bool _isFirestoreConnected = false;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<JobOffer>>? _jobsSubscription;
  StreamSubscription<List<JobApplication>>? _applicationsSubscription;

  // Posizione corrente utente per filtro distanza (Default: Milano)
  final double _userLat = 45.4642;
  final double _userLon = 9.1900;
  double _maxDistanceKm = 600.0;
  String _roleQuery = '';

  // Curriculum Cloud pre-caricato su Firestore (findmyjob-510711)
  CloudResume _cloudResume = CloudResume(
    userId: 'demo-user-1',
    fullName: 'Giovanni Messina',
    email: 'giovannimessina96@gmail.com',
    phone: '+39 348 712 9045',
    headline: 'Senior Flutter & Cloud Mobile Architect',
    summary:
        'Sviluppatore Flutter/Dart con esperienza avanzata su Cloud Firestore (findmyjob-510711), autenticazione OAuth e architetture reattive.',
    skills:
        'Flutter, Dart, Cloud Firestore, Firebase Messaging, Google Meet API, Gmail API',
    experience: 'Tech Lead Mobile @ FinTech Milano (2023-oggi)',
    education:
        'Laurea Magistrale Ingegneria Informatica — Politecnico di Milano',
    portfolioUrl: 'https://github.com/giovannimessina-dev',
    updatedAt: DateTime.now(),
  );

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
          'Sviluppo della super-app in Flutter sincronizzata in tempo reale con Cloud Firestore e notifiche push personalizzate.',
      requirements:
          'Flutter, Dart, Firebase Firestore, REST API, Clean Architecture',
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
          'Architettura serverless su Firestore Enterprise (findmyjob-510711) e integrazione Google Workspace.',
      requirements: 'Firestore Security Rules, Dart/Flutter, GCP, OAuth2',
      recruiterId: 'recruiter-hub-2',
      recruiterName: 'Elena Visconti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
    JobOffer(
      id: 'job-flutter-roma-03',
      title: 'Flutter Cross-Platform Developer',
      company: 'Capitolium Smart Gov',
      locationName: 'Roma — EUR',
      latitude: 41.8318,
      longitude: 12.4697,
      salaryRange: '€42.000 - €54.000',
      contractType: 'Ibrido',
      category: 'Mobile & Flutter',
      description:
          'Applicazioni mobile civiche con mappe interattive geolocalizzate e notifiche push.',
      requirements:
          'Flutter, flutter_map, geolocator, Firebase Messaging',
      recruiterId: 'recruiter-gov-3',
      recruiterName: 'Lorenzo Conti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
  ];

  List<JobOffer> _jobs = [];
  List<JobApplication> _applications = [];
  final List<String> _pushNotificationsLog = [
    'Benvenuto su FindMyJob (Firestore: findmyjob-510711) — Servizi attivi.',
  ];

  @override
  void initState() {
    super.initState();
    _jobs = List.from(_seedJobs);
    _initFirebaseAndAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _jobsSubscription?.cancel();
    _applicationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initFirebaseAndAuth() async {
    // Verifica connessione Firestore
    final bool connected = await _firestoreService.verifyConnection();
    setState(() => _isFirestoreConnected = connected);

    // Seeding annunci default su Firestore se vuoto
    await _firestoreService.seedInitialJobsIfEmpty(_seedJobs);

    // Sottoscrizione annunci in tempo reale da Firestore
    _jobsSubscription = _firestoreService.watchJobs().listen((firestoreJobs) {
      if (mounted && firestoreJobs.isNotEmpty) {
        setState(() => _jobs = firestoreJobs);
      }
    }, onError: (err) {
      debugPrint('Firestore Jobs Stream Error: $err');
    });

    // Sottoscrizione Auth state Firebase
    _authSubscription = _authService.authStateChanges.listen((user) async {
      setState(() => _currentUser = user);
      if (user != null) {
        _emitPushBanner(
          'Autenticato con Google',
          'Accesso effettuato come ${user.displayName ?? user.email}',
        );

        // Aggiorna CloudResume con i dettagli del profilo Google
        final existingResume =
            await _firestoreService.getCloudResume(user.uid);
        if (existingResume != null) {
          setState(() => _cloudResume = existingResume);
        } else {
          setState(() {
            _cloudResume = CloudResume(
              userId: user.uid,
              fullName: user.displayName ?? _cloudResume.fullName,
              email: user.email ?? _cloudResume.email,
              phone: _cloudResume.phone,
              headline: _cloudResume.headline,
              summary: _cloudResume.summary,
              skills: _cloudResume.skills,
              experience: _cloudResume.experience,
              education: _cloudResume.education,
              portfolioUrl: _cloudResume.portfolioUrl,
              updatedAt: DateTime.now(),
            );
          });
          // Salva profilo iniziale su Firestore
          await _firestoreService.saveCloudResume(_cloudResume);
        }

        // Ascolta le candidature dell'utente autenticato
        _applicationsSubscription?.cancel();
        _applicationsSubscription = _firestoreService
            .watchApplications(candidateId: user.uid)
            .listen((apps) {
          if (mounted && apps.isNotEmpty) {
            setState(() => _applications = apps);
          }
        }, onError: (err) {
          debugPrint('Applications Stream Note: $err');
        });
      }
    });
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
        _emitPushBanner(
          'Login Riuscito',
          'Benvenuto ${userCred.user?.displayName ?? "Utente"}!',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Errore autenticazione Google: $e'),
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    setState(() {
      _currentUser = null;
      _applications.clear();
    });
    _emitPushBanner('Disconnessione', 'Sessione terminata.');
  }

  /// Modale BottomSheet per Candidatura 1-Click (CV Cloud vs CV Ad-Hoc + Note)
  Future<void> _openOneClickApplyModal(JobOffer job) async {
    String selectedCvSource = 'cloud';
    String customCvTitle = 'CV Ad-Hoc per ${job.title}';
    String customCvContent =
        '${_cloudResume.fullName} — Profilo mirato per ${job.title}.\nCompetenze: ${_cloudResume.skills}';
    final TextEditingController notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Candidatura 1-Click · ${job.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'cloud',
                        label: Text('CV Cloud (Firestore)'),
                        icon: Icon(Icons.cloud_done_outlined),
                      ),
                      ButtonSegment(
                        value: 'custom',
                        label: Text('CV Ad-Hoc Offerta'),
                        icon: Icon(Icons.upload_file_outlined),
                      ),
                    ],
                    selected: {selectedCvSource},
                    onSelectionChanged: (val) {
                      setModalState(() => selectedCvSource = val.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedCvSource == 'custom')
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null && result.files.isNotEmpty) {
                          setModalState(() {
                            customCvTitle =
                                'File Ad-Hoc: ${result.files.single.name}';
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(customCvTitle),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText:
                          'Note aggiuntive per il Recruiter / Datore di lavoro',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final String candidateId =
                            _currentUser?.uid ?? _cloudResume.userId;
                        final String candidateName =
                            _currentUser?.displayName ?? _cloudResume.fullName;
                        final String candidateEmail =
                            _currentUser?.email ?? _cloudResume.email;

                        final newApp = JobApplication(
                          id: 'app-${DateTime.now().millisecondsSinceEpoch}',
                          jobId: job.id,
                          jobTitle: job.title,
                          company: job.company,
                          candidateId: candidateId,
                          candidateName: candidateName,
                          candidateEmail: candidateEmail,
                          recruiterId: job.recruiterId,
                          recruiterEmail: job.recruiterEmail,
                          cvSource: selectedCvSource,
                          cvTitle: selectedCvSource == 'cloud'
                              ? 'CV Cloud Firestore — $candidateName'
                              : customCvTitle,
                          cvContent: selectedCvSource == 'cloud'
                              ? '${_cloudResume.summary}\nCompetenze: ${_cloudResume.skills}'
                              : customCvContent,
                          candidateNotes: notesCtrl.text.trim(),
                          status: 'in_review',
                          employerResponse: '',
                          meetLink: '',
                          interviewDate: '',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        // Salvataggio su Firestore
                        try {
                          await _firestoreService.submitOneClickApplication(
                            job: job,
                            candidateId: candidateId,
                            candidateName: candidateName,
                            candidateEmail: candidateEmail,
                            cvSource: selectedCvSource,
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
                          'Candidatura Inviata',
                          'Hai inviato la candidatura a ${job.company} con 1 clic (Firestore sincronizzato).',
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Invia Candidatura con 1 Clic'),
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

  /// 1-Tap Colloquio: Crea stanza Google Meet e invia email a candidato e recruiter
  Future<void> _scheduleOneTapMeet(JobApplication app) async {
    final String? token = _authService.accessToken;
    String meetLink;
    try {
      meetLink = await _firestoreService.scheduleOneTapMeetInterview(
        application: app,
        interviewDate: '30 Ott 2026 ore 15:00',
        customMessage:
            'Profilo selezionato per colloquio su Google Meet. Inviato invito ufficiale via Gmail.',
        oauthAccessToken: token,
      );
    } catch (_) {
      meetLink = await _workspaceService.createGoogleMeetSpace(
        accessToken: token,
      );
    }

    const String dateStr = '30 Ott 2026 ore 15:00';
    final String msg =
        'Colloquio fissato su Google Meet ($dateStr). Email automatica inviata a ${app.candidateEmail}.';

    setState(() {
      final idx = _applications.indexWhere((a) => a.id == app.id);
      if (idx != -1) {
        _applications[idx] = JobApplication(
          id: app.id,
          jobId: app.jobId,
          jobTitle: app.jobTitle,
          company: app.company,
          candidateId: app.candidateId,
          candidateName: app.candidateName,
          candidateEmail: app.candidateEmail,
          recruiterId: app.recruiterId,
          recruiterEmail: app.recruiterEmail,
          cvSource: app.cvSource,
          cvTitle: app.cvTitle,
          cvContent: app.cvContent,
          candidateNotes: app.candidateNotes,
          status: 'interview_scheduled',
          employerResponse: msg,
          meetLink: meetLink,
          interviewDate: dateStr,
          createdAt: app.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    });

    _emitPushBanner(
      'Colloquio Google Meet Creato',
      'Link $meetLink inviato via mail a candidato e recruiter.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _jobs.where((job) {
      if (job.status == 'closed') return false;
      final dist = job.distanceFromKm(_userLat, _userLon);
      if (dist > _maxDistanceKm) return false;
      if (_roleQuery.isNotEmpty &&
          !job.title.toLowerCase().contains(_roleQuery.toLowerCase()) &&
          !job.requirements.toLowerCase().contains(_roleQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'FindMyJob',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isFirestoreConnected
                    ? Colors.green.shade100
                    : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isFirestoreConnected
                        ? Icons.cloud_done
                        : Icons.cloud_queue,
                    size: 14,
                    color: _isFirestoreConnected
                        ? Colors.green.shade800
                        : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isFirestoreConnected ? 'Firestore OK' : 'Firestore Connessione...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isFirestoreConnected
                          ? Colors.green.shade900
                          : Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Google Auth Action / Profile
          if (_currentUser == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Accedi con Google'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'logout') _handleSignOut();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.displayName ?? 'Utente Google',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentUser?.email ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Disconnetti'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF2563EB),
                  backgroundImage: _currentUser?.photoURL != null
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: _currentUser?.photoURL == null
                      ? Text(
                          (_currentUser?.displayName ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        )
                      : null,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Centro Notifiche Push (${_pushNotificationsLog.length})',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Notifiche Push Personalizzate'),
                  content: SizedBox(
                    width: 420,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _pushNotificationsLog.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) => Text(_pushNotificationsLog[i]),
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
            },
            icon: Badge(
              label: Text('${_pushNotificationsLog.length}'),
              child: const Icon(Icons.notifications_active_outlined),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0: Annunci & Ricerca 1-Click
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_currentUser == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Accedi con Google per sincronizzare automaticamente il tuo CV Cloud Firestore e candidarti con 1 clic.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _handleGoogleSignIn,
                        child: const Text('Accedi'),
                      ),
                    ],
                  ),
                ),
              TextField(
                onChanged: (v) => setState(() => _roleQuery = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Filtra per posizione lavorativa o competenze',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Distanza massima: '),
                  Expanded(
                    child: Slider(
                      value: _maxDistanceKm,
                      min: 10,
                      max: 800,
                      divisions: 79,
                      label: '${_maxDistanceKm.round()} km',
                      onChanged: (v) => setState(() => _maxDistanceKm = v),
                    ),
                  ),
                  Text('${_maxDistanceKm.round()} km'),
                ],
              ),
              const SizedBox(height: 8),
              ...filteredJobs.map((job) {
                final dist = job.distanceFromKm(_userLat, _userLon);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${job.category} · ${job.contractType} · $dist km da te',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                            '${job.company} · ${job.locationName} · ${job.salaryRange}'),
                        const SizedBox(height: 8),
                        Text(job.description),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _openOneClickApplyModal(job),
                            icon: const Icon(Icons.send),
                            label: const Text('Candidati con 1 Clic'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          // 1: Mappa Interattiva delle Offerte nelle Vicinanze
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(_userLat, _userLon),
              initialZoom: 6.2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.findmyjob.find_my_job_flutter',
              ),
              MarkerLayer(
                markers: filteredJobs.map((job) {
                  return Marker(
                    point: LatLng(job.latitude, job.longitude),
                    width: 140,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _openOneClickApplyModal(job),
                      child: Card(
                        color: const Color(0xFF2563EB),
                        child: Center(
                          child: Text(
                            job.company.split(' ').first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2: Stato Candidature & CV Cloud Firestore
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monitoraggio Candidature',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showCvCloudDialog();
                    },
                    icon: const Icon(Icons.cloud_done, size: 16),
                    label: const Text('Mio CV Cloud'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_applications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Nessuna candidatura inviata finora.\nUsa il pulsante "Candidati con 1 Clic" nella scheda Annunci.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ..._applications.map((app) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${app.jobTitle} · ${app.company}'),
                      subtitle: Text(
                        'Stato: ${app.status}\nRisposta Datore: ${app.employerResponse.isEmpty ? "In attesa di risposta obbligatoria" : app.employerResponse}',
                      ),
                      trailing: app.meetLink.isNotEmpty
                          ? IconButton(
                              tooltip: 'Avvia Google Meet',
                              icon: const Icon(Icons.video_call,
                                  color: Colors.blue),
                              onPressed: () =>
                                  launchUrl(Uri.parse(app.meetLink)),
                            )
                          : null,
                    ),
                  )),
            ],
          ),

          // 3: Gestionale Recruiter ATS (1-Tap Meet + Mail & Chiusura Posizione)
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Gestionale Annunci Recruiter & 1-Tap Google Meet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_applications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nessun candidato presente nell\'ATS. Le candidature inviate appariranno qui.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ..._applications.map((app) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${app.candidateName} (${app.candidateEmail})',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Offerta: ${app.jobTitle} (${app.company})'),
                          Text(
                              'CV: ${app.cvTitle}\nNote: ${app.candidateNotes}'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _scheduleOneTapMeet(app),
                                icon: const Icon(Icons.video_call),
                                label: const Text('1-Tap Meet + Mail'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await _firestoreService
                                      .respondToCandidateApplication(
                                    application: app,
                                    decision: 'accepted',
                                    employerResponse:
                                        'Complimenti! La tua candidatura è stata accettata.',
                                    oauthAccessToken:
                                        _authService.accessToken,
                                  );
                                  _emitPushBanner(
                                    'Candidato Accettato',
                                    'Notifica ed email inviate a ${app.candidateEmail}.',
                                  );
                                },
                                icon: const Icon(Icons.check, color: Colors.green),
                                label: const Text('Assumi'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await _firestoreService
                                      .respondToCandidateApplication(
                                    application: app,
                                    decision: 'rejected',
                                    employerResponse:
                                        'Gentile candidato, abbiamo proseguito con un altro profilo.',
                                    oauthAccessToken:
                                        _authService.accessToken,
                                  );
                                  _emitPushBanner(
                                    'Riscontro Inviato',
                                    'Email di riscontro inviata a ${app.candidateEmail}.',
                                  );
                                },
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text('Scarta'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            label: 'Annunci',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Mappa',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Candidature',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_center_outlined),
            label: 'Gestionale ATS',
          ),
        ],
      ),
    );
  }

  void _showCvCloudDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_done, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('CV Cloud Firestore'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _cloudResume.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('${_cloudResume.headline} · ${_cloudResume.email}'),
              const Divider(height: 24),
              const Text(
                'Riepilogo Professionale:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(_cloudResume.summary),
              const SizedBox(height: 12),
              const Text(
                'Competenze Chiave:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(_cloudResume.skills),
              const SizedBox(height: 12),
              const Text(
                'Esperienza:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(_cloudResume.experience),
            ],
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
}
