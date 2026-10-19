import React from 'react';
import { useApp } from '../../context/AppContext';
import {
  Calendar,
  Clock,
  QrCode,
  ShieldCheck,
  MapPin,
  Phone,
  Radio,
  FileCheck2,
  ChevronRight,
  AlertCircle
} from 'lucide-react';

export const ParoleeDashboard: React.FC = () => {
  const { currentUser, activities, attendanceRecords, trackers, setActiveView } = useApp();

  const myActivities = activities.filter(a => a.paroleeIds.includes(currentUser.id));
  const myAttendance = attendanceRecords.filter(r => r.paroleeId === currentUser.id);
  const myTracker = trackers.find(t => t.assignedParoleeId === currentUser.id) || trackers[0];

  // Calculate supervision days
  const startDate = new Date(currentUser.supervisionStartDate || '2025-01-15');
  const endDate = new Date(currentUser.supervisionEndDate || '2027-01-15');
  const today = new Date();
  const totalDays = Math.max(1, Math.round((endDate.getTime() - startDate.getTime()) / (1000 * 3600 * 24)));
  const elapsedDays = Math.max(0, Math.round((today.getTime() - startDate.getTime()) / (1000 * 3600 * 24)));
  const progressPercent = Math.min(100, Math.round((elapsedDays / totalDays) * 100));

  return (
    <div className="space-y-6">
      {/* Subject Header Banner */}
      <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div className="flex items-start gap-4">
          <img
            src={currentUser.avatarUrl || 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'}
            alt={currentUser.name}
            className="w-16 h-16 rounded-full object-cover border-2 border-slate-200 shadow-xs shrink-0"
          />
          <div>
            <div className="flex items-center gap-2.5">
              <h1 className="text-xl font-bold tracking-tight text-slate-900">{currentUser.name}</h1>
              <span className="text-xs bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 rounded-full font-semibold">
                Supervision Status: Compliant
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-1 font-mono">
              Case Number: {currentUser.caseNumber} · Risk Tier: {currentUser.riskLevel?.toUpperCase()}
            </p>
            <p className="text-xs text-slate-600 mt-1 flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5 text-blue-600" />
              Assigned Supervising Officer: <strong>{currentUser.assignedOfficerName}</strong>
            </p>
          </div>
        </div>

        {/* Primary Action Button */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 shrink-0">
          <button
            onClick={() => setActiveView('check-in')}
            className="px-5 py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 transition-all flex items-center justify-center gap-2 shadow-xs"
          >
            <QrCode className="w-4 h-4 text-emerald-400" />
            Check-In Now (QR / GPS)
          </button>
        </div>
      </div>

      {/* Supervision Progress Card */}
      <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs">
        <div className="flex items-center justify-between mb-3">
          <div>
            <h2 className="text-base font-bold text-slate-900">Probation & Supervision Period Term</h2>
            <p className="text-xs text-slate-500">Scheduled completion date: {currentUser.supervisionEndDate}</p>
          </div>
          <span className="text-sm font-bold text-slate-900 tabular-nums">{progressPercent}% Completed</span>
        </div>

        {/* Progress Bar */}
        <div className="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
          <div
            className="bg-slate-900 h-3 rounded-full transition-all duration-500"
            style={{ width: `${progressPercent}%` }}
          />
        </div>

        <div className="mt-4 grid grid-cols-3 text-center border-t border-slate-100 pt-4 text-xs">
          <div>
            <span className="text-slate-400 block text-[11px]">Start Date</span>
            <span className="font-semibold text-slate-800 mt-0.5 block">{currentUser.supervisionStartDate}</span>
          </div>
          <div>
            <span className="text-slate-400 block text-[11px]">Days Supervised</span>
            <span className="font-semibold text-slate-800 mt-0.5 block tabular-nums">{elapsedDays} Days</span>
          </div>
          <div>
            <span className="text-slate-400 block text-[11px]">Days Remaining</span>
            <span className="font-semibold text-emerald-600 mt-0.5 block tabular-nums">{totalDays - elapsedDays} Days</span>
          </div>
        </div>
      </div>

      {/* 2-Column Split: Hardware GPS Monitor & Next Program */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* GPS Tracker Status */}
        <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Radio className="w-4 h-4 text-emerald-500 animate-pulse" />
              <h2 className="text-base font-bold text-slate-900">Ankle Monitor IoT Status</h2>
            </div>
            <span className="text-xs font-semibold px-2 py-0.5 bg-emerald-100 text-emerald-700 rounded-full">
              Connected (5G LTE)
            </span>
          </div>

          <div className="p-4 bg-slate-50 rounded-xl border border-slate-100 text-xs space-y-2.5">
            <div className="flex justify-between">
              <span className="text-slate-500">Device ID:</span>
              <span className="font-mono font-bold text-slate-900">{myTracker?.id}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Battery Level:</span>
              <span className="font-bold text-emerald-600">{myTracker?.batteryLevel}%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Curfew Geofence:</span>
              <span className="font-medium text-slate-800">{myTracker?.homeBaseLocation.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Allowed Perimeter Radius:</span>
              <span className="font-bold text-blue-600">{myTracker?.geofenceRadiusMeters} meters</span>
            </div>
          </div>

          <p className="text-[11px] text-slate-400">
            Reminder: Keep your device charged above 20% at all times. Do not submerge device in water.
          </p>
        </div>

        {/* Assigned Mandatory Programs */}
        <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-bold text-slate-900">Upcoming Programs</h2>
              <button
                onClick={() => setActiveView('parolee-activities')}
                className="text-xs text-blue-600 font-semibold hover:underline"
              >
                View All ({myActivities.length})
              </button>
            </div>

            {myActivities.length === 0 ? (
              <div className="p-6 text-center text-xs text-slate-400 bg-slate-50 rounded-lg">
                No mandatory sessions scheduled for this week.
              </div>
            ) : (
              <div className="space-y-3">
                {myActivities.slice(0, 2).map(act => (
                  <div key={act.id} className="p-3 bg-slate-50 rounded-lg border border-slate-200/60 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-slate-900">{act.title}</span>
                      <span className="text-[10px] font-semibold bg-white border border-slate-200 px-1.5 py-0.5 rounded">
                        +{act.pointsOrHours}h Credit
                      </span>
                    </div>
                    <div className="mt-2 flex items-center gap-4 text-slate-500 text-[11px]">
                      <span className="flex items-center gap-1">
                        <Calendar className="w-3.5 h-3.5 text-slate-400" />
                        {act.scheduledDate}
                      </span>
                      <span className="flex items-center gap-1">
                        <Clock className="w-3.5 h-3.5 text-slate-400" />
                        {act.startTime}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between text-xs">
            <span className="text-slate-500">Need emergency assistance?</span>
            <a
              href="tel:5550192831"
              className="text-blue-600 font-semibold flex items-center gap-1 hover:underline"
            >
              <Phone className="w-3.5 h-3.5" /> Call Officer Vance
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};
