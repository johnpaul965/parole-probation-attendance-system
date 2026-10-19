import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { ActivityModel, ActivityType, ActivityStatus } from '../../types';
import { QrScannerModal } from '../common/QrScannerModal';
import {
  CalendarCheck,
  Plus,
  QrCode,
  MapPin,
  Clock,
  Users,
  CheckCircle2,
  Calendar,
  AlertCircle,
  X,
  Check,
  Sparkles,
} from 'lucide-react';

export const ActivitiesManagement: React.FC = () => {
  const { activities, users, createActivity, updateActivityStatus, markAttendanceManual } = useApp();

  const [activeTab, setActiveTab] = useState<ActivityStatus | 'all'>('all');
  const [selectedActivity, setSelectedActivity] = useState<ActivityModel | null>(activities[0] || null);

  // Create Activity form
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [title, setTitle] = useState('');
  const [type, setType] = useState<ActivityType>('treePlanting');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('Cancabato Bay Coastal Area, Tacloban City');
  const [scheduleDate, setScheduleDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    d.setHours(9, 0, 0, 0);
    return d.toISOString().slice(0, 16);
  });
  const [selectedParoleeIds, setSelectedParoleeIds] = useState<string[]>(['demo-parolee', 'demo-parolee-3']);

  // Scanner modal
  const [isScannerOpen, setIsScannerOpen] = useState(false);

  const parolees = users.filter((u) => u.role === 'parolee');

  const filteredActivities = activities.filter((a) => {
    if (activeTab === 'all') return true;
    return a.status === activeTab;
  });

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || selectedParoleeIds.length === 0) return;

    createActivity({
      title: title.trim(),
      type,
      description: description.trim(),
      location: location.trim(),
      scheduleDate: new Date(scheduleDate).toISOString(),
      assignedParoleeIds: selectedParoleeIds,
    });

    setShowCreateModal(false);
    setTitle('');
    setDescription('');
  };

  const toggleParoleeSelection = (id: string) => {
    setSelectedParoleeIds((prev) =>
      prev.includes(id) ? prev.filter((pId) => pId !== id) : [...prev, id]
    );
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <CalendarCheck className="w-5 h-5 text-blue-600" />
            <h1 className="text-xl font-bold text-slate-900">Activity & Session Management</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Organize tree planting, community clean-ups, counseling sessions, and scan check-in QR tickets
          </p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="px-4 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl text-xs sm:text-sm shadow-md transition-all flex items-center gap-2 self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>Create Activity</span>
        </button>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 bg-slate-100 p-1 rounded-xl w-fit">
        <button
          onClick={() => setActiveTab('all')}
          className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
            activeTab === 'all' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          All Activities ({activities.length})
        </button>
        <button
          onClick={() => setActiveTab('pending')}
          className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
            activeTab === 'pending' ? 'bg-white text-amber-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Pending
        </button>
        <button
          onClick={() => setActiveTab('ongoing')}
          className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
            activeTab === 'ongoing' ? 'bg-white text-blue-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Ongoing
        </button>
        <button
          onClick={() => setActiveTab('completed')}
          className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
            activeTab === 'completed' ? 'bg-white text-emerald-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Completed
        </button>
      </div>

      {/* Main Grid: Activity List & Selected Activity Detail */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left: Activities List */}
        <div className="space-y-3 lg:col-span-1">
          {filteredActivities.length === 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 p-8 text-center text-slate-400 text-xs">
              No activities found in this category
            </div>
          ) : (
            filteredActivities.map((act) => {
              const isSelected = selectedActivity?.id === act.id;
              const compPercent = Math.round(
                act.assignedParoleeIds.length > 0
                  ? (act.completedParoleeIds.length / act.assignedParoleeIds.length) * 100
                  : 0
              );

              return (
                <div
                  key={act.id}
                  onClick={() => setSelectedActivity(act)}
                  className={`p-4 rounded-xl border transition-all cursor-pointer ${
                    isSelected
                      ? 'bg-blue-50/70 border-blue-500 shadow-xs ring-2 ring-blue-500/20'
                      : 'bg-white border-slate-200 hover:border-slate-300'
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <span
                      className={`text-[10px] font-semibold uppercase px-2 py-0.5 rounded-md ${
                        act.status === 'completed'
                          ? 'bg-emerald-100 text-emerald-800'
                          : act.status === 'ongoing'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-amber-100 text-amber-800'
                      }`}
                    >
                      {act.status}
                    </span>
                    <span className="text-[11px] text-slate-500">
                      {new Date(act.scheduleDate).toLocaleDateString([], { month: 'short', day: 'numeric' })}
                    </span>
                  </div>

                  <h3 className="font-bold text-sm text-slate-900 mt-2 line-clamp-1">{act.title}</h3>
                  <p className="text-xs text-slate-500 line-clamp-2 mt-1">{act.description}</p>

                  <div className="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500">
                    <span className="flex items-center gap-1">
                      <Users className="w-3.5 h-3.5" /> {act.assignedParoleeIds.length} Assigned
                    </span>
                    <span className="font-semibold text-slate-700">{compPercent}% Verified</span>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Right: Selected Activity Detail & Attendance Roster */}
        {selectedActivity && (
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs lg:col-span-2 space-y-6">
            {/* Detail Top Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200">
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md bg-blue-100 text-blue-800">
                    {selectedActivity.type}
                  </span>
                  <span className="text-xs text-slate-400">Created: {new Date(selectedActivity.createdAt).toLocaleDateString()}</span>
                </div>
                <h2 className="text-xl font-bold text-slate-900 mt-1">{selectedActivity.title}</h2>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setIsScannerOpen(true)}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-semibold shadow-md transition-colors flex items-center gap-2"
                >
                  <QrCode className="w-4 h-4" />
                  <span>Scan QR for this Activity</span>
                </button>
              </div>
            </div>

            {/* Meta Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100">
                <span className="text-slate-400 block mb-0.5 flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5 text-blue-600" /> Location
                </span>
                <span className="font-semibold text-slate-900">{selectedActivity.location}</span>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100">
                <span className="text-slate-400 block mb-0.5 flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-blue-600" /> Scheduled Date & Time
                </span>
                <span className="font-semibold text-slate-900">
                  {new Date(selectedActivity.scheduleDate).toLocaleString([], {
                    month: 'short',
                    day: 'numeric',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </span>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100">
                <span className="text-slate-400 block mb-0.5 flex items-center gap-1">
                  <Users className="w-3.5 h-3.5 text-blue-600" /> Supervising Officer
                </span>
                <span className="font-semibold text-slate-900">{selectedActivity.officerName || 'Maria Santos'}</span>
              </div>
            </div>

            {/* Description */}
            <div>
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">Activity Scope & Directives</h4>
              <p className="text-xs text-slate-700 leading-relaxed bg-slate-50 p-3.5 rounded-xl border border-slate-100">
                {selectedActivity.description}
              </p>
            </div>

            {/* Assigned Parolees Roster */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                  <Users className="w-4 h-4 text-slate-500" /> Assigned Parolees Roster ({selectedActivity.assignedParoleeIds.length})
                </h4>
                <span className="text-xs text-slate-500">
                  {selectedActivity.completedParoleeIds.length} of {selectedActivity.assignedParoleeIds.length} Verified
                </span>
              </div>

              <div className="divide-y divide-slate-100 border border-slate-200 rounded-xl overflow-hidden">
                {selectedActivity.assignedParoleeIds.map((pId) => {
                  const parolee = users.find((u) => u.id === pId);
                  const isCheckedIn = selectedActivity.completedParoleeIds.includes(pId);

                  return (
                    <div
                      key={pId}
                      className="p-3.5 flex items-center justify-between text-xs hover:bg-slate-50 transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-slate-800 text-white font-bold flex items-center justify-center text-[10px]">
                          {parolee?.avatarInitials || parolee?.fullName.slice(0, 2).toUpperCase() || 'P'}
                        </div>
                        <div>
                          <p className="font-semibold text-slate-900">{parolee?.fullName || 'Assigned Parolee'}</p>
                          <p className="text-[11px] text-slate-500">Case: {parolee?.caseNumber || 'N/A'}</p>
                        </div>
                      </div>

                      <div className="flex items-center gap-2">
                        {isCheckedIn ? (
                          <span className="inline-flex items-center gap-1 font-semibold text-emerald-700 px-2.5 py-1 rounded-lg bg-emerald-50 border border-emerald-200">
                            <CheckCircle2 className="w-3.5 h-3.5" /> Checked In
                          </span>
                        ) : (
                          <div className="flex items-center gap-2">
                            <span className="text-amber-700 font-medium px-2 py-1 rounded-lg bg-amber-50 text-[11px]">
                              Awaiting QR Scan
                            </span>
                            <button
                              onClick={() => markAttendanceManual(selectedActivity.id, pId, 'checkedIn')}
                              className="px-2.5 py-1 bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold rounded-lg text-[11px] transition-colors"
                            >
                              Verify Manually
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Create Activity Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleCreateSubmit}
            className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150 max-h-[90vh] overflow-y-auto"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="font-bold text-base text-slate-900">Create New Rehabilitation Activity</h3>
              <button onClick={() => setShowCreateModal(false)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="mt-4 space-y-3.5 text-xs">
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Activity Type</label>
                <select
                  value={type}
                  onChange={(e) => setType(e.target.value as ActivityType)}
                  className="w-full text-xs px-3.5 py-2.5 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden font-medium"
                >
                  <option value="treePlanting">Tree Planting & Coastal Rehabilitation</option>
                  <option value="communityCleanup">Community Clean-Up Drive</option>
                  <option value="counselingSession">Counseling & Guidance Session</option>
                  <option value="other">Other Community Service</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Activity Title</label>
                <input
                  type="text"
                  placeholder="e.g. Cancabato Bay Mangrove Rehabilitation"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Description & Requirements</label>
                <textarea
                  rows={3}
                  placeholder="Mandatory rehabilitation task, required gear, safety directives..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                  required
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Location</label>
                  <input
                    type="text"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                    required
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Schedule Date & Time</label>
                  <input
                    type="datetime-local"
                    value={scheduleDate}
                    onChange={(e) => setScheduleDate(e.target.value)}
                    className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                    required
                  />
                </div>
              </div>

              {/* Assign Parolees Checkbox List */}
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1.5">
                  Assign Parolees ({selectedParoleeIds.length} selected)
                </label>
                <div className="border border-slate-200 rounded-xl divide-y divide-slate-100 max-h-44 overflow-y-auto">
                  {parolees.map((p) => {
                    const checked = selectedParoleeIds.includes(p.id);
                    return (
                      <div
                        key={p.id}
                        onClick={() => toggleParoleeSelection(p.id)}
                        className="p-2.5 flex items-center justify-between hover:bg-slate-50 cursor-pointer transition-colors"
                      >
                        <div>
                          <p className="font-semibold text-slate-900">{p.fullName}</p>
                          <p className="text-[11px] text-slate-500">{p.caseNumber || 'Parolee'}</p>
                        </div>
                        <div
                          className={`w-5 h-5 rounded-md flex items-center justify-center border transition-colors ${
                            checked ? 'bg-blue-600 border-blue-600 text-white' : 'border-slate-300 bg-white'
                          }`}
                        >
                          {checked && <Check className="w-3.5 h-3.5" />}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
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
                Create Activity
              </button>
            </div>
          </form>
        </div>
      )}

      {/* QR Scanner */}
      <QrScannerModal
        activity={selectedActivity || undefined}
        isOpen={isScannerOpen}
        onClose={() => setIsScannerOpen(false)}
      />
    </div>
  );
};
