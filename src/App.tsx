/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useEffect, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { User } from 'firebase/auth';
import {
  Bell,
  Briefcase,
  CheckCircle2,
  ClipboardCheck,
  MapPin,
  Search,
  Send,
  X,
} from 'lucide-react';
import {
  auth,
  db,
  googleSignIn,
  handleFirestoreError,
  initAuth,
  logout,
  OperationType,
} from './firebase';
import {
  AutomatedEmailLog,
  CityLocation,
  CloudResume,
  ContractType,
  CvSource,
  InterviewFeedback,
  JobApplication,
  JobOffer,
  PushNotification,
} from './types';
import {
  INITIAL_APPLICATIONS,
  INITIAL_CLOUD_RESUME,
  INITIAL_EMAIL_LOGS,
  INITIAL_FEEDBACKS,
  INITIAL_JOBS,
  INITIAL_NOTIFICATIONS,
  ITALIAN_CITIES,
} from './data/seedData';
import {
  buildMandatoryClosureBroadcasts,
  filterJobsByCriteria,
} from './utils/recruitingLogic';
import {
  createGoogleMeetSpace,
  sendGmailMessage,
} from './services/workspaceService';
import { OneClickApplyModal } from './components/OneClickApplyModal';
import { InteractiveMapView } from './components/InteractiveMapView';
import { CandidateHubView } from './components/CandidateHubView';
import { RecruiterAtsView } from './components/RecruiterAtsView';
import { FeedbackHubView } from './components/FeedbackHubView';
import { AnalyticsDashboardView } from './components/AnalyticsDashboardView';
import { FlutterCodeExplorerView } from './components/FlutterCodeExplorerView';
import { Code2, Smartphone } from 'lucide-react';

type ActiveTab =
  | 'jobs'
  | 'map'
  | 'applications'
  | 'recruiter'
  | 'feedback'
  | 'analytics'
  | 'flutter';

