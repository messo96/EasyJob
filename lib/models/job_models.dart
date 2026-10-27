import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class JobOffer {
  final String id;
  final String title;
  final String company;
  final String locationName;
  final double latitude;
  final double longitude;
  final String salaryRange;
  final String contractType;
  final String category;
  final String description;
  final String requirements;
  final String recruiterId;
  final String recruiterName;
  final String recruiterEmail;
  final String status; // 'open' | 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.salaryRange,
    required this.contractType,
    required this.category,
    required this.description,
    required this.requirements,
    required this.recruiterId,
    required this.recruiterName,
    required this.recruiterEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  double distanceFromKm(double userLat, double userLon) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(latitude - userLat);
    final double dLon = _degToRad(longitude - userLon);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(userLat)) *
            math.cos(_degToRad(latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return ((earthRadiusKm * c) * 10).roundToDouble() / 10;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  factory JobOffer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JobOffer(
      id: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      locationName: data['locationName'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 45.4642,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 9.1900,
      salaryRange: data['salaryRange'] ?? '',
      contractType: data['contractType'] ?? 'Full-time',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      requirements: data['requirements'] ?? '',
      recruiterId: data['recruiterId'] ?? '',
      recruiterName: data['recruiterName'] ?? '',
      recruiterEmail: data['recruiterEmail'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreCreateMap() {
    return {
      'title': title,
      'company': company,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'salaryRange': salaryRange,
      'contractType': contractType,
      'category': category,
      'description': description,
      'requirements': requirements,
      'recruiterId': recruiterId,
      'recruiterName': recruiterName,
      'recruiterEmail': recruiterEmail,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class CloudResume {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String headline;
  final String summary;
  final String skills;
  final String experience;
  final String education;
  final String portfolioUrl;
  final DateTime updatedAt;

  const CloudResume({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.headline,
    required this.summary,
    required this.skills,
    required this.experience,
    required this.education,
    required this.portfolioUrl,
    required this.updatedAt,
  });

  factory CloudResume.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CloudResume(
      userId: data['userId'] ?? doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      headline: data['headline'] ?? '',
      summary: data['summary'] ?? '',
      skills: data['skills'] ?? '',
      experience: data['experience'] ?? '',
      education: data['education'] ?? '',
      portfolioUrl: data['portfolioUrl'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'headline': headline,
      'summary': summary,
      'skills': skills,
      'experience': experience,
      'education': education,
      'portfolioUrl': portfolioUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final String recruiterId;
  final String recruiterEmail;
  final String cvSource; // 'cloud' | 'custom'
  final String cvTitle;
  final String cvContent;
  final String candidateNotes;
  final String status; // 'in_review' | 'interview_scheduled' | 'accepted' | 'rejected' | 'position_closed'
  final String employerResponse;
  final String meetLink;
  final String interviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    required this.recruiterId,
    required this.recruiterEmail,
    required this.cvSource,
    required this.cvTitle,
    required this.cvContent,
    required this.candidateNotes,
    required this.status,
    required this.employerResponse,
    required this.meetLink,
    required this.interviewDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobApplication.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JobApplication(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      company: data['company'] ?? '',
      candidateId: data['candidateId'] ?? '',
      candidateName: data['candidateName'] ?? '',
      candidateEmail: data['candidateEmail'] ?? '',
      recruiterId: data['recruiterId'] ?? '',
      recruiterEmail: data['recruiterEmail'] ?? '',
      cvSource: data['cvSource'] ?? 'cloud',
      cvTitle: data['cvTitle'] ?? '',
      cvContent: data['cvContent'] ?? '',
      candidateNotes: data['candidateNotes'] ?? '',
      status: data['status'] ?? 'in_review',
      employerResponse: data['employerResponse'] ?? '',
      meetLink: data['meetLink'] ?? '',
      interviewDate: data['interviewDate'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class InterviewFeedback {
  final String id;
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String candidateId;
  final String candidateName;
  final String recruiterId;
  final double technicalScore;
  final double communicationScore;
  final double cultureFitScore;
  final double overallRating;
  final String strengths;
  final String areasForImprovement;
  final String recommendation; // 'strong_hire' | 'hire' | 'hold' | 'no_hire'
  final String sharedSummaryForCandidate;
  final DateTime createdAt;

  const InterviewFeedback({
    required this.id,
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.candidateId,
    required this.candidateName,
    required this.recruiterId,
    required this.technicalScore,
    required this.communicationScore,
    required this.cultureFitScore,
    required this.overallRating,
    required this.strengths,
    required this.areasForImprovement,
    required this.recommendation,
    required this.sharedSummaryForCandidate,
    required this.createdAt,
  });
}
