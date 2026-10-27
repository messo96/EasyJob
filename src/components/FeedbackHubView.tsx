import React, { useState } from 'react';
import { CheckCircle2, ClipboardCheck, Star } from 'lucide-react';
import {
  HiringRecommendation,
  InterviewFeedback,
  JobApplication,
} from '../types';
import { validateFeedbackInput } from '../utils/recruitingLogic';

interface FeedbackHubViewProps {
  applications: JobApplication[];
  feedbacks: InterviewFeedback[];
  preselectedApplicationId: string | null;
  onSaveFeedback: (
    feedback: Omit<InterviewFeedback, 'id' | 'createdAt' | 'updatedAt'>
  ) => Promise<void>;
}

const RECOMMENDATION_LABELS: Record<HiringRecommendation, string> = {
  strong_hire: 'Fortemente Consigliato (Strong Hire)',
  hire: 'Idoneo all’Assunzione (Hire)',
  hold: 'In Valutazione / Seconda Intervista (Hold)',
  no_hire: 'Non Idoneo (No Hire)',
};

export const FeedbackHubView: React.FC<FeedbackHubViewProps> = ({
  applications,
  feedbacks,
  preselectedApplicationId,
  onSaveFeedback,
}) => {
  const [selectedAppId, setSelectedAppId] = useState<string>(
    preselectedApplicationId || applications[0]?.id || ''
  );
  const [technicalScore, setTechnicalScore] = useState<number>(5);
  const [communicationScore, setCommunicationScore] = useState<number>(5);
  const [cultureFitScore, setCultureFitScore] = useState<number>(4);
  const [overallRating, setOverallRating] = useState<number>(5);
  const [strengths, setStrengths] = useState<string>('');
  const [areasForImprovement, setAreasForImprovement] = useState<string>('');
  const [recommendation, setRecommendation] =
    useState<HiringRecommendation>('strong_hire');
  const [sharedSummaryForCandidate, setSharedSummaryForCandidate] =
    useState<string>('');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [savedToast, setSavedToast] = useState<string | null>(null);

  const selectedApp =
    applications.find((a) => a.id === selectedAppId) || applications[0] || null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSavedToast(null);

    if (!selectedApp) {
      setErrorMsg('Seleziona una candidatura valida.');
      return;
    }

    const draft = {
      applicationId: selectedApp.id,
      jobId: selectedApp.jobId,
      jobTitle: selectedApp.jobTitle,
      candidateId: selectedApp.candidateId,
      candidateName: selectedApp.candidateName,
      recruiterId: selectedApp.recruiterId,
      technicalScore,
      communicationScore,
      cultureFitScore,
      overallRating,
      strengths: strengths.trim(),
      areasForImprovement: areasForImprovement.trim(),
      recommendation,
      sharedSummaryForCandidate: sharedSummaryForCandidate.trim(),
    };

    const validationErr = validateFeedbackInput(draft);
    if (validationErr) {
      setErrorMsg(validationErr);
      return;
    }

    await onSaveFeedback(draft);
    setStrengths('');
    setAreasForImprovement('');
    setSharedSummaryForCandidate('');
    setSavedToast(
      `Feedback post-colloquio per ${selectedApp.candidateName} registrato e notificato con successo.`
    );
  };

  return (
    <div className="space-y-6">
      <div className="border-b border-slate-200 pb-4">
        <h2 className="text-xl font-bold text-slate-900">
          Hub Centralizzato Feedback Post-Colloquio
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Raccogli valutazioni strutturate dopo i colloqui su Google Meet e condividi un riscontro trasparente con il candidato
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left 5 Cols: New Evaluation Scorecard Form */}
        <div className="lg:col-span-5 rounded-xl border border-slate-200 bg-white p-6 space-y-4">
          <div className="flex items-center gap-2 border-b border-slate-200 pb-3">
            <ClipboardCheck className="h-5 w-5 text-blue-600" />
            <h3 className="text-base font-bold text-slate-900">
              Registra Nuova Scheda di Valutazione
            </h3>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label
                htmlFor="fb-select-app"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Candidato e Posizione Valutata
              </label>
              <select
                id="fb-select-app"
                value={selectedApp?.id || ''}
                onChange={(e) => setSelectedAppId(e.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
              >
                {applications.map((app) => (
                  <option key={app.id} value={app.id}>
                    {app.candidateName} — {app.jobTitle} ({app.company})
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label
                  htmlFor="fb-tech-score"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Punteggio Tecnico (1-5)
                </label>
                <input
                  id="fb-tech-score"
                  type="number"
                  min={1}
                  max={5}
                  value={technicalScore}
                  onChange={(e) => setTechnicalScore(Number(e.target.value))}
                  className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-mono tabular-nums text-slate-900"
                />
              </div>
              <div>
                <label
                  htmlFor="fb-comm-score"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Comunicazione (1-5)
                </label>
                <input
                  id="fb-comm-score"
                  type="number"
                  min={1}
                  max={5}
                  value={communicationScore}
                  onChange={(e) => setCommunicationScore(Number(e.target.value))}
                  className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-mono tabular-nums text-slate-900"
                />
              </div>
              <div>
                <label
                  htmlFor="fb-culture-score"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Team & Culture Fit (1-5)
                </label>
                <input
                  id="fb-culture-score"
                  type="number"
                  min={1}
                  max={5}
                  value={cultureFitScore}
                  onChange={(e) => setCultureFitScore(Number(e.target.value))}
                  className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-mono tabular-nums text-slate-900"
                />
              </div>
              <div>
                <label
                  htmlFor="fb-overall-score"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Voto Complessivo (1-5)
                </label>
                <input
                  id="fb-overall-score"
                  type="number"
                  min={1}
                  max={5}
                  value={overallRating}
                  onChange={(e) => setOverallRating(Number(e.target.value))}
                  className="w-full rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-mono tabular-nums text-slate-900"
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="fb-recommendation"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Esito / Raccomandazione Recruiting
              </label>
              <select
                id="fb-recommendation"
                value={recommendation}
                onChange={(e) =>
                  setRecommendation(e.target.value as HiringRecommendation)
                }
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
              >
                <option value="strong_hire">
                  Fortemente Consigliato (Strong Hire)
                </option>
                <option value="hire">Idoneo all’Assunzione (Hire)</option>
                <option value="hold">In Valutazione (Hold)</option>
                <option value="no_hire">Non Idoneo (No Hire)</option>
              </select>
            </div>

            <div>
              <label
                htmlFor="fb-strengths"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Punti di Forza Rilevati
              </label>
              <textarea
                id="fb-strengths"
                rows={2}
                value={strengths}
                onChange={(e) => setStrengths(e.target.value)}
                placeholder="Es. Ottima padronanza di Flutter, stato applicativo e sicurezza Firestore..."
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                required
              />
            </div>

            <div>
              <label
                htmlFor="fb-improvements"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Aree di Miglioramento / Note Interne
              </label>
              <textarea
                id="fb-improvements"
                rows={2}
                value={areasForImprovement}
                onChange={(e) => setAreasForImprovement(e.target.value)}
                placeholder="Es. Approfondire CI/CD per distribuzioni multi-ambiente..."
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                required
              />
            </div>

            <div>
              <label
                htmlFor="fb-shared-summary"
                className="block text-xs font-semibold text-slate-700 mb-1"
              >
                Sintesi Condivisa col Candidato (Visibile nella sua Dashboard)
              </label>
              <textarea
                id="fb-shared-summary"
                rows={2}
                value={sharedSummaryForCandidate}
                onChange={(e) => setSharedSummaryForCandidate(e.target.value)}
                placeholder="Scrivi il feedback costruttivo che verrà inviato al candidato..."
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-xs text-slate-900"
                required
              />
            </div>

            {errorMsg && (
              <p className="text-xs text-red-600 font-medium">{errorMsg}</p>
            )}
            {savedToast && (
              <p className="text-xs text-emerald-700 font-medium">{savedToast}</p>
            )}

            <button
              type="submit"
              className="w-full px-4 py-2.5 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Salva Feedback Centralizzato & Notifica Candidato
            </button>
          </form>
        </div>

        {/* Right 7 Cols: Centralized Feedback Archive */}
        <div className="lg:col-span-7 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-base font-bold text-slate-900">
              Archivio Valutazioni Post-Colloquio ({feedbacks.length})
            </h3>
            <span className="text-xs text-slate-500 font-mono tabular-nums">
              Sincronizzato su Firestore
            </span>
          </div>

          {feedbacks.length === 0 ? (
            <div className="rounded-xl border border-slate-200 bg-white p-8 text-center">
              <p className="text-sm font-semibold text-slate-900">
                Nessun feedback post-colloquio registrato
              </p>
              <p className="text-xs text-slate-500 mt-1">
                Compila il modulo a sinistra dopo aver svolto il colloquio su Google Meet.
              </p>
            </div>
          ) : (
            feedbacks.map((fb) => (
              <div
                key={fb.id}
                className="rounded-xl border border-slate-200 bg-white p-5 space-y-3.5"
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-slate-100 pb-3">
                  <div>
                    <div className="text-sm font-bold text-slate-900">
                      {fb.candidateName} · {fb.jobTitle}
                    </div>
                    <div className="text-xs text-slate-500">
                      <span>{RECOMMENDATION_LABELS[fb.recommendation]}</span>
                      <span aria-hidden="true"> · </span>
                      <span className="font-mono tabular-nums">
                        {new Date(fb.createdAt).toLocaleDateString('it-IT')}
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center gap-1 text-xs font-mono tabular-nums font-bold text-blue-700">
                    <Star className="h-4 w-4 fill-blue-600 text-blue-600" />
                    <span>{fb.overallRating.toFixed(1)} / 5.0</span>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-3 rounded-lg bg-slate-50 p-3 text-xs">
                  <div>
                    <span className="text-slate-500 block">Tecnico</span>
                    <span className="font-mono tabular-nums font-semibold text-slate-900">
                      {fb.technicalScore} / 5
                    </span>
                  </div>
                  <div>
                    <span className="text-slate-500 block">Comunicazione</span>
                    <span className="font-mono tabular-nums font-semibold text-slate-900">
                      {fb.communicationScore} / 5
                    </span>
                  </div>
                  <div>
                    <span className="text-slate-500 block">Culture Fit</span>
                    <span className="font-mono tabular-nums font-semibold text-slate-900">
                      {fb.cultureFitScore} / 5
                    </span>
                  </div>
                </div>

                <div className="space-y-1.5 text-xs">
                  <div>
                    <span className="font-semibold text-slate-800">
                      Punti di Forza:{' '}
                    </span>
                    <span className="text-slate-600">{fb.strengths}</span>
                  </div>
                  <div>
                    <span className="font-semibold text-slate-800">
                      Aree di Miglioramento:{' '}
                    </span>
                    <span className="text-slate-600">
                      {fb.areasForImprovement}
                    </span>
                  </div>
                  <div className="pt-1 flex items-start gap-1.5 text-emerald-800">
                    <CheckCircle2 className="h-3.5 w-3.5 shrink-0 mt-0.5" />
                    <span>
                      <strong>Condiviso col candidato:</strong>{' '}
                      {fb.sharedSummaryForCandidate}
                    </span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
