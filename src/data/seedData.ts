import {
  AutomatedEmailLog,
  CityLocation,
  CloudResume,
  InterviewFeedback,
  JobApplication,
  JobOffer,
  PushNotification,
} from '../types';

export const ITALIAN_CITIES: CityLocation[] = [
  { name: 'Milano, Lombardia', latitude: 45.4642, longitude: 9.19, region: 'Lombardia' },
  { name: 'Roma, Lazio', latitude: 41.9028, longitude: 12.4964, region: 'Lazio' },
  { name: 'Torino, Piemonte', latitude: 45.0703, longitude: 7.6869, region: 'Piemonte' },
  { name: 'Bologna, Emilia-Romagna', latitude: 44.4949, longitude: 11.3426, region: 'Emilia-Romagna' },
  { name: 'Firenze, Toscana', latitude: 43.7696, longitude: 11.2558, region: 'Toscana' },
  { name: 'Napoli, Campania', latitude: 40.8518, longitude: 14.2681, region: 'Campania' },
];

export const INITIAL_CLOUD_RESUME: CloudResume = {
  userId: 'demo-user-1',
  fullName: 'Giovanni Messina',
  email: 'giovannimessina96@gmail.com',
  phone: '+39 348 712 9045',
  headline: 'Senior Flutter & Full-Stack Mobile Architect',
  summary:
    'Ingegnere del software specializzato nello sviluppo di applicazioni mobile multipiattaforma in Flutter/Dart e architetture cloud scalabili su Firebase, Firestore e Google Cloud Platform. Esperienza consolidata in UX reattiva, integrazioni OAuth e sistemi real-time.',
  skills:
    'Flutter, Dart, Firebase Firestore, Cloud Functions, React, TypeScript, REST & GraphQL, Google Cloud, CI/CD, Clean Architecture',
  experience:
    '• Tech Lead Mobile @ FinTech Milano (2023 - Presente): Guida del team mobile (8 sviluppatori), rilascio app bancaria Flutter con 450k utenti attivi.\n• Senior Mobile Developer @ Digital Lab Torino (2020 - 2023): Sviluppo di 12 app iOS/Android in Flutter sincronizzate con Cloud Firestore e notifiche push FCM.',
  education: 'Laurea Magistrale in Ingegneria Informatica — Politecnico di Milano (110/110 e Lode)',
  portfolioUrl: 'https://github.com/giovannimessina-dev',
  updatedAt: '2026-10-26T08:30:00Z',
};

