export type ContractType = 'Full-time' | 'Part-time' | 'Remoto' | 'Ibrido' | 'Freelance';

export type JobStatus = 'open' | 'closed';

export type ApplicationStatus =
  | 'in_review'
  | 'interview_scheduled'
  | 'accepted'
  | 'rejected'
  | 'position_closed';

export type CvSource = 'cloud' | 'custom';

export type HiringRecommendation = 'strong_hire' | 'hire' | 'hold' | 'no_hire';

export type NotificationType =
  | 'new_job'
  | 'application_received'
  | 'status_update'
  | 'interview_meet'
  | 'position_closed'
  | 'feedback_shared';

export interface JobOffer {
  id: string;
  title: string;
  company: string;
  locationName: string;
  latitude: number;
  longitude: number;
  salaryRange: string;
  contractType: ContractType;
  category: string;
  description: string;
  requirements: string;
  recruiterId: string;
  recruiterName: string;
  recruiterEmail: string;
  status: JobStatus;
  createdAt: string;
  updatedAt: string;
  distanceKm?: number;
}

export interface CloudResume {
  userId: string;
  fullName: string;
  email: string;
  phone: string;
  headline: string;
  summary: string;
  skills: string;
  experience: string;
  education: string;
  portfolioUrl: string;
  updatedAt: string;
}

export interface JobApplication {
  id: string;
  jobId: string;
  jobTitle: string;
  company: string;
  candidateId: string;
  candidateName: string;
  candidateEmail: string;
  recruiterId: string;
  recruiterEmail: string;
  cvSource: CvSource;
  cvTitle: string;
  cvContent: string;
  candidateNotes: string;
  status: ApplicationStatus;
  employerResponse: string;
  meetLink: string;
  interviewDate: string;
  createdAt: string;
  updatedAt: string;
}

export interface InterviewFeedback {
  id: string;
  applicationId: string;
  jobId: string;
  jobTitle: string;
  candidateId: string;
  candidateName: string;
  recruiterId: string;
  technicalScore: number;
  communicationScore: number;
  cultureFitScore: number;
  overallRating: number;
  strengths: string;
  areasForImprovement: string;
  recommendation: HiringRecommendation;
  sharedSummaryForCandidate: string;
  createdAt: string;
  updatedAt: string;
}

export interface PushNotification {
  id: string;
  recipientId: string;
  senderId: string;
  type: NotificationType;
  title: string;
  body: string;
  relatedJobId: string;
  relatedApplicationId: string;
  isRead: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AutomatedEmailLog {
  id: string;
  to: string;
  cc?: string;
  subject: string;
  body: string;
  triggerType: 'interview_meet' | 'candidate_accepted' | 'candidate_rejected' | 'position_closed' | 'application_confirmation';
  sentViaGmailApi: boolean;
  meetLink?: string;
  timestamp: string;
}

export interface CityLocation {
  name: string;
  latitude: number;
  longitude: number;
  region: string;
}
