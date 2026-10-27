import test from 'node:test';
import assert from 'node:assert/strict';
import {
  buildMandatoryClosureBroadcasts,
  calculateDistanceKm,
  computeRecruitingAnalytics,
  encodeGmailRawMessage,
  filterJobsByCriteria,
  validateJobOfferInput,
} from './recruitingLogic';
import { JobApplication, JobOffer } from '../types';

const sampleJobs: JobOffer[] = [
  {
    id: 'job-milano-1',
    title: 'Senior Flutter & Mobile Engineer',
    company: 'NexaPay Italia',
    locationName: 'Milano, MI',
    latitude: 45.4642,
    longitude: 9.19,
    salaryRange: '€50.000 - €65.000',
    contractType: 'Ibrido',
    category: 'Mobile & Flutter',
    description: 'Sviluppo app mobile multipiattaforma in Flutter e Dart.',
    requirements: 'Flutter, Dart, Firebase, REST API',
    recruiterId: 'recruiter-1',
    recruiterName: 'Marco Ferri',
    recruiterEmail: 'm.ferri@nexapay.it',
    status: 'open',
    createdAt: '2026-10-20T10:00:00Z',
    updatedAt: '2026-10-20T10:00:00Z',
  },
  {
    id: 'job-roma-2',
    title: 'Cloud Backend Architect',
    company: 'Tevere Tech',
    locationName: 'Roma, RM',
    latitude: 41.9028,
    longitude: 12.4964,
    salaryRange: '€55.000 - €70.000',
    contractType: 'Full-time',
    category: 'Cloud & Backend',
    description: 'Progettazione microservizi su Google Cloud e Firestore.',
    requirements: 'Node.js, TypeScript, GCP, Kubernetes',
    recruiterId: 'recruiter-1',
    recruiterName: 'Marco Ferri',
    recruiterEmail: 'm.ferri@nexapay.it',
    status: 'open',
    createdAt: '2026-10-21T10:00:00Z',
    updatedAt: '2026-10-21T10:00:00Z',
  },
];

test('calculateDistanceKm computes accurate geographic distance between Milano and Roma', () => {
  const dist = calculateDistanceKm(45.4642, 9.19, 41.9028, 12.4964);
  assert.ok(dist > 470 && dist < 485, `Expected ~477km, got ${dist}km`);
});

test('filterJobsByCriteria filters by role keyword and maxDistanceKm radius', () => {
  // User in Milano with 50km radius should only see the Milano job
  const nearbyMilano = filterJobsByCriteria(sampleJobs, {
    query: '',
    category: 'Tutte',
    contractType: 'Tutti',
    userLat: 45.4642,
    userLon: 9.19,
    maxDistanceKm: 50,
  });
  assert.equal(nearbyMilano.length, 1);
  assert.equal(nearbyMilano[0].id, 'job-milano-1');

  // Searching for "Flutter" with 1000km radius
  const flutterSearch = filterJobsByCriteria(sampleJobs, {
    query: 'flutter',
    category: 'Tutte',
    contractType: 'Tutti',
    userLat: 45.4642,
    userLon: 9.19,
    maxDistanceKm: 1000,
  });
  assert.equal(flutterSearch.length, 1);
  assert.equal(flutterSearch[0].title, 'Senior Flutter & Mobile Engineer');
});

