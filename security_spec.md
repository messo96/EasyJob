# Security Specification (`security_spec.md`)

## 1. Data Invariants

1. **Global Default-Deny & Path Hardening**: Every collection not explicitly matched is denied. Every single-document path variable (`{jobId}`, `{userId}`, `{applicationId}`, `{feedbackId}`, `{notificationId}`) must pass `isValidId(id)` (`^[a-zA-Z0-9_\-]+$`, max 128 chars).
2. **Verified Identity Invariant**: All write operations require an authenticated user (`request.auth != null`) with a verified email (`request.auth.token.email_verified == true`).
3. **JobOffer Ownership & Immutability**: A `JobOffer` can only be created when `recruiterId == request.auth.uid` and `createdAt == request.time`. Only the owning `recruiterId` (or admin) can update it, `recruiterId` and `createdAt` are immutable, and once `status == 'closed'` (terminal state), no further updates are permitted by standard users.
4. **CloudResume PII Isolation**: A `CloudResume` document at `/resumes/{userId}` contains PII (`email`, `phone`, `fullName`) and is strictly isolated: `get`, `list`, `create`, `update`, and `delete` are restricted exclusively to `request.auth.uid == userId` (or `isAdmin()`).
5. **JobApplication Relational & Terminal Invariant**: A `JobApplication` can only be created if the referenced `/jobs/$(incoming().jobId)` exists, is currently `'open'`, `candidateId == request.auth.uid`, and `status == 'in_review'`. Reads (`get` and `list`) are strictly bounded to `resource.data.candidateId == request.auth.uid || resource.data.recruiterId == request.auth.uid`. Terminal states (`accepted`, `rejected`, `position_closed`) lock further standard updates.
6. **InterviewFeedback Relational Invariant**: An `InterviewFeedback` record can only be created by the `recruiterId` (`recruiterId == request.auth.uid`) when the referenced `/applications/$(incoming().applicationId)` exists and belongs to `recruiterId`. Reads are restricted to `resource.data.recruiterId == request.auth.uid || resource.data.candidateId == request.auth.uid`.
7. **PushNotification Isolation**: A `PushNotification` can only be created when `senderId == request.auth.uid`. Reads (`get` and `list`) are restricted to `resource.data.recipientId == request.auth.uid || resource.data.senderId == request.auth.uid`. Only the `recipientId` can mark `isRead` via the action-based update gate.

## 2. The "Dirty Dozen" Adversarial Payloads

1. **Payload 1 (Shadow Field Injection on JobOffer)**:
   `{ "title": "Senior Flutter Dev", ..., "isFeatured": true }` -> Rejected by `hasOnly()` key enforcement in `isValidJobOffer`.
2. **Payload 2 (Identity Spoofing on JobOffer Create)**:
   `{ "title": "Backend Engineer", "recruiterId": "victim-uid-999", ... }` -> Rejected because `incoming().recruiterId == request.auth.uid` fails.
3. **Payload 3 (Unverified Email Write Attempt)**:
   Auth token with `email_verified: false` attempting to create a `JobOffer` -> Rejected by `isVerifiedUser()`.
4. **Payload 4 (Cross-User PII Read on CloudResume)**:
   User `attacker-uid` attempting `get(/resumes/victim-uid)` -> Rejected by `isOwner(userId)` check.
5. **Payload 5 (ID Poisoning Attack)**:
   Document ID containing special characters or >128 chars (`/jobs/bad$id!@#`) -> Rejected by `isValidId(jobId)`.
6. **Payload 6 (Denial of Wallet / Oversized String)**:
   `JobOffer` with `description` of 50,000 characters -> Rejected by `data.description.size() <= 2500`.
7. **Payload 7 (Orphaned Application Creation)**:
   Creating `JobApplication` referencing a non-existent `jobId: "ghost-job-1"` -> Rejected by `exists(/databases/$(database)/documents/jobs/$(incoming().jobId))`.
8. **Payload 8 (State Shortcutting on Application Create)**:
   Candidate creates `JobApplication` with `status: "accepted"` -> Rejected because `create` mandates `incoming().status == 'in_review'`.
9. **Payload 9 (Terminal State Mutation)**:
   Attempting to update a `JobApplication` whose existing `status` is `'rejected'` -> Rejected by terminal state lock `!(existing().status in ['accepted', 'rejected', 'position_closed'])`.
10. **Payload 10 (Immortal Field Mutation on Update)**:
    Recruiter updates a `JobApplication` and attempts to alter `candidateId` or `createdAt` -> Rejected by `incoming().candidateId == existing().candidateId && incoming().createdAt == existing().createdAt` and `affectedKeys().hasOnly(...)`.
11. **Payload 11 (Unbounded List Scraping on Applications)**:
    Authenticated user executes unfiltered `list` query on `/applications` -> Rejected because `allow list` requires `resource.data.candidateId == request.auth.uid || resource.data.recruiterId == request.auth.uid`.
12. **Payload 12 (Client Timestamp Forgery)**:
    Creating or updating any document with a past/future `createdAt` or `updatedAt` != `request.time` -> Rejected by `incoming().createdAt == request.time` / `incoming().updatedAt == request.time`.
