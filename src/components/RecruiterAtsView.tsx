import React, { useState } from 'react';
import {
  Ban,
  CheckCircle2,
  FileText,
  Mail,
  MessageSquare,
  Plus,
  Users,
  Video,
  X,
  XCircle,
} from 'lucide-react';
import {
  ApplicationStatus,
  ContractType,
  JobApplication,
  JobOffer,
} from '../types';
import { ITALIAN_CITIES } from '../data/seedData';
import { validateJobOfferInput } from '../utils/recruitingLogic';

interface RecruiterAtsViewProps {
  jobs: JobOffer[];
  applications: JobApplication[];
  onCreateJobOffer: (newJob: Omit<JobOffer, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  onScheduleMeetInterview: (
    app: JobApplication,
    interviewDate: string,
    customMessage: string
  ) => Promise<void>;
  onUpdateApplicationDecision: (
    app: JobApplication,
    decision: 'accepted' | 'rejected',
    employerResponse: string
  ) => Promise<void>;
  onCloseJobPosition: (job: JobOffer, closureReason: string) => Promise<void>;
  onOpenFeedbackForApp: (appId: string) => void;
}

const STATUS_NAMES: Record<ApplicationStatus, string> = {
  in_review: 'In Valutazione',
  interview_scheduled: 'Colloquio Meet Fissato',
  accepted: 'Assunto / Preso',
  rejected: 'Scartato',
  position_closed: 'Posizione Chiusa',
};

export const RecruiterAtsView: React.FC<RecruiterAtsViewProps> = ({
  jobs,
  applications,
  onCreateJobOffer,
  onScheduleMeetInterview,
  onUpdateApplicationDecision,
  onCloseJobPosition,
  onOpenFeedbackForApp,
}) => {
  const [selectedJobId, setSelectedJobId] = useState<string>(jobs[0]?.id || '');
  const [showNewJobModal, setShowNewJobModal] = useState(false);

  // New Job Form State
  const [title, setTitle] = useState('');
  const [company, setCompany] = useState('SatisCloud FinTech');
  const [selectedCityName, setSelectedCityName] = useState(ITALIAN_CITIES[0].name);
  const [salaryRange, setSalaryRange] = useState('€45.000 - €60.000');
  const [contractType, setContractType] = useState<ContractType>('Ibrido');
  const [category, setCategory] = useState('Mobile & Flutter');
  const [description, setDescription] = useState('');
  const [requirements, setRequirements] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  // Workspace Confirmation Modal State (Mandatory before sending Gmail / creating Google Meet)
  const [pendingAction, setPendingAction] = useState<{
    type: 'meet' | 'accept' | 'reject' | 'close_job';
    app?: JobApplication;
    job?: JobOffer;
  } | null>(null);
  const [interviewDateInput, setInterviewDateInput] = useState('2026-10-30 ore 15:00');
  const [responseMessageInput, setResponseMessageInput] = useState('');
  const [isExecutingAction, setIsExecutingAction] = useState(false);

  const selectedJob = jobs.find((j) => j.id === selectedJobId) || jobs[0] || null;
  const jobApplications = applications.filter(
    (a) => selectedJob && a.jobId === selectedJob.id
  );

  const openMeetConfirmation = (app: JobApplication) => {
    setInterviewDateInput('2026-10-30 ore 15:00');
    setResponseMessageInput(
      `Ciao ${app.candidateName}, il tuo CV è risultato molto interessante per la posizione ${app.jobTitle}. Abbiamo creato una stanza Google Meet per un primo colloquio conoscitivo.`
    );
    setPendingAction({ type: 'meet', app });
  };

  const openDecisionConfirmation = (
    app: JobApplication,
    decision: 'accepted' | 'rejected'
  ) => {
    const defaultMsg =
      decision === 'accepted'
        ? `Congratulazioni ${app.candidateName}! Siamo felici di comunicarti che sei stato selezionato per il ruolo di ${app.jobTitle} presso ${app.company}.`
        : `Grazie ${app.candidateName} per aver partecipato alla selezione per ${app.jobTitle}. Al momento abbiamo scelto di procedere con un profilo con maggiore seniority specifica, ma conserviamo il tuo CV.`;
    setResponseMessageInput(defaultMsg);
    setPendingAction({
      type: decision === 'accepted' ? 'accept' : 'reject',
      app,
    });
  };

  const openCloseJobConfirmation = (job: JobOffer) => {
    setResponseMessageInput(
      `La posizione "${job.title}" presso ${job.company} non è più disponibile. Tutti i candidati in attesa ricevono questa notifica automatica di chiusura selezione.`
    );
    setPendingAction({ type: 'close_job', job });
  };

  const handleConfirmWorkspaceAction = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!pendingAction) return;
    setIsExecutingAction(true);
    try {
      if (pendingAction.type === 'meet' && pendingAction.app) {
        await onScheduleMeetInterview(
          pendingAction.app,
          interviewDateInput.trim(),
          responseMessageInput.trim()
        );
      } else if (
        (pendingAction.type === 'accept' || pendingAction.type === 'reject') &&
        pendingAction.app
      ) {
        await onUpdateApplicationDecision(
          pendingAction.app,
          pendingAction.type === 'accept' ? 'accepted' : 'rejected',
          responseMessageInput.trim()
        );
      } else if (pendingAction.type === 'close_job' && pendingAction.job) {
        await onCloseJobPosition(
          pendingAction.job,
          responseMessageInput.trim()
        );
      }
      setPendingAction(null);
    } finally {
      setIsExecutingAction(false);
    }
  };

  const handleCreateJobSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    const cityObj =
      ITALIAN_CITIES.find((c) => c.name === selectedCityName) || ITALIAN_CITIES[0];

    const draft = {
      title: title.trim(),
      company: company.trim(),
      locationName: cityObj.name,
      latitude: cityObj.latitude,
      longitude: cityObj.longitude,
      salaryRange: salaryRange.trim(),
      contractType,
      category,
      description: description.trim(),
      requirements: requirements.trim(),
      recruiterId: 'demo-user-1',
      recruiterName: 'Giovanni Messina (Recruiter)',
      recruiterEmail: 'giovannimessina96@gmail.com',
      status: 'open' as const,
    };

    const err = validateJobOfferInput(draft);
    if (err) {
      setFormError(err);
      return;
    }

    await onCreateJobOffer(draft);
    setTitle('');
    setDescription('');
    setRequirements('');
    setShowNewJobModal(false);
  };

  return (
    <div className="space-y-6">
      {/* Top Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <h2 className="text-xl font-bold text-slate-900">
            Gestionale Annunci & Recruiting ATS
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Gestisci candidature, CV Cloud/Ad-Hoc, note candidati, colloqui Google Meet 1-Tap e risposte obbligatorie
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowNewJobModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors whitespace-nowrap shrink-0"
        >
          <Plus className="h-4 w-4" />
          <span>Pubblica Nuovo Annuncio (Invia Push)</span>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left 4 Cols: Employer's Published Job Listings */}
        <div className="lg:col-span-4 rounded-xl border border-slate-200 bg-white overflow-hidden">
          <div className="border-b border-slate-200 px-4 py-3 text-xs font-semibold text-slate-800">
            I Tuoi Annunci di Lavoro ({jobs.length})
          </div>
          <div className="divide-y divide-slate-100">
            {jobs.map((job) => {
              const count = applications.filter((a) => a.jobId === job.id).length;
              const isSelected = selectedJob?.id === job.id;
              return (
                <button
                  key={job.id}
                  type="button"
                  onClick={() => setSelectedJobId(job.id)}
                  className={`w-full px-4 py-3.5 text-left transition-colors flex items-start justify-between gap-3 ${
                    isSelected ? 'bg-blue-50/70' : 'hover:bg-slate-50'
                  }`}
                >
                  <div className="min-w-0">
                    <div className="text-xs font-bold text-slate-900 truncate">
                      {job.title}
                    </div>
                    <div className="text-xs text-slate-500 truncate mt-0.5">
                      {job.company} · {job.locationName}
                    </div>
                    <div className="text-[11px] text-slate-500 mt-1">
                      Stato:{' '}
                      <span
                        className={
                          job.status === 'open'
                            ? 'font-semibold text-emerald-700'
                            : 'font-semibold text-red-700'
                        }
                      >
                        {job.status === 'open' ? 'Attivo' : 'Chiuso / Non disponibile'}
                      </span>
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    <span className="inline-flex items-center gap-1 text-xs font-mono tabular-nums font-semibold text-slate-800">
                      <Users className="h-3.5 w-3.5 text-blue-600" />
                      <span>{count}</span>
                    </span>
                    <div className="text-[11px] text-slate-400">candidati</div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Right 8 Cols: Job ATS Gestionale for Selected Job */}
        <div className="lg:col-span-8 space-y-5">
          {selectedJob ? (
            <>
              {/* Job Management Header Card */}
              <div className="rounded-xl border border-slate-200 bg-white p-5 space-y-3">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <div className="text-xs text-slate-500">
                      <span>{selectedJob.company}</span>
                      <span aria-hidden="true"> · </span>
                      <span>{selectedJob.locationName}</span>
                      <span aria-hidden="true"> · </span>
                      <span className="font-mono tabular-nums">
                        {selectedJob.salaryRange}
                      </span>
                    </div>
                    <h3 className="text-lg font-bold text-slate-900 mt-0.5">
                      Gestionale Candidature: {selectedJob.title}
                    </h3>
                  </div>

                  {selectedJob.status === 'open' ? (
                    <button
                      type="button"
                      onClick={() => openCloseJobConfirmation(selectedJob)}
                      className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-semibold text-red-700 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100 transition-colors whitespace-nowrap shrink-0"
                    >
                      <Ban className="h-3.5 w-3.5" />
                      <span>Chiudi Posizione (Notifica Tutti)</span>
                    </button>
                  ) : (
                    <span className="text-xs font-semibold text-red-700">
                      Posizione Chiusa — Tutti i candidati sono stati notificati
                    </span>
                  )}
                </div>

                <p className="text-xs text-slate-600">{selectedJob.description}</p>
              </div>

              {/* Candidate Pipeline List */}
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h4 className="text-sm font-bold text-slate-900">
                    Candidature Ricevute ({jobApplications.length})
                  </h4>
                  <span className="text-xs text-slate-500">
                    Ogni azione invia notifica push + email automatica
                  </span>
                </div>

                {jobApplications.length === 0 ? (
                  <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
                    <p className="text-sm font-semibold text-slate-900">
                      Ancora nessuna candidatura per questo annuncio
                    </p>
                    <p className="text-xs text-slate-500 mt-1">
                      Quando un candidato applica con 1 clic, vedrai qui il suo CV Cloud o Ad-Hoc e le sue note.
                    </p>
                  </div>
                ) : (
                  jobApplications.map((app) => (
                    <div
                      key={app.id}
                      className="rounded-xl border border-slate-200 bg-white p-5 space-y-4"
                    >
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-slate-100 pb-3">
                        <div>
                          <div className="text-sm font-bold text-slate-900">
                            {app.candidateName}
                          </div>
                          <div className="text-xs text-slate-500">
                            <span>{app.candidateEmail}</span>
                            <span aria-hidden="true"> · </span>
                            <span>
                              {app.cvSource === 'cloud'
                                ? 'CV Cloud (Firestore)'
                                : 'CV Ad-Hoc per la posizione'}
                            </span>
                          </div>
                        </div>
                        <div className="text-xs font-semibold text-slate-800">
                          Stato: {STATUS_NAMES[app.status]}
                        </div>
                      </div>

                      {/* Candidate Curriculum Content */}
                      <div className="rounded-lg border border-slate-200 bg-slate-50 p-3.5 space-y-1.5">
                        <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-800">
                          <FileText className="h-3.5 w-3.5 text-blue-600" />
                          <span>{app.cvTitle}</span>
                        </div>
                        <p className="text-xs text-slate-700 whitespace-pre-line leading-relaxed">
                          {app.cvContent}
                        </p>
                      </div>

                      {/* Candidate Additional Notes */}
                      <div className="text-xs text-slate-700">
                        <span className="font-semibold text-slate-900">
                          Note del Candidato:{' '}
                        </span>
                        <span>
                          {app.candidateNotes ||
                            'Nessuna nota aggiuntiva allegata dal candidato.'}
                        </span>
                      </div>

                      {/* Meet Link if scheduled */}
                      {app.meetLink && (
                        <div className="flex items-center justify-between rounded-lg border border-blue-200 bg-blue-50/50 px-3.5 py-2 text-xs">
                          <div>
                            <span className="font-semibold text-slate-900">
                              Stanza Google Meet attiva:{' '}
                            </span>
                            <span className="font-mono tabular-nums text-slate-700">
                              {app.interviewDate}
                            </span>
                          </div>
                          <a
                            href={app.meetLink}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="font-semibold text-blue-600 hover:text-blue-800 underline"
                          >
                            Apri Google Meet ({app.meetLink})
                          </a>
                        </div>
                      )}

                      {/* Recruiter 1-Tap Actions Bar */}
                      <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-slate-100">
                        <div className="flex flex-wrap items-center gap-2">
                          <button
                            type="button"
                            onClick={() => openMeetConfirmation(app)}
                            disabled={
                              app.status === 'accepted' ||
                              app.status === 'rejected' ||
                              app.status === 'position_closed'
                            }
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-40 transition-colors whitespace-nowrap shrink-0"
                          >
                            <Video className="h-3.5 w-3.5" />
                            <span>1-Tap Colloquio Meet + Mail</span>
                          </button>

                          <button
                            type="button"
                            onClick={() => openDecisionConfirmation(app, 'accepted')}
                            disabled={
                              app.status === 'accepted' ||
                              app.status === 'rejected' ||
                              app.status === 'position_closed'
                            }
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-emerald-800 bg-emerald-50 border border-emerald-200 rounded-lg hover:bg-emerald-100 disabled:opacity-40 transition-colors whitespace-nowrap shrink-0"
                          >
                            <CheckCircle2 className="h-3.5 w-3.5" />
                            <span>Assumi / Prendi</span>
                          </button>

                          <button
                            type="button"
                            onClick={() => openDecisionConfirmation(app, 'rejected')}
                            disabled={
                              app.status === 'accepted' ||
                              app.status === 'rejected' ||
                              app.status === 'position_closed'
                            }
                            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-red-800 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100 disabled:opacity-40 transition-colors whitespace-nowrap shrink-0"
                          >
                            <XCircle className="h-3.5 w-3.5" />
                            <span>Scarta con Risposta</span>
                          </button>
                        </div>

                        <button
                          type="button"
                          onClick={() => onOpenFeedbackForApp(app.id)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors whitespace-nowrap shrink-0"
                        >
                          <MessageSquare className="h-3.5 w-3.5" />
                          <span>Feedback Post-Colloquio</span>
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </>
          ) : null}
        </div>
      </div>

      {/* Mandatory User Confirmation Dialog for Workspace APIs (Meet + Gmail) & Status Broadcasts */}
      {pendingAction && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-xs"
          role="dialog"
          aria-modal="true"
          aria-labelledby="workspace-confirm-title"
        >
          <div className="w-full max-w-lg rounded-xl border border-slate-200 bg-white p-6 shadow-xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-200 pb-3">
              <div className="flex items-center gap-2">
                <Mail className="h-5 w-5 text-blue-600" />
                <h3
                  id="workspace-confirm-title"
                  className="text-base font-bold text-slate-900"
                >
                  {pendingAction.type === 'meet' &&
                    'Conferma Creazione Google Meet & Invio Email'}
                  {pendingAction.type === 'accept' &&
                    'Conferma Assunzione & Invio Notifica/Email'}
                  {pendingAction.type === 'reject' &&
                    'Conferma Esito Negativo & Invio Notifica/Email'}
                  {pendingAction.type === 'close_job' &&
                    'Conferma Chiusura Posizione & Broadcast a Tutti i Candidati'}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setPendingAction(null)}
                aria-label="Chiudi conferma"
                className="rounded-lg p-1 text-slate-500 hover:bg-slate-100"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form onSubmit={handleConfirmWorkspaceAction} className="space-y-4">
              <p className="text-xs text-slate-600 leading-relaxed">
                {pendingAction.type === 'meet' && pendingAction.app && (
                  <>
                    Stai per creare una stanza video su <strong>Google Meet</strong> e inviare un’email automatica tramite <strong>Gmail</strong> sia al candidato (
                    <span className="font-mono">{pendingAction.app.candidateEmail}</span>
                    ) sia al recruiter (
                    <span className="font-mono">{pendingAction.app.recruiterEmail}</span>
                    ), oltre a una notifica push.
                  </>
                )}
                {(pendingAction.type === 'accept' ||
                  pendingAction.type === 'reject') &&
                  pendingAction.app && (
                    <>
                      Stai per aggiornare lo stato della candidatura di{' '}
                      <strong>{pendingAction.app.candidateName}</strong> e inviare una risposta ufficiale tramite <strong>Gmail</strong> (
                      <span className="font-mono">{pendingAction.app.candidateEmail}</span>
                      ) e notifica push.
                    </>
                  )}
                {pendingAction.type === 'close_job' && pendingAction.job && (
                  <>
                    Stai per chiudere definitivamente l’annuncio{' '}
                    <strong>{pendingAction.job.title}</strong>. Verrà inviata una notifica push e un’email automatica a tutti i candidati in attesa di risposta.
                  </>
                )}
              </p>

              {pendingAction.type === 'meet' && (
                <div>
                  <label
                    htmlFor="confirm-interview-date"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    Data e Ora del Colloquio su Google Meet
                  </label>
                  <input
                    id="confirm-interview-date"
                    type="text"
                    value={interviewDateInput}
                    onChange={(e) => setInterviewDateInput(e.target.value)}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900 font-mono"
                    required
                  />
                </div>
              )}

              <div>
                <label
                  htmlFor="confirm-response-message"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Messaggio di Risposta Ufficiale (Inviato via Email & Push)
                </label>
                <textarea
                  id="confirm-response-message"
                  rows={3}
                  value={responseMessageInput}
                  onChange={(e) => setResponseMessageInput(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                  required
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-2 border-t border-slate-200">
                <button
                  type="button"
                  onClick={() => setPendingAction(null)}
                  className="px-4 py-2 text-xs font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200"
                >
                  Annulla
                </button>
                <button
                  type="submit"
                  disabled={isExecutingAction}
                  className="px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                  {isExecutingAction
                    ? 'Esecuzione in corso...'
                    : 'Conferma e Invia Ora'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Create New Job Modal */}
      {showNewJobModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-xs"
          role="dialog"
          aria-modal="true"
          aria-labelledby="new-job-modal-title"
        >
          <div className="w-full max-w-xl rounded-xl border border-slate-200 bg-white p-6 shadow-xl space-y-4 max-h-[88vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-200 pb-3">
              <h3
                id="new-job-modal-title"
                className="text-base font-bold text-slate-900"
              >
                Pubblica Nuova Offerta di Lavoro
              </h3>
              <button
                type="button"
                onClick={() => setShowNewJobModal(false)}
                aria-label="Chiudi creazione annuncio"
                className="rounded-lg p-1 text-slate-500 hover:bg-slate-100"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <form onSubmit={handleCreateJobSubmit} className="space-y-3.5">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label
                    htmlFor="new-job-title"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    Titolo Posizione
                  </label>
                  <input
                    id="new-job-title"
                    type="text"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="Es. Flutter Mobile Developer"
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                    required
                  />
                </div>
                <div>
                  <label
                    htmlFor="new-job-company"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    Azienda
                  </label>
                  <input
                    id="new-job-company"
                    type="text"
                    value={company}
                    onChange={(e) => setCompany(e.target.value)}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label
                    htmlFor="new-job-city"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    Sede Geografica (Mappa)
                  </label>
                  <select
                    id="new-job-city"
                    value={selectedCityName}
                    onChange={(e) => setSelectedCityName(e.target.value)}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                  >
                    {ITALIAN_CITIES.map((c) => (
                      <option key={c.name} value={c.name}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label
                    htmlFor="new-job-contract"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    Contratto
                  </label>
                  <select
                    id="new-job-contract"
                    value={contractType}
                    onChange={(e) =>
                      setContractType(e.target.value as ContractType)
                    }
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                  >
                    <option value="Full-time">Full-time</option>
                    <option value="Ibrido">Ibrido</option>
                    <option value="Remoto">Remoto</option>
                    <option value="Part-time">Part-time</option>
                    <option value="Freelance">Freelance</option>
                  </select>
                </div>
                <div>
                  <label
                    htmlFor="new-job-salary"
                    className="block text-xs font-semibold text-slate-700 mb-1"
                  >
                    RAL / Compenso
                  </label>
                  <input
                    id="new-job-salary"
                    type="text"
                    value={salaryRange}
                    onChange={(e) => setSalaryRange(e.target.value)}
                    className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900 font-mono"
                    required
                  />
                </div>
              </div>

              <div>
                <label
                  htmlFor="new-job-category"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Categoria Professionale
                </label>
                <select
                  id="new-job-category"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                >
                  <option value="Mobile & Flutter">Mobile & Flutter</option>
                  <option value="Cloud & Backend">Cloud & Backend</option>
                  <option value="Design & UX">Design & UX</option>
                  <option value="AI & Data Science">AI & Data Science</option>
                  <option value="Frontend & Web">Frontend & Web</option>
                </select>
              </div>

              <div>
                <label
                  htmlFor="new-job-description"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Descrizione Posizione
                </label>
                <textarea
                  id="new-job-description"
                  rows={3}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Descrivi le responsabilità e il team..."
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                  required
                />
              </div>

              <div>
                <label
                  htmlFor="new-job-requirements"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Requisiti Richiesti
                </label>
                <input
                  id="new-job-requirements"
                  type="text"
                  value={requirements}
                  onChange={(e) => setRequirements(e.target.value)}
                  placeholder="Es. Flutter, Dart, Firebase, Git..."
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                  required
                />
              </div>

              {formError && (
                <p className="text-xs text-red-600 font-medium">{formError}</p>
              )}

              <div className="flex items-center justify-end gap-3 pt-2 border-t border-slate-200">
                <button
                  type="button"
                  onClick={() => setShowNewJobModal(false)}
                  className="px-4 py-2 text-xs font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200"
                >
                  Annulla
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700"
                >
                  Pubblica e Invia Notifica Push
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