test('buildMandatoryClosureBroadcasts notifies all active candidates when a position closes', () => {
  const applications: JobApplication[] = [
    {
      id: 'app-1',
      jobId: 'job-milano-1',
      jobTitle: 'Senior Flutter & Mobile Engineer',
      company: 'NexaPay Italia',
      candidateId: 'cand-1',
      candidateName: 'Giulia Bianchi',
      candidateEmail: 'giulia@example.com',
      recruiterId: 'recruiter-1',
      recruiterEmail: 'm.ferri@nexapay.it',
      cvSource: 'cloud',
      cvTitle: 'CV Cloud Giulia',
      cvContent: 'Esperienza 5 anni in Flutter e Firebase.',
      candidateNotes: 'Disponibile da subito.',
      status: 'in_review',
      employerResponse: '',
      meetLink: '',
      interviewDate: '',
      createdAt: '2026-10-22T10:00:00Z',
      updatedAt: '2026-10-22T10:00:00Z',
    },
    {
      id: 'app-2',
      jobId: 'job-milano-1',
      jobTitle: 'Senior Flutter & Mobile Engineer',
      company: 'NexaPay Italia',
      candidateId: 'cand-2',
      candidateName: 'Luca Verdi',
      candidateEmail: 'luca@example.com',
      recruiterId: 'recruiter-1',
      recruiterEmail: 'm.ferri@nexapay.it',
      cvSource: 'custom',
      cvTitle: 'CV Custom Mobile',
      cvContent: 'Sviluppatore iOS/Android e Flutter.',
      candidateNotes: '',
      status: 'rejected',
      employerResponse: 'Profilo già valutato.',
      meetLink: '',
      interviewDate: '',
      createdAt: '2026-10-22T11:00:00Z',
      updatedAt: '2026-10-22T11:00:00Z',
    },
  ];

  const broadcasts = buildMandatoryClosureBroadcasts(sampleJobs[0], applications);
  // Only app-1 (in_review) should be transitioned to position_closed; app-2 is already terminal (rejected)
  assert.equal(broadcasts.length, 1);
  assert.equal(broadcasts[0].applicationId, 'app-1');
  assert.equal(broadcasts[0].newStatus, 'position_closed');
  assert.ok(broadcasts[0].notificationTitle.includes('Senior Flutter & Mobile Engineer'));
});

test('computeRecruitingAnalytics computes accurate response rate and conversion percentages', () => {
  const apps: JobApplication[] = [
    {
      id: 'a1',
      jobId: 'job-milano-1',
      jobTitle: 'Senior Flutter & Mobile Engineer',
      company: 'NexaPay Italia',
      candidateId: 'c1',
      candidateName: 'Elena',
      candidateEmail: 'elena@example.com',
      recruiterId: 'r1',
      recruiterEmail: 'r@example.com',
      cvSource: 'cloud',
      cvTitle: 'CV',
      cvContent: 'Contenuto CV',
      candidateNotes: '',
      status: 'accepted',
      employerResponse: 'Congratulazioni, assunto!',
      meetLink: 'https://meet.google.com/abc-defg-hij',
      interviewDate: '2026-10-25 15:00',
      createdAt: '2026-10-20T10:00:00Z',
      updatedAt: '2026-10-25T10:00:00Z',
    },
    {
      id: 'a2',
      jobId: 'job-milano-1',
      jobTitle: 'Senior Flutter & Mobile Engineer',
      company: 'NexaPay Italia',
      candidateId: 'c2',
      candidateName: 'Marco',
      candidateEmail: 'marco@example.com',
      recruiterId: 'r1',
      recruiterEmail: 'r@example.com',
      cvSource: 'custom',
      cvTitle: 'CV Ad Hoc',
      cvContent: 'Contenuto CV 2',
      candidateNotes: '',
      status: 'interview_scheduled',
      employerResponse: 'Ti invitiamo al primo colloquio su Google Meet.',
      meetLink: 'https://meet.google.com/xyz-uvwx-rst',
      interviewDate: '2026-10-27 11:00',
      createdAt: '2026-10-21T10:00:00Z',
      updatedAt: '2026-10-26T10:00:00Z',
    },
  ];

  const metrics = computeRecruitingAnalytics(sampleJobs, apps, []);
  assert.equal(metrics.totalApplications, 2);
  assert.equal(metrics.employerResponseRatePct, 100);
  assert.equal(metrics.interviewConversionRatePct, 100);
  assert.equal(metrics.hireRatePct, 50);
});

test('validateJobOfferInput and encodeGmailRawMessage work properly', () => {
  const err = validateJobOfferInput({ title: 'A' });
  assert.ok(err !== null);

  const raw = encodeGmailRawMessage('test@example.com', 'Colloquio Google Meet', 'Link: https://meet.google.com/abc-defg-hij');
  assert.ok(raw.length > 20);
  assert.ok(!raw.includes('+'));
});
