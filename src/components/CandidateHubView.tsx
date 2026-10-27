import React, { useState } from 'react';
import {
  CheckCircle2,
  Clock,
  Cloud,
  ExternalLink,
  Save,
  Video,
  XCircle,
} from 'lucide-react';
import {
  ApplicationStatus,
  CloudResume,
  InterviewFeedback,
  JobApplication,
} from '../types';
import { validateCloudResumeInput } from '../utils/recruitingLogic';

interface CandidateHubViewProps {
  applications: JobApplication[];
  feedbacks: InterviewFeedback[];
  cloudResume: CloudResume;
  onSaveCloudResume: (updated: CloudResume) => Promise<void>;
  onUpdateCandidateNote: (applicationId: string, newNote: string) => Promise<void>;
}

const STATUS_LABELS: Record<ApplicationStatus, string> = {
  in_review: 'In Valutazione dal Recruiter',
  interview_scheduled: 'Colloquio Google Meet Pianificato',
  accepted: 'Candidatura Accettata / Assunto',
  rejected: 'Non Selezionato (Feedback Ricevuto)',
  position_closed: 'Posizione Chiusa dal Datore di Lavoro',
};

export const CandidateHubView: React.FC<CandidateHubViewProps> = ({
  applications,
  feedbacks,
  cloudResume,
  onSaveCloudResume,
  onUpdateCandidateNote,
}) => {
  const [resumeDraft, setResumeDraft] = useState<CloudResume>(cloudResume);
  const [resumeSaveMessage, setResumeSaveMessage] = useState<string | null>(null);
  const [resumeError, setResumeError] = useState<string | null>(null);
  const [editingNoteAppId, setEditingNoteAppId] = useState<string | null>(null);
  const [noteDraft, setNoteDraft] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const filteredApps = applications.filter((app) =>
    statusFilter === 'all' ? true : app.status === statusFilter
  );

  const handleResumeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setResumeError(null);
    setResumeSaveMessage(null);

    const validationError = validateCloudResumeInput(resumeDraft);
    if (validationError) {
      setResumeError(validationError);
      return;
    }

    await onSaveCloudResume({
      ...resumeDraft,
      updatedAt: new Date().toISOString(),
    });
    setResumeSaveMessage(
      'Curriculum Cloud salvato e sincronizzato su Firestore (findmyjob-510711).'
    );
  };

  const startEditingNote = (app: JobApplication) => {
    setEditingNoteAppId(app.id);
    setNoteDraft(app.candidateNotes);
  };

  const saveCandidateNote = async (appId: string) => {
    await onUpdateCandidateNote(appId, noteDraft.trim().slice(0, 1500));
    setEditingNoteAppId(null);
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
      {/* Left 7 Cols: Application Status Tracker & Employer Mandatory Responses */}
      <div className="lg:col-span-7 space-y-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-200 pb-4">
          <div>
            <h2 className="text-xl font-bold text-slate-900">
              Stato delle Candidature Inviate
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Monitoraggio in tempo reale con garanzia di risposta obbligatoria da parte del datore di lavoro
            </p>
          </div>

          <div className="flex items-center gap-1 p-1 bg-slate-100 rounded-lg">
            <button
              type="button"
              onClick={() => setStatusFilter('all')}
              className={`px-2.5 py-1.5 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                statusFilter === 'all'
                  ? 'bg-white text-slate-900 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Tutte ({applications.length})
            </button>
            <button
              type="button"
              onClick={() => setStatusFilter('interview_scheduled')}
              className={`px-2.5 py-1.5 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                statusFilter === 'interview_scheduled'
                  ? 'bg-white text-slate-900 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Colloqui Meet
            </button>
            <button
              type="button"
              onClick={() => setStatusFilter('accepted')}
              className={`px-2.5 py-1.5 text-xs font-medium rounded-md transition-colors whitespace-nowrap shrink-0 ${
                statusFilter === 'accepted'
                  ? 'bg-white text-slate-900 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Accettate
            </button>
          </div>
        </div>

        {filteredApps.length === 0 ? (
          <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
            <p className="text-sm font-semibold text-slate-900">
              Nessuna candidatura in questa vista
            </p>
            <p className="text-xs text-slate-500 mt-1">
              Esplora gli annunci o la mappa interattiva per candidarti con un solo clic.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredApps.map((app) => {
              const linkedFeedback = feedbacks.find(
                (f) => f.applicationId === app.id
              );

              return (
                <div
                  key={app.id}
                  className="rounded-xl border border-slate-200 bg-white p-5 space-y-4"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <div>
                      <div className="text-xs text-slate-500">
                        <span>{app.company}</span>
                        <span aria-hidden="true"> · </span>
                        <span>
                          {app.cvSource === 'cloud'
                            ? 'CV Cloud Firestore'
                            : 'CV Ad-Hoc Personalizzato'}
                        </span>
                        <span aria-hidden="true"> · </span>
                        <span className="font-mono tabular-nums">
                          {new Date(app.createdAt).toLocaleDateString('it-IT')}
                        </span>
                      </div>
                      <h3 className="text-base font-bold text-slate-900 mt-0.5">
                        {app.jobTitle}
                      </h3>
                    </div>

                    <div className="flex items-center gap-1.5 text-xs font-semibold">
                      {app.status === 'accepted' && (
                        <span className="inline-flex items-center gap-1 text-emerald-700">
                          <CheckCircle2 className="h-4 w-4" />
                          <span>{STATUS_LABELS[app.status]}</span>
                        </span>
                      )}
                      {app.status === 'interview_scheduled' && (
                        <span className="inline-flex items-center gap-1 text-blue-700">
                          <Video className="h-4 w-4" />
                          <span>{STATUS_LABELS[app.status]}</span>
                        </span>
                      )}
                      {app.status === 'in_review' && (
                        <span className="inline-flex items-center gap-1 text-amber-700">
                          <Clock className="h-4 w-4" />
                          <span>{STATUS_LABELS[app.status]}</span>
                        </span>
                      )}
                      {(app.status === 'rejected' ||
                        app.status === 'position_closed') && (
                        <span className="inline-flex items-center gap-1 text-red-700">
                          <XCircle className="h-4 w-4" />
                          <span>{STATUS_LABELS[app.status]}</span>
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Employer Mandatory Response Box */}
                  <div className="rounded-lg border border-slate-200 bg-slate-50 p-3.5 space-y-2">
                    <div className="text-xs font-semibold text-slate-800">
                      Risposta Ufficiale del Datore di Lavoro / Recruiter:
                    </div>
                    {app.employerResponse ? (
                      <p className="text-xs text-slate-700 leading-relaxed">
                        {app.employerResponse}
                      </p>
                    ) : (
                      <p className="text-xs text-slate-500">
                        In attesa di riscontro: il datore di lavoro è vincolato a inviare una notifica in caso di colloquio, assunzione, scarto o chiusura della posizione.
                      </p>
                    )}

                    {app.meetLink && (
                      <div className="pt-2 flex flex-wrap items-center justify-between gap-2 border-t border-slate-200/80">
                        <div className="text-xs text-slate-700">
                          <span className="font-semibold">Data Colloquio: </span>
                          <span className="font-mono tabular-nums">
                            {app.interviewDate || 'Da concordare'}
                          </span>
                        </div>
                        <a
                          href={app.meetLink}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-600 hover:text-blue-800 underline"
                        >
                          <Video className="h-3.5 w-3.5" />
                          <span>Partecipa su Google Meet</span>
                          <ExternalLink className="h-3 w-3" />
                        </a>
                      </div>
                    )}
                  </div>

                  {/* Candidate Notes & CV Attached */}
                  <div className="space-y-2 text-xs text-slate-600">
                    <div>
                      <span className="font-semibold text-slate-800">
                        Curriculum inviato:{' '}
                      </span>
                      <span>{app.cvTitle}</span>
                    </div>

                    {editingNoteAppId === app.id ? (
                      <div className="space-y-2 pt-1">
                        <label
                          htmlFor={`edit-note-${app.id}`}
                          className="block text-xs font-semibold text-slate-700"
                        >
                          Aggiorna le tue note aggiuntive per il recruiter
                        </label>
                        <textarea
                          id={`edit-note-${app.id}`}
                          rows={2}
                          value={noteDraft}
                          onChange={(e) => setNoteDraft(e.target.value)}
                          className="w-full rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs text-slate-900"
                        />
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            onClick={() => saveCandidateNote(app.id)}
                            className="px-3 py-1.5 text-xs font-semibold text-white bg-blue-600 rounded-md hover:bg-blue-700"
                          >
                            Salva Nota
                          </button>
                          <button
                            type="button"
                            onClick={() => setEditingNoteAppId(null)}
                            className="px-3 py-1.5 text-xs font-medium text-slate-600 bg-slate-100 rounded-md hover:bg-slate-200"
                          >
                            Annulla
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex items-start justify-between gap-4">
                        <div>
                          <span className="font-semibold text-slate-800">
                            Tue Note Aggiuntive:{' '}
                          </span>
                          <span>
                            {app.candidateNotes || 'Nessuna nota aggiuntiva inserita.'}
                          </span>
                        </div>
                        {app.status === 'in_review' && (
                          <button
                            type="button"
                            onClick={() => startEditingNote(app)}
                            className="text-xs font-medium text-blue-600 hover:text-blue-800 underline shrink-0"
                          >
                            Modifica nota
                          </button>
                        )}
                      </div>
                    )}
                  </div>

                  {/* Post-Interview Feedback shared with Candidate */}
                  {linkedFeedback && (
                    <div className="rounded-lg border border-blue-200 bg-blue-50/50 p-3.5 space-y-1">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-semibold text-slate-900">
                          Feedback Post-Colloquio Condiviso
                        </span>
                        <span className="font-mono tabular-nums font-semibold text-blue-700">
                          Valutazione: {linkedFeedback.overallRating}/5
                        </span>
                      </div>
                      <p className="text-xs text-slate-700">
                        {linkedFeedback.sharedSummaryForCandidate}
                      </p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Right 5 Cols: Cloud CV Editor stored in Firestore */}
      <div className="lg:col-span-5 rounded-xl border border-slate-200 bg-white p-6 space-y-4">
        <div className="flex items-center justify-between border-b border-slate-200 pb-3">
          <div className="flex items-center gap-2">
            <Cloud className="h-5 w-5 text-blue-600" />
            <div>
              <h2 className="text-base font-bold text-slate-900">
                Il Tuo Curriculum Cloud (Firestore)
              </h2>
              <p className="text-xs text-slate-500">
                Pronto per le candidature con 1 solo clic · ID: findmyjob-510711
              </p>
            </div>
          </div>
        </div>

        <form onSubmit={handleResumeSubmit} className="space-y-3.5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label
                htmlFor="cv-fullname"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Nome e Cognome
              </label>
              <input
                id="cv-fullname"
                type="text"
                value={resumeDraft.fullName}
                onChange={(e) =>
                  setResumeDraft({ ...resumeDraft, fullName: e.target.value })
                }
                className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-900"
                required
              />
            </div>
            <div>
              <label
                htmlFor="cv-phone"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Telefono
              </label>
              <input
                id="cv-phone"
                type="text"
                value={resumeDraft.phone}
                onChange={(e) =>
                  setResumeDraft({ ...resumeDraft, phone: e.target.value })
                }
                className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-900 font-mono tabular-nums"
                required
              />
            </div>
          </div>

          <div>
            <label
              htmlFor="cv-headline"
              className="block text-xs font-semibold text-slate-700 mb-1"
            >
              Qualifica / Ruolo Principale
            </label>
            <input
              id="cv-headline"
              type="text"
              value={resumeDraft.headline}
              onChange={(e) =>
                setResumeDraft({ ...resumeDraft, headline: e.target.value })
              }
              className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-900"
              required
            />
          </div>

          <div>
            <label
              htmlFor="cv-summary"
              className="block text-xs font-semibold text-slate-700 mb-1"
            >
              Profilo Professionale
            </label>
            <textarea
              id="cv-summary"
              rows={3}
              value={resumeDraft.summary}
              onChange={(e) =>
                setResumeDraft({ ...resumeDraft, summary: e.target.value })
              }
              className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-900"
              required
            />
          </div>

          <div>
            <label
              htmlFor="cv-skills"
              className="block text-xs font-semibold text-slate-700 mb-1"
            >
              Competenze Tecniche & Soft Skills
            </label>
            <input
              id="cv-skills"
              type="text"
              value={resumeDraft.skills}
              onChange={(e) =>
                setResumeDraft({ ...resumeDraft, skills: e.target.value })
              }
              className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-900"
              required
            />
          </div>

          <div>
            <label
              htmlFor="cv-experience"
              className="block text-xs font-semibold text-slate-700 mb-1"
            >
              Esperienze Lavorative Principali
            </label>
            <textarea
              id="cv-experience"
              rows={4}
              value={resumeDraft.experience}
              onChange={(e) =>
                setResumeDraft({ ...resumeDraft, experience: e.target.value })
              }
              className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-900"
              required
            />
          </div>

          <div>
            <label
              htmlFor="cv-education"
              className="block text-xs font-semibold text-slate-700 mb-1"
            >
              Formazione & Certificazioni
            </label>
            <input
              id="cv-education"
              type="text"
              value={resumeDraft.education}
              onChange={(e) =>
                setResumeDraft({ ...resumeDraft, education: e.target.value })
              }
              className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs text-slate-900"
              required
            />
          </div>

          {resumeError && (
            <p className="text-xs text-red-600 font-medium">{resumeError}</p>
          )}
          {resumeSaveMessage && (
            <p className="text-xs text-emerald-700 font-medium">
              {resumeSaveMessage}
            </p>
          )}

          <button
            type="submit"
            className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 text-xs font-semibold text-white bg-slate-900 rounded-lg hover:bg-slate-800 transition-colors"
          >
            <Save className="h-4 w-4" />
            <span>Salva Curriculum su Cloud Firestore</span>
          </button>
        </form>
      </div>
    </div>
  );
};
