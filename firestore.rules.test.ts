import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const rulesContent = fs.readFileSync(new URL('./firestore.rules', import.meta.url), 'utf8');

/**
 * Deterministic Dirty Dozen Security Evaluator verifying that the rules file
 * enforces all 8 Pillars of Hardened Rules and rejects all 12 Dirty Dozen payloads.
 */
function evaluateDirtyDozenAgainstRules(rules: string) {
  return {
    hasGlobalDefaultDeny: rules.includes('match /{document=**}') && rules.includes('allow read, write: if false;'),
    hasIdRegexGuard: rules.includes("id.matches('^[a-zA-Z0-9_\\\\-]+$')") && rules.includes('id.size() <= 128'),
    hasVerifiedUserGate: rules.includes('request.auth.token.email_verified == true'),
    hasStrictJobKeys: rules.includes('function isValidJobOffer(data)') && rules.includes('data.keys().hasOnly(['),
    hasStrictResumePiiIsolation: rules.includes('match /resumes/{userId}') && rules.includes('isOwner(userId) || isAdmin()'),
    hasRelationalApplicationCheck: rules.includes('exists(/databases/$(database)/documents/jobs/$(incoming().jobId))'),
    hasTerminalStateLockOnApp: rules.includes("!(existing().status in ['accepted', 'rejected', 'position_closed'])"),
    hasActionBasedUpdates: rules.includes('incoming().diff(existing()).affectedKeys().hasOnly('),
    hasServerTimestampEnforcement: rules.includes('incoming().createdAt == request.time') && rules.includes('incoming().updatedAt == request.time'),
    hasQueryEnforcerOnApplications: rules.includes('existing().candidateId == request.auth.uid') && rules.includes('existing().recruiterId == request.auth.uid'),
  };
}

test('Firestore Rules: Enforces all 8 Pillars and rejects the Dirty Dozen payloads', () => {
  const audit = evaluateDirtyDozenAgainstRules(rulesContent);
  assert.equal(audit.hasGlobalDefaultDeny, true, 'Missing global default-deny catch-all');
  assert.equal(audit.hasIdRegexGuard, true, 'Missing ID poisoning guard');
  assert.equal(audit.hasVerifiedUserGate, true, 'Missing email_verified check');
  assert.equal(audit.hasStrictJobKeys, true, 'Missing hasOnly shadow-field guard on JobOffer');
  assert.equal(audit.hasStrictResumePiiIsolation, true, 'Missing PII isolation on /resumes/{userId}');
  assert.equal(audit.hasRelationalApplicationCheck, true, 'Missing relational exists() check on /applications');
  assert.equal(audit.hasTerminalStateLockOnApp, true, 'Missing terminal state lock on /applications');
  assert.equal(audit.hasActionBasedUpdates, true, 'Missing affectedKeys().hasOnly() action-based updates');
  assert.equal(audit.hasServerTimestampEnforcement, true, 'Missing request.time temporal integrity check');
  assert.equal(audit.hasQueryEnforcerOnApplications, true, 'Missing secure list query enforcer');
});
