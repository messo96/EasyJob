import React, { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import { Compass, MapPin, Navigation, Search, Send } from 'lucide-react';
import { CityLocation, JobApplication, JobOffer } from '../types';
import { ITALIAN_CITIES } from '../data/seedData';
import { filterJobsByCriteria } from '../utils/recruitingLogic';

interface InteractiveMapViewProps {
  jobs: JobOffer[];
  applications: JobApplication[];
  userLocation: CityLocation;
  onChangeUserLocation: (loc: CityLocation) => void;
  maxDistanceKm: number;
  onChangeMaxDistanceKm: (km: number) => void;
  searchQuery: string;
  onChangeSearchQuery: (q: string) => void;
  onOpenApplyModal: (job: JobOffer) => void;
}

export const InteractiveMapView: React.FC<InteractiveMapViewProps> = ({
  jobs,
  applications,
  userLocation,
  onChangeUserLocation,
  maxDistanceKm,
  onChangeMaxDistanceKm,
  searchQuery,
  onChangeSearchQuery,
  onOpenApplyModal,
}) => {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersLayerRef = useRef<L.LayerGroup | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('Tutte');
  const [selectedJobId, setSelectedJobId] = useState<string | null>(
    jobs[0]?.id || null
  );
  const [geoStatus, setGeoStatus] = useState<string>('');

  const filteredJobs = filterJobsByCriteria(jobs, {
    query: searchQuery,
    category: selectedCategory,
    contractType: 'Tutti',
    userLat: userLocation.latitude,
    userLon: userLocation.longitude,
    maxDistanceKm,
    includeClosed: false,
  });

  const activeSelectedJob =
    filteredJobs.find((j) => j.id === selectedJobId) || filteredJobs[0] || null;

  const handleLocateMe = () => {
    if (!navigator.geolocation) {
      setGeoStatus('Geolocalizzazione non supportata dal browser.');
      return;
    }
    setGeoStatus('Rilevamento posizione GPS...');
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        onChangeUserLocation({
          name: 'La mia posizione GPS',
          latitude: Math.round(pos.coords.latitude * 10000) / 10000,
          longitude: Math.round(pos.coords.longitude * 10000) / 10000,
          region: 'GPS Attivo',
        });
        setGeoStatus('Posizione GPS aggiornata');
      },
      () => {
        setGeoStatus('Impossibile leggere il GPS; usa il selettore città.');
      },
      { timeout: 6000 }
    );
  };

  // Initialize Leaflet map once
  useEffect(() => {
    if (!mapContainerRef.current || mapInstanceRef.current) return;

    const map = L.map(mapContainerRef.current, {
      center: [userLocation.latitude, userLocation.longitude],
      zoom: 6,
      zoomControl: true,
    });

    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 18,
    }).addTo(map);

    const layerGroup = L.layerGroup().addTo(map);
    mapInstanceRef.current = map;
    markersLayerRef.current = layerGroup;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
      markersLayerRef.current = null;
    };
  }, []);

  // Update markers and radius circle when filters or userLocation change
  useEffect(() => {
    const map = mapInstanceRef.current;
    const layerGroup = markersLayerRef.current;
    if (!map || !layerGroup) return;

    layerGroup.clearLayers();

    // User location marker + radius circle
    const userIcon = L.divIcon({
      className: 'custom-user-pin',
      html: `<div style="width:18px;height:18px;border-radius:9999px;background:#0F172A;border:3px solid #FFFFFF;box-shadow:0 2px 6px rgba(0,0,0,0.35);"></div>`,
      iconSize: [18, 18],
      iconAnchor: [9, 9],
    });

    L.marker([userLocation.latitude, userLocation.longitude], { icon: userIcon })
      .bindPopup(`<strong>La tua posizione:</strong><br/>${userLocation.name}`)
      .addTo(layerGroup);

    if (maxDistanceKm > 0 && maxDistanceKm <= 600) {
      L.circle([userLocation.latitude, userLocation.longitude], {
        radius: maxDistanceKm * 1000,
        color: '#2563EB',
        weight: 1.5,
        fillColor: '#3B82F6',
        fillOpacity: 0.08,
      }).addTo(layerGroup);
    }

    // Job markers
    filteredJobs.forEach((job) => {
      const isSelected = activeSelectedJob?.id === job.id;
      const pinColor = isSelected ? '#1D4ED8' : '#2563EB';
      const scale = isSelected ? 'scale(1.12)' : 'scale(1)';

      const jobIcon = L.divIcon({
        className: 'custom-job-pin',
        html: `<div style="transform:${scale};display:inline-flex;align-items:center;gap:4px;background:${pinColor};color:#FFFFFF;font-weight:600;font-size:11px;padding:4px 8px;border-radius:6px;border:2px solid #FFFFFF;box-shadow:0 3px 8px rgba(15,23,42,0.28);white-space:nowrap;">
          <span>${job.company.split(' ')[0]}</span>
          <span style="opacity:0.85;font-family:monospace;">${job.distanceKm}km</span>
        </div>`,
        iconSize: [110, 28],
        iconAnchor: [55, 14],
      });

      const marker = L.marker([job.latitude, job.longitude], { icon: jobIcon });
      marker.on('click', () => {
        setSelectedJobId(job.id);
      });
      marker.addTo(layerGroup);
    });
  }, [filteredJobs, userLocation, maxDistanceKm, activeSelectedJob?.id]);

  const handleCitySelect = (cityName: string) => {
    const found = ITALIAN_CITIES.find((c) => c.name === cityName);
    if (found) {
      onChangeUserLocation(found);
      if (mapInstanceRef.current) {
        mapInstanceRef.current.setView([found.latitude, found.longitude], 7, {
          animate: true,
        });
      }
    }
  };

  const focusJobOnMap = (job: JobOffer) => {
    setSelectedJobId(job.id);
    if (mapInstanceRef.current) {
      mapInstanceRef.current.setView([job.latitude, job.longitude], 11, {
        animate: true,
      });
    }
  };

  return (
    <div className="space-y-6">
      {/* Filter Controls Bar */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-end">
          {/* Position / Role search */}
          <div className="md:col-span-4">
            <label
              htmlFor="map-role-search"
              className="block text-xs font-semibold text-slate-700 mb-1.5"
            >
              Filtra per Posizione Lavorativa o Competenze
            </label>
            <div className="relative">
              <Search className="h-4 w-4 text-slate-400 absolute left-3 top-2.5" />
              <input
                id="map-role-search"
                type="text"
                value={searchQuery}
                onChange={(e) => onChangeSearchQuery(e.target.value)}
                placeholder="Es. Flutter, Cloud Architect, Designer..."
                className="w-full rounded-lg border border-slate-300 bg-white pl-9 pr-3 py-2 text-sm text-slate-900 focus:border-blue-600 focus:outline-hidden"
              />
            </div>
          </div>

          {/* User Base Location */}
          <div className="md:col-span-3">
            <label
              htmlFor="map-city-select"
              className="block text-xs font-semibold text-slate-700 mb-1.5"
            >
              La Tua Posizione di Partenza
            </label>
            <div className="flex items-center gap-2">
              <select
                id="map-city-select"
                value={
                  ITALIAN_CITIES.some((c) => c.name === userLocation.name)
                    ? userLocation.name
                    : ITALIAN_CITIES[0].name
                }
                onChange={(e) => handleCitySelect(e.target.value)}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-blue-600 focus:outline-hidden"
              >
                {ITALIAN_CITIES.map((city) => (
                  <option key={city.name} value={city.name}>
                    {city.name}
                  </option>
                ))}
              </select>
              <button
                type="button"
                onClick={handleLocateMe}
                title="Usa la mia posizione GPS attuale"
                aria-label="Usa posizione GPS attuale"
                className="rounded-lg border border-slate-300 bg-slate-50 p-2 text-slate-700 hover:bg-slate-100 transition-colors shrink-0"
              >
                <Navigation className="h-4 w-4 text-blue-600" />
              </button>
            </div>
          </div>

          {/* Category Filter */}
          <div className="md:col-span-2">
            <label
              htmlFor="map-category-select"
              className="block text-xs font-semibold text-slate-700 mb-1.5"
            >
              Settore / Area
            </label>
            <select
              id="map-category-select"
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-blue-600 focus:outline-hidden"
            >
              <option value="Tutte">Tutte le aree</option>
              <option value="Mobile & Flutter">Mobile & Flutter</option>
              <option value="Cloud & Backend">Cloud & Backend</option>
              <option value="Design & UX">Design & UX</option>
              <option value="AI & Data Science">AI & Data Science</option>
              <option value="Frontend & Web">Frontend & Web</option>
            </select>
          </div>

          {/* Distance Slider */}
          <div className="md:col-span-3">
            <div className="flex items-center justify-between text-xs font-semibold text-slate-700 mb-1.5">
              <label htmlFor="map-distance-range">Raggio Massima Distanza</label>
              <span className="font-mono tabular-nums text-blue-600">
                {maxDistanceKm >= 800 ? 'Tutta Italia (800 km)' : `${maxDistanceKm} km`}
              </span>
            </div>
            <input
              id="map-distance-range"
              type="range"
              min={10}
              max={800}
              step={10}
              value={maxDistanceKm}
              onChange={(e) => onChangeMaxDistanceKm(Number(e.target.value))}
              className="w-full accent-blue-600 cursor-pointer"
            />
          </div>
        </div>

        {geoStatus && (
          <p className="mt-2 text-xs text-slate-500">{geoStatus}</p>
        )}
      </div>

      {/* Interactive Map + Nearby Jobs Split Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        {/* Map Viewport */}
        <div className="lg:col-span-7 rounded-xl border border-slate-200 bg-white overflow-hidden flex flex-col">
          <div className="flex items-center justify-between border-b border-slate-200 px-4 py-3">
            <div className="flex items-center gap-2 text-xs text-slate-600">
              <Compass className="h-4 w-4 text-blue-600" />
              <span className="font-semibold text-slate-900">
                Mappa Geografica Offerte di Lavoro
              </span>
              <span aria-hidden="true">·</span>
              <span className="font-mono tabular-nums">
                {filteredJobs.length} posizioni nel raggio di {maxDistanceKm} km
              </span>
            </div>
            <span className="text-xs text-slate-500 font-mono tabular-nums">
              {userLocation.latitude.toFixed(2)}°N, {userLocation.longitude.toFixed(2)}°E
            </span>
          </div>
          <div
            ref={mapContainerRef}
            data-testid="interactive-jobs-map"
            className="w-full h-[460px] lg:flex-1 bg-slate-100"
          />
        </div>

        {/* Selected Job & Nearby List Panel */}
        <div className="lg:col-span-5 flex flex-col gap-4">
          {activeSelectedJob ? (
            <div className="rounded-xl border border-slate-200 bg-white p-5 space-y-4">
              <div>
                <div className="flex items-center justify-between text-xs text-slate-500">
                  <span>{activeSelectedJob.category}</span>
                  <span className="font-mono tabular-nums text-blue-600 font-semibold">
                    Distanza: {activeSelectedJob.distanceKm} km
                  </span>
                </div>
                <h3 className="text-lg font-bold text-slate-900 mt-1">
                  {activeSelectedJob.title}
                </h3>
                <p className="text-xs text-slate-600 mt-0.5">
                  {activeSelectedJob.company} · {activeSelectedJob.locationName} ·{' '}
                  {activeSelectedJob.contractType} ·{' '}
                  <span className="font-mono tabular-nums font-medium text-slate-900">
                    {activeSelectedJob.salaryRange}
                  </span>
                </p>
              </div>

              <p className="text-xs text-slate-600 leading-relaxed">
                {activeSelectedJob.description}
              </p>

              <div className="text-xs text-slate-500 border-t border-slate-100 pt-3">
                <span className="font-semibold text-slate-700">Requisiti: </span>
                {activeSelectedJob.requirements}
              </div>

              <div className="flex items-center justify-between pt-2">
                <span className="text-xs text-slate-500">
                  Recruiter: {activeSelectedJob.recruiterName}
                </span>
                {applications.some(
                  (a) =>
                    a.jobId === activeSelectedJob.id &&
                    a.candidateId === 'demo-user-1'
                ) ? (
                  <span className="text-xs font-semibold text-emerald-700">
                    Candidatura già inviata
                  </span>
                ) : (
                  <button
                    type="button"
                    aria-label={`Candidati con 1 Clic per ${activeSelectedJob.title}`}
                    onClick={() => onOpenApplyModal(activeSelectedJob)}
                    className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors whitespace-nowrap shrink-0"
                  >
                    <Send className="h-3.5 w-3.5" />
                    <span>Candidati con 1 Clic</span>
                  </button>
                )}
              </div>
            </div>
          ) : (
            <div className="rounded-xl border border-slate-200 bg-white p-6 text-center space-y-2">
              <p className="text-sm font-semibold text-slate-900">
                Nessuna offerta entro {maxDistanceKm} km
              </p>
              <p className="text-xs text-slate-500">
                Aumenta il raggio di distanza o modifica la ricerca per visualizzare più annunci sulla mappa.
              </p>
              <button
                type="button"
                onClick={() => onChangeMaxDistanceKm(800)}
                className="mt-2 px-4 py-2 text-xs font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Mostra tutta Italia (800 km)
              </button>
            </div>
          )}

          {/* Scrollable List of Nearby Offers */}
          <div className="rounded-xl border border-slate-200 bg-white overflow-hidden flex-1">
            <div className="border-b border-slate-200 px-4 py-3 text-xs font-semibold text-slate-800">
              Offerte ordinate per prossimità ({filteredJobs.length})
            </div>
            <div className="divide-y divide-slate-100 max-h-[260px] overflow-y-auto">
              {filteredJobs.map((job) => {
                const isSelected = activeSelectedJob?.id === job.id;
                return (
                  <button
                    key={job.id}
                    type="button"
                    onClick={() => focusJobOnMap(job)}
                    className={`w-full px-4 py-3 text-left transition-colors flex items-center justify-between gap-3 ${
                      isSelected ? 'bg-blue-50/70' : 'hover:bg-slate-50'
                    }`}
                  >
                    <div className="min-w-0">
                      <div className="text-xs font-semibold text-slate-900 truncate">
                        {job.title}
                      </div>
                      <div className="text-xs text-slate-500 truncate mt-0.5">
                        {job.company} · {job.locationName}
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <div className="text-xs font-mono tabular-nums font-semibold text-blue-600 flex items-center justify-end gap-1">
                        <MapPin className="h-3 w-3" />
                        <span>{job.distanceKm} km</span>
                      </div>
                      <div className="text-[11px] font-mono tabular-nums text-slate-500">
                        {job.contractType}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
