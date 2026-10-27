import {
  ApplicationStatus,
  CloudResume,
  InterviewFeedback,
  JobApplication,
  JobOffer,
} from '../types';

const ID_REGEX = /^[a-zA-Z0-9_\-]+$/;

export function isValidEntityId(id: string): boolean {
  return typeof id === 'string' && id.length >= 1 && id.length <= 128 && ID_REGEX.test(id);
}

/**
 * Calculates great-circle distance between two coordinates in kilometers using the Haversine formula.
 */
export function calculateDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const R = 6371; // Earth radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

export interface JobFilterParams {
  query: string;
  category: string;
  contractType: string;
  userLat: number;
  userLon: number;
  maxDistanceKm: number;
  includeClosed?: boolean;
}

/**
 * Filters job offers by position/role search query, category, contract type, and geographic distance.
 */
export function filterJobsByCriteria(
  jobs: JobOffer[],
  params: JobFilterParams
): JobOffer[] {
  const normalizedQuery = params.query.trim().toLowerCase();

  return jobs
    .map((job) => ({
      ...job,
      distanceKm: calculateDistanceKm(
        params.userLat,
        params.userLon,
        job.latitude,
        job.longitude
      ),
    }))
    .filter((job) => {
      if (!params.includeClosed && job.status === 'closed') {
        return false;
      }
      if (params.category && params.category !== 'Tutte' && job.category !== params.category) {
        return false;
      }
      if (
        params.contractType &&
        params.contractType !== 'Tutti' &&
        job.contractType !== params.contractType
      ) {
        return false;
      }
      if (params.maxDistanceKm > 0 && (job.distanceKm ?? 0) > params.maxDistanceKm) {
        return false;
      }
      if (normalizedQuery) {
        const haystack =
          `${job.title} ${job.company} ${job.locationName} ${job.category} ${job.requirements}`.toLowerCase();
        if (!haystack.includes(normalizedQuery)) {
          return false;
        }
      }
      return true;
    })
    .sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
}

/**
 * Validates JobOffer fields against firebase-blueprint.json volumetric constraints.
 */
export function validateJobOfferInput(data: Partial<JobOffer>): string | null {
  if (!data.title || data.title.trim().length < 2 || data.title.trim().length > 120) {
    return 'Il titolo della posizione deve contenere tra 2 e 120 caratteri.';
  }
  if (!data.company || data.company.trim().length < 2 || data.company.trim().length > 100) {
    return 'Il nome azienda deve contenere tra 2 e 100 caratteri.';
  }
  if (!data.locationName || data.locationName.trim().length < 2 || data.locationName.trim().length > 100) {
    return 'La località deve contenere tra 2 e 100 caratteri.';
  }
  if (typeof data.latitude !== 'number' || data.latitude < -90 || data.latitude > 90) {
    return 'Latitudine non valida.';
  }
  if (typeof data.longitude !== 'number' || data.longitude < -180 || data.longitude > 180) {
    return 'Longitudine non valida.';
  }
  if (!data.salaryRange || data.salaryRange.trim().length < 2 || data.salaryRange.trim().length > 80) {
    return 'La fascia retributiva deve contenere tra 2 e 80 caratteri.';
  }
  if (!data.description || data.description.trim().length < 10 || data.description.trim().length > 2500) {
    return 'La descrizione deve contenere tra 10 e 2500 caratteri.';
  }
  if (!data.requirements || data.requirements.trim().length < 2 || data.requirements.trim().length > 1000) {
    return 'I requisiti devono contenere tra 2 e 1000 caratteri.';
  }
  return null;
}

/**
 * Validates CloudResume fields against firebase-blueprint.json volumetric constraints.
 */
export function validateCloudResumeInput(data: Partial<CloudResume>): string | null {
  if (!data.fullName || data.fullName.trim().length < 2 || data.fullName.trim().length > 100) {
    return 'Il nome completo deve contenere tra 2 e 100 caratteri.';
  }
  if (!data.email || !data.email.includes('@') || data.email.trim().length > 150) {
    return 'Inserisci un indirizzo email valido.';
  }
  if (!data.phone || data.phone.trim().length < 5 || data.phone.trim().length > 40) {
    return 'Inserisci un numero di telefono valido (5-40 caratteri).';
  }
  if (!data.headline || data.headline.trim().length < 2 || data.headline.trim().length > 140) {
    return 'La qualifica professionale deve contenere tra 2 e 140 caratteri.';
  }
  if (!data.summary || data.summary.trim().length < 10 || data.summary.trim().length > 2000) {
    return 'Il profilo professionale deve contenere tra 10 e 2000 caratteri.';
  }
  if (!data.skills || data.skills.trim().length < 2 || data.skills.trim().length > 600) {
    return 'Le competenze devono contenere tra 2 e 600 caratteri.';
  }
  if (!data.experience || data.experience.trim().length < 5 || data.experience.trim().length > 2500) {
    return 'Le esperienze lavorative devono contenere tra 5 e 2500 caratteri.';
  }
  if (!data.education || data.education.trim().length < 2 || data.education.trim().length > 1000) {
    return 'La formazione deve contenere tra 2 e 1000 caratteri.';
  }
  return null;
}

/**
 * Validates Post-Interview Feedback input against firebase-blueprint.json constraints.
 */
