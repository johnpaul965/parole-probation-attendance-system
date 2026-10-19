import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { LeafletMap } from '../common/LeafletMap';
import {
  Radio,
  MapPin,
  Battery,
  Shield,
  ShieldAlert,
  AlertTriangle,
  RefreshCw,
  Navigation,
  Compass,
  Zap,
  Volume2
} from 'lucide-react';

export const LiveTrackingView: React.FC = () => {
  const { trackers, updateTracker, simulateGpsMovement, simulateGeofenceBreach } = useApp();
  const [selectedTrackerId, setSelectedTrackerId] = useState<string>(trackers[0]?.id || '');
  const [buzzerMessage, setBuzzerMessage] = useState<string | null>(null);

  const selectedTracker = trackers.find(t => t.id === selectedTrackerId) || trackers[0];

  const handleTriggerBuzzer = (trackerId: string) => {
    setBuzzerMessage(`Audible buzzer & vibration dispatched to IoT device ${trackerId}. Tone sounding for 30s.`);
    setTimeout(() => {
      setBuzzerMessage(null);
    }, 4500);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Real-Time GPS Tracking & Geofence Console
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Active cellular GPS triangulation, speed monitoring, and curfew perimeter boundary enforcement.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => simulateGpsMovement(selectedTrackerId)}
            className="px-3 py-1.5 text-xs font-semibold bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors flex items-center gap-1.5 shadow-2xs"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            Update Coordinates
          </button>
          <button
            onClick={() => handleTriggerBuzzer(selectedTrackerId)}
            className="px-3.5 py-1.5 text-xs font-semibold bg-amber-500 text-white rounded-lg hover:bg-amber-600 transition-colors flex items-center gap-1.5 shadow-xs"
          >
            <Volume2 className="w-3.5 h-3.5" />
            Trigger Device Buzzer
          </button>
        </div>
      </div>

      {buzzerMessage && (
        <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-900 flex items-center gap-2 animate-fadeIn">
          <Volume2 className="w-4 h-4 text-amber-600 shrink-0" />
          <span>{buzzerMessage}</span>
        </div>
      )}

      {/* Main Map + Side Subject Telemetry Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Left 3 cols: Full Interactive Map */}
        <div className="lg:col-span-3">
          <LeafletMap
            trackers={trackers}
            selectedTrackerId={selectedTrackerId}
            onSelectTracker={(t) => setSelectedTrackerId(t.id)}
            height="580px"
          />
        </div>

        {/* Right 1 col: Subject List & Telemetry Box */}
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs">
            <h3 className="text-xs font-bold text-slate-900 uppercase tracking-wider mb-3">
              Monitored Subjects ({trackers.length})
            </h3>
            <div className="space-y-2 max-h-72 overflow-y-auto">
              {trackers.map(t => {
                const isSelected = t.id === selectedTrackerId;
                const isBreach = t.status === 'breach';
                return (
                  <button
                    key={t.id}
                    onClick={() => setSelectedTrackerId(t.id)}
                    className={`w-full text-left p-3 rounded-lg border transition-all text-xs ${
                      isSelected
                        ? 'border-slate-900 bg-slate-900 text-white'
                        : isBreach
                        ? 'border-red-200 bg-red-50 text-red-900 hover:bg-red-100'
                        : 'border-slate-200 bg-white hover:bg-slate-50 text-slate-700'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-bold truncate">{t.assignedParoleeName}</span>
                      <span className={`text-[10px] font-semibold px-1.5 py-0.2 rounded capitalize ${
                        isSelected ? 'bg-white/20 text-white' :
                        isBreach ? 'bg-red-200 text-red-800' : 'bg-slate-100 text-slate-600'
                      }`}>
                        {t.status}
                      </span>
                    </div>
                    <div className={`mt-1 flex items-center justify-between text-[11px] ${isSelected ? 'text-slate-300' : 'text-slate-500'}`}>
                      <span>{t.id}</span>
                      <span>{t.batteryLevel}% Batt</span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Telemetry Inspector Box */}
          {selectedTracker && (
            <div className="bg-white rounded-xl border border-slate-200 p-4 text-xs space-y-3 shadow-xs">
              <h4 className="font-bold text-slate-900 border-b border-slate-100 pb-2 flex items-center justify-between">
                <span>{selectedTracker.assignedParoleeName}</span>
                <span className="text-[11px] font-mono text-slate-400">{selectedTracker.id}</span>
              </h4>

              <div className="space-y-2 text-slate-600 text-xs">
                <div className="flex justify-between">
                  <span>Velocity:</span>
                  <span className="font-bold text-slate-900 tabular-nums">{selectedTracker.currentLocation.speedKmH} km/h</span>
                </div>
                <div className="flex justify-between">
                  <span>GPS Precision:</span>
                  <span className="font-medium text-slate-800">±{selectedTracker.currentLocation.accuracy}m</span>
                </div>
                <div className="flex justify-between">
                  <span>Curfew Radius:</span>
                  <span className="font-bold text-blue-600">{selectedTracker.geofenceRadiusMeters} meters</span>
                </div>
                <div className="flex justify-between">
                  <span>Last Location Ping:</span>
                  <span className="font-medium text-slate-700">{selectedTracker.lastPing}</span>
                </div>
                <div className="pt-2 border-t border-slate-100">
                  <span className="text-slate-400 text-[11px] block">Address:</span>
                  <span className="text-slate-800 font-medium block mt-0.5">{selectedTracker.currentLocation.address}</span>
                </div>
              </div>

              <div className="pt-2 border-t border-slate-100 flex gap-2">
                <button
                  onClick={() => simulateGeofenceBreach(selectedTracker.id)}
                  className="w-full py-1.5 bg-red-50 text-red-700 border border-red-200 rounded-lg text-xs font-semibold hover:bg-red-100"
                >
                  Test Breach Alert
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
