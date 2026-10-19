import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { GpsTracker } from '../../types';
import {
  Radio,
  Battery,
  BatteryCharging,
  Shield,
  ShieldAlert,
  AlertOctagon,
  Settings,
  RefreshCw,
  Search,
  CheckCircle2,
  Cpu
} from 'lucide-react';

export const TrackerManagement: React.FC = () => {
  const { trackers, updateTracker, users, simulateGpsMovement, simulateGeofenceBreach } = useApp();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTracker, setSelectedTracker] = useState<GpsTracker | null>(null);
  const [editRadius, setEditRadius] = useState<number>(500);

  const parolees = users.filter(u => u.role === 'parolee');

  const filteredTrackers = trackers.filter(t =>
    t.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.serialNumber.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (t.assignedParoleeName && t.assignedParoleeName.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const handleOpenConfig = (tracker: GpsTracker) => {
    setSelectedTracker(tracker);
    setEditRadius(tracker.geofenceRadiusMeters);
  };

  const handleSaveConfig = () => {
    if (!selectedTracker) return;
    updateTracker(selectedTracker.id, {
      geofenceRadiusMeters: editRadius
    });
    setSelectedTracker(null);
  };

  const handleToggleTamper = (tracker: GpsTracker) => {
    const isNowTampered = !tracker.isTampered;
    updateTracker(tracker.id, {
      isTampered: isNowTampered,
      status: isNowTampered ? 'tampered' : 'online'
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            IoT GPS Tracker Hardware Registry
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Ankle monitor telemetry, firmware revisions, optical tamper sensors, and geofence boundary calibration.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search serial, IMEI, or parolee..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9 pr-4 py-1.5 text-xs rounded-lg border border-slate-300 bg-white focus:outline-hidden focus:ring-2 focus:ring-slate-900 w-64"
            />
          </div>
        </div>
      </div>

      {/* Tracker Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredTrackers.map(tracker => {
          const isBreach = tracker.status === 'breach';
          const isTampered = tracker.isTampered;
          const isLowBatt = tracker.batteryLevel < 25;

          return (
            <div
              key={tracker.id}
              className={`bg-white rounded-xl border p-5 transition-all shadow-xs ${
                isBreach || isTampered
                  ? 'border-red-300 ring-1 ring-red-200'
                  : 'border-slate-200 hover:border-slate-300'
              }`}
            >
              {/* Header */}
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2.5">
                  <div className={`w-9 h-9 rounded-lg flex items-center justify-center font-mono font-bold text-xs ${
                    isBreach || isTampered ? 'bg-red-100 text-red-700' : 'bg-slate-100 text-slate-700'
                  }`}>
                    <Cpu className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-slate-900 text-sm">{tracker.id}</span>
                      <span className="text-[11px] font-mono text-slate-400">{tracker.serialNumber}</span>
                    </div>
                    <span className="text-xs text-slate-500">{tracker.model}</span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <span className={`px-2 py-0.5 rounded-full text-xs font-semibold capitalize ${
                    tracker.status === 'breach' ? 'bg-red-100 text-red-700' :
                    tracker.status === 'tampered' ? 'bg-red-100 text-red-700' :
                    tracker.status === 'low_battery' ? 'bg-amber-100 text-amber-700' :
                    'bg-emerald-100 text-emerald-700'
                  }`}>
                    {tracker.status}
                  </span>
                </div>
              </div>

              {/* Subject Info */}
              <div className="mt-4 p-3 bg-slate-50 rounded-lg border border-slate-100 text-xs">
                <div className="flex justify-between items-center">
                  <span className="text-slate-500">Assigned Subject:</span>
                  <span className="font-bold text-slate-900">{tracker.assignedParoleeName || 'Unassigned'}</span>
                </div>
                <div className="flex justify-between items-center mt-1 text-[11px]">
                  <span className="text-slate-500">Curfew Geofence:</span>
                  <span className="text-slate-700 font-medium">{tracker.homeBaseLocation.name} ({tracker.geofenceRadiusMeters}m radius)</span>
                </div>
              </div>

              {/* Status Metrics */}
              <div className="mt-4 grid grid-cols-3 gap-2 py-2 border-y border-slate-100 text-center text-xs">
                <div>
                  <span className="text-[11px] text-slate-400 block">Battery Level</span>
                  <div className="flex items-center justify-center gap-1 mt-0.5 font-bold">
                    {tracker.isCharging ? (
                      <BatteryCharging className="w-4 h-4 text-emerald-500" />
                    ) : (
                      <Battery className={`w-4 h-4 ${isLowBatt ? 'text-red-500' : 'text-slate-600'}`} />
                    )}
                    <span className={`tabular-nums ${isLowBatt ? 'text-red-600' : 'text-slate-900'}`}>{tracker.batteryLevel}%</span>
                  </div>
                </div>

                <div>
                  <span className="text-[11px] text-slate-400 block">Optical Tamper</span>
                  <span className={`font-semibold mt-0.5 block ${isTampered ? 'text-red-600 font-bold' : 'text-emerald-600'}`}>
                    {isTampered ? 'TRIGGERED' : 'Intact'}
                  </span>
                </div>

                <div>
                  <span className="text-[11px] text-slate-400 block">Last Check-in</span>
                  <span className="font-medium text-slate-700 mt-0.5 block">{tracker.lastPing}</span>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="mt-4 flex items-center justify-between gap-2 pt-1">
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => simulateGpsMovement(tracker.id)}
                    className="p-1.5 text-xs text-slate-600 hover:text-slate-900 border border-slate-200 rounded-md hover:bg-slate-50 transition-colors"
                    title="Simulate GPS coordinate ping"
                  >
                    <RefreshCw className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => handleToggleTamper(tracker)}
                    className={`px-2.5 py-1 text-xs font-medium rounded-md border transition-colors ${
                      isTampered ? 'bg-red-600 text-white border-red-600' : 'border-slate-200 text-slate-600 hover:bg-slate-50'
                    }`}
                    title="Toggle optical tamper sensor"
                  >
                    {isTampered ? 'Clear Tamper' : 'Test Tamper'}
                  </button>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => simulateGeofenceBreach(tracker.id)}
                    className="px-2.5 py-1 text-xs font-semibold bg-red-50 text-red-700 border border-red-200 rounded-md hover:bg-red-100 transition-colors"
                  >
                    Simulate Breach
                  </button>
                  <button
                    onClick={() => handleOpenConfig(tracker)}
                    className="px-3 py-1 text-xs font-semibold bg-slate-900 text-white rounded-md hover:bg-slate-800 transition-colors flex items-center gap-1"
                  >
                    <Settings className="w-3.5 h-3.5" /> Configure
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Geofence & Tracker Configuration Modal */}
      {selectedTracker && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl border border-slate-200 max-w-md w-full p-6 shadow-2xl">
            <h3 className="text-base font-bold text-slate-900">
              Configure Tracker {selectedTracker.id}
            </h3>
            <p className="text-xs text-slate-500 mt-1">
              Adjust authorized perimeter boundary radius and firmware configuration.
            </p>

            <div className="mt-5 space-y-4 text-xs">
              <div>
                <label className="font-semibold text-slate-700 block mb-1">
                  Geofence Allowed Radius (Meters): <span className="text-blue-600 font-bold">{editRadius}m</span>
                </label>
                <input
                  type="range"
                  min="100"
                  max="2500"
                  step="50"
                  value={editRadius}
                  onChange={(e) => setEditRadius(Number(e.target.value))}
                  className="w-full cursor-pointer accent-slate-900"
                />
                <div className="flex justify-between text-[10px] text-slate-400 mt-1">
                  <span>100m (Strict)</span>
                  <span>500m (Standard)</span>
                  <span>2500m (County Metro)</span>
                </div>
              </div>

              <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 space-y-1.5 text-slate-600">
                <p><strong>IMEI:</strong> {selectedTracker.imei}</p>
                <p><strong>Firmware Version:</strong> {selectedTracker.firmwareVersion}</p>
                <p><strong>Assigned Subject:</strong> {selectedTracker.assignedParoleeName}</p>
                <p><strong>Curfew Anchor:</strong> {selectedTracker.homeBaseLocation.name}</p>
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-2">
              <button
                onClick={() => setSelectedTracker(null)}
                className="px-4 py-1.5 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveConfig}
                className="px-4 py-1.5 text-xs font-semibold bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors"
              >
                Save Settings
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
