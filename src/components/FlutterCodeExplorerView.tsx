import React, { useState } from 'react';
import { Check, Code2, Copy, Download, Smartphone } from 'lucide-react';
import pubspecRaw from '../../pubspec.yaml?raw';
import firebaseOptionsRaw from '../../lib/firebase_options.dart?raw';
import jobModelsRaw from '../../lib/models/job_models.dart?raw';
import firestoreServiceRaw from '../../lib/services/firestore_recruiting_service.dart?raw';
import workspaceServiceRaw from '../../lib/services/workspace_meet_gmail_service.dart?raw';
import mainDartRaw from '../../lib/main.dart?raw';
import firestoreRulesRaw from '../../firestore.rules?raw';

interface FlutterFileItem {
  path: string;
  label: string;
  description: string;
  content: string;
}

const FLUTTER_FILES: FlutterFileItem[] = [
  {
    path: 'pubspec.yaml',
    label: 'pubspec.yaml',
    description:
      'Dipendenze Flutter: firebase_core, cloud_firestore, firebase_auth, firebase_messaging, google_sign_in, flutter_map, geolocator, file_picker, http.',
    content: pubspecRaw,
  },
  {
    path: 'lib/main.dart',
    label: 'lib/main.dart',
    description:
      'Entrypoint Flutter Material 3 con NavigationBar, Candidatura 1-Click, Mappa FlutterMap, Stato Candidature e Gestionale ATS.',
    content: mainDartRaw,
  },
  {
    path: 'lib/firebase_options.dart',
    label: 'lib/firebase_options.dart',
    description:
      'Configurazione Firebase/Firestore pre-collegata al progetto findmyjob-510711.',
    content: firebaseOptionsRaw,
  },
  {
    path: 'lib/models/job_models.dart',
    label: 'lib/models/job_models.dart',
    description:
      'Modelli Dart (JobOffer, CloudResume, JobApplication, InterviewFeedback) con formula Haversine per il filtro distanza.',
    content: jobModelsRaw,
  },
  {
    path: 'lib/services/firestore_recruiting_service.dart',
    label: 'lib/services/firestore_recruiting_service.dart',
    description:
      'Servizio Cloud Firestore completo: candidatura 1-Click, CV Cloud, risposta obbligatoria datore, chiusura posizione e feedback post-colloquio.',
    content: firestoreServiceRaw,
  },
  {
    path: 'lib/services/workspace_meet_gmail_service.dart',
    label: 'lib/services/workspace_meet_gmail_service.dart',
    description:
      'Integrazione Dart con Google Meet API v2 (1-Tap creazione stanza) e Gmail API (invio mail automatiche RFC 2822).',
    content: workspaceServiceRaw,
  },
  {
    path: 'firestore.rules',
    label: 'firestore.rules',
    description:
      'Regole di sicurezza Cloud Firestore Zero-Trust distribuite sul progetto findmyjob-510711.',
    content: firestoreRulesRaw,
  },
];

interface FlutterCodeExplorerViewProps {
  isFlutterMobileFrame: boolean;
  onToggleFlutterMobileFrame: () => void;
}

export const FlutterCodeExplorerView: React.FC<FlutterCodeExplorerViewProps> = ({
  isFlutterMobileFrame,
  onToggleFlutterMobileFrame,
}) => {
  const [selectedFilePath, setSelectedFilePath] = useState<string>('lib/main.dart');
  const [copiedPath, setCopiedPath] = useState<string | null>(null);

  const activeFile =
    FLUTTER_FILES.find((f) => f.path === selectedFilePath) || FLUTTER_FILES[0];

  const handleCopy = async (file: FlutterFileItem) => {
    await navigator.clipboard.writeText(file.content);
    setCopiedPath(file.path);
    setTimeout(() => setCopiedPath(null), 2000);
  };

  const handleDownloadFile = (file: FlutterFileItem) => {
    const blob = new Blob([file.content], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = file.path.replace(/\//g, '_');
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <h2 className="text-xl font-bold text-slate-900">
            Codice Sorgente Completo Progetto Flutter / Dart
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Tutti i file nativi Flutter (`pubspec.yaml` e `lib/**/*.dart`) sono presenti nel repository e pronti per `flutter run` con Firestore `findmyjob-510711`
          </p>
        </div>

        <button
          type="button"
          onClick={onToggleFlutterMobileFrame}
          className="inline-flex items-center gap-2 px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors whitespace-nowrap shrink-0"
        >
          <Smartphone className="h-4 w-4" />
          <span>
            {isFlutterMobileFrame
              ? 'Torna a Vista Desktop'
              : 'Attiva Simulatore Mobile Flutter'}
          </span>
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left 4 Cols: Flutter File Tree */}
        <div className="lg:col-span-4 rounded-xl border border-slate-200 bg-white overflow-hidden">
          <div className="border-b border-slate-200 px-4 py-3 text-xs font-semibold text-slate-800 flex items-center gap-2">
            <Code2 className="h-4 w-4 text-blue-600" />
            <span>File del Progetto Flutter ({FLUTTER_FILES.length})</span>
          </div>
          <div className="divide-y divide-slate-100">
            {FLUTTER_FILES.map((file) => {
              const isSelected = activeFile.path === file.path;
              return (
                <button
                  key={file.path}
                  type="button"
                  onClick={() => setSelectedFilePath(file.path)}
                  className={`w-full px-4 py-3 text-left transition-colors ${
                    isSelected ? 'bg-blue-50/80' : 'hover:bg-slate-50'
                  }`}
                >
                  <div className="text-xs font-mono font-semibold text-slate-900">
                    {file.label}
                  </div>
                  <div className="text-[11px] text-slate-500 mt-0.5">
                    {file.description}
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Right 8 Cols: Source Code Viewer */}
        <div className="lg:col-span-8 rounded-xl border border-slate-200 bg-slate-900 text-slate-100 overflow-hidden">
          <div className="flex items-center justify-between border-b border-slate-800 px-4 py-3">
            <div>
              <span className="text-xs font-mono font-bold text-blue-400">
                /{activeFile.path}
              </span>
              <p className="text-[11px] text-slate-400 mt-0.5">
                {activeFile.description}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => handleCopy(activeFile)}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-md transition-colors"
              >
                {copiedPath === activeFile.path ? (
                  <>
                    <Check className="h-3.5 w-3.5 text-emerald-400" />
                    <span>Copiato</span>
                  </>
                ) : (
                  <>
                    <Copy className="h-3.5 w-3.5" />
                    <span>Copia Codice</span>
                  </>
                )}
              </button>
              <button
                type="button"
                onClick={() => handleDownloadFile(activeFile)}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-blue-600 hover:bg-blue-500 text-white rounded-md transition-colors"
              >
                <Download className="h-3.5 w-3.5" />
                <span>Scarica</span>
              </button>
            </div>
          </div>

          <pre className="p-4 text-xs font-mono leading-relaxed overflow-x-auto max-h-[560px] overflow-y-auto text-slate-200">
            <code>{activeFile.content}</code>
          </pre>
        </div>
      </div>
    </div>
  );
};