export const INITIAL_JOBS: JobOffer[] = [
  {
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
      'Cerchiamo un Senior Flutter Engineer per guidare l’evoluzione della nostra super-app di pagamenti digitali. Lavorerai a stretto contatto con il team Product e Cloud su architettura BLoC/Riverpod, integrazioni Firestore real-time e animazioni native a 120fps.',
    requirements:
      '4+ anni in Flutter/Dart, padronanza di Cloud Firestore, autenticazione OAuth2, test automatizzati e pubblicazione su App Store / Google Play.',
    recruiterId: 'demo-user-1',
    recruiterName: 'Elena Visconti (HR Tech Lead)',
    recruiterEmail: 'giovannimessina96@gmail.com',
    status: 'open',
    createdAt: '2026-10-24T09:00:00Z',
    updatedAt: '2026-10-24T09:00:00Z',
  },
  {
    id: 'job-fullstack-milano-02',
    title: 'Cloud & Firebase Solutions Architect',
    company: 'Velasca Digital Hub',
    locationName: 'Milano — Isola',
    latitude: 45.4878,
    longitude: 9.1882,
    salaryRange: '€58.000 - €75.000',
    contractType: 'Full-time',
    category: 'Cloud & Backend',
    description:
      'Progettazione di infrastrutture serverless ad alta affidabilità su Google Cloud Platform e Firebase Enterprise. Responsabilità su regole di sicurezza Zero-Trust, indicizzazione geo-spaziale e pipeline di analytics in tempo reale.',
    requirements:
      'Esperienza avanzata con Firestore Security Rules, TypeScript, Node.js, Google Workspace APIs e architetture event-driven.',
    recruiterId: 'demo-user-1',
    recruiterName: 'Elena Visconti (HR Tech Lead)',
    recruiterEmail: 'giovannimessina96@gmail.com',
    status: 'open',
    createdAt: '2026-10-25T10:30:00Z',
    updatedAt: '2026-10-25T10:30:00Z',
  },
  {
    id: 'job-product-torino-03',
    title: 'Lead Product Designer (Mobile & Design Systems)',
    company: 'Orion Mobility Lab',
    locationName: 'Torino — OGR Tech',
    latitude: 45.0668,
    longitude: 7.6612,
    salaryRange: '€45.000 - €58.000',
    contractType: 'Ibrido',
    category: 'Design & UX',
    description:
      'Ricerchiamo un Product Designer capace di trasformare flussi complessi di mobilità connessa e mappe interattive in esperienze mobile intuitive. Gestirai il Design System condiviso tra Figma e componenti Flutter/React.',
    requirements:
      'Portfolio mobile-first, padronanza di Figma, prototipazione interattiva, esperienza con flussi di geolocalizzazione e design system tokenizzati.',
    recruiterId: 'demo-user-1',
    recruiterName: 'Marco Rinaldi (Talent Partner)',
    recruiterEmail: 'giovannimessina96@gmail.com',
    status: 'open',
    createdAt: '2026-10-23T14:15:00Z',
    updatedAt: '2026-10-23T14:15:00Z',
  },
  {
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
      'Sviluppo di pipeline predittive e cruscotti di analisi clinica e operativa. Collaborerai con ricercatori e ingegneri per esporre modelli ML tramite API veloci e sicure.',
    requirements:
      'Python, TypeScript, pipeline dati in cloud, visualizzazione KPI ad alta densità, basi di dati NoSQL e SQL.',
    recruiterId: 'demo-user-1',
    recruiterName: 'Chiara Moretti (People Ops)',
    recruiterEmail: 'giovannimessina96@gmail.com',
    status: 'open',
    createdAt: '2026-10-22T11:00:00Z',
    updatedAt: '2026-10-22T11:00:00Z',
  },
  {
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
      'Entra nel team che sviluppa le applicazioni civiche per oltre 2 milioni di cittadini. Implementerai moduli di notifiche push personalizzate, mappe dei servizi di prossimità e autenticazione digitale.',
    requirements:
      '2+ anni di esperienza in Flutter, integrazione mappe e geolocalizzazione, gestione stato reattiva e attenzione all’accessibilità WCAG AA.',
    recruiterId: 'demo-user-1',
    recruiterName: 'Lorenzo Conti (Recruiting Lead)',
    recruiterEmail: 'giovannimessina96@gmail.com',
    status: 'open',
    createdAt: '2026-10-21T16:00:00Z',
    updatedAt: '2026-10-21T16:00:00Z',
  },
  {
    id: 'job-frontend-firenze-06',
    title: 'Frontend & Mobile UI Engineer',
    company: 'Arno Luxury Commerce',
    locationName: 'Firenze — Centro Storico',
    latitude: 43.7731,
    longitude: 11.256,
    salaryRange: '€44.000 - €56.000',
    contractType: 'Full-time',
    category: 'Frontend & Web',
    description:
      'Sviluppo di interfacce editoriali ad alte prestazioni per il settore alta moda e retail omnicanale, con focus su micro-interazioni fluide e tempi di risposta sotto i 100ms.',
    requirements:
      'React 19, TypeScript, Tailwind CSS, esperienza con app ibride o Flutter Web.',
    recruiterId: 'demo-user-1',
    recruiterName: 'Elena Visconti (HR Tech Lead)',
    recruiterEmail: 'giovannimessina96@gmail.com',
    status: 'open',
    createdAt: '2026-10-19T12:00:00Z',
    updatedAt: '2026-10-19T12:00:00Z',
  },
];

