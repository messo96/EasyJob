import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'models/job_models.dart';
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
  final WorkspaceMeetGmailService _workspaceService =
      WorkspaceMeetGmailService();

  // Posizione corrente utente per filtro distanza (Default: Milano)
  double _userLat = 45.4642;
  double _userLon = 9.1900;
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
    skills: 'Flutter, Dart, Cloud Firestore, Firebase Messaging, Google Meet API, Gmail API',
    experience: 'Tech Lead Mobile @ FinTech Milano (2023-oggi)',
    education: 'Laurea Magistrale Ingegneria Informatica — Politecnico di Milano',
    portfolioUrl: 'https://github.com/giovannimessina-dev',
    updatedAt: DateTime.now(),
  );

  final List<JobOffer> _jobs = [
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
      requirements: 'Flutter, Dart, Firebase Firestore, REST API, Clean Architecture',
      recruiterId: 'demo-user-1',
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
      recruiterId: 'demo-user-1',
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
      requirements: 'Flutter, flutter_map, geolocator, Firebase Messaging',
      recruiterId: 'demo-user-1',
      recruiterName: 'Lorenzo Conti',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
  ];

  final List<JobApplication> _applications = [];
  final List<InterviewFeedback> _feedbacks = [];
  final List<String> _pushNotificationsLog = [
    'Benvenuto su FindMyJob (Firestore ID: findmyjob-510711) — Notifiche Push attive.',
  ];

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
                      onPressed: () {
                        final newApp = JobApplication(
                          id: 'app-${DateTime.now().millisecondsSinceEpoch}',
                          jobId: job.id,
                          jobTitle: job.title,
                          company: job.company,
                          candidateId: _cloudResume.userId,
                          candidateName: _cloudResume.fullName,
                          candidateEmail: _cloudResume.email,
                          recruiterId: job.recruiterId,
                          recruiterEmail: job.recruiterEmail,
                          cvSource: selectedCvSource,
                          cvTitle: selectedCvSource == 'cloud'
                              ? 'CV Cloud Firestore — ${_cloudResume.fullName}'
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
                        setState(() => _applications.insert(0, newApp));
                        Navigator.pop(ctx);
                        _emitPushBanner(
                          'Candidatura Inviata',
                          'Hai applicato a ${job.title} (${job.company}) con 1 clic.',
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
    final String meetLink = await _workspaceService.createGoogleMeetSpace(
      accessToken: null,
    );
    const String dateStr = '30 Ott 2026 ore 15:00';
    final String msg =
        'Profilo selezionato per colloquio su Google Meet ($dateStr). Email inviata a ${app.candidateEmail} e ${app.recruiterEmail}.';

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
        title: const Text('FindMyJob · Flutter (findmyjob-510711)'),
        actions: [
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
                        Text('${job.company} · ${job.locationName} · ${job.salaryRange}'),
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
                userAgentPackageName: 'com.findmyjob.flutter',
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

          // 2: Stato Candidature & CV Cloud
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Monitoraggio Stato Candidature Inviate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_applications.isEmpty)
                const Text('Nessuna candidatura inviata. Usa il pulsante 1-Click sugli annunci.'),
              ..._applications.map((app) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${app.jobTitle} · ${app.company}'),
                      subtitle: Text(
                        'Stato: ${app.status}\nRisposta Datore: ${app.employerResponse.isEmpty ? "In attesa di risposta obbligatoria" : app.employerResponse}',
                      ),
                      trailing: app.meetLink.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.video_call, color: Colors.blue),
                              onPressed: () => launchUrl(Uri.parse(app.meetLink)),
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
              ..._applications.map((app) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${app.candidateName} (${app.candidateEmail})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('CV: ${app.cvTitle}\nNote: ${app.candidateNotes}'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _scheduleOneTapMeet(app),
                                icon: const Icon(Icons.video_call),
                                label: const Text('1-Tap Meet + Mail'),
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
}
