import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Users,
  CheckCircle,
  AlertTriangle,
  Radio,
  MapPin,
  Calendar,
  Smartphone,
  ExternalLink,
  ShieldAlert,
  BatteryCharging,
  QrCode
} from 'lucide-react';
import { LeafletMap } from '../common/LeafletMap';

export const OfficerDashboard: React.FC = () => {
  const {
    users,
    trackers,
    attendanceRecords,
    activities,
    alerts,
    acknowledgeAlert,
    simulateGpsMovement,
    simulateGeofenceBreach,
    setActiveView
  } = useApp();

  const [selectedTrackerId, setSelectedTrackerId] = useState<string>(trackers[0]?.id || '');
  const [filterQuery, setFilterQuery] = useState('');

  const parolees = users.filter(u => u.role === 'parolee');
  const activeAlerts = alerts.filter(a => !a.acknowledged);
  const todaysAttendance = attendanceRecords.filter(r => r.timestamp.includes('2026-10-18') || r.timestamp.includes('2026-10-19') || r.timestamp.includes('T'));
  const complianceRate = Math.round((attendanceRecords.filter(r => r.status === 'present').length / Math.max(1, attendanceRecords.length)) * 100);

  const selectedTracker = trackers.find(t => t.id === selectedTrackerId) || trackers[0];

  return (
    <div className="space-y-6">
      {/* Page Title & Emergency Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Supervision Command Center
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Real-time biometric attendance verification, IoT ankle monitor telemetry, and geofence enforcement.
          </p>
        </div>

        {/* Quick Simulation / Action Controls */}
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={() => simulateGpsMovement(selectedTrackerId)}
            className="px-3 py-1.5 text-xs font-semibold bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors flex items-center gap-1.5 shadow-2xs"
          >
            <Radio className="w-3.5 h-3.5 text-emerald-600 animate-pulse" />
            Ping Live GPS
          </button>
          <button
            onClick={() => simulateGeofenceBreach(selectedTrackerId)}
            className="px-3 py-1.5 text-xs font-semibold bg-red-50 border border-red-200 text-red-700 rounded-lg hover:bg-red-100 transition-colors flex items-center gap-1.5"
            title="Simulates tracker moving outside authorized perimeter"
          >
            <ShieldAlert className="w-3.5 h-3.5 text-red-600" />
            Simulate Perimeter Breach
          </button>
          <button
            onClick={() => setActiveView('activities')}
            className="px-3 py-1.5 text-xs font-semibold bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors flex items-center gap-1.5 shadow-xs"
          >
            <Calendar className="w-3.5 h-3.5" />
            New Activity
          </button>
        </div>
      </div>

      {/* Metric Cards (60-30-10 & Tabular discipline) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Active Subjects</span>
            <Users className="w-4 h-4 text-slate-400" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold tracking-tight text-slate-900 tabular-nums">{parolees.length}</span>
            <span className="text-xs text-emerald-600 font-semibold">100% Monitored</span>
          </div>
          <p className="text-xs text-slate-500 mt-1">4 active in District 4</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Today's Check-Ins</span>
            <CheckCircle className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold tracking-tight text-slate-900 tabular-nums">{todaysAttendance.length}</span>
            <span className="text-xs text-slate-500">of {parolees.length} expected</span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Verified with QR & GPS Latch</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Overall Compliance</span>
            <span className="text-xs font-bold text-blue-600">30-Day Index</span>
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold tracking-tight text-slate-900 tabular-nums">{complianceRate}%</span>
            <span className="text-xs text-emerald-600 font-medium">+4.2% vs last mo</span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Acceptable threshold &gt; 85%</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Active Alerts</span>
            <AlertTriangle className={`w-4 h-4 ${activeAlerts.length > 0 ? 'text-red-500' : 'text-slate-400'}`} />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className={`text-3xl font-extrabold tracking-tight tabular-nums ${activeAlerts.length > 0 ? 'text-red-600' : 'text-slate-900'}`}>
              {activeAlerts.length}
            </span>
            {activeAlerts.length > 0 && (
              <span className="text-xs bg-red-100 text-red-700 px-1.5 py-0.5 rounded font-semibold">Requires Action</span>
            )}
          </div>
          <p className="text-xs text-slate-500 mt-1">Perimeter & battery status</p>
        </div>
      </div>

      {/* Critical Active Alerts Bar if any */}
      {activeAlerts.length > 0 && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-4">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-xs font-bold text-red-900 uppercase tracking-wider flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-red-600" />
              Attention Required: {activeAlerts.length} Unresolved Incident(s)
            </h3>
            <span className="text-xs text-red-700">Audit logged to central registry</span>
          </div>
          <div className="space-y-2">
            {activeAlerts.map(alert => (
              <div key={alert.id} className="bg-white p-3 rounded-lg border border-red-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
                <div>
                  <span className="font-bold text-slate-900 mr-2">{alert.paroleeName}</span>
                  <span className="text-slate-500">[{alert.trackerId}]</span>
                  <p className="text-slate-700 mt-0.5">{alert.notes}</p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className="text-slate-400 text-[11px]">{alert.timestamp}</span>
                  <button
                    onClick={() => acknowledgeAlert(alert.id, 'Officer acknowledged incident in field console')}
                    className="px-3 py-1 bg-red-600 text-white rounded-md font-medium hover:bg-red-700 transition-colors"
                  >
                    Acknowledge
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Interactive Map & Telemetry Split */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Live Map */}
        <div className="lg:col-span-2 space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-bold text-slate-900">District Geo-Tracking & Curfew Geofences</h2>
              <p className="text-xs text-slate-500">Live positions updated every 15s. Blue circles mark approved boundary perimeters.</p>
            </div>
            <button
              onClick={() => setActiveView('tracking')}
              className="text-xs text-blue-600 font-semibold hover:underline flex items-center gap-1"
            >
              Full Screen Map <ExternalLink className="w-3 h-3" />
            </button>
          </div>

          <LeafletMap
            trackers={trackers}
            selectedTrackerId={selectedTrackerId}
            onSelectTracker={(t) => setSelectedTrackerId(t.id)}
            height="440px"
          />
        </div>

        {/* Right 1 Col: Selected Tracker Quick Inspector */}
        <div className="bg-white rounded-xl border border-slate-200 p-5 flex flex-col justify-between shadow-xs">
          <div>
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Device Inspector</span>
                <h3 className="text-sm font-bold text-slate-900 mt-0.5">{selectedTracker?.id}</h3>
              </div>
              <span className={`text-xs px-2 py-0.5 rounded-full font-semibold capitalize ${
                selectedTracker?.status === 'breach' ? 'bg-red-100 text-red-700' :
                selectedTracker?.status === 'low_battery' ? 'bg-amber-100 text-amber-700' :
                'bg-emerald-100 text-emerald-700'
              }`}>
                {selectedTracker?.status}
              </span>
            </div>

            {/* Tracker details */}
            <div className="py-4 space-y-3 text-xs">
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-slate-500">Assigned Subject:</span>
                <span className="font-semibold text-slate-900">{selectedTracker?.assignedParoleeName}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-slate-500">Hardware Model:</span>
                <span className="font-medium text-slate-800">{selectedTracker?.model}</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-slate-500">Battery Level:</span>
                <span className="font-bold flex items-center gap-1 text-slate-900">
                  <BatteryCharging className="w-3.5 h-3.5 text-emerald-500" />
                  {selectedTracker?.batteryLevel}%
                </span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-slate-500">Current Velocity:</span>
                <span className="font-semibold text-slate-900 tabular-nums">{selectedTracker?.currentLocation.speedKmH} km/h</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-slate-500">Geofence Radius:</span>
                <span className="font-semibold text-blue-600 tabular-nums">{selectedTracker?.geofenceRadiusMeters} meters</span>
              </div>
              <div className="flex justify-between items-center py-1 border-b border-slate-50">
                <span className="text-slate-500">GPS Accuracy:</span>
                <span className="font-medium text-slate-700 tabular-nums">±{selectedTracker?.currentLocation.accuracy}m</span>
              </div>
              <div className="pt-1">
                <span className="text-slate-500 block text-[11px]">Reported Address:</span>
                <span className="font-medium text-slate-800 block mt-0.5">{selectedTracker?.currentLocation.address}</span>
              </div>
            </div>
          </div>

          {/* Quick select other subjects */}
          <div className="pt-3 border-t border-slate-100">
            <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-2">
              Select Monitored Subject:
            </span>
            <div className="grid grid-cols-2 gap-1.5">
              {trackers.map(t => (
                <button
                  key={t.id}
                  onClick={() => setSelectedTrackerId(t.id)}
                  className={`text-left p-2 rounded-lg border text-xs transition-colors ${
                    t.id === selectedTrackerId
                      ? 'border-slate-900 bg-slate-900 text-white font-medium'
                      : 'border-slate-200 hover:bg-slate-50 text-slate-700'
                  }`}
                >
                  <p className="font-semibold truncate">{t.assignedParoleeName}</p>
                  <p className={`text-[10px] ${t.id === selectedTrackerId ? 'text-slate-300' : 'text-slate-500'}`}>{t.id}</p>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Two Column Layout: Recent Attendance Log & Upcoming Activities */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Attendance Verification Log */}
        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">Recent Attendance Verifications</h2>
              <p className="text-xs text-slate-500">Automated QR scans and biometric touchpoints</p>
            </div>
            <button
              onClick={() => setActiveView('reports')}
              className="text-xs text-blue-600 font-semibold hover:underline"
            >
              Export CSV / PDF
            </button>
          </div>

          <div className="divide-y divide-slate-100 overflow-hidden">
            {attendanceRecords.slice(0, 5).map(record => (
              <div key={record.id} className="py-3 flex items-center justify-between gap-3 text-xs">
                <div className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${
                    record.status === 'present' ? 'bg-emerald-100 text-emerald-700' :
                    record.status === 'late' ? 'bg-amber-100 text-amber-700' :
                    'bg-slate-100 text-slate-700'
                  }`}>
                    <QrCode className="w-4 h-4" />
                  </div>
                  <div>
                    <span className="font-bold text-slate-900 text-sm block">{record.paroleeName}</span>
                    <span className="text-slate-500 text-[11px]">
                      {record.type.toUpperCase()} · Verified via {record.verificationMethod}
                    </span>
                    <span className="text-[11px] text-slate-400 block mt-0.5">{record.location?.address}</span>
                  </div>
                </div>

                <div className="text-right shrink-0">
                  <span className={`inline-block px-2 py-0.5 rounded-full text-[11px] font-semibold uppercase ${
                    record.status === 'present' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                    record.status === 'late' ? 'bg-amber-50 text-amber-700 border border-amber-200' :
                    'bg-red-50 text-red-700 border border-red-200'
                  }`}>
                    {record.status}
                  </span>
                  <span className="text-[10px] text-slate-400 block mt-1 font-mono">{record.ticketCode}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Scheduled Activities and Counseling */}
        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">Mandatory Activities & Programs</h2>
              <p className="text-xs text-slate-500">Court compliance, drug testing, and community service</p>
            </div>
            <button
              onClick={() => setActiveView('activities')}
              className="text-xs text-blue-600 font-semibold hover:underline"
            >
              Manage ({activities.length})
            </button>
          </div>

          <div className="space-y-3">
            {activities.slice(0, 3).map(activity => (
              <div key={activity.id} className="p-3.5 rounded-lg border border-slate-100 bg-slate-50/50 hover:bg-slate-50 transition-colors">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-900">{activity.title}</span>
                    {activity.mandatory && (
                      <span className="text-[10px] font-semibold text-red-700 bg-red-100 px-1.5 py-0.2 rounded">Mandatory</span>
                    )}
                  </div>
                  <span className="text-xs font-semibold text-slate-600 bg-white border border-slate-200 px-2 py-0.5 rounded">
                    {activity.pointsOrHours} Hours Credit
                  </span>
                </div>

                <p className="text-xs text-slate-600 mt-1 line-clamp-2">{activity.description}</p>

                <div className="mt-3 flex items-center justify-between text-[11px] text-slate-500 pt-2 border-t border-slate-100">
                  <span className="flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5 text-slate-400" />
                    {activity.scheduledDate} · {activity.startTime}
                  </span>
                  <span className="font-medium text-slate-700">
                    {activity.paroleeIds.length} Subject(s) Assigned
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
