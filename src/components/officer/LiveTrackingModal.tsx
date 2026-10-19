import React from 'react';
import { useApp } from '../../context/AppContext';
import { LeafletMap } from '../common/LeafletMap';
import {
  X,
  Compass,
  Battery,
  Shield,
  MapPin,
  RefreshCw,
  History,
  AlertTriangle,
  CheckCircle2,
  Radio,
} from 'lucide-react';

interface Props {
  paroleeId: string;
  isOpen: boolean;
  onClose: () => void;
  onOpenHistory?: (paroleeId: string) => void;
}

export const LiveTrackingModal: React.FC<Props> = ({
  paroleeId,
  isOpen,
  onClose,
  onOpenHistory,
}) => {
  const { users, liveLocations, getParoleeSummary } = useApp();

  if (!isOpen) return null;

  const parolee = users.find((u) => u.id === paroleeId);
  const summary = getParoleeSummary(paroleeId);
  const loc = summary?.latestLocation || liveLocations[paroleeId];

  const isWithinProx = summary?.checkInProximity.isWithinProximity;
  const isInsideGeofence = summary?.geofenceStatus === 'inside';

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 overflow-y-auto">
      <div className="bg-white rounded-2xl max-w-4xl w-full shadow-2xl border border-slate-200 overflow-hidden flex flex-col my-auto max-h-[90vh]">
        {/* Header */}
        <div className="bg-[#1565C0] text-white px-6 py-4 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-xl bg-white/10">
              <MapPin className="w-5 h-5 text-blue-200" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-bold text-base">{parolee?.fullName || 'Parolee Live GPS Tracking'}</h3>
                <span className="text-[10px] font-semibold uppercase px-2 py-0.5 rounded-full bg-white/20">
                  {parolee?.caseNumber || 'Active'}
                </span>
              </div>
              <p className="text-xs text-blue-100">
                Hardware Beacon: {summary?.tracker?.id || 'TRK-001'} • Real-Time Tacloban Coordinates
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {onOpenHistory && (
              <button
                onClick={() => {
                  onClose();
                  onOpenHistory(paroleeId);
                }}
                className="px-3 py-1.5 bg-white/10 hover:bg-white/20 text-white rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors"
              >
                <History className="w-4 h-4" />
                <span>History</span>
              </button>
            )}
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg text-white/80 hover:text-white hover:bg-white/10 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Map Area */}
        <div className="p-4 sm:p-6 space-y-4 overflow-y-auto flex-1">
          {/* Status Badges Row */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {/* Proximity Status */}
            <div
              className={`p-3 rounded-xl border flex items-center gap-2.5 ${
                isWithinProx
                  ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
                  : 'bg-slate-50 border-slate-200 text-slate-800'
              }`}
            >
              <Compass className={`w-5 h-5 ${isWithinProx ? 'text-emerald-600' : 'text-slate-400'}`} />
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider block text-slate-500">
                  Check-in Proximity (50m)
                </span>
                <span className="text-xs font-bold">
                  {isWithinProx ? 'INSIDE 50M PERIMETER' : `${summary?.checkInProximity.distanceMeters ?? '—'}m FROM OFFICE`}
                </span>
              </div>
            </div>

            {/* Geofence Status */}
            <div
              className={`p-3 rounded-xl border flex items-center gap-2.5 ${
                isInsideGeofence
                  ? 'bg-blue-50 border-blue-200 text-blue-900'
                  : 'bg-amber-50 border-amber-200 text-amber-900'
              }`}
            >
              <Shield className={`w-5 h-5 ${isInsideGeofence ? 'text-blue-600' : 'text-amber-600'}`} />
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider block text-slate-500">
                  Monitoring Zone
                </span>
                <span className="text-xs font-bold uppercase">
                  {summary?.geofenceStatus === 'inside'
                    ? 'Inside Assigned Area'
                    : summary?.geofenceStatus === 'outside'
                    ? 'Outside Assigned Area'
                    : 'Monitoring Zone Active'}
                </span>
              </div>
            </div>

            {/* Hardware Status & Battery */}
            <div className="p-3 rounded-xl border border-slate-200 bg-slate-50 flex items-center gap-2.5">
              <Battery className="w-5 h-5 text-slate-600" />
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider block text-slate-500">
                  Beacon Battery
                </span>
                <span className="text-xs font-bold text-slate-900">
                  {loc?.batteryLevel ?? summary?.tracker?.batteryLevel ?? 84}% • {summary?.tracker?.status || 'Active'}
                </span>
              </div>
            </div>
          </div>

          {/* Leaflet Map */}
          <div className="rounded-xl overflow-hidden shadow-xs border border-slate-200">
            <LeafletMap
              location={loc}
              geofences={summary?.geofences}
              height="380px"
            />
          </div>

          {/* Telemetry Detail Table */}
          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 text-xs">
            <div className="flex items-center justify-between mb-3 border-b border-slate-200 pb-2">
              <span className="font-bold text-slate-900 flex items-center gap-1.5">
                <Radio className="w-4 h-4 text-blue-600" /> Live GPS Telemetry Stream
              </span>
              <span className="text-[11px] text-slate-500 font-medium">
                Pinging every 4 seconds • Tacloban City Grid
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Latitude</span>
                <span className="font-mono font-medium text-slate-800">{loc?.latitude ?? '11.240800'}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Longitude</span>
                <span className="font-mono font-medium text-slate-800">{loc?.longitude ?? '125.003900'}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Speed & Bearing</span>
                <span className="font-medium text-slate-800">
                  {loc?.speed ?? '2.1'} km/h • {loc?.heading ?? '45'}°
                </span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Horizontal Accuracy</span>
                <span className="font-medium text-slate-800">±{loc?.accuracy ?? '4.8'} meters</span>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="bg-slate-50 px-6 py-3 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500 shrink-0">
          <span>Proximity verification radius: 50m</span>
          <button
            onClick={onClose}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-900 text-white rounded-xl font-semibold transition-colors"
          >
            Close Live Map
          </button>
        </div>
      </div>
    </div>
  );
};