export function validateFeedbackInput(data: Partial<InterviewFeedback>): string | null {
  const scores = [
    data.technicalScore,
    data.communicationScore,
    data.cultureFitScore,
    data.overallRating,
  ];
  for (const s of scores) {
    if (typeof s !== 'number' || s < 1 || s > 5) {
      return 'Tutti i punteggi devono essere compresi tra 1 e 5.';
    }
  }
  if (!data.strengths || data.strengths.trim().length < 2 || data.strengths.trim().length > 1200) {
    return 'I punti di forza devono contenere tra 2 e 1200 caratteri.';
  }
  if (
    !data.areasForImprovement ||
    data.areasForImprovement.trim().length < 2 ||
    data.areasForImprovement.trim().length > 1200
  ) {
    return 'Le aree di miglioramento devono contenere tra 2 e 1200 caratteri.';
  }
  if (
    !data.sharedSummaryForCandidate ||
    data.sharedSummaryForCandidate.trim().length < 2 ||
    data.sharedSummaryForCandidate.trim().length > 1200
  ) {
    return 'Il feedback condiviso con il candidato deve contenere tra 2 e 1200 caratteri.';
  }
  return null;
}

export interface ClosureBroadcastAction {
  applicationId: string;
  candidateId: string;
  candidateName: string;
  candidateEmail: string;
  newStatus: ApplicationStatus;
  employerResponse: string;
  notificationTitle: string;
  notificationBody: string;
  emailSubject: string;
  emailBody: string;
}

/**
 * Generates mandatory notifications and status transitions for all active applicants
 * when a job offer is closed ("non più disponibile").
 */
export function buildMandatoryClosureBroadcasts(
  job: Pick<JobOffer, 'id' | 'title' | 'company'>,
  applications: JobApplication[],
  customReason?: string
): ClosureBroadcastAction[] {
  const activeApps = applications.filter(
    (app) =>
      app.jobId === job.id &&
      (app.status === 'in_review' || app.status === 'interview_scheduled')
  );

  const responseText =
    customReason && customReason.trim().length >= 5
      ? customReason.trim().slice(0, 1500)
      : `La posizione "${job.title}" presso ${job.company} non è più disponibile. Ti ringraziamo per il tempo dedicato e conserviamo il tuo CV nel nostro database per future opportunità.`;

  return activeApps.map((app) => ({
    applicationId: app.id,
    candidateId: app.candidateId,
    candidateName: app.candidateName,
    candidateEmail: app.candidateEmail,
    newStatus: 'position_closed',
    employerResponse: responseText,
    notificationTitle: `Posizione chiusa: ${job.title} (${job.company})`,
    notificationBody: responseText,
    emailSubject: `[Aggiornamento Candidatura] ${job.title} — ${job.company}`,
    emailBody: `Gentile ${app.candidateName},\n\nTi scriviamo in merito alla tua candidatura per la posizione di ${job.title} presso ${job.company}.\n\n${responseText}\n\nCordiali saluti,\nTeam Recruiting ${job.company}`,
  }));
}

export interface RecruitingAnalytics {
  totalJobs: number;
  openJobs: number;
  closedJobs: number;
  totalApplications: number;
  inReviewCount: number;
  interviewScheduledCount: number;
  acceptedCount: number;
  rejectedCount: number;
  positionClosedCount: number;
  employerResponseRatePct: number;
  interviewConversionRatePct: number;
  hireRatePct: number;
  averageFeedbackRating: number;
}

export function computeRecruitingAnalytics(
  jobs: JobOffer[],
  applications: JobApplication[],
  feedbacks: InterviewFeedback[]
): RecruitingAnalytics {
  const totalJobs = jobs.length;
  const openJobs = jobs.filter((j) => j.status === 'open').length;
  const closedJobs = jobs.filter((j) => j.status === 'closed').length;
  const totalApplications = applications.length;

  const inReviewCount = applications.filter((a) => a.status === 'in_review').length;
  const interviewScheduledCount = applications.filter(
    (a) => a.status === 'interview_scheduled'
  ).length;
  const acceptedCount = applications.filter((a) => a.status === 'accepted').length;
  const rejectedCount = applications.filter((a) => a.status === 'rejected').length;
  const positionClosedCount = applications.filter((a) => a.status === 'position_closed').length;

  const respondedCount = applications.filter(
    (a) => a.status !== 'in_review' || a.employerResponse.trim().length > 0
  ).length;

  const employerResponseRatePct =
    totalApplications === 0 ? 100 : Math.round((respondedCount / totalApplications) * 100);

  const progressedToInterviewOrHire =
    interviewScheduledCount + acceptedCount;
  const interviewConversionRatePct =
    totalApplications === 0
      ? 0
      : Math.round((progressedToInterviewOrHire / totalApplications) * 100);

  const hireRatePct =
    totalApplications === 0 ? 0 : Math.round((acceptedCount / totalApplications) * 100);

  const averageFeedbackRating =
    feedbacks.length === 0
      ? 0
      : Math.round(
          (feedbacks.reduce((acc, f) => acc + f.overallRating, 0) / feedbacks.length) * 10
        ) / 10;

  return {
    totalJobs,
    openJobs,
    closedJobs,
    totalApplications,
    inReviewCount,
    interviewScheduledCount,
    acceptedCount,
    rejectedCount,
    positionClosedCount,
    employerResponseRatePct,
    interviewConversionRatePct,
    hireRatePct,
    averageFeedbackRating,
  };
}

/**
 * Encodes an RFC 2822 email message into base64url format for the Gmail REST API.
 */
export function encodeGmailRawMessage(to: string, subject: string, bodyText: string): string {
  const utf8Subject = `=?utf-8?B?${btoa(unescape(encodeURIComponent(subject)))}?=`;
  const messageParts = [
    `To: ${to}`,
    'Content-Type: text/plain; charset=utf-8',
    'MIME-Version: 1.0',
    `Subject: ${utf8Subject}`,
    '',
    bodyText,
  ];
  const message = messageParts.join('\r\n');
  const base64 = btoa(unescape(encodeURIComponent(message)));
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