export const INITIAL_APPLICATIONS: JobApplication[] = [
  {
    id: 'app-demo-01',
    jobId: 'job-flutter-milano-01',
    jobTitle: 'Senior Flutter Mobile Engineer',
    company: 'SatisCloud FinTech',
    candidateId: 'demo-user-1',
    candidateName: 'Giovanni Messina',
    candidateEmail: 'giovannimessina96@gmail.com',
    recruiterId: 'demo-user-1',
    recruiterEmail: 'giovannimessina96@gmail.com',
    cvSource: 'cloud',
    cvTitle: 'CV Cloud Firestore — Giovanni Messina (Senior Flutter Architect)',
    cvContent:
      'Giovanni Messina — Senior Flutter & Full-Stack Mobile Architect. 6+ anni di esperienza in sviluppo mobile Flutter/Dart, Cloud Firestore (progetto findmyjob-510711), OAuth2 e architetture reattive ad alta affidabilità. Laurea Magistrale Politecnico di Milano.',
    candidateNotes:
      'Ho già sviluppato 3 app FinTech con Flutter + Firestore e notifiche push real-time. Disponibile per un colloquio tecnico su Google Meet anche in settimana.',
    status: 'interview_scheduled',
    employerResponse:
      'Profilo eccellente! Abbiamo pianificato il primo colloquio tecnico su Google Meet per approfondire l’architettura Flutter e Firestore.',
    meetLink: 'https://meet.google.com/fmj-tech-one',
    interviewDate: '2026-10-28 ore 15:00',
    createdAt: '2026-10-24T14:20:00Z',
    updatedAt: '2026-10-25T09:15:00Z',
  },
  {
    id: 'app-demo-02',
    jobId: 'job-flutter-milano-01',
    jobTitle: 'Senior Flutter Mobile Engineer',
    company: 'SatisCloud FinTech',
    candidateId: 'cand-sofia-02',
    candidateName: 'Sofia Esposito',
    candidateEmail: 'sofia.esposito.dev@example.com',
    recruiterId: 'demo-user-1',
    recruiterEmail: 'giovannimessina96@gmail.com',
    cvSource: 'custom',
    cvTitle: 'CV Ad-Hoc FinTech — Sofia Esposito (Flutter & Mobile Security)',
    cvContent:
      'Sofia Esposito — Mobile Security & Flutter Developer. 4 anni di esperienza su app di mobile banking, autenticazione biometrica, crittografia end-to-end e integrazione REST/gRPC.',
    candidateNotes:
      'Allego un CV ad hoc focalizzato sui progetti di sicurezza mobile e pagamenti istantanei SEPA che ho seguito negli ultimi 2 anni.',
    status: 'in_review',
    employerResponse: '',
    meetLink: '',
    interviewDate: '',
    createdAt: '2026-10-25T11:40:00Z',
    updatedAt: '2026-10-25T11:40:00Z',
  },
  {
    id: 'app-demo-03',
    jobId: 'job-fullstack-milano-02',
    jobTitle: 'Cloud & Firebase Solutions Architect',
    company: 'Velasca Digital Hub',
    candidateId: 'cand-matteo-03',
    candidateName: 'Matteo Galli',
    candidateEmail: 'matteo.galli.cloud@example.com',
    recruiterId: 'demo-user-1',
    recruiterEmail: 'giovannimessina96@gmail.com',
    cvSource: 'cloud',
    cvTitle: 'CV Cloud — Matteo Galli (Lead Cloud Engineer)',
    cvContent:
      'Matteo Galli — Google Cloud Professional Architect. 7 anni su Firestore Enterprise, Cloud Run, BigQuery e Terraform.',
    candidateNotes:
      'Molto interessato alla parte di Zero-Trust Firestore Security Rules e scalabilità multi-regione.',
    status: 'accepted',
    employerResponse:
      'Complimenti Matteo! Il team tecnico ha approvato all’unanimità il tuo inserimento come Cloud & Firebase Solutions Architect.',
    meetLink: 'https://meet.google.com/vls-arch-int',
    interviewDate: '2026-10-25 ore 11:00',
    createdAt: '2026-10-25T12:10:00Z',
    updatedAt: '2026-10-26T10:00:00Z',
  },
];

