import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { LeafletMap } from '../common/LeafletMap';
import {
  X,
  History,
  Calendar,
  Clock,
  MapPin,
  Play,
  Pause,
  RotateCcw,
  Compass,
} from 'lucide-react';

interface Props {
  paroleeId: string;
  isOpen: boolean;
  onClose: () => void;
}

export const LocationHistoryModal: React.FC<Props> = ({
  paroleeId,
  isOpen,
  onClose,
}) => {
  const { users, locationHistories, getParoleeSummary } = useApp();
  const [selectedPointIndex, setSelectedPointIndex] = useState<number>(0);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);

  if (!isOpen) return null;

  const parolee = users.find((u) => u.id === paroleeId);
  const summary = getParoleeSummary(paroleeId);
  const history = locationHistories[paroleeId] || [];

  const activePoint = history[selectedPointIndex] || history[0];

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 overflow-y-auto">
      <div className="bg-white rounded-2xl max-w-4xl w-full shadow-2xl border border-slate-200 overflow-hidden flex flex-col my-auto max-h-[90vh]">
        {/* Header */}
        <div className="bg-[#1565C0] text-white px-6 py-4 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-xl bg-white/10">
              <History className="w-5 h-5 text-blue-200" />
            </div>
            <div>
              <h3 className="font-bold text-base">
                Location History Trail: {parolee?.fullName || 'Parolee'}
              </h3>
              <p className="text-xs text-blue-100">
                Route Breadcrumbs & Movement Playback • Tacloban City
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-white/80 hover:text-white hover:bg-white/10 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-4 sm:p-6 space-y-4 overflow-y-auto flex-1">
          {/* Map with Polyline History Trail */}
          <div className="rounded-xl overflow-hidden shadow-xs border border-slate-200">
            <LeafletMap
              location={activePoint}
              history={history}
              geofences={summary?.geofences}
              height="340px"
            />
          </div>

          {/* Timeline and Trail Logs */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Playback Controls */}
            <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 text-xs space-y-3">
              <h4 className="font-bold text-slate-800 uppercase tracking-wider text-[11px]">
                Playback Controls
              </h4>
              <p className="text-slate-500 text-[11px]">
                {history.length} breadcrumb waypoints recorded during current supervision period.
              </p>

              <div className="flex items-center gap-2 pt-2">
                <button
                  onClick={() => {
                    if (selectedPointIndex > 0) {
                      setSelectedPointIndex(selectedPointIndex - 1);
                    }
                  }}
                  className="px-3 py-1.5 bg-white border border-slate-200 hover:bg-slate-100 rounded-lg font-semibold"
                >
                  Step Prev
                </button>
                <button
                  onClick={() => {
                    if (selectedPointIndex < history.length - 1) {
                      setSelectedPointIndex(selectedPointIndex + 1);
                    }
                  }}
                  className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold"
                >
                  Step Next
                </button>
                <button
                  onClick={() => setSelectedPointIndex(0)}
                  className="p-1.5 bg-white border border-slate-200 hover:bg-slate-100 rounded-lg text-slate-600"
                  title="Reset to latest"
                >
                  <RotateCcw className="w-4 h-4" />
                </button>
              </div>

              {activePoint && (
                <div className="p-2.5 rounded-lg bg-blue-50/70 border border-blue-100 text-[11px] text-blue-900 space-y-1">
                  <p className="font-semibold">Waypoint #{selectedPointIndex + 1}:</p>
                  <p>Lat: {activePoint.latitude}, Lng: {activePoint.longitude}</p>
                  <p>Time: {new Date(activePoint.recordedAt).toLocaleString()}</p>
                </div>
              )}
            </div>

            {/* Breadcrumb List */}
            <div className="md:col-span-2 bg-white border border-slate-200 rounded-xl p-4 text-xs">
              <h4 className="font-bold text-slate-800 uppercase tracking-wider text-[11px] mb-2">
                Recorded Location Breadcrumbs
              </h4>

              <div className="max-h-56 overflow-y-auto divide-y divide-slate-100">
                {history.length === 0 ? (
                  <p className="text-slate-400 py-6 text-center">No location history recorded</p>
                ) : (
                  history.map((record, idx) => (
                    <div
                      key={record.id || idx}
                      onClick={() => setSelectedPointIndex(idx)}
                      className={`py-2 px-2.5 flex items-center justify-between cursor-pointer rounded-lg transition-colors ${
                        selectedPointIndex === idx ? 'bg-blue-50 text-blue-900 font-semibold' : 'hover:bg-slate-50'
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className="w-5 text-center text-slate-400 font-mono text-[10px]">{idx + 1}</span>
                        <div>
                          <p className="text-slate-900 font-medium">
                            {record.latitude.toFixed(6)}, {record.longitude.toFixed(6)}
                          </p>
                          <p className="text-[10px] text-slate-400">
                            {new Date(record.recordedAt).toLocaleTimeString()} • ±{record.accuracy || 5}m accuracy
                          </p>
                        </div>
                      </div>
                      <span className="text-[10px] px-2 py-0.5 rounded-md bg-slate-100 text-slate-600 font-mono">
                        {record.speed ? `${record.speed} km/h` : '0 km/h'}
                      </span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="bg-slate-50 px-6 py-3 border-t border-slate-200 flex items-center justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-900 text-white rounded-xl text-xs font-semibold"
          >
            Close History
          </button>
        </div>
      </div>
    </div>
  );
};
