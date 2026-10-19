import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { ActivityModel } from '../../types';
import {
  Calendar,
  Plus,
  Users,
  MapPin,
  Clock,
  Award,
  CheckCircle,
  FileText,
  AlertCircle
} from 'lucide-react';

export const ActivitiesManagement: React.FC = () => {
  const { activities, createActivity, assignParoleeToActivity, users, currentUser } = useApp();
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedActivityForAssign, setSelectedActivityForAssign] = useState<ActivityModel | null>(null);

  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState<ActivityModel['category']>('counseling');
  const [location, setLocation] = useState('');
  const [scheduledDate, setScheduledDate] = useState('2026-10-25');
  const [startTime, setStartTime] = useState('10:00 AM');
  const [endTime, setEndTime] = useState('12:00 PM');
  const [hours, setHours] = useState(2);
  const [mandatory, setMandatory] = useState(true);

  const parolees = users.filter(u => u.role === 'parolee');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !location) return;

    createActivity({
      title,
      description,
      category,
      location,
      latitude: 37.7749,
      longitude: -122.4194,
      scheduledDate,
      startTime,
      endTime,
      assignedOfficerId: currentUser.id,
      assignedOfficerName: currentUser.name,
      paroleeIds: [],
      mandatory,
      pointsOrHours: hours,
      status: 'upcoming'
    });

    // Reset
    setTitle('');
    setDescription('');
    setLocation('');
    setShowCreateModal(false);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Mandatory Programs & Community Service
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Schedule rehabilitation workshops, court hearings, drug screenings, and assign supervised subjects.
          </p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="px-4 py-2 text-xs font-semibold bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors flex items-center gap-1.5 shadow-xs"
        >
          <Plus className="w-4 h-4" />
          Schedule Program
        </button>
      </div>

      {/* Program Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {activities.map(activity => {
          const categoryColors = {
            counseling: 'bg-purple-100 text-purple-700 border-purple-200',
            community_service: 'bg-emerald-100 text-emerald-700 border-emerald-200',
            drug_test: 'bg-red-100 text-red-700 border-red-200',
            court_hearing: 'bg-blue-100 text-blue-700 border-blue-200',
            job_training: 'bg-amber-100 text-amber-700 border-amber-200',
          };

          return (
            <div key={activity.id} className="bg-white rounded-xl border border-slate-200 p-5 flex flex-col justify-between shadow-xs">
              <div>
                <div className="flex items-center justify-between gap-2">
                  <span className={`px-2 py-0.5 rounded-full text-[11px] font-semibold border ${categoryColors[activity.category] || 'bg-slate-100 text-slate-700'}`}>
                    {activity.category.replace('_', ' ').toUpperCase()}
                  </span>
                  {activity.mandatory && (
                    <span className="text-[11px] text-red-600 font-bold flex items-center gap-0.5">
                      <AlertCircle className="w-3.5 h-3.5" /> Mandatory
                    </span>
                  )}
                </div>

                <h3 className="font-bold text-slate-900 text-base mt-2.5 leading-snug">
                  {activity.title}
                </h3>
                <p className="text-xs text-slate-600 mt-1.5 line-clamp-2">
                  {activity.description}
                </p>

                <div className="mt-4 space-y-2 text-xs text-slate-600 border-t border-slate-100 pt-3">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-slate-400 shrink-0" />
                    <span>{activity.scheduledDate} ({activity.startTime} - {activity.endTime})</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-slate-400 shrink-0" />
                    <span className="truncate">{activity.location}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Award className="w-4 h-4 text-slate-400 shrink-0" />
                    <span className="font-medium text-slate-900">{activity.pointsOrHours} Hours Compliance Credit</span>
                  </div>
                </div>

                {/* Assigned Parolees */}
                <div className="mt-4 pt-3 border-t border-slate-100">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">
                      Assigned ({activity.paroleeIds.length})
                    </span>
                    <button
                      onClick={() => setSelectedActivityForAssign(activity)}
                      className="text-xs text-blue-600 font-semibold hover:underline"
                    >
                      + Assign Subject
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    {activity.paroleeIds.length === 0 ? (
                      <span className="text-xs text-slate-400 italic">No subjects assigned yet</span>
                    ) : (
                      activity.paroleeIds.map(pId => {
                        const p = users.find(u => u.id === pId);
                        return (
                          <span key={pId} className="text-xs bg-slate-100 text-slate-700 px-2 py-0.5 rounded-md font-medium">
                            {p?.name || pId}
                          </span>
                        );
                      })
                    )}
                  </div>
                </div>
              </div>

              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-400">Supervisor: {activity.assignedOfficerName}</span>
                <span className="font-semibold text-emerald-600 capitalize">{activity.status}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Create Activity Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl border border-slate-200 max-w-lg w-full p-6 shadow-2xl">
            <h3 className="text-base font-bold text-slate-900">Schedule Supervision Program</h3>
            <p className="text-xs text-slate-500 mt-0.5">Define court-ordered activity, location, and credit value.</p>

            <form onSubmit={handleSubmit} className="mt-4 space-y-3.5 text-xs">
              <div>
                <label className="font-semibold text-slate-700 block mb-1">Activity Title</label>
                <input
                  type="text"
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g. Substance Abuse Rehabilitation Panel"
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Category</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value as any)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs bg-white"
                  >
                    <option value="counseling">Counseling & Rehab</option>
                    <option value="community_service">Community Service</option>
                    <option value="drug_test">Drug & Alcohol Test</option>
                    <option value="court_hearing">Court Hearing</option>
                    <option value="job_training">Job Training</option>
                  </select>
                </div>
                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Credit Hours</label>
                  <input
                    type="number"
                    min="1"
                    max="12"
                    value={hours}
                    onChange={(e) => setHours(Number(e.target.value))}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Facility / Street Location</label>
                <input
                  type="text"
                  required
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  placeholder="e.g. Community Center, 400 Main St, Springfield"
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs"
                />
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Date</label>
                  <input
                    type="date"
                    value={scheduledDate}
                    onChange={(e) => setScheduledDate(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs"
                  />
                </div>
                <div>
                  <label className="font-semibold text-slate-700 block mb-1">Start</label>
                  <input
                    type="text"
                    value={startTime}
                    onChange={(e) => setStartTime(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs"
                  />
                </div>
                <div>
                  <label className="font-semibold text-slate-700 block mb-1">End</label>
                  <input
                    type="text"
                    value={endTime}
                    onChange={(e) => setEndTime(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs"
                  />
                </div>
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Description & Requirements</label>
                <textarea
                  rows={2}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Specific obligations, dress code, counselor contact..."
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg text-xs"
                />
              </div>

              <div className="flex items-center gap-2 pt-1">
                <input
                  type="checkbox"
                  id="mand"
                  checked={mandatory}
                  onChange={(e) => setMandatory(e.target.checked)}
                  className="rounded border-slate-300"
                />
                <label htmlFor="mand" className="text-xs text-slate-700 font-medium">
                  Mandatory Program (Failure to attend flags an infraction)
                </label>
              </div>

              <div className="mt-5 flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="px-4 py-1.5 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-1.5 text-xs font-semibold bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors"
                >
                  Create & Notify
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Assign Parolee Modal */}
      {selectedActivityForAssign && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl border border-slate-200 max-w-md w-full p-6 shadow-2xl">
            <h3 className="text-base font-bold text-slate-900">
              Assign Subject to {selectedActivityForAssign.title}
            </h3>
            <p className="text-xs text-slate-500 mt-1">
              Select supervised individuals required to attend this session.
            </p>

            <div className="mt-4 space-y-2 max-h-60 overflow-y-auto">
              {parolees.map(p => {
                const isAssigned = selectedActivityForAssign.paroleeIds.includes(p.id);
                return (
                  <div
                    key={p.id}
                    className="p-3 rounded-lg border border-slate-200 flex items-center justify-between text-xs"
                  >
                    <div>
                      <p className="font-bold text-slate-900">{p.name}</p>
                      <p className="text-slate-500 text-[11px]">{p.caseNumber} · Risk: {p.riskLevel}</p>
                    </div>
                    {isAssigned ? (
                      <span className="text-xs font-semibold text-emerald-600 flex items-center gap-1">
                        <CheckCircle className="w-4 h-4" /> Assigned
                      </span>
                    ) : (
                      <button
                        onClick={() => {
                          assignParoleeToActivity(selectedActivityForAssign.id, p.id);
                          setSelectedActivityForAssign(prev => prev ? ({ ...prev, paroleeIds: [...prev.paroleeIds, p.id] }) : null);
                        }}
                        className="px-3 py-1 bg-slate-900 text-white text-xs font-semibold rounded-md hover:bg-slate-800"
                      >
                        Assign
                      </button>
                    )}
                  </div>
                );
              })}
            </div>

            <div className="mt-5 flex justify-end">
              <button
                onClick={() => setSelectedActivityForAssign(null)}
                className="px-4 py-1.5 text-xs font-semibold bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