export const INITIAL_FEEDBACKS: InterviewFeedback[] = [
  {
    id: 'fb-demo-01',
    applicationId: 'app-demo-03',
    jobId: 'job-fullstack-milano-02',
    jobTitle: 'Cloud & Firebase Solutions Architect',
    candidateId: 'cand-matteo-03',
    candidateName: 'Matteo Galli',
    recruiterId: 'demo-user-1',
    technicalScore: 5,
    communicationScore: 5,
    cultureFitScore: 4,
    overallRating: 5,
    strengths:
      'Padronanza eccezionale delle regole di sicurezza Firestore (ABAC e Zero-Trust), ottima chiarezza espositiva su pattern di scalabilità.',
    areasForImprovement:
      'Approfondire ulteriormente l’integrazione lato client mobile con Flutter.',
    recommendation: 'strong_hire',
    sharedSummaryForCandidate:
      'Colloquio tecnico eccellente: abbiamo apprezzato in particolare la tua competenza pratica su Firestore Enterprise e la chiarezza progettuale.',
    createdAt: '2026-10-25T16:30:00Z',
    updatedAt: '2026-10-25T16:30:00Z',
  },
];

export const INITIAL_NOTIFICATIONS: PushNotification[] = [
  {
    id: 'notif-demo-01',
    recipientId: 'demo-user-1',
    senderId: 'demo-user-1',
    type: 'interview_meet',
    title: 'Colloquio Google Meet confermato — SatisCloud FinTech',
    body: 'Sei stato invitato al primo colloquio per Senior Flutter Mobile Engineer il 28/10 ore 15:00. Link Meet pronto.',
    relatedJobId: 'job-flutter-milano-01',
    relatedApplicationId: 'app-demo-01',
    isRead: false,
    createdAt: '2026-10-25T09:15:00Z',
    updatedAt: '2026-10-25T09:15:00Z',
  },
  {
    id: 'notif-demo-02',
    recipientId: 'demo-user-1',
    senderId: 'demo-user-1',
    type: 'new_job',
    title: 'Nuova offerta nelle vicinanze (Milano, 2.3 km)',
    body: 'Velasca Digital Hub ha pubblicato: Cloud & Firebase Solutions Architect (€58.000 - €75.000). Candidati con 1 clic!',
    relatedJobId: 'job-fullstack-milano-02',
    relatedApplicationId: '',
    isRead: false,
    createdAt: '2026-10-25T10:30:00Z',
    updatedAt: '2026-10-25T10:30:00Z',
  },
];

export const INITIAL_EMAIL_LOGS: AutomatedEmailLog[] = [
  {
    id: 'mail-demo-01',
    to: 'giovannimessina96@gmail.com',
    cc: 'giovannimessina96@gmail.com',
    subject: '[Invito Colloquio Google Meet] Senior Flutter Mobile Engineer — SatisCloud FinTech',
    body: 'Ciao Giovanni,\n\nIl tuo profilo è risultato in linea con la posizione Senior Flutter Mobile Engineer. Abbiamo generato la stanza Google Meet (https://meet.google.com/fmj-tech-one) per il colloquio del 28/10 ore 15:00.\n\nA presto,\nTeam Recruiting SatisCloud FinTech',
    triggerType: 'interview_meet',
    sentViaGmailApi: false,
    meetLink: 'https://meet.google.com/fmj-tech-one',
    timestamp: '2026-10-25T09:15:00Z',
  },
];
