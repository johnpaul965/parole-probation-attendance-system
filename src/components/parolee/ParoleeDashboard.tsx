import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { computeSupervision, APP_CONFIG } from '../../constants';
import { SupervisionPeriodCard } from '../common/SupervisionPeriodCard';
import {
  QrCode,
  CheckCircle2,
  Calendar,
  Clock,
  MapPin,
  TrendingUp,
  Share2,
  Radio,
  ChevronRight,
  Shield,
  User,
  Compass,
} from 'lucide-react';

interface Props {
  onNavigate: (tab: string) => void;
}

export const ParoleeDashboard: React.FC<Props> = ({ onNavigate }) => {
  const { currentUser, users, attendance, activities, shareParoleeLocation, getParoleeSummary } = useApp();
  const [isSharingLocation, setIsSharingLocation] = useState(false);
  const [locationSharedSuccess, setLocationSharedSuccess] = useState(false);

  if (!currentUser) return null;

  const assignedOfficer = users.find((u) => u.id === currentUser.officerId);
  const supervision = computeSupervision(
    currentUser.supervisionStartDate,
    currentUser.supervisionEndDate,
    currentUser.supervisionIsSuspended
  );

  const myAttendance = attendance.filter((a) => a.paroleeId === currentUser.id);
  const lastRecord = myAttendance.length > 0 ? myAttendance[0] : null;

  // Next scheduled activity
  const myActivities = activities.filter((a) => a.assignedParoleeIds.includes(currentUser.id));
  const upcomingActivity = myActivities.find((a) => a.status === 'pending' || a.status === 'ongoing') || myActivities[0];

  const complianceRate = myAttendance.length > 0
    ? Math.round((myAttendance.filter((a) => a.status === 'checkedIn').length / myAttendance.length) * 100)
    : 100;

  const summary = getParoleeSummary(currentUser.id);

  const handleShareGps = () => {
    setIsSharingLocation(true);
    // Simulate mobile location right at office or nearby
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          shareParoleeLocation(currentUser.id, pos.coords.latitude, pos.coords.longitude);
          setIsSharingLocation(false);
          setLocationSharedSuccess(true);
          setTimeout(() => setLocationSharedSuccess(false), 3000);
        },
        () => {
          // Fallback to simulated Tacloban position
          shareParoleeLocation(
            currentUser.id,
            APP_CONFIG.taclobanLat + 0.0002,
            APP_CONFIG.taclobanLng + 0.0001
          );
          setIsSharingLocation(false);
          setLocationSharedSuccess(true);
          setTimeout(() => setLocationSharedSuccess(false), 3000);
        }
      );
    } else {
      shareParoleeLocation(
        currentUser.id,
        APP_CONFIG.taclobanLat + 0.0002,
        APP_CONFIG.taclobanLng + 0.0001
      );
      setIsSharingLocation(false);
      setLocationSharedSuccess(true);
      setTimeout(() => setLocationSharedSuccess(false), 3000);
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Parolee Gradient Banner */}
      <div className="rounded-2xl bg-gradient-to-r from-[#1A237E] via-[#283593] to-[#0D1B2A] text-white p-6 sm:p-8 shadow-md">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <span className="text-xs font-semibold text-indigo-200 uppercase tracking-wider">
              Parolee & Probationer Portal
            </span>
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight mt-1">
              Welcome back, {currentUser.fullName}
            </h1>
            <div className="flex flex-wrap items-center gap-2 mt-2 text-xs text-indigo-100/90">
              <span className="font-mono bg-white/10 px-2.5 py-0.5 rounded-md">
                Case: {currentUser.caseNumber || 'PP-2024-1847'}
              </span>
              <span>•</span>
              <span>Officer: {assignedOfficer?.fullName || 'Maria Santos'}</span>
            </div>
          </div>

          <button
            onClick={() => onNavigate('check-in')}
            className="px-5 py-3 bg-white text-indigo-900 hover:bg-indigo-50 font-bold rounded-xl text-xs sm:text-sm shadow-lg transition-all flex items-center justify-center gap-2 self-start sm:self-auto shrink-0"
          >
            <QrCode className="w-5 h-5 text-indigo-700" />
            <span>Activity Check-in QR</span>
          </button>
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Supervision, GPS Share, Last Check-in */}
        <div className="lg:col-span-2 space-y-5">
          {/* Supervision Period */}
          <SupervisionPeriodCard
            snapshot={supervision}
            startDate={currentUser.supervisionStartDate}
            endDate={currentUser.supervisionEndDate}
            paroleeFacing={true}
          />

          {/* Share Location Card */}
          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="flex items-start gap-3">
              <div className="p-2.5 rounded-xl bg-blue-50 text-blue-600 shrink-0">
                <MapPin className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-bold text-sm text-slate-900">Check-in Location Proximity</h4>
                <p className="text-xs text-slate-500 mt-0.5 leading-relaxed">
                  Verify current position relative to PPA Tacloban Field Office (50m compliance zone).
                </p>
                {summary && (
                  <p className="text-xs font-semibold text-emerald-700 mt-1 flex items-center gap-1">
                    <Compass className="w-3.5 h-3.5 text-emerald-600" />
                    Distance: {summary.checkInProximity.distanceMeters}m from Office
                    {summary.checkInProximity.isWithinProximity ? ' (Inside 50m Proximity)' : ''}
                  </p>
                )}
              </div>
            </div>

            <button
              onClick={handleShareGps}
              disabled={isSharingLocation}
              className="px-4 py-2 bg-slate-900 hover:bg-black text-white text-xs font-semibold rounded-xl transition-colors flex items-center justify-center gap-2 shrink-0"
            >
              <Share2 className="w-4 h-4" />
              <span>{isSharingLocation ? 'Sharing GPS...' : 'Share Location'}</span>
            </button>
          </div>

          {locationSharedSuccess && (
            <div className="p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl text-xs flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>GPS reading sent successfully to supervising officer.</span>
            </div>
          )}

          {/* Last Check-in Status Card */}
          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-500">
                Last Check-in Record
              </span>
              <button
                onClick={() => onNavigate('history')}
                className="text-xs font-semibold text-indigo-700 hover:text-indigo-900"
              >
                View History
              </button>
            </div>

            {lastRecord ? (
              <div className="mt-3 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-full bg-emerald-50 text-emerald-600">
                    <CheckCircle2 className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-sm text-slate-900">{lastRecord.ticketId}</h4>
                    <p className="text-xs text-slate-500 mt-0.5">
                      {lastRecord.checkInTime
                        ? new Date(lastRecord.checkInTime).toLocaleString([], {
                            month: 'short',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                          })
                        : 'Pending'}
                      {lastRecord.location ? ` • ${lastRecord.location}` : ''}
                    </p>
                  </div>
                </div>

                <span
                  className={`text-xs font-bold px-2.5 py-1 rounded-lg ${
                    lastRecord.verified ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'
                  }`}
                >
                  {lastRecord.verified ? 'Verified Check-in' : 'Awaiting Officer Scan'}
                </span>
              </div>
            ) : (
              <p className="text-xs text-slate-400 py-3 text-center">No attendance records yet</p>
            )}
          </div>
        </div>

        {/* Right Column: Next Schedule & Compliance */}
        <div className="space-y-5">
          {/* Next Schedule Card */}
          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 block mb-3">
              Next Scheduled Session
            </span>

            {upcomingActivity ? (
              <div className="space-y-3">
                <div className="p-3.5 bg-indigo-50/60 border border-indigo-100 rounded-xl">
                  <span className="text-[10px] font-bold uppercase tracking-wider text-indigo-700 block mb-1">
                    {upcomingActivity.type}
                  </span>
                  <h4 className="font-bold text-sm text-slate-900">{upcomingActivity.title}</h4>
                  <p className="text-xs text-slate-600 mt-1 flex items-center gap-1.5">
                    <Clock className="w-3.5 h-3.5 text-indigo-600" />
                    {new Date(upcomingActivity.scheduleDate).toLocaleString([], {
                      weekday: 'short',
                      month: 'short',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                  <p className="text-xs text-slate-600 mt-1 flex items-center gap-1.5">
                    <MapPin className="w-3.5 h-3.5 text-indigo-600" />
                    {upcomingActivity.location}
                  </p>
                </div>

                <button
                  onClick={() => onNavigate('check-in')}
                  className="w-full py-2 bg-indigo-700 hover:bg-indigo-800 text-white text-xs font-semibold rounded-xl transition-colors flex items-center justify-center gap-1.5"
                >
                  <QrCode className="w-4 h-4" />
                  <span>Show My QR Code</span>
                </button>
              </div>
            ) : (
              <p className="text-xs text-slate-400 py-4 text-center">No upcoming activities scheduled</p>
            )}
          </div>

          {/* Compliance Meter Card */}
          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 block mb-3">
              Compliance Overview
            </span>

            <div className="flex items-center gap-3">
              <div className="p-3 bg-emerald-50 rounded-2xl text-emerald-600">
                <TrendingUp className="w-6 h-6" />
              </div>
              <div>
                <p className="text-xl font-bold text-slate-900">{complianceRate}% Rate</p>
                <p className="text-xs text-slate-500 mt-0.5">
                  {myAttendance.filter((a) => a.status === 'checkedIn').length} of {myAttendance.length} check-ins on time
                </p>
              </div>
            </div>

            <div className="w-full bg-slate-100 rounded-full h-2 mt-4 overflow-hidden">
              <div
                className="bg-emerald-500 h-2 rounded-full transition-all duration-300"
                style={{ width: `${complianceRate}%` }}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
