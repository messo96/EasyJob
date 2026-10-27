import React from 'react';
import { BarChart3, CheckCircle2, Mail, Video } from 'lucide-react';
import {
  AutomatedEmailLog,
  InterviewFeedback,
  JobApplication,
  JobOffer,
} from '../types';
import { computeRecruitingAnalytics } from '../utils/recruitingLogic';

interface AnalyticsDashboardViewProps {
  jobs: JobOffer[];
  applications: JobApplication[];
  feedbacks: InterviewFeedback[];
  emailLogs: AutomatedEmailLog[];
}

export const AnalyticsDashboardView: React.FC<AnalyticsDashboardViewProps> = ({
  jobs,
  applications,
  feedbacks,
  emailLogs,
}) => {
  const metrics = computeRecruitingAnalytics(jobs, applications, feedbacks);

  return (
    <div className="space-y-8">
      <div className="border-b border-slate-200 pb-4">
        <h2 className="text-xl font-bold text-slate-900">
          Cruscotto di Analisi Recruiting & Automazione Email
        </h2>
        <p className="text-xs text-slate-500 mt-0.5">
          Metriche real-time su conversione candidature, rispetto dell’obbligo di risposta al candidato, colloqui Google Meet e log invio mail
        </p>
      </div>

      {/* 4 Primary KPI Strip */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <div className="text-xs text-slate-500">Annunci Pubblicati</div>
          <div className="text-2xl font-bold font-mono tabular-nums text-slate-900 mt-1">
            {metrics.totalJobs}
          </div>
          <div className="text-xs text-slate-500 mt-1 font-mono tabular-nums">
            {metrics.openJobs} attivi · {metrics.closedJobs} chiusi
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <div className="text-xs text-slate-500">
            Tasso di Risposta Recruiter
          </div>
          <div className="text-2xl font-bold font-mono tabular-nums text-blue-600 mt-1">
            {metrics.employerResponseRatePct}%
          </div>
          <div className="text-xs text-slate-500 mt-1">
            Obbligo notifica su esito o chiusura
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <div className="text-xs text-slate-500">
            Conversione a Colloquio Meet
          </div>
          <div className="text-2xl font-bold font-mono tabular-nums text-slate-900 mt-1">
            {metrics.interviewConversionRatePct}%
          </div>
          <div className="text-xs text-slate-500 mt-1 font-mono tabular-nums">
            {metrics.interviewScheduledCount + metrics.acceptedCount} su{' '}
            {metrics.totalApplications} candidature
          </div>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-5">
          <div className="text-xs text-slate-500">
            Media Valutazioni Post-Colloquio
          </div>
          <div className="text-2xl font-bold font-mono tabular-nums text-emerald-700 mt-1">
            {metrics.averageFeedbackRating > 0
              ? `${metrics.averageFeedbackRating} / 5.0`
              : 'N/D'}
          </div>
          <div className="text-xs text-slate-500 mt-1 font-mono tabular-nums">
            Su {feedbacks.length} colloqui valutati
          </div>
        </div>
      </div>

      {/* Pipeline Funnel Breakdown + Automated Email Dispatch Log */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Funnel Table */}
        <div className="lg:col-span-5 rounded-xl border border-slate-200 bg-white overflow-hidden">
          <div className="flex items-center gap-2 border-b border-slate-200 px-5 py-3.5">
            <BarChart3 className="h-4 w-4 text-blue-600" />
            <h3 className="text-sm font-bold text-slate-900">
              Stato Pipeline Candidature
            </h3>
          </div>
          <div className="divide-y divide-slate-100 text-xs">
            <div className="flex items-center justify-between px-5 py-3">
              <span className="text-slate-700">In Valutazione (In Review)</span>
              <span className="font-mono tabular-nums font-semibold text-slate-900">
                {metrics.inReviewCount}
              </span>
            </div>
            <div className="flex items-center justify-between px-5 py-3">
              <span className="text-slate-700">
                Colloquio Pianificato su Google Meet
              </span>
              <span className="font-mono tabular-nums font-semibold text-blue-600">
                {metrics.interviewScheduledCount}
              </span>
            </div>
            <div className="flex items-center justify-between px-5 py-3">
              <span className="text-slate-700">Assunti / Presi (Accepted)</span>
              <span className="font-mono tabular-nums font-semibold text-emerald-700">
                {metrics.acceptedCount}
              </span>
            </div>
            <div className="flex items-center justify-between px-5 py-3">
              <span className="text-slate-700">
                Non Selezionati con Feedback
              </span>
              <span className="font-mono tabular-nums font-semibold text-slate-600">
                {metrics.rejectedCount}
              </span>
            </div>
            <div className="flex items-center justify-between px-5 py-3">
              <span className="text-slate-700">
                Notificati per Chiusura Posizione
              </span>
              <span className="font-mono tabular-nums font-semibold text-amber-700">
                {metrics.positionClosedCount}
              </span>
            </div>
          </div>
        </div>

        {/* Automated Email System Log */}
        <div className="lg:col-span-7 rounded-xl border border-slate-200 bg-white overflow-hidden">
          <div className="flex items-center justify-between border-b border-slate-200 px-5 py-3.5">
            <div className="flex items-center gap-2">
              <Mail className="h-4 w-4 text-blue-600" />
              <h3 className="text-sm font-bold text-slate-900">
                Registro Invio Email Automatiche (Gmail API & Recruiting)
              </h3>
            </div>
            <span className="text-xs font-mono tabular-nums text-slate-500">
              {emailLogs.length} email inviate
            </span>
          </div>

          <div className="divide-y divide-slate-100 max-h-[360px] overflow-y-auto">
            {emailLogs.map((log) => (
              <div key={log.id} className="p-4 space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-slate-900">
                    {log.subject}
                  </span>
                  <span className="font-mono tabular-nums text-slate-500">
                    {new Date(log.timestamp).toLocaleTimeString('it-IT', {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </span>
                </div>
                <div className="text-xs text-slate-500">
                  <span>Destinatario: {log.to}</span>
                  {log.cc && <span> · CC Recruiter: {log.cc}</span>}
                  <span>
                    {' '}
                    · Canale:{' '}
                    {log.sentViaGmailApi
                      ? 'Gmail REST API (OAuth)'
                      : 'Motore Email Automatico'}
                  </span>
                </div>
                <p className="text-xs text-slate-600 whitespace-pre-line">
                  {log.body}
                </p>
                {log.meetLink && (
                  <div className="pt-1 flex items-center gap-1.5 text-xs font-semibold text-blue-600">
                    <Video className="h-3.5 w-3.5" />
                    <span>Link Google Meet incluso: {log.meetLink}</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Per-Job Performance Table */}
      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        <div className="border-b border-slate-200 px-5 py-3.5 flex items-center justify-between">
          <h3 className="text-sm font-bold text-slate-900">
            Dettaglio Performance per Singola Posizione
          </h3>
          <span className="text-xs text-slate-500">
            Database Firestore: findmyjob-510711
          </span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50 text-slate-600">
                <th className="py-3 px-4 font-semibold">Posizione</th>
                <th className="py-3 px-4 font-semibold">Azienda & Città</th>
                <th className="py-3 px-4 font-semibold">Stato</th>
                <th className="py-3 px-4 font-semibold text-right">
                  Candidature
                </th>
                <th className="py-3 px-4 font-semibold text-right">
                  Colloqui Meet
                </th>
                <th className="py-3 px-4 font-semibold text-right">
                  Risposte Inviate
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {jobs.map((job) => {
                const jobApps = applications.filter((a) => a.jobId === job.id);
                const meetCount = jobApps.filter(
                  (a) => a.meetLink.trim().length > 0
                ).length;
                const responded = jobApps.filter(
                  (a) =>
                    a.status !== 'in_review' ||
                    a.employerResponse.trim().length > 0
                ).length;

                return (
                  <tr key={job.id} className="hover:bg-slate-50">
                    <td className="py-3 px-4 font-semibold text-slate-900">
                      {job.title}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      {job.company} · {job.locationName}
                    </td>
                    <td className="py-3 px-4">
                      {job.status === 'open' ? (
                        <span className="inline-flex items-center gap-1 text-emerald-700 font-semibold">
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          <span>Aperta</span>
                        </span>
                      ) : (
                        <span className="text-red-700 font-semibold">
                          Chiusa
                        </span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums font-semibold">
                      {jobApps.length}
                    </td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums text-blue-600 font-semibold">
                      {meetCount}
                    </td>
                    <td className="py-3 px-4 text-right font-mono tabular-nums">
                      {responded} / {jobApps.length}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
