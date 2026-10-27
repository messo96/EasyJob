import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../models/job_models.dart';
import 'workspace_meet_gmail_service.dart';

class FirestoreRecruitingService {
  late final FirebaseFirestore _db;
  final WorkspaceMeetGmailService _workspaceService =
      WorkspaceMeetGmailService();

  FirestoreRecruitingService() {
    try {
      _db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: DefaultFirebaseOptions.firestoreDatabaseId,
      );
    } catch (e) {
      debugPrint('Firestore custom databaseId fallback to default: $e');
      _db = FirebaseFirestore.instance;
    }
  }

  /// Verifica la connessione effettiva a Firestore
  Future<bool> verifyConnection() async {
    try {
      await _db.collection('jobs').limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Firestore connection test: $e');
      return false;
    }
  }

  /// Inizializza gli annunci di default se la collezione è vuota
  Future<void> seedInitialJobsIfEmpty(List<JobOffer> initialJobs) async {
    try {
      final snap = await _db.collection('jobs').limit(1).get();
      if (snap.docs.isEmpty) {
        for (final job in initialJobs) {
          await _db.collection('jobs').doc(job.id).set(job.toFirestoreCreateMap());
        }
      }
    } catch (e) {
      debugPrint('Seed initial jobs note: $e');
    }
  }

  /// Stream in tempo reale di tutti gli annunci di lavoro pubblicati
  Stream<List<JobOffer>> watchJobs() {
    return _db.collection('jobs').snapshots().map(
          (snap) => snap.docs.map((d) => JobOffer.fromFirestore(d)).toList(),
        );
  }

  /// Stream in tempo reale delle candidature inviate
  Stream<List<JobApplication>> watchApplications({String? candidateId}) {
    Query<Map<String, dynamic>> query = _db.collection('applications');
    if (candidateId != null && candidateId.isNotEmpty) {
      query = query.where('candidateId', isEqualTo: candidateId);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => JobApplication.fromFirestore(d)).toList(),
        );
  }

  /// Stream delle notifiche push per l'utente loggato
  Stream<List<String>> watchPushNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => '${d.data()['title']} — ${d.data()['body']}')
            .toList());
  }

  /// Pubblica un nuovo annuncio e invia una notifica push per le nuove pubblicazioni
  Future<void> publishNewJobOffer({
    required JobOffer job,
    required String senderUid,
  }) async {
    final docRef = _db.collection('jobs').doc(job.id);
    await docRef.set(job.toFirestoreCreateMap());

    await sendPushNotification(
      recipientId: senderUid,
      senderId: senderUid,
      type: 'new_job',
      title: 'Nuova pubblicazione: ${job.title}',
      body:
          '${job.company} ha pubblicato "${job.title}" a ${job.locationName} (${job.salaryRange}).',
      relatedJobId: job.id,
      relatedApplicationId: '',
    );
  }

  /// Recupera il Curriculum Cloud su Firestore (`/resumes/{userId}`)
  Future<CloudResume?> getCloudResume(String userId) async {
    try {
      final doc = await _db.collection('resumes').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return CloudResume.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Errore lettura CV Cloud: $e');
    }
    return null;
  }

  /// Salva o aggiorna il Curriculum Cloud su Firestore (`/resumes/{userId}`)
  Future<void> saveCloudResume(CloudResume resume) async {
    await _db
        .collection('resumes')
        .doc(resume.userId)
        .set(resume.toFirestoreMap());
  }

  /// Candidatura rapida con 1 solo clic (usando CV Cloud o CV Ad-Hoc + note candidato)
  Future<void> submitOneClickApplication({
    required JobOffer job,
    required String candidateId,
    required String candidateName,
    required String candidateEmail,
    required String cvSource, // 'cloud' | 'custom'
    required String cvTitle,
    required String cvContent,
    required String candidateNotes,
  }) async {
    final String appId = 'app-${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('applications').doc(appId).set({
      'jobId': job.id,
      'jobTitle': job.title,
      'company': job.company,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'candidateEmail': candidateEmail,
      'recruiterId': job.recruiterId,
      'recruiterEmail': job.recruiterEmail,
      'cvSource': cvSource,
      'cvTitle': cvTitle,
      'cvContent': cvContent,
      'candidateNotes': candidateNotes,
      'status': 'in_review',
      'employerResponse': '',
      'meetLink': '',
      'interviewDate': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await sendPushNotification(
      recipientId: candidateId,
      senderId: candidateId,
      type: 'application_received',
      title: 'Candidatura 1-Click inviata: ${job.title}',
      body:
          'Hai applicato presso ${job.company} con ${cvSource == "cloud" ? "CV Cloud Firestore" : "CV Ad-Hoc"}.',
      relatedJobId: job.id,
      relatedApplicationId: appId,
    );
  }

  /// 1-Tap Colloquio: Crea riunione su Google Meet e invia email automatica
  /// sia al candidato che al recruiter, più notifica push personalizzata.
  Future<String> scheduleOneTapMeetInterview({
    required JobApplication application,
    required String interviewDate,
    required String customMessage,
    required String? oauthAccessToken,
  }) async {
    final String meetUri = await _workspaceService.createGoogleMeetSpace(
      accessToken: oauthAccessToken,
    );

    await _db.collection('applications').doc(application.id).update({
      'status': 'interview_scheduled',
      'employerResponse': customMessage,
      'meetLink': meetUri,
      'interviewDate': interviewDate,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String subject =
        '[Invito Colloquio Google Meet] ${application.jobTitle} — ${application.company}';
    final String emailBody =
        '$customMessage\n\nData Colloquio: $interviewDate\nLink Google Meet: $meetUri';

    // Invio email automatica a candidato e recruiter
    await _workspaceService.sendAutomatedEmail(
      accessToken: oauthAccessToken,
      toEmail: application.candidateEmail,
      subject: subject,
      bodyText: emailBody,
    );
    await _workspaceService.sendAutomatedEmail(
      accessToken: oauthAccessToken,
      toEmail: application.recruiterEmail,
      subject: subject,
      bodyText: emailBody,
    );

    await sendPushNotification(
      recipientId: application.candidateId,
      senderId: application.recruiterId,
      type: 'interview_meet',
      title: 'Colloquio Google Meet fissato: ${application.jobTitle}',
      body: 'Data: $interviewDate · Link Meet: $meetUri',
      relatedJobId: application.jobId,
      relatedApplicationId: application.id,
    );

    return meetUri;
  }

  /// Risposta obbligatoria del datore di lavoro (Assunto o Scartato) con invio mail e notifica push
  Future<void> respondToCandidateApplication({
    required JobApplication application,
    required String decision, // 'accepted' | 'rejected'
    required String employerResponse,
    required String? oauthAccessToken,
  }) async {
    await _db.collection('applications').doc(application.id).update({
      'status': decision,
      'employerResponse': employerResponse,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final String subject = decision == 'accepted'
        ? '[Esito Positivo Selezione] ${application.jobTitle} — ${application.company}'
        : '[Riscontro Selezione] ${application.jobTitle} — ${application.company}';

    await _workspaceService.sendAutomatedEmail(
      accessToken: oauthAccessToken,
      toEmail: application.candidateEmail,
      subject: subject,
      bodyText: employerResponse,
    );

    await sendPushNotification(
      recipientId: application.candidateId,
      senderId: application.recruiterId,
      type: 'status_update',
      title: decision == 'accepted'
          ? 'Candidatura Accettata: ${application.jobTitle}'
          : 'Riscontro dal Recruiter: ${application.jobTitle}',
      body: employerResponse,
      relatedJobId: application.jobId,
      relatedApplicationId: application.id,
    );
  }

  /// Chiude l'annuncio ("non più disponibile") e invia automaticamente una notifica
  /// e un'email a tutte le persone che avevano applicato.
  Future<void> closeJobAndNotifyAllApplicants({
    required JobOffer job,
    required List<JobApplication> allApplicationsForJob,
    required String closureMessage,
    required String? oauthAccessToken,
  }) async {
    await _db.collection('jobs').doc(job.id).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final activeApplicants = allApplicationsForJob.where(
      (a) => a.status == 'in_review' || a.status == 'interview_scheduled',
    );

    for (final app in activeApplicants) {
      await _db.collection('applications').doc(app.id).update({
        'status': 'position_closed',
        'employerResponse': closureMessage,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _workspaceService.sendAutomatedEmail(
        accessToken: oauthAccessToken,
        toEmail: app.candidateEmail,
        subject: '[Posizione Chiusa] ${job.title} — ${job.company}',
        bodyText: closureMessage,
      );

      await sendPushNotification(
        recipientId: app.candidateId,
        senderId: job.recruiterId,
        type: 'position_closed',
        title: 'Posizione non più disponibile: ${job.title}',
        body: closureMessage,
        relatedJobId: job.id,
        relatedApplicationId: app.id,
      );
    }
  }

  /// Registra un feedback post-colloquio centralizzato e avvisa il candidato
  Future<void> savePostInterviewFeedback(InterviewFeedback feedback) async {
    await _db.collection('feedbacks').doc(feedback.id).set({
      'applicationId': feedback.applicationId,
      'jobId': feedback.jobId,
      'jobTitle': feedback.jobTitle,
      'candidateId': feedback.candidateId,
      'candidateName': feedback.candidateName,
      'recruiterId': feedback.recruiterId,
      'technicalScore': feedback.technicalScore,
      'communicationScore': feedback.communicationScore,
      'cultureFitScore': feedback.cultureFitScore,
      'overallRating': feedback.overallRating,
      'strengths': feedback.strengths,
      'areasForImprovement': feedback.areasForImprovement,
      'recommendation': feedback.recommendation,
      'sharedSummaryForCandidate': feedback.sharedSummaryForCandidate,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await sendPushNotification(
      recipientId: feedback.candidateId,
      senderId: feedback.recruiterId,
      type: 'feedback_shared',
      title: 'Feedback Post-Colloquio: ${feedback.jobTitle}',
      body:
          'Valutazione ${feedback.overallRating}/5 — ${feedback.sharedSummaryForCandidate}',
      relatedJobId: feedback.jobId,
      relatedApplicationId: feedback.applicationId,
    );
  }

  /// Crea una notifica push personalizzata su Firestore
  Future<void> sendPushNotification({
    required String recipientId,
    required String senderId,
    required String type,
    required String title,
    required String body,
    required String relatedJobId,
    required String relatedApplicationId,
  }) async {
    final String notifId = 'notif-${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('notifications').doc(notifId).set({
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type,
      'title': title,
      'body': body,
      'relatedJobId': relatedJobId,
      'relatedApplicationId': relatedApplicationId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
