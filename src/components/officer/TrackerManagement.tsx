import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { GpsTracker } from '../../types';
import { APP_CONFIG } from '../../constants';
import {
  Radio,
  Plus,
  Battery,
  AlertTriangle,
  Compass,
  CheckCircle2,
  Clock,
  MapPin,
  Cpu,
  Layers,
  X,
  Info,
} from 'lucide-react';

interface Props {
  onOpenLiveTracking?: (paroleeId: string) => void;
  onOpenHistory?: (paroleeId: string) => void;
}

export const TrackerManagement: React.FC<Props> = ({ onOpenLiveTracking, onOpenHistory }) => {
  const { trackers, users, createTracker, assignTracker, unassignTracker, getParoleeSummary, notifications } = useApp();

  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newTrackerId, setNewTrackerId] = useState('');
  const [newDevIdentifier, setNewDevIdentifier] = useState('');
  const [createdSummary, setCreatedSummary] = useState<string | null>(null);

  const [assigningTracker, setAssigningTracker] = useState<GpsTracker | null>(null);

  const proximityAlerts = notifications.filter((n) => n.type === 'proximity');
  const parolees = users.filter((u) => u.role === 'parolee');

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTrackerId.trim()) return;

    createTracker(newTrackerId.trim().toUpperCase(), newDevIdentifier.trim());
    setCreatedSummary(newTrackerId.trim().toUpperCase());
    setNewTrackerId('');
    setNewDevIdentifier('');
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Top Banner & Header */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Radio className="w-5 h-5 text-blue-600" />
            <h1 className="text-xl font-bold text-slate-900">GPS Tracker Hardware Management</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Wearable ESP32 IoT beacons, telemetry ingestion, battery health, and proximity alert logs
          </p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl text-xs sm:text-sm shadow-md transition-all flex items-center gap-2 self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>New Tracker</span>
        </button>
      </div>

      {/* Simulated GPS Explanation Banner */}
      <div className="bg-blue-50/70 border border-blue-200 rounded-xl p-4 text-xs text-blue-900 flex items-start gap-3">
        <Info className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <p className="font-semibold text-blue-900">Simulated GPS & Firmware Integration</p>
          <p className="text-[11px] text-blue-800 leading-relaxed">
            Simulated GPS readings are generated in the background around Tacloban City Hall. Officers are automatically
            notified only when a parolee enters the 50 m check-in radius. Being outside the 50 m perimeter does not mark
            the parolee absent.
          </p>
        </div>
      </div>

      {/* Check-in Proximity Alerts Section */}
      {proximityAlerts.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Compass className="w-4 h-4 text-emerald-600" />
            <h2 className="text-xs font-bold uppercase tracking-wider text-slate-600">
              Live Check-In Proximity Alerts ({proximityAlerts.length})
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {proximityAlerts.slice(0, 4).map((alert) => (
              <div
                key={alert.id}
                className="bg-emerald-50/80 border border-emerald-200 rounded-xl p-3.5 flex items-start gap-3"
              >
                <div className="p-2 rounded-lg bg-emerald-100 text-emerald-700 shrink-0 mt-0.5">
                  <Compass className="w-4 h-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-emerald-950 text-xs">{alert.title}</span>
                    <span className="text-[10px] text-emerald-700 font-medium">
                      {new Date(alert.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                  <p className="text-[11px] text-emerald-800 mt-0.5">{alert.message}</p>
                  {alert.paroleeId && (
                    <button
                      onClick={() => onOpenLiveTracking && onOpenLiveTracking(alert.paroleeId!)}
                      className="mt-2 text-[11px] font-semibold text-emerald-900 hover:underline flex items-center gap-1"
                    >
                      <MapPin className="w-3 h-3" /> View on Live Map
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Trackers Inventory Grid */}
      <div className="space-y-3">
        <h2 className="text-xs font-bold uppercase tracking-wider text-slate-600 flex items-center gap-1.5">
          <Cpu className="w-4 h-4 text-slate-500" /> Provisioned Hardware Inventory ({trackers.length})
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {trackers.map((t) => {
            const summary = t.paroleeId ? getParoleeSummary(t.paroleeId) : null;
            const battery = summary?.latestLocation?.batteryLevel ?? t.batteryLevel ?? 100;
            const isLowBattery = battery <= APP_CONFIG.lowBatteryThreshold;

            return (
              <div
                key={t.id}
                className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col justify-between hover:border-blue-300 transition-colors"
              >
                <div>
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-slate-900 text-base">{t.id}</span>
                        <span
                          className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize ${
                            t.status === 'active'
                              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                              : t.status === 'offline'
                              ? 'bg-rose-50 text-rose-700 border border-rose-200'
                              : 'bg-slate-100 text-slate-600'
                          }`}
                        >
                          {t.status}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5">{t.deviceName || t.deviceIdentifier}</p>
                    </div>

                    {/* Battery Indicator */}
                    <div
                      className={`flex items-center gap-1 text-xs font-bold px-2 py-1 rounded-lg ${
                        isLowBattery
                          ? 'bg-rose-50 text-rose-700 border border-rose-200'
                          : 'bg-slate-100 text-slate-700'
                      }`}
                    >
                      <Battery className={`w-3.5 h-3.5 ${isLowBattery ? 'text-rose-600' : 'text-slate-500'}`} />
                      <span>{battery}%</span>
                    </div>
                  </div>

                  {/* Telemetry rows */}
                  <div className="mt-4 pt-3 border-t border-slate-100 space-y-2 text-xs">
                    <div className="flex items-center justify-between text-slate-600">
                      <span className="text-slate-400">Assigned To:</span>
                      <span className="font-semibold text-slate-900">{t.paroleeName || 'Unassigned'}</span>
                    </div>

                    <div className="flex items-center justify-between text-slate-600">
                      <span className="text-slate-400">Serial Number:</span>
                      <span className="font-mono text-[11px] text-slate-700">{t.serialNumber || 'SN-TAC-000'}</span>
                    </div>

                    <div className="flex items-center justify-between text-slate-600">
                      <span className="text-slate-400">Proximity to Office:</span>
                      <span className="font-medium text-slate-900">
                        {summary?.checkInProximity.distanceMeters !== undefined
                          ? `${summary.checkInProximity.distanceMeters}m`
                          : 'N/A'}
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-slate-600">
                      <span className="text-slate-400">Last Telemetry:</span>
                      <span className="text-slate-500 text-[11px]">
                        {t.lastSeenAt ? new Date(t.lastSeenAt).toLocaleTimeString() : 'Just now'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Card Actions */}
                <div className="mt-5 pt-3 border-t border-slate-100 flex items-center gap-2">
                  {t.paroleeId ? (
                    <>
                      <button
                        onClick={() => onOpenLiveTracking && onOpenLiveTracking(t.paroleeId!)}
                        className="flex-1 py-1.5 px-3 bg-blue-50 hover:bg-blue-100 text-blue-700 text-xs font-semibold rounded-lg transition-colors flex items-center justify-center gap-1"
                      >
                        <MapPin className="w-3.5 h-3.5" /> Track Live
                      </button>
                      <button
                        onClick={() => unassignTracker(t.id)}
                        className="py-1.5 px-3 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-medium rounded-lg transition-colors"
                      >
                        Unassign
                      </button>
                    </>
                  ) : (
                    <button
                      onClick={() => setAssigningTracker(t)}
                      className="w-full py-1.5 px-3 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-lg transition-colors"
                    >
                      Assign to Parolee
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Create Tracker Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="font-bold text-base text-slate-900">Register New GPS Tracker</h3>
              <button onClick={() => setShowCreateModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateSubmit} className="mt-4 space-y-3">
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">
                  Tracker ID (e.g. TRK-005)
                </label>
                <input
                  type="text"
                  placeholder="TRK-005"
                  value={newTrackerId}
                  onChange={(e) => setNewTrackerId(e.target.value)}
                  className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">
                  Device Hardware Identifier
                </label>
                <input
                  type="text"
                  placeholder="ESP32-TAC-05"
                  value={newDevIdentifier}
                  onChange={(e) => setNewDevIdentifier(e.target.value)}
                  className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                />
              </div>

              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-[11px] text-slate-600 space-y-1">
                <p className="font-semibold text-slate-800">Firmware Provisioning Guide:</p>
                <p>1. Put <code>TRACKER_ID</code> in <code>firmware/gps_tracker/device_config.h</code>.</p>
                <p>2. Suggested device email: <code>trk-005@pptac-attendance-capstone.web.app</code>.</p>
              </div>

              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-xs font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-semibold transition-colors"
                >
                  Create Hardware Tracker
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Created Tracker Dialog */}
      {createdSummary && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
            <CheckCircle2 className="w-10 h-10 text-emerald-600 mb-2" />
            <h3 className="font-bold text-base text-slate-900">Tracker {createdSummary} Registered</h3>
            <p className="text-xs text-slate-600 mt-2 leading-relaxed">
              Hardware beacon is ready in the inventory. You can now bind it to any active parolee for real-time
              surveillance.
            </p>
            <button
              onClick={() => setCreatedSummary(null)}
              className="mt-5 w-full py-2 bg-slate-900 hover:bg-black text-white text-xs font-semibold rounded-xl"
            >
              Done
            </button>
          </div>
        </div>
      )}

      {/* Assign to Parolee Dialog */}
      {assigningTracker && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
            <h3 className="font-bold text-base text-slate-900">Assign {assigningTracker.id}</h3>
            <p className="text-xs text-slate-500 mt-1">Select parolee to attach this beacon</p>

            <div className="mt-4 space-y-2 max-h-60 overflow-y-auto">
              {parolees.map((p) => (
                <button
                  key={p.id}
                  onClick={() => {
                    assignTracker(assigningTracker.id, p.id);
                    setAssigningTracker(null);
                  }}
                  className="w-full p-3 rounded-xl text-left border border-slate-200 hover:bg-blue-50 hover:border-blue-300 text-xs transition-colors"
                >
                  <p className="font-semibold text-slate-900">{p.fullName}</p>
                  <p className="text-[11px] text-slate-500">Case: {p.caseNumber || 'N/A'}</p>
                </button>
              ))}
            </div>

            <button
              onClick={() => setAssigningTracker(null)}
              className="mt-4 w-full py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-xs font-semibold"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
