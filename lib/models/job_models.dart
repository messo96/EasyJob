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

class CityLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String region;

  const CityLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.region,
  });
}

const List<CityLocation> kItalianCities = [
  CityLocation(name: 'Milano', latitude: 45.4642, longitude: 9.1900, region: 'Lombardia'),
  CityLocation(name: 'Roma', latitude: 41.9028, longitude: 12.4964, region: 'Lazio'),
  CityLocation(name: 'Torino', latitude: 45.0703, longitude: 7.6869, region: 'Piemonte'),
  CityLocation(name: 'Bologna', latitude: 44.4949, longitude: 11.3426, region: 'Emilia-Romagna'),
  CityLocation(name: 'Firenze', latitude: 43.7696, longitude: 11.2558, region: 'Toscana'),
  CityLocation(name: 'Napoli', latitude: 40.8518, longitude: 14.2681, region: 'Campania'),
  CityLocation(name: 'Verona', latitude: 45.4384, longitude: 10.9916, region: 'Veneto'),
  CityLocation(name: 'Genova', latitude: 44.4056, longitude: 8.9463, region: 'Liguria'),
  CityLocation(name: 'Palermo', latitude: 38.1157, longitude: 13.3615, region: 'Sicilia'),
  CityLocation(name: 'Bari', latitude: 41.1171, longitude: 16.8719, region: 'Puglia'),
  CityLocation(name: 'Catania', latitude: 37.5079, longitude: 15.0830, region: 'Sicilia'),
];

class CloudResume {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String birthDate;
  final String locationCity;
  final double userLat;
  final double userLon;
  final String photoUrl;
  final String headline;
  final String summary;
  final String skills;
  final String experience;
  final String education;
  final String portfolioUrl;
  final String role; // 'candidate' | 'recruiter'
  final String cvPdfName;
  final String cvPdfPath;
  final String cvPdfBase64;
  final String cvPdfSize;
  final DateTime updatedAt;

  const CloudResume({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.birthDate = '15/06/1996',
    this.locationCity = 'Milano',
    this.userLat = 45.4642,
    this.userLon = 9.1900,
    this.photoUrl = '',
    this.role = 'candidate',
    this.cvPdfName = '',
    this.cvPdfPath = '',
    this.cvPdfBase64 = '',
    this.cvPdfSize = '',
    this.headline = '',
    this.summary = '',
    this.skills = '',
    this.experience = '',
    this.education = '',
    this.portfolioUrl = '',
    required this.updatedAt,
  });

  CloudResume copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? birthDate,
    String? locationCity,
    double? userLat,
    double? userLon,
    String? photoUrl,
    String? role,
    String? cvPdfName,
    String? cvPdfPath,
    String? cvPdfBase64,
    String? cvPdfSize,
    String? headline,
    String? summary,
    String? skills,
    String? experience,
    String? education,
    String? portfolioUrl,
    DateTime? updatedAt,
  }) {
    return CloudResume(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      locationCity: locationCity ?? this.locationCity,
      userLat: userLat ?? this.userLat,
      userLon: userLon ?? this.userLon,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      cvPdfName: cvPdfName ?? this.cvPdfName,
      cvPdfPath: cvPdfPath ?? this.cvPdfPath,
      cvPdfBase64: cvPdfBase64 ?? this.cvPdfBase64,
      cvPdfSize: cvPdfSize ?? this.cvPdfSize,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CloudResume.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CloudResume(
      userId: data['userId'] ?? doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      birthDate: data['birthDate'] ?? '15/06/1996',
      locationCity: data['locationCity'] ?? 'Milano',
      userLat: (data['userLat'] as num?)?.toDouble() ?? 45.4642,
      userLon: (data['userLon'] as num?)?.toDouble() ?? 9.1900,
      photoUrl: data['photoUrl'] ?? '',
      role: data['role'] ?? 'candidate',
      cvPdfName: data['cvPdfName'] ?? '',
      cvPdfPath: data['cvPdfPath'] ?? '',
      cvPdfBase64: data['cvPdfBase64'] ?? '',
      cvPdfSize: data['cvPdfSize'] ?? '',
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
    // Salvaguardia: se il PDF supera i 650KB in base64, conserviamo i metadata (nome, path, dimensione)
    // su Firestore per restare sempre ben al di sotto del limite rigido di 1MB per documento
    final String safeBase64 = cvPdfBase64.length > 700000 ? '' : cvPdfBase64;
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'birthDate': birthDate,
      'locationCity': locationCity,
      'userLat': userLat,
      'userLon': userLon,
      'photoUrl': photoUrl,
      'role': role,
      'cvPdfName': cvPdfName,
      'cvPdfPath': cvPdfPath,
      'cvPdfBase64': safeBase64,
      'cvPdfSize': cvPdfSize,
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
  final String interviewType; // 'remote' | 'in_person'
  final String interviewLocation;
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
    this.interviewType = 'remote',
    this.interviewLocation = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobApplication.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final meet = data['meetLink'] ?? '';
    final loc = data['interviewLocation'] ?? meet;
    final type = data['interviewType'] ??
        (loc.toString().startsWith('http') ? 'remote' : 'in_person');
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
      meetLink: meet,
      interviewDate: data['interviewDate'] ?? '',
      interviewType: type,
      interviewLocation: loc,
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
