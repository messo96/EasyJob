import React, { useState } from 'react';
import { Cloud, FileText, Send, Upload, X } from 'lucide-react';
import { CloudResume, CvSource, JobOffer } from '../types';

interface OneClickApplyModalProps {
  job: JobOffer;
  cloudResume: CloudResume;
  onClose: () => void;
  onSubmitApplication: (payload: {
    job: JobOffer;
    cvSource: CvSource;
    cvTitle: string;
    cvContent: string;
    candidateNotes: string;
  }) => Promise<void>;
}

export const OneClickApplyModal: React.FC<OneClickApplyModalProps> = ({
  job,
  cloudResume,
  onClose,
  onSubmitApplication,
}) => {
  const [cvSource, setCvSource] = useState<CvSource>('cloud');
  const [customTitle, setCustomTitle] = useState(
    `CV Ad-Hoc per ${job.title} — ${cloudResume.fullName}`
  );
  const [customContent, setCustomContent] = useState(
    `${cloudResume.fullName} — Candidatura mirata per ${job.title} presso ${job.company}.\nCompetenze chiave allineate a "${job.requirements}":\n${cloudResume.skills}\n\nEsperienza rilevante:\n${cloudResume.experience}`
  );
  const [candidateNotes, setCandidateNotes] = useState('');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const cloudCvFormatted = `${cloudResume.fullName} (${cloudResume.headline})\nEmail: ${cloudResume.email} · Tel: ${cloudResume.phone}\nProfilo: ${cloudResume.summary}\nCompetenze: ${cloudResume.skills}\nEsperienza: ${cloudResume.experience}\nFormazione: ${cloudResume.education}`;

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setCustomTitle(`File CV Ad-Hoc: ${file.name}`);
    const reader = new FileReader();
    reader.onload = () => {
      const text = typeof reader.result === 'string' ? reader.result : '';
      if (text.trim().length >= 10) {
        setCustomContent(text.slice(0, 3800));
      } else {
        setCustomContent(
          `Documento caricato: ${file.name} (${Math.round(file.size / 1024)} KB) — Candidato: ${cloudResume.fullName}.\nCompetenze principali per ${job.title}: ${cloudResume.skills}`
        );
      }
    };
    reader.readAsText(file);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    const finalTitle =
      cvSource === 'cloud'
        ? `CV Cloud Firestore — ${cloudResume.fullName} (${cloudResume.headline})`
        : customTitle.trim();
    const finalContent =
      cvSource === 'cloud' ? cloudCvFormatted : customContent.trim();

    if (finalTitle.length < 2 || finalTitle.length > 140) {
      setErrorMsg('Il titolo del CV deve contenere tra 2 e 140 caratteri.');
      return;
    }
    if (finalContent.length < 10 || finalContent.length > 4000) {
      setErrorMsg('Il contenuto del CV deve contenere tra 10 e 4000 caratteri.');
      return;
    }
    if (candidateNotes.length > 1500) {
      setErrorMsg('Le note aggiuntive non possono superare i 1500 caratteri.');
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmitApplication({
        job,
        cvSource,
        cvTitle: finalTitle,
        cvContent: finalContent,
        candidateNotes: candidateNotes.trim(),
      });
      onClose();
    } catch (err) {
      setErrorMsg(
        err instanceof Error ? err.message : 'Errore durante l’invio della candidatura.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-xs"
      role="dialog"
      aria-modal="true"
      aria-labelledby="apply-modal-title"
    >
      <div className="w-full max-w-2xl rounded-xl border border-slate-200 bg-white shadow-xl overflow-hidden">
        <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
          <div>
            <p className="text-xs font-medium text-blue-600">
              Candidatura Rapida 1-Click · Cloud Firestore
            </p>
            <h2 id="apply-modal-title" className="text-lg font-bold text-slate-900">
              {job.title} · {job.company}
            </h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Chiudi finestra candidatura"
            className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-900 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5 max-h-[82vh] overflow-y-auto">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-2">
              Seleziona il Curriculum da allegare all’offerta
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setCvSource('cloud')}
                className={`flex items-start gap-3 rounded-lg border p-3.5 text-left transition-colors ${
                  cvSource === 'cloud'
                    ? 'border-blue-600 bg-blue-50/60 text-slate-900'
                    : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300'
                }`}
              >
                <Cloud className="h-5 w-5 text-blue-600 shrink-0 mt-0.5" />
                <div>
                  <div className="text-sm font-semibold text-slate-900">
                    CV Cloud (Firestore)
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Usa il tuo profilo principale già salvato in cloud per candidarti istantaneamente.
                  </p>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setCvSource('custom')}
                className={`flex items-start gap-3 rounded-lg border p-3.5 text-left transition-colors ${
                  cvSource === 'custom'
                    ? 'border-blue-600 bg-blue-50/60 text-slate-900'
                    : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300'
                }`}
              >
                <FileText className="h-5 w-5 text-blue-600 shrink-0 mt-0.5" />
                <div>
                  <div className="text-sm font-semibold text-slate-900">
                    CV Ad-Hoc per l’Offerta
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Carica o personalizza un curriculum specifico per questa posizione lavorativa.
                  </p>
                </div>
              </button>
            </div>
          </div>

          {cvSource === 'cloud' ? (
            <div className="rounded-lg border border-slate-200 bg-slate-50 p-4 space-y-1.5">
              <div className="flex items-center justify-between text-xs text-slate-500">
                <span className="font-semibold text-slate-800">
                  {cloudResume.fullName} · {cloudResume.headline}
                </span>
                <span>Sincronizzato su Firestore (findmyjob-510711)</span>
              </div>
              <p className="text-xs text-slate-600 line-clamp-3">{cloudResume.summary}</p>
              <p className="text-xs text-slate-500">
                Competenze: <span className="text-slate-700">{cloudResume.skills}</span>
              </p>
            </div>
          ) : (
            <div className="space-y-3 rounded-lg border border-slate-200 bg-slate-50 p-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <label
                  htmlFor="custom-cv-title"
                  className="text-xs font-semibold text-slate-700"
                >
                  Titolo CV Ad-Hoc
                </label>
                <label className="inline-flex items-center gap-1.5 text-xs font-medium text-blue-600 hover:text-blue-700 cursor-pointer">
                  <Upload className="h-3.5 w-3.5" />
                  <span>Carica file CV (.txt, .md, .pdf)</span>
                  <input
                    type="file"
                    accept=".txt,.md,.pdf,.doc,.docx"
                    onChange={handleFileUpload}
                    className="sr-only"
                  />
                </label>
              </div>
              <input
                id="custom-cv-title"
                type="text"
                value={customTitle}
                onChange={(e) => setCustomTitle(e.target.value)}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-blue-600 focus:outline-hidden"
                placeholder="Es. CV Custom Flutter Developer"
                required
              />
              <div>
                <label
                  htmlFor="custom-cv-content"
                  className="block text-xs font-semibold text-slate-700 mb-1"
                >
                  Contenuto / Estratto Mirato del Curriculum
                </label>
                <textarea
                  id="custom-cv-content"
                  rows={4}
                  value={customContent}
                  onChange={(e) => setCustomContent(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs text-slate-900 focus:border-blue-600 focus:outline-hidden"
                  required
                />
              </div>
            </div>
          )}

          <div>
            <label
              htmlFor="candidate-notes-input"
              className="block text-xs font-semibold text-slate-700 mb-1"
            >
              Note Aggiuntive per il Recruiter / Datore di Lavoro (Opzionale)
            </label>
            <textarea
              id="candidate-notes-input"
              rows={3}
              value={candidateNotes}
              onChange={(e) => setCandidateNotes(e.target.value)}
              placeholder="Scrivi una nota diretta per chi ha creato l'annuncio (es. disponibilità per colloquio Meet, preavviso, link a progetti specifici)..."
              className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-blue-600 focus:outline-hidden"
            />
          </div>

          {errorMsg && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
              {errorMsg}
            </div>
          )}

          <div className="flex items-center justify-end gap-3 pt-2 border-t border-slate-200">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors whitespace-nowrap shrink-0"
            >
              Annulla
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors whitespace-nowrap shrink-0"
            >
              <Send className="h-3.5 w-3.5" />
              <span>{isSubmitting ? 'Invio in corso...' : 'Invia Candidatura con 1 Clic'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