export default function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('jobs');
  const [isFlutterMobileFrame, setIsFlutterMobileFrame] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [oauthToken, setOauthToken] = useState<string | null>(null);
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  // Core Domain State (seeded with deterministic data + synced with Firestore when authenticated)
  const [jobs, setJobs] = useState<JobOffer[]>(INITIAL_JOBS);
  const [cloudResume, setCloudResume] = useState<CloudResume>(INITIAL_CLOUD_RESUME);
  const [applications, setApplications] =
    useState<JobApplication[]>(INITIAL_APPLICATIONS);
  const [feedbacks, setFeedbacks] =
    useState<InterviewFeedback[]>(INITIAL_FEEDBACKS);
  const [notifications, setNotifications] =
    useState<PushNotification[]>(INITIAL_NOTIFICATIONS);
  const [emailLogs, setEmailLogs] =
    useState<AutomatedEmailLog[]>(INITIAL_EMAIL_LOGS);

  // Search & Geographic Filtering State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('Tutte');
  const [selectedContract, setSelectedContract] = useState('Tutti');
  const [userLocation, setUserLocation] = useState<CityLocation>(ITALIAN_CITIES[0]); // Milano default
  const [maxDistanceKm, setMaxDistanceKm] = useState<number>(600);

  // Modals & Push Center UI State
  const [applyingJob, setApplyingJob] = useState<JobOffer | null>(null);
  const [showPushCenter, setShowPushCenter] = useState(false);
  const [activePushBanner, setActivePushBanner] =
    useState<PushNotification | null>(null);
  const [preselectedFeedbackAppId, setPreselectedFeedbackAppId] = useState<
    string | null
  >(null);
  const [browserPushEnabled, setBrowserPushEnabled] = useState(false);

  // Initialize Auth & Firestore Real-Time Listeners
  useEffect(() => {
    const unsubscribeAuth = initAuth(
      (loggedInUser, token) => {
        setUser(loggedInUser);
        setOauthToken(token);
      },
      () => {
        setUser(null);
        setOauthToken(null);
      }
    );
    return () => unsubscribeAuth();
  }, []);

  useEffect(() => {
    if (!user) return;
    const uid = user.uid;

    // 1. Listen to Jobs
    const unsubJobs = onSnapshot(
      collection(db, 'jobs'),
      (snap) => {
        if (!snap.empty) {
          const loaded: JobOffer[] = snap.docs.map((d) => {
            const data = d.data();
            return {
              id: d.id,
              title: data.title,
              company: data.company,
              locationName: data.locationName,
              latitude: data.latitude,
              longitude: data.longitude,
              salaryRange: data.salaryRange,
              contractType: data.contractType as ContractType,
              category: data.category,
              description: data.description,
              requirements: data.requirements,
              recruiterId: data.recruiterId,
              recruiterName: data.recruiterName,
              recruiterEmail: data.recruiterEmail,
              status: data.status,
              createdAt:
                data.createdAt?.toDate?.()?.toISOString?.() ||
                new Date().toISOString(),
              updatedAt:
                data.updatedAt?.toDate?.()?.toISOString?.() ||
                new Date().toISOString(),
            };
          });
          setJobs(loaded);
        }
      },
      (err) => handleFirestoreError(err, OperationType.LIST, 'jobs')
    );

    // 2. Listen to User's Cloud Resume
    const unsubResume = onSnapshot(
      doc(db, 'resumes', uid),
      (snap) => {
        if (snap.exists()) {
          const data = snap.data();
          setCloudResume({
            userId: data.userId,
            fullName: data.fullName,
            email: data.email,
            phone: data.phone,
            headline: data.headline,
            summary: data.summary,
            skills: data.skills,
            experience: data.experience,
            education: data.education,
            portfolioUrl: data.portfolioUrl,
            updatedAt:
              data.updatedAt?.toDate?.()?.toISOString?.() ||
              new Date().toISOString(),
          });
        }
      },
      (err) => handleFirestoreError(err, OperationType.GET, `resumes/${uid}`)
    );

    // 3. Listen to User's Notifications
    const notifQuery = query(
      collection(db, 'notifications'),
      where('recipientId', '==', uid)
    );
    const unsubNotifs = onSnapshot(
      notifQuery,
      (snap) => {
        if (!snap.empty) {
          const loaded: PushNotification[] = snap.docs.map((d) => {
            const data = d.data();
            return {
              id: d.id,
              recipientId: data.recipientId,
              senderId: data.senderId,
              type: data.type,
              title: data.title,
              body: data.body,
              relatedJobId: data.relatedJobId,
              relatedApplicationId: data.relatedApplicationId,
              isRead: data.isRead,
              createdAt:
                data.createdAt?.toDate?.()?.toISOString?.() ||
                new Date().toISOString(),
              updatedAt:
                data.updatedAt?.toDate?.()?.toISOString?.() ||
                new Date().toISOString(),
            };
          });
          setNotifications(loaded);
        }
      },
      (err) => handleFirestoreError(err, OperationType.LIST, 'notifications')
    );

    return () => {
      unsubJobs();
      unsubResume();
      unsubNotifs();
    };
  }, [user]);

  // Push Notification Dispatcher (In-App + Browser Notification API + Firestore)
  const triggerPushNotification = async (
    notif: Omit<PushNotification, 'id' | 'createdAt' | 'updatedAt' | 'isRead'>
  ) => {
    const nowIso = new Date().toISOString();
    const id = `notif-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
    const fullNotif: PushNotification = {
      ...notif,
      id,
      isRead: false,
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    setNotifications((prev) => [fullNotif, ...prev]);
    setActivePushBanner(fullNotif);

    if (
      browserPushEnabled &&
      typeof window !== 'undefined' &&
      'Notification' in window &&
      Notification.permission === 'granted'
    ) {
      try {
        new Notification(fullNotif.title, { body: fullNotif.body });
      } catch {
        // Ignore browser notification errors in headless frames
      }
    }

    if (user && auth.currentUser) {
      try {
        await setDoc(doc(db, 'notifications', id), {
          recipientId: fullNotif.recipientId,
          senderId: auth.currentUser.uid,
          type: fullNotif.type,
          title: fullNotif.title.slice(0, 140),
          body: fullNotif.body.slice(0, 1000),
          relatedJobId: fullNotif.relatedJobId.slice(0, 128),
          relatedApplicationId: fullNotif.relatedApplicationId.slice(0, 128),
          isRead: false,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      } catch (err) {
        handleFirestoreError(err, OperationType.CREATE, `notifications/${id}`);
      }
    }
  };

  const handleEnableBrowserPush = async () => {
    if (typeof window !== 'undefined' && 'Notification' in window) {
      const perm = await Notification.requestPermission();
      setBrowserPushEnabled(perm === 'granted');
    } else {
      setBrowserPushEnabled(true);
    }
  };

  const handleGoogleLogin = async () => {
    setIsLoggingIn(true);
    try {
      const res = await googleSignIn();
      if (res) {
        setUser(res.user);
        setOauthToken(res.accessToken);
      }
    } catch (err) {
      console.error('Login error:', err);
    } finally {
      setIsLoggingIn(false);
    }
  };

  // 1-Click Application Handler
  const handleOneClickApply = async (payload: {
    job: JobOffer;
    cvSource: CvSource;
    cvTitle: string;
    cvContent: string;
    candidateNotes: string;
  }) => {
    const nowIso = new Date().toISOString();
    const appId = `app-${Date.now()}`;
    const candidateUid = user?.uid || cloudResume.userId;

    const newApp: JobApplication = {
      id: appId,
      jobId: payload.job.id,
      jobTitle: payload.job.title,
      company: payload.job.company,
      candidateId: candidateUid,
      candidateName: cloudResume.fullName,
      candidateEmail: cloudResume.email,
      recruiterId: payload.job.recruiterId,
      recruiterEmail: payload.job.recruiterEmail,
      cvSource: payload.cvSource,
      cvTitle: payload.cvTitle.slice(0, 140),
      cvContent: payload.cvContent.slice(0, 4000),
      candidateNotes: payload.candidateNotes.slice(0, 1500),
      status: 'in_review',
      employerResponse: '',
      meetLink: '',
      interviewDate: '',
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    setApplications((prev) => [newApp, ...prev]);

    await triggerPushNotification({
      recipientId: candidateUid,
      senderId: candidateUid,
      type: 'application_received',
      title: `Candidatura 1-Click inviata: ${payload.job.title}`,
      body: `Hai applicato presso ${payload.job.company} utilizzando "${
        payload.cvSource === 'cloud' ? 'CV Cloud Firestore' : 'CV Ad-Hoc'
      }". Riceverai una notifica non appena il recruiter risponderà.`,
      relatedJobId: payload.job.id,
      relatedApplicationId: appId,
    });
  };

  // Save Cloud Resume to Firestore
  const handleSaveCloudResume = async (updated: CloudResume) => {
    const uid = user?.uid || updated.userId;
    const normalized: CloudResume = { ...updated, userId: uid };
    setCloudResume(normalized);

    if (user && auth.currentUser) {
      try {
        await setDoc(doc(db, 'resumes', uid), {
          userId: uid,
          fullName: normalized.fullName.slice(0, 100),
          email: normalized.email.slice(0, 150),
          phone: normalized.phone.slice(0, 40),
          headline: normalized.headline.slice(0, 140),
          summary: normalized.summary.slice(0, 2000),
          skills: normalized.skills.slice(0, 600),
          experience: normalized.experience.slice(0, 2500),
          education: normalized.education.slice(0, 1000),
          portfolioUrl: normalized.portfolioUrl.slice(0, 300),
          updatedAt: serverTimestamp(),
        });
      } catch (err) {
        handleFirestoreError(err, OperationType.WRITE, `resumes/${uid}`);
      }
    }
  };

  // Update Candidate Note on Application
  const handleUpdateCandidateNote = async (appId: string, newNote: string) => {
    setApplications((prev) =>
      prev.map((a) =>
        a.id === appId
          ? { ...a, candidateNotes: newNote, updatedAt: new Date().toISOString() }
          : a
      )
    );
    if (user && auth.currentUser) {
      try {
        await updateDoc(doc(db, 'applications', appId), {
          candidateNotes: newNote.slice(0, 1500),
          updatedAt: serverTimestamp(),
        });
      } catch (err) {
        handleFirestoreError(
          err,
          OperationType.UPDATE,
          `applications/${appId}`
        );
      }
    }
  };

  // Create New Job Offer & Trigger New Publication Push Notification
  const handleCreateJobOffer = async (
    draft: Omit<JobOffer, 'id' | 'createdAt' | 'updatedAt'>
  ) => {
    const nowIso = new Date().toISOString();
    const jobId = `job-${Date.now()}`;
    const recruiterUid = user?.uid || draft.recruiterId;

    const createdJob: JobOffer = {
      ...draft,
      id: jobId,
      recruiterId: recruiterUid,
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    setJobs((prev) => [createdJob, ...prev]);

    if (user && auth.currentUser) {
      try {
        await setDoc(doc(db, 'jobs', jobId), {
          title: createdJob.title.slice(0, 120),
          company: createdJob.company.slice(0, 100),
          locationName: createdJob.locationName.slice(0, 100),
          latitude: createdJob.latitude,
          longitude: createdJob.longitude,
          salaryRange: createdJob.salaryRange.slice(0, 80),
          contractType: createdJob.contractType,
          category: createdJob.category.slice(0, 60),
          description: createdJob.description.slice(0, 2500),
          requirements: createdJob.requirements.slice(0, 1000),
          recruiterId: recruiterUid,
          recruiterName: createdJob.recruiterName.slice(0, 100),
          recruiterEmail: createdJob.recruiterEmail.slice(0, 150),
          status: 'open',
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      } catch (err) {
        handleFirestoreError(err, OperationType.CREATE, `jobs/${jobId}`);
      }
    }

    await triggerPushNotification({
      recipientId: recruiterUid,
      senderId: recruiterUid,
      type: 'new_job',
      title: `Nuova pubblicazione: ${createdJob.title}`,
      body: `${createdJob.company} ha pubblicato una nuova posizione a ${createdJob.locationName} (${createdJob.salaryRange}).`,
      relatedJobId: jobId,
      relatedApplicationId: '',
    });
  };

  // 1-Tap Google Meet + Automatic Gmail Dispatch to Candidate & Recruiter
  const handleScheduleMeetInterview = async (
    app: JobApplication,
    interviewDate: string,
    customMessage: string
  ) => {
    const meetResult = await createGoogleMeetSpace();
    const subject = `[Invito Colloquio Google Meet] ${app.jobTitle} — ${app.company}`;
    const emailBody = `${customMessage}\n\nData e Ora: ${interviewDate}\nLink Videochiamata Google Meet: ${meetResult.meetingUri}\n\nCopia invito inviata a candidato (${app.candidateEmail}) e recruiter (${app.recruiterEmail}).`;

    // Send email to candidate and recruiter
    const mailCandidate = await sendGmailMessage(
      app.candidateEmail,
      subject,
      emailBody
    );
    await sendGmailMessage(app.recruiterEmail, subject, emailBody);

    const nowIso = new Date().toISOString();
    setApplications((prev) =>
      prev.map((a) =>
        a.id === app.id
          ? {
              ...a,
              status: 'interview_scheduled',
              employerResponse: customMessage,
              meetLink: meetResult.meetingUri,
              interviewDate,
              updatedAt: nowIso,
            }
          : a
      )
    );

    setEmailLogs((prev) => [
      {
        id: `mail-${Date.now()}`,
        to: app.candidateEmail,
        cc: app.recruiterEmail,
        subject,
        body: emailBody,
        triggerType: 'interview_meet',
        sentViaGmailApi: mailCandidate.sentViaApi,
        meetLink: meetResult.meetingUri,
        timestamp: nowIso,
      },
      ...prev,
    ]);

    await triggerPushNotification({
      recipientId: app.candidateId,
      senderId: user?.uid || app.recruiterId,
      type: 'interview_meet',
      title: `Colloquio Google Meet Fissato: ${app.jobTitle}`,
      body: `${app.company} ti ha invitato a un colloquio il ${interviewDate}. Link Meet: ${meetResult.meetingUri}`,
      relatedJobId: app.jobId,
      relatedApplicationId: app.id,
    });
  };

  // Mandatory Employer Response: Accept or Reject Candidate
  const handleUpdateApplicationDecision = async (
    app: JobApplication,
    decision: 'accepted' | 'rejected',
    employerResponse: string
  ) => {
    const nowIso = new Date().toISOString();
    const subject =
      decision === 'accepted'
        ? `[Esito Positivo Selezione] ${app.jobTitle} — ${app.company}`
        : `[Riscontro Selezione] ${app.jobTitle} — ${app.company}`;

    const mailRes = await sendGmailMessage(
      app.candidateEmail,
      subject,
      employerResponse
    );

    setApplications((prev) =>
      prev.map((a) =>
        a.id === app.id
          ? {
              ...a,
              status: decision,
              employerResponse,
              updatedAt: nowIso,
            }
          : a
      )
    );

    setEmailLogs((prev) => [
      {
        id: `mail-${Date.now()}`,
        to: app.candidateEmail,
        cc: app.recruiterEmail,
        subject,
        body: employerResponse,
        triggerType:
          decision === 'accepted' ? 'candidate_accepted' : 'candidate_rejected',
        sentViaGmailApi: mailRes.sentViaApi,
        timestamp: nowIso,
      },
      ...prev,
    ]);

    await triggerPushNotification({
      recipientId: app.candidateId,
      senderId: user?.uid || app.recruiterId,
      type: 'status_update',
      title:
        decision === 'accepted'
          ? `Assunzione Confermata: ${app.jobTitle} (${app.company})`
          : `Risposta dal Recruiter: ${app.jobTitle} (${app.company})`,
      body: employerResponse,
      relatedJobId: app.jobId,
      relatedApplicationId: app.id,
    });
  };

  // Position Closed Broadcast to ALL Active Applicants
  const handleCloseJobPosition = async (
    job: JobOffer,
    closureReason: string
  ) => {
    const nowIso = new Date().toISOString();
    const broadcasts = buildMandatoryClosureBroadcasts(
      job,
      applications,
      closureReason
    );

    setJobs((prev) =>
      prev.map((j) =>
        j.id === job.id ? { ...j, status: 'closed', updatedAt: nowIso } : j
      )
    );

    const affectedIds = new Set(broadcasts.map((b) => b.applicationId));
    setApplications((prev) =>
      prev.map((a) => {
        if (!affectedIds.has(a.id)) return a;
        const b = broadcasts.find((x) => x.applicationId === a.id)!;
        return {
          ...a,
          status: 'position_closed',
          employerResponse: b.employerResponse,
          updatedAt: nowIso,
        };
      })
    );

    for (const b of broadcasts) {
      const mailRes = await sendGmailMessage(
        b.candidateEmail,
        b.emailSubject,
        b.emailBody
      );
      setEmailLogs((prev) => [
        {
          id: `mail-${Date.now()}-${b.applicationId}`,
          to: b.candidateEmail,
          subject: b.emailSubject,
          body: b.emailBody,
          triggerType: 'position_closed',
          sentViaGmailApi: mailRes.sentViaApi,
          timestamp: nowIso,
        },
        ...prev,
      ]);

      await triggerPushNotification({
        recipientId: b.candidateId,
        senderId: user?.uid || job.recruiterId,
        type: 'position_closed',
        title: b.notificationTitle,
        body: b.notificationBody,
        relatedJobId: job.id,
        relatedApplicationId: b.applicationId,
      });
    }
  };

  // Save Centralized Post-Interview Feedback
  const handleSaveFeedback = async (
    draft: Omit<InterviewFeedback, 'id' | 'createdAt' | 'updatedAt'>
  ) => {
    const nowIso = new Date().toISOString();
    const fbId = `fb-${Date.now()}`;
    const fullFb: InterviewFeedback = {
      ...draft,
      id: fbId,
      createdAt: nowIso,
      updatedAt: nowIso,
    };

    setFeedbacks((prev) => [fullFb, ...prev]);

    await triggerPushNotification({
      recipientId: draft.candidateId,
      senderId: user?.uid || draft.recruiterId,
      type: 'feedback_shared',
      title: `Nuovo Feedback Post-Colloquio: ${draft.jobTitle}`,
      body: `Valutazione: ${draft.overallRating}/5 — "${draft.sharedSummaryForCandidate}"`,
      relatedJobId: draft.jobId,
      relatedApplicationId: draft.applicationId,
    });
  };

  const filteredJobs = filterJobsByCriteria(jobs, {
    query: searchQuery,
    category: selectedCategory,
    contractType: selectedContract,
    userLat: userLocation.latitude,
    userLon: userLocation.longitude,
    maxDistanceKm,
    includeClosed: false,
  });

  const unreadNotifCount = notifications.filter((n) => !n.isRead).length;

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-slate-900">
      {/* Strict 3-Zone Top Bar Contract */}
      <header className="flex items-center justify-between gap-8 px-6 py-4 bg-white border-b border-slate-200 sticky top-0 z-30">
        {/* Zone 1: Single text element wordmark */}
        <a
          href="#jobs"
          onClick={(e) => {
            e.preventDefault();
            setActiveTab('jobs');
          }}
          className="text-xl font-bold tracking-tight text-slate-900 whitespace-nowrap shrink-0"
        >
          FindMyJob
        </a>

        {/* Zone 2: 5 concise single-line navigation links */}
        <nav
          aria-label="Navigazione principale"
          className="hidden md:flex items-center gap-6 text-sm font-medium text-slate-600"
        >
          <a
            href="#jobs"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('jobs');
            }}
            className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 ${
              activeTab === 'jobs'
                ? 'text-slate-900 underline underline-offset-8 decoration-2 decoration-blue-600 font-semibold'
                : ''
            }`}
          >
            Annunci
          </a>
          <a
            href="#map"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('map');
            }}
            className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 ${
              activeTab === 'map'
                ? 'text-slate-900 underline underline-offset-8 decoration-2 decoration-blue-600 font-semibold'
                : ''
            }`}
          >
            Mappa
          </a>
          <a
            href="#applications"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('applications');
            }}
            className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 ${
              activeTab === 'applications'
                ? 'text-slate-900 underline underline-offset-8 decoration-2 decoration-blue-600 font-semibold'
                : ''
            }`}
          >
            Candidature
          </a>
          <a
            href="#recruiter"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('recruiter');
            }}
            className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 ${
              activeTab === 'recruiter'
                ? 'text-slate-900 underline underline-offset-8 decoration-2 decoration-blue-600 font-semibold'
                : ''
            }`}
          >
            Recruiter
          </a>
          <a
            href="#analytics"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('analytics');
            }}
            className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 ${
              activeTab === 'analytics'
                ? 'text-slate-900 underline underline-offset-8 decoration-2 decoration-blue-600 font-semibold'
                : ''
            }`}
          >
            Analisi
          </a>
        </nav>

        {/* Zone 3: 1 primary action (Sign in with Google / Account Action) */}
        <div className="flex items-center gap-3 shrink-0">
          {user ? (
            <button
              type="button"
              onClick={logout}
              className="px-4 py-2 text-xs font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors whitespace-nowrap shrink-0"
            >
              Esci ({user.displayName?.split(' ')[0] || 'Account'})
            </button>
          ) : (
            <button
              type="button"
              onClick={handleGoogleLogin}
              disabled={isLoggingIn}
              className="gsi-material-button inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-slate-800 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 shadow-2xs transition-colors whitespace-nowrap shrink-0"
            >
              <svg
                version="1.1"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 48 48"
                className="h-4 w-4 block"
              >
                <path
                  fill="#EA4335"
                  d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
                ></path>
                <path
                  fill="#4285F4"
                  d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
                ></path>
                <path
                  fill="#FBBC05"
                  d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
                ></path>
                <path
                  fill="#34A853"
                  d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
                ></path>
              </svg>
              <span>
                {isLoggingIn ? 'Accesso...' : 'Sign in with Google'}
              </span>
            </button>
          )}
        </div>
      </header>

      {/* Workspace Sub-Toolbar (Mobile Navigation + Feedback Hub + Push Notification Center) */}
      <div className="bg-slate-900 text-white px-6 py-2.5">
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-4">
          {/* Mobile & Extended View Switcher */}
          <div className="flex items-center gap-2 overflow-x-auto py-0.5">
            <button
              type="button"
              onClick={() => setActiveTab('jobs')}
              className={`md:hidden px-2.5 py-1 text-xs rounded-md whitespace-nowrap shrink-0 ${
                activeTab === 'jobs' ? 'bg-blue-600 text-white' : 'text-slate-300'
              }`}
            >
              Annunci
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('map')}
              className={`md:hidden px-2.5 py-1 text-xs rounded-md whitespace-nowrap shrink-0 ${
                activeTab === 'map' ? 'bg-blue-600 text-white' : 'text-slate-300'
              }`}
            >
              Mappa
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('applications')}
              className={`md:hidden px-2.5 py-1 text-xs rounded-md whitespace-nowrap shrink-0 ${
                activeTab === 'applications'
                  ? 'bg-blue-600 text-white'
                  : 'text-slate-300'
              }`}
            >
              Candidature
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('recruiter')}
              className={`md:hidden px-2.5 py-1 text-xs rounded-md whitespace-nowrap shrink-0 ${
                activeTab === 'recruiter'
                  ? 'bg-blue-600 text-white'
                  : 'text-slate-300'
              }`}
            >
              Recruiter
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('analytics')}
              className={`md:hidden px-2.5 py-1 text-xs rounded-md whitespace-nowrap shrink-0 ${
                activeTab === 'analytics'
                  ? 'bg-blue-600 text-white'
                  : 'text-slate-300'
              }`}
            >
              Analisi
            </button>

            <span className="hidden md:inline text-xs text-slate-400">
              Firestore Project: <strong className="text-white font-mono">findmyjob-510711</strong> ·{' '}
              {oauthToken ? 'Gmail & Google Meet Connessi' : 'Modalità Interattiva Pronta'}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setActiveTab('flutter')}
              className={`inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                activeTab === 'flutter'
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-800 text-blue-300 hover:bg-slate-700'
              }`}
            >
              <Code2 className="h-3.5 w-3.5" />
              <span>Codice Flutter / Dart (7 file)</span>
            </button>

            <button
              type="button"
              onClick={() => setIsFlutterMobileFrame((v) => !v)}
              className={`inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                isFlutterMobileFrame
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-800 text-slate-200 hover:bg-slate-700'
              }`}
            >
              <Smartphone className="h-3.5 w-3.5" />
              <span>{isFlutterMobileFrame ? 'Vista Desktop' : 'Vista Mobile Flutter'}</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('feedback')}
              className={`inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                activeTab === 'feedback'
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-800 text-slate-200 hover:bg-slate-700'
              }`}
            >
              <ClipboardCheck className="h-3.5 w-3.5" />
              <span>Feedback Post-Colloquio ({feedbacks.length})</span>
            </button>

            <button
              type="button"
              onClick={() => setShowPushCenter((v) => !v)}
              aria-label="Apri Centro Notifiche Push"
              className="inline-flex items-center gap-1.5 px-3 py-1 text-xs font-medium bg-slate-800 hover:bg-slate-700 text-white rounded-md transition-colors whitespace-nowrap shrink-0"
            >
              <Bell className="h-3.5 w-3.5 text-blue-400" />
              <span>Notifiche Push</span>
              <span className="font-mono tabular-nums font-bold text-blue-400">
                ({unreadNotifCount})
              </span>
            </button>
          </div>
        </div>
      </div>

      {/* Live Push Notification Toast Banner */}
      {activePushBanner && (
        <div
          role="status"
          className="bg-blue-950 text-white px-6 py-3 border-b border-blue-800"
        >
          <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
            <div className="flex items-center gap-3 text-xs">
              <Bell className="h-4 w-4 text-blue-400 shrink-0" />
              <div>
                <span className="font-bold">{activePushBanner.title}</span>
                <span aria-hidden="true"> — </span>
                <span className="text-blue-100">{activePushBanner.body}</span>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setActivePushBanner(null)}
              aria-label="Chiudi avviso notifica push"
              className="text-blue-200 hover:text-white p-1"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}

      {/* Push Notifications Slide-Down Panel */}
      {showPushCenter && (
        <div className="bg-white border-b border-slate-200 shadow-md px-6 py-5">
          <div className="max-w-7xl mx-auto space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="text-sm font-bold text-slate-900">
                  Centro Notifiche Push Personalizzate (Nuovi Annunci, Esiti, Colloqui Meet)
                </h3>
                <p className="text-xs text-slate-500">
                  Ricevi avvisi istantanei su nuove offerte vicine, stati candidatura e chiusura posizioni
                </p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleEnableBrowserPush}
                  className="px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 border border-blue-200 rounded-lg hover:bg-blue-100"
                >
                  {browserPushEnabled
                    ? 'Notifiche Push Browser Attive'
                    : 'Attiva Notifiche Push Browser'}
                </button>
                <button
                  type="button"
                  onClick={() =>
                    setNotifications((prev) =>
                      prev.map((n) => ({ ...n, isRead: true }))
                    )
                  }
                  className="px-3 py-1.5 text-xs font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200"
                >
                  Segna tutte come lette
                </button>
                <button
                  type="button"
                  onClick={() => setShowPushCenter(false)}
                  aria-label="Chiudi pannello notifiche"
                  className="p-1.5 text-slate-500 hover:text-slate-900"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 max-h-60 overflow-y-auto">
              {notifications.map((n) => (
                <div
                  key={n.id}
                  onClick={() =>
                    setNotifications((prev) =>
                      prev.map((x) =>
                        x.id === n.id ? { ...x, isRead: true } : x
                      )
                    )
                  }
                  className={`rounded-lg border p-3 text-xs cursor-pointer transition-colors ${
                    n.isRead
                      ? 'border-slate-200 bg-slate-50 text-slate-600'
                      : 'border-blue-300 bg-blue-50/40 text-slate-900'
                  }`}
                >
                  <div className="flex items-center justify-between font-semibold">
                    <span>{n.title}</span>
                    <span className="font-mono tabular-nums text-[11px] text-slate-400">
                      {new Date(n.createdAt).toLocaleTimeString('it-IT', {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </span>
                  </div>
                  <p className="mt-1 text-slate-600">{n.body}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Main Content Container */}
      <main
        className={`flex-1 w-full mx-auto px-6 py-8 transition-all ${
          isFlutterMobileFrame
            ? 'max-w-[460px] border-x border-slate-300 bg-white shadow-lg my-4 rounded-2xl'
            : 'max-w-7xl'
        }`}
      >
        {activeTab === 'jobs' && (
          <div className="space-y-8">
            {/* Hero & Search Filter Bar */}
            <div className="rounded-xl border border-slate-200 bg-white p-6 space-y-5">
              <div className="flex flex-col lg:flex-row lg:items-end justify-between gap-4">
                <div className="max-w-2xl">
                  <p className="text-xs font-semibold text-blue-600">
                    Candidatura 1-Click · CV Cloud Firestore · Risposta Garantita al 100%
                  </p>
                  <h1 className="text-2xl sm:text-3xl font-bold text-slate-900 mt-1 text-balance">
                    Trova il tuo prossimo lavoro e candidati con un solo clic
                  </h1>
                  <p className="text-sm text-slate-600 mt-1.5">
                    Usa il tuo Curriculum già caricato su Cloud Firestore oppure allega un CV ad hoc per la singola offerta. Ogni datore di lavoro garantisce una risposta ufficiale o l’invito diretto su Google Meet.
                  </p>
                </div>

                <div className="flex items-center gap-3 shrink-0">
                  <button
                    type="button"
                    onClick={() => setActiveTab('map')}
                    className="inline-flex items-center gap-2 px-4 py-2.5 text-xs font-semibold text-slate-800 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors whitespace-nowrap shrink-0"
                  >
                    <MapPin className="h-4 w-4 text-blue-600" />
                    <span>Apri Mappa Interattiva</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setActiveTab('applications')}
                    className="inline-flex items-center gap-2 px-4 py-2.5 text-xs font-semibold text-white bg-slate-900 rounded-lg hover:bg-slate-800 transition-colors whitespace-nowrap shrink-0"
                  >
                    <Briefcase className="h-4 w-4" />
                    <span>Gestisci CV Cloud ({applications.length})</span>
                  </button>
                </div>
              </div>

              {/* Search & Distance Filter Controls */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-12 gap-3 pt-4 border-t border-slate-100 items-end">
                <div className="lg:col-span-4">
                  <label
                    htmlFor="job-board-search"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    Posizione lavorativa, ruolo o azienda
                  </label>
                  <div className="relative">
                    <Search className="h-4 w-4 text-slate-400 absolute left-3 top-2.5" />
                    <input
                      id="job-board-search"
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder="Cerca Flutter, Cloud, Designer, Milano..."
                      className="w-full rounded-lg border border-slate-300 bg-white pl-9 pr-3 py-2 text-sm text-slate-900 focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="lg:col-span-3">
                  <label
                    htmlFor="job-board-city"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    La tua città di riferimento
                  </label>
                  <select
                    id="job-board-city"
                    value={userLocation.name}
                    onChange={(e) => {
                      const found = ITALIAN_CITIES.find(
                        (c) => c.name === e.target.value
                      );
                      if (found) setUserLocation(found);
                    }}
                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900"
                  >
                    {ITALIAN_CITIES.map((c) => (
                      <option key={c.name} value={c.name}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="lg:col-span-2">
                  <label
                    htmlFor="job-board-category"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    Area professionale
                  </label>
                  <select
                    id="job-board-category"
                    value={selectedCategory}
                    onChange={(e) => setSelectedCategory(e.target.value)}
                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900"
                  >
                    <option value="Tutte">Tutte le aree</option>
                    <option value="Mobile & Flutter">Mobile & Flutter</option>
                    <option value="Cloud & Backend">Cloud & Backend</option>
                    <option value="Design & UX">Design & UX</option>
                    <option value="AI & Data Science">AI & Data Science</option>
                    <option value="Frontend & Web">Frontend & Web</option>
                  </select>
                </div>

                <div className="lg:col-span-3">
                  <div className="flex items-center justify-between text-xs font-semibold text-slate-700 mb-1">
                    <label htmlFor="job-board-distance">Distanza massima</label>
                    <span className="font-mono tabular-nums text-blue-600">
                      {maxDistanceKm >= 800
                        ? 'Tutta Italia'
                        : `${maxDistanceKm} km`}
                    </span>
                  </div>
                  <input
                    id="job-board-distance"
                    type="range"
                    min={15}
                    max={800}
                    step={15}
                    value={maxDistanceKm}
                    onChange={(e) => setMaxDistanceKm(Number(e.target.value))}
                    className="w-full accent-blue-600 cursor-pointer"
                  />
                </div>
              </div>
            </div>

            {/* Contract Filter Tabs */}
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div className="flex items-center gap-1 p-1 bg-slate-200/70 rounded-lg">
                {(['Tutti', 'Full-time', 'Ibrido', 'Remoto'] as const).map(
                  (type) => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setSelectedContract(type)}
                      className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                        selectedContract === type
                          ? 'bg-white text-slate-900 shadow-xs'
                          : 'text-slate-600 hover:text-slate-900'
                      }`}
                    >
                      {type === 'Tutti' ? 'Tutti i contratti' : type}
                    </button>
                  )
                )}
              </div>

              <div className="text-xs text-slate-500 font-mono tabular-nums">
                {filteredJobs.length} offerte disponibili ordinate per distanza da{' '}
                {userLocation.name.split(',')[0]}
              </div>
            </div>

            {/* Job Listings Grid */}
            {filteredJobs.length === 0 ? (
              <div className="rounded-xl border border-slate-200 bg-white p-10 text-center space-y-3">
                <p className="text-base font-bold text-slate-900">
                  Nessuna posizione trovata con i filtri attuali
                </p>
                <p className="text-xs text-slate-500">
                  Prova ad ampliare la distanza massima o reimpostare la ricerca per ruolo.
                </p>
                <button
                  type="button"
                  onClick={() => {
                    setSearchQuery('');
                    setSelectedCategory('Tutte');
                    setSelectedContract('Tutti');
                    setMaxDistanceKm(800);
                  }}
                  className="px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700"
                >
                  Reimposta tutti i filtri
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {filteredJobs.map((job) => {
                  const currentCandidateId = user?.uid || cloudResume.userId;
                  const existingApp = applications.find(
                    (a) =>
                      a.jobId === job.id && a.candidateId === currentCandidateId
                  );

                  return (
                    <article
                      key={job.id}
                      className="rounded-xl border border-slate-200 bg-white p-6 flex flex-col justify-between space-y-4 hover:border-slate-300 transition-colors"
                    >
                      <div className="space-y-2.5">
                        {/* Unboxed Metadata Line (Zero-Pill Discipline) */}
                        <div className="flex items-center justify-between text-xs text-slate-500">
                          <div>
                            <span className="font-medium text-slate-700">
                              {job.category}
                            </span>
                            <span aria-hidden="true"> · </span>
                            <span>{job.contractType}</span>
                          </div>
                          <span className="font-mono tabular-nums font-semibold text-blue-600">
                            {job.distanceKm} km da te
                          </span>
                        </div>

                        <h2 className="text-lg font-bold text-slate-900">
                          {job.title}
                        </h2>

                        <div className="text-xs text-slate-600">
                          <span className="font-semibold text-slate-800">
                            {job.company}
                          </span>
                          <span aria-hidden="true"> · </span>
                          <span>{job.locationName}</span>
                          <span aria-hidden="true"> · </span>
                          <span className="font-mono tabular-nums font-semibold text-slate-900">
                            {job.salaryRange}
                          </span>
                        </div>

                        <p className="text-xs text-slate-600 leading-relaxed line-clamp-3">
                          {job.description}
                        </p>

                        <p className="text-xs text-slate-500 pt-1">
                          <span className="font-semibold text-slate-700">
                            Competenze richieste:{' '}
                          </span>
                          {job.requirements}
                        </p>
                      </div>

                      <div className="flex items-center justify-between pt-4 border-t border-slate-100">
                        <span className="text-xs text-slate-500">
                          Recruiter: {job.recruiterName}
                        </span>

                        {existingApp ? (
                          <button
                            type="button"
                            aria-label={`Vedi stato candidatura per ${job.title}`}
                            onClick={() => setActiveTab('applications')}
                            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors whitespace-nowrap shrink-0"
                          >
                            <CheckCircle2 className="h-3.5 w-3.5" />
                            <span>Candidatura Inviata (Vedi Stato)</span>
                          </button>
                        ) : (
                          <button
                            type="button"
                            aria-label={`Candidati con 1 Clic per ${job.title}`}
                            onClick={() => setApplyingJob(job)}
                            className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors whitespace-nowrap shrink-0"
                          >
                            <Send className="h-3.5 w-3.5" />
                            <span>Candidati con 1 Clic</span>
                          </button>
                        )}
                      </div>
                    </article>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {activeTab === 'map' && (
          <InteractiveMapView
            jobs={jobs}
            applications={applications}
            userLocation={userLocation}
            onChangeUserLocation={setUserLocation}
            maxDistanceKm={maxDistanceKm}
            onChangeMaxDistanceKm={setMaxDistanceKm}
            searchQuery={searchQuery}
            onChangeSearchQuery={setSearchQuery}
            onOpenApplyModal={(job) => setApplyingJob(job)}
          />
        )}

        {activeTab === 'applications' && (
          <CandidateHubView
            applications={applications}
            feedbacks={feedbacks}
            cloudResume={cloudResume}
            onSaveCloudResume={handleSaveCloudResume}
            onUpdateCandidateNote={handleUpdateCandidateNote}
          />
        )}

        {activeTab === 'recruiter' && (
          <RecruiterAtsView
            jobs={jobs}
            applications={applications}
            onCreateJobOffer={handleCreateJobOffer}
            onScheduleMeetInterview={handleScheduleMeetInterview}
            onUpdateApplicationDecision={handleUpdateApplicationDecision}
            onCloseJobPosition={handleCloseJobPosition}
            onOpenFeedbackForApp={(appId) => {
              setPreselectedFeedbackAppId(appId);
              setActiveTab('feedback');
            }}
          />
        )}

        {activeTab === 'feedback' && (
          <FeedbackHubView
            applications={applications}
            feedbacks={feedbacks}
            preselectedApplicationId={preselectedFeedbackAppId}
            onSaveFeedback={handleSaveFeedback}
          />
        )}

        {activeTab === 'analytics' && (
          <AnalyticsDashboardView
            jobs={jobs}
            applications={applications}
            feedbacks={feedbacks}
            emailLogs={emailLogs}
          />
        )}

        {activeTab === 'flutter' && (
          <FlutterCodeExplorerView
            isFlutterMobileFrame={isFlutterMobileFrame}
            onToggleFlutterMobileFrame={() =>
              setIsFlutterMobileFrame((v) => !v)
            }
          />
        )}
      </main>

      {/* Quiet Footer */}
      <footer className="border-t border-slate-200 bg-white px-6 py-4 text-xs text-slate-500">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-2">
          <span>
            FindMyJob — Piattaforma di Ricerca Lavoro 1-Click & ATS Recruiting
          </span>
          <span>
            Cloud Firestore Project: <span className="font-mono">findmyjob-510711</span> · Google Meet & Gmail Integration
          </span>
        </div>
      </footer>

      {/* 1-Click Apply Modal */}
      {applyingJob && (
        <OneClickApplyModal
          job={applyingJob}
          cloudResume={cloudResume}
          onClose={() => setApplyingJob(null)}
          onSubmitApplication={handleOneClickApply}
        />
      )}
    </div>
  );
}
