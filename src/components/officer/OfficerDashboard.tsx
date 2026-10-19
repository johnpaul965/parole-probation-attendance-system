import React, { useState, useMemo } from 'react';
import { useApp } from '../../context/AppContext';
import { AttendanceStatus, AppUser } from '../../types';
import { computeSupervision, APP_CONFIG } from '../../constants';
import { StatCard } from '../common/StatCard';
import { QrScannerModal } from '../common/QrScannerModal';
import { LeafletMap } from '../common/LeafletMap';
import {
  Search,
  CheckCircle2,
  Clock,
  AlertOctagon,
  Users,
  Compass,
  Battery,
  MapPin,
  Calendar,
  ExternalLink,
  ChevronRight,
  ShieldAlert,
  ArrowRight,
  Radio,
  FileSpreadsheet,
} from 'lucide-react';

interface OfficerDashboardProps {
  onNavigate: (tab: string) => void;
  onOpenLiveTracking?: (paroleeId: string) => void;
  onOpenHistory?: (paroleeId: string) => void;
}

export const OfficerDashboard: React.FC<OfficerDashboardProps> = ({
  onNavigate,
  onOpenLiveTracking,
  onOpenHistory,
}) => {
  const { currentUser, users, stats, attendance, activities, liveLocations, getParoleeSummary } = useApp();
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<AttendanceStatus | null>(null);
  const [isScannerOpen, setIsScannerOpen] = useState(false);

  const parolees = useMemo(() => {
    return users.filter((u) => u.role === 'parolee');
  }, [users]);

  // Filtered parolees
  const filteredParolees = useMemo(() => {
    return parolees.filter((p) => {
      const matchSearch =
        p.fullName.toLowerCase().includes(search.toLowerCase()) ||
        (p.caseNumber && p.caseNumber.toLowerCase().includes(search.toLowerCase()));

      if (!matchSearch) return false;
      if (!filter) return true;

      // Check attendance status for this parolee
      const rec = attendance.find((a) => a.paroleeId === p.id);
      const currentStatus = rec ? rec.status : 'pending';
      return currentStatus === filter;
    });
  }, [parolees, search, filter, attendance]);

  // Time of day greeting
  const greeting = useMemo(() => {
    const h = new Date().getHours();
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }, []);

  return (
    <div className="space-y-6 pb-12">
      {/* Officer Gradient Header */}
      <div className="rounded-2xl bg-gradient-to-r from-[#1565C0] via-[#1E40AF] to-[#0D1B2A] text-white p-6 sm:p-8 shadow-md">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <span className="text-xs font-semibold text-blue-200 uppercase tracking-wider">
              Probation & Parole Administration
            </span>
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight mt-1">
              Good {greeting}, {currentUser?.fullName || 'Officer'}
            </h1>
            <p className="text-xs sm:text-sm text-blue-100/80 mt-1">
              {currentUser?.department || 'District 4 - Tacloban Field Office'} • Active Monitoring Active
            </p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setIsScannerOpen(true)}
              className="px-4 py-2.5 bg-white text-blue-700 hover:bg-blue-50 font-semibold rounded-xl text-xs sm:text-sm shadow-md transition-all flex items-center gap-2 shrink-0"
            >
              <CheckCircle2 className="w-4 h-4 text-blue-600" />
              <span>Scan Attendance QR</span>
            </button>
            <button
              onClick={() => onNavigate('reports')}
              className="px-4 py-2.5 bg-blue-700/80 hover:bg-blue-600 text-white font-medium rounded-xl text-xs sm:text-sm border border-blue-400/30 transition-all flex items-center gap-2 shrink-0"
            >
              <FileSpreadsheet className="w-4 h-4" />
              <span>Reports</span>
            </button>
          </div>
        </div>

        {/* Metric Stat Cards */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4 mt-6">
          <StatCard
            label="Total Cases"
            value={stats.totalCases}
            isSelected={filter === null}
            onClick={() => setFilter(null)}
            icon={<Users className="w-4 h-4" />}
          />
          <StatCard
            label="Checked-in"
            value={stats.checkedIn}
            isSelected={filter === 'checkedIn'}
            onClick={() => setFilter('checkedIn')}
            icon={<CheckCircle2 className="w-4 h-4 text-emerald-500" />}
          />
          <StatCard
            label="Pending"
            value={stats.pending}
            isSelected={filter === 'pending'}
            onClick={() => setFilter('pending')}
            icon={<Clock className="w-4 h-4 text-amber-500" />}
          />
          <StatCard
            label="Missed"
            value={stats.missed}
            isSelected={filter === 'missed'}
            onClick={() => setFilter('missed')}
            icon={<AlertOctagon className="w-4 h-4 text-rose-500" />}
          />
        </div>
      </div>

      {/* Search & Status Filters */}
      <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs flex flex-col md:flex-row gap-3 items-center justify-between">
        <div className="relative w-full md:w-96">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search parolees by name or case #..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-300 rounded-xl text-xs sm:text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* Filter Chips */}
        <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto no-scrollbar">
          <button
            onClick={() => setFilter(null)}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors shrink-0 ${
              filter === null ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            All ({parolees.length})
          </button>
          <button
            onClick={() => setFilter('checkedIn')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors shrink-0 ${
              filter === 'checkedIn' ? 'bg-emerald-600 text-white' : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
            }`}
          >
            Checked In ({stats.checkedIn})
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors shrink-0 ${
              filter === 'pending' ? 'bg-amber-600 text-white' : 'bg-amber-50 text-amber-700 hover:bg-amber-100'
            }`}
          >
            Pending ({stats.pending})
          </button>
          <button
            onClick={() => setFilter('missed')}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors shrink-0 ${
              filter === 'missed' ? 'bg-rose-600 text-white' : 'bg-rose-50 text-rose-700 hover:bg-rose-100'
            }`}
          >
            Missed ({stats.missed})
          </button>
        </div>
      </div>

      {/* Main Grid: Live Tracking Preview & Upcoming Schedules */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Live GPS Tracking Section */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Radio className="w-4 h-4 text-emerald-600 animate-pulse" />
              <h2 className="text-sm font-bold uppercase tracking-wider text-slate-700">
                Live GPS Monitoring & Proximity
              </h2>
            </div>
            <button
              onClick={() => onNavigate('trackers')}
              className="text-xs font-semibold text-blue-600 hover:text-blue-800 flex items-center gap-1"
            >
              All Trackers <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Interactive Tacloban Map Snippet */}
          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs p-3">
            <div className="flex items-center justify-between pb-2 mb-2 border-b border-slate-100 text-xs">
              <span className="font-semibold text-slate-800 flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-blue-600" /> Tacloban Surveillance Map
              </span>
              <span className="text-[11px] text-slate-500">
                50m Office Proximity Perimeter Active
              </span>
            </div>
            <LeafletMap
              location={liveLocations['demo-parolee']}
              height="280px"
            />
          </div>

          {/* Real-time Tracking Highlights */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {parolees.slice(0, 2).map((p) => {
              const summary = getParoleeSummary(p.id);
              const loc = summary?.latestLocation;
              const isProx = summary?.checkInProximity.isWithinProximity;

              return (
                <div
                  key={p.id}
                  className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs hover:border-blue-300 transition-colors"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h4 className="font-bold text-sm text-slate-900">{p.fullName}</h4>
                      <p className="text-[11px] text-slate-500">{p.caseNumber || 'Case Active'} • {summary?.tracker?.id || 'No Tracker'}</p>
                    </div>
                    <span
                      className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                        summary?.trackingStatus === 'active'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-slate-100 text-slate-600'
                      }`}
                    >
                      {summary?.trackingStatus || 'Unassigned'}
                    </span>
                  </div>

                  {/* Proximity Banner */}
                  <div className="mt-3 p-2.5 rounded-lg bg-slate-50 border border-slate-200/80 flex items-center justify-between text-xs">
                    <span className="text-slate-600 font-medium">Check-in Distance:</span>
                    <span
                      className={`font-bold flex items-center gap-1 ${
                        isProx ? 'text-emerald-700' : 'text-slate-700'
                      }`}
                    >
                      <Compass className={`w-3.5 h-3.5 ${isProx ? 'text-emerald-600' : 'text-slate-400'}`} />
                      {summary?.checkInProximity.distanceMeters ?? '—'}m from Office
                    </span>
                  </div>

                  <div className="mt-2.5 flex items-center justify-between text-[11px] text-slate-500">
                    <div className="flex items-center gap-1">
                      <Battery className="w-3.5 h-3.5 text-slate-400" />
                      <span>{loc?.batteryLevel ?? summary?.tracker?.batteryLevel ?? '—'}% Battery</span>
                    </div>
                    <span>{loc?.speed ? `${loc.speed} km/h` : 'Stationary'}</span>
                  </div>

                  <div className="mt-3 pt-3 border-t border-slate-100 flex items-center gap-2">
                    <button
                      onClick={() => onOpenLiveTracking && onOpenLiveTracking(p.id)}
                      className="flex-1 py-1.5 px-3 rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-700 font-semibold text-xs transition-colors flex items-center justify-center gap-1"
                    >
                      <MapPin className="w-3.5 h-3.5" /> Track Live
                    </button>
                    <button
                      onClick={() => onOpenHistory && onOpenHistory(p.id)}
                      className="py-1.5 px-3 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium text-xs transition-colors"
                    >
                      History
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column: Upcoming Activities & Shortcuts */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-bold uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
              <Calendar className="w-4 h-4 text-blue-600" /> Activities & Sessions
            </h2>
            <button
              onClick={() => onNavigate('activities')}
              className="text-xs font-semibold text-blue-600 hover:text-blue-800"
            >
              Manage
            </button>
          </div>

          <div className="space-y-3">
            {activities.slice(0, 3).map((act) => {
              const compPercent = Math.round(
                act.assignedParoleeIds.length > 0
                  ? (act.completedParoleeIds.length / act.assignedParoleeIds.length) * 100
                  : 0
              );

              return (
                <div
                  key={act.id}
                  onClick={() => onNavigate('activities')}
                  className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs hover:border-blue-400 transition-colors cursor-pointer"
                >
                  <div className="flex items-start justify-between gap-2">
                    <h4 className="font-semibold text-xs text-slate-900 line-clamp-1">{act.title}</h4>
                    <span
                      className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize shrink-0 ${
                        act.status === 'completed'
                          ? 'bg-emerald-50 text-emerald-700'
                          : act.status === 'ongoing'
                          ? 'bg-blue-50 text-blue-700'
                          : 'bg-amber-50 text-amber-700'
                      }`}
                    >
                      {act.status}
                    </span>
                  </div>

                  <p className="text-[11px] text-slate-500 mt-1 line-clamp-1">{act.location}</p>

                  <div className="mt-3">
                    <div className="flex justify-between text-[10px] text-slate-500 font-medium mb-1">
                      <span>Attendance Compliance</span>
                      <span>
                        {act.completedParoleeIds.length}/{act.assignedParoleeIds.length} ({compPercent}%)
                      </span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                      <div
                        className="bg-blue-600 h-1.5 rounded-full transition-all duration-300"
                        style={{ width: `${compPercent}%` }}
                      />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Quick Notice Card */}
          <div className="bg-amber-50/70 border border-amber-200 rounded-xl p-4 text-xs text-amber-900">
            <div className="flex items-center gap-1.5 font-bold text-amber-800 mb-1">
              <ShieldAlert className="w-4 h-4 text-amber-600" />
              <span>50m Proximity Protocol</span>
            </div>
            <p className="text-[11px] text-amber-800 leading-relaxed">
              Officers are alerted when parolees cross the 50 m check-in radius. Being outside the 50 m perimeter does
              not automatically mark the parolee absent.
            </p>
          </div>
        </div>
      </div>

      {/* Assigned Parolees Roster Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
          <div>
            <h3 className="font-bold text-slate-900 text-sm">Assigned Parolees Directory</h3>
            <p className="text-xs text-slate-500">Supervision compliance, tracking hardware & attendance status</p>
          </div>
          <button
            onClick={() => onNavigate('users')}
            className="text-xs font-semibold text-blue-600 hover:text-blue-800 flex items-center gap-1"
          >
            Manage Users <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="divide-y divide-slate-100 overflow-x-auto">
          {filteredParolees.length === 0 ? (
            <div className="py-12 text-center text-slate-400 text-xs">
              No parolees matching criteria
            </div>
          ) : (
            filteredParolees.map((p) => {
              const summary = getParoleeSummary(p.id);
              const lastRec = attendance.find((a) => a.paroleeId === p.id);
              const supervision = computeSupervision(p.supervisionStartDate, p.supervisionEndDate, p.supervisionIsSuspended);

              return (
                <div
                  key={p.id}
                  className="px-6 py-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50/80 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-slate-800 text-white font-semibold text-xs flex items-center justify-center shrink-0 shadow-xs">
                      {p.avatarInitials || p.fullName.slice(0, 2).toUpperCase()}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-slate-900 text-sm">{p.fullName}</span>
                        {!p.isActive && (
                          <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-600">
                            Inactive
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-500 mt-0.5">
                        Case: {p.caseNumber || 'N/A'} • {supervision.shortLabel}
                      </p>
                    </div>
                  </div>

                  {/* Middle: Attendance Status & GPS Distance */}
                  <div className="flex items-center gap-4 text-xs">
                    <div>
                      <span className="text-[10px] uppercase font-bold tracking-wider text-slate-400 block mb-0.5">
                        Latest Attendance
                      </span>
                      <span
                        className={`inline-flex items-center gap-1 font-semibold ${
                          lastRec?.status === 'checkedIn'
                            ? 'text-emerald-700'
                            : lastRec?.status === 'missed'
                            ? 'text-rose-700'
                            : 'text-amber-700'
                        }`}
                      >
                        {lastRec?.status === 'checkedIn' && <CheckCircle2 className="w-3.5 h-3.5" />}
                        {lastRec?.status === 'missed' && <AlertOctagon className="w-3.5 h-3.5" />}
                        {lastRec?.status === 'pending' && <Clock className="w-3.5 h-3.5" />}
                        {lastRec ? (lastRec.verified ? 'Verified' : 'Pending Check-in') : 'No Records'}
                      </span>
                    </div>

                    <div>
                      <span className="text-[10px] uppercase font-bold tracking-wider text-slate-400 block mb-0.5">
                        Tracker Status
                      </span>
                      <span className="text-slate-700 font-medium">
                        {summary?.tracker ? `${summary.tracker.id} (${summary.tracker.status})` : 'Unassigned'}
                      </span>
                    </div>
                  </div>

                  {/* Right Actions */}
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => onOpenLiveTracking && onOpenLiveTracking(p.id)}
                      className="px-3 py-1.5 bg-blue-50 hover:bg-blue-100 text-blue-700 text-xs font-semibold rounded-lg transition-colors flex items-center gap-1"
                    >
                      <MapPin className="w-3.5 h-3.5" />
                      Live Map
                    </button>
                    <button
                      onClick={() => onOpenHistory && onOpenHistory(p.id)}
                      className="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-medium rounded-lg transition-colors"
                    >
                      History
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* QR Scanner Modal */}
      <QrScannerModal
        isOpen={isScannerOpen}
        onClose={() => setIsScannerOpen(false)}
      />
    </div>
  );
};
