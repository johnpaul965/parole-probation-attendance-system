import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { AppUser, UserRole, Geofence } from '../../types';
import { computeSupervision, APP_CONFIG } from '../../constants';
import {
  Users,
  UserPlus,
  Shield,
  MapPin,
  Radio,
  Trash2,
  Check,
  X,
  Compass,
  AlertTriangle,
  Phone,
  Calendar,
  Lock,
} from 'lucide-react';

export const UserManagement: React.FC = () => {
  const {
    users,
    trackers,
    currentUser,
    toggleUserActive,
    deleteUser,
    assignOfficer,
    removeOfficer,
    assignTracker,
    unassignTracker,
    assignGeofence,
    getParoleeSummary,
  } = useApp();

  const [roleFilter, setRoleFilter] = useState<UserRole | 'all'>('all');
  const [selectedParolee, setSelectedParolee] = useState<AppUser | null>(null);

  // Dialog states
  const [showAssignOfficerModal, setShowAssignOfficerModal] = useState(false);
  const [showAssignTrackerModal, setShowAssignTrackerModal] = useState(false);
  const [showGeofenceModal, setShowGeofenceModal] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<AppUser | null>(null);

  // Geofence form
  const [gfName, setGfName] = useState('Tacloban Monitoring Zone');
  const [gfLat, setGfLat] = useState(APP_CONFIG.taclobanLat.toString());
  const [gfLng, setGfLng] = useState(APP_CONFIG.taclobanLng.toString());
  const [gfRadius, setGfRadius] = useState(APP_CONFIG.defaultGeofenceRadiusMeters.toString());

  const officers = users.filter((u) => u.role === 'officer');
  const parolees = users.filter((u) => u.role === 'parolee');

  const filteredUsers = users.filter((u) => {
    if (roleFilter === 'all') return true;
    return u.role === roleFilter;
  });

  const handleSaveGeofence = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedParolee) return;

    assignGeofence({
      paroleeId: selectedParolee.id,
      name: gfName.trim() || 'Monitoring Area',
      centerLat: parseFloat(gfLat) || APP_CONFIG.taclobanLat,
      centerLng: parseFloat(gfLng) || APP_CONFIG.taclobanLng,
      radiusMeters: parseFloat(gfRadius) || APP_CONFIG.defaultGeofenceRadiusMeters,
      isActive: true,
    });

    setShowGeofenceModal(false);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Users className="w-5 h-5 text-blue-600" />
            <h1 className="text-xl font-bold text-slate-900">User Management & Caseload</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Manage officer assignments, wearable GPS tracker bindings, and geofence monitoring zones
          </p>
        </div>

        {/* Role Filters */}
        <div className="flex items-center gap-2 bg-slate-100 p-1 rounded-xl">
          <button
            onClick={() => setRoleFilter('all')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              roleFilter === 'all' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            All ({users.length})
          </button>
          <button
            onClick={() => setRoleFilter('officer')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              roleFilter === 'officer' ? 'bg-white text-blue-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Officers ({officers.length})
          </button>
          <button
            onClick={() => setRoleFilter('parolee')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              roleFilter === 'parolee' ? 'bg-white text-indigo-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Parolees ({parolees.length})
          </button>
        </div>
      </div>

      {/* User Roster */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredUsers.map((u) => {
          const isParolee = u.role === 'parolee';
          const assignedOfficer = officers.find((o) => o.id === u.officerId);
          const summary = isParolee ? getParoleeSummary(u.id) : null;
          const tracker = trackers.find((t) => t.paroleeId === u.id || t.id === u.trackerId);
          const supervision = isParolee
            ? computeSupervision(u.supervisionStartDate, u.supervisionEndDate, u.supervisionIsSuspended)
            : null;

          return (
            <div
              key={u.id}
              className={`bg-white rounded-xl border p-5 shadow-xs flex flex-col justify-between transition-all ${
                !u.isActive ? 'border-slate-200 bg-slate-50/50 opacity-80' : 'border-slate-200/90 hover:border-slate-300'
              }`}
            >
              <div>
                {/* User Card Top */}
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className={`w-10 h-10 rounded-full font-bold text-xs flex items-center justify-center text-white shadow-xs ${
                        isParolee ? 'bg-[#1A237E]' : 'bg-[#1565C0]'
                      }`}
                    >
                      {u.avatarInitials || u.fullName.slice(0, 2).toUpperCase()}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 text-sm leading-snug">{u.fullName}</h3>
                      <p className="text-[11px] text-slate-500 font-medium">{u.email}</p>
                    </div>
                  </div>

                  {/* Active Toggle Switch */}
                  <div className="flex items-center gap-1.5">
                    <span className="text-[10px] font-semibold text-slate-400 uppercase">
                      {u.isActive ? 'Active' : 'Off'}
                    </span>
                    <button
                      onClick={() => toggleUserActive(u.id, !u.isActive)}
                      className={`w-8 h-4 rounded-full transition-colors relative p-0.5 ${
                        u.isActive ? 'bg-emerald-500' : 'bg-slate-300'
                      }`}
                    >
                      <div
                        className={`w-3 h-3 rounded-full bg-white transition-transform ${
                          u.isActive ? 'translate-x-4' : 'translate-x-0'
                        }`}
                      />
                    </button>
                  </div>
                </div>

                {/* Details Section */}
                <div className="mt-4 pt-3 border-t border-slate-100 space-y-2 text-xs">
                  <div className="flex items-center justify-between text-slate-600">
                    <span className="flex items-center gap-1.5 text-slate-400">
                      <Shield className="w-3.5 h-3.5" /> Role:
                    </span>
                    <span
                      className={`font-semibold capitalize px-2 py-0.5 rounded-full text-[10px] ${
                        isParolee ? 'bg-indigo-50 text-indigo-700' : 'bg-blue-50 text-blue-700'
                      }`}
                    >
                      {u.role}
                    </span>
                  </div>

                  {isParolee && (
                    <>
                      <div className="flex items-center justify-between text-slate-600">
                        <span className="flex items-center gap-1.5 text-slate-400">
                          <Users className="w-3.5 h-3.5" /> Assigned Officer:
                        </span>
                        <span className="font-medium text-slate-900">
                          {assignedOfficer?.fullName || 'Unassigned'}
                        </span>
                      </div>

                      <div className="flex items-center justify-between text-slate-600">
                        <span className="flex items-center gap-1.5 text-slate-400">
                          <Radio className="w-3.5 h-3.5" /> GPS Tracker:
                        </span>
                        <span className="font-medium text-slate-900">
                          {tracker ? `${tracker.id} (${tracker.status})` : 'None Assigned'}
                        </span>
                      </div>

                      {supervision && (
                        <div className="flex items-center justify-between text-slate-600">
                          <span className="flex items-center gap-1.5 text-slate-400">
                            <Calendar className="w-3.5 h-3.5" /> Supervision:
                          </span>
                          <span className="font-medium text-slate-900">{supervision.shortLabel}</span>
                        </div>
                      )}

                      {u.phone && (
                        <div className="flex items-center justify-between text-slate-600">
                          <span className="flex items-center gap-1.5 text-slate-400">
                            <Phone className="w-3.5 h-3.5" /> Contact:
                          </span>
                          <span className="font-medium text-slate-900">{u.phone}</span>
                        </div>
                      )}
                    </>
                  )}

                  {!isParolee && (
                    <div className="flex items-center justify-between text-slate-600">
                      <span className="text-slate-400">Department:</span>
                      <span className="font-medium text-slate-900">{u.department || 'Field Officer'}</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center gap-2">
                {isParolee ? (
                  <>
                    <button
                      onClick={() => {
                        setSelectedParolee(u);
                        setShowAssignOfficerModal(true);
                      }}
                      className="flex-1 py-1.5 px-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-[11px] font-semibold rounded-lg transition-colors text-center"
                    >
                      Officer
                    </button>
                    <button
                      onClick={() => {
                        setSelectedParolee(u);
                        setShowAssignTrackerModal(true);
                      }}
                      className="flex-1 py-1.5 px-2 bg-blue-50 hover:bg-blue-100 text-blue-700 text-[11px] font-semibold rounded-lg transition-colors text-center"
                    >
                      Tracker
                    </button>
                    <button
                      onClick={() => {
                        setSelectedParolee(u);
                        setShowGeofenceModal(true);
                      }}
                      className="flex-1 py-1.5 px-2 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-[11px] font-semibold rounded-lg transition-colors text-center"
                    >
                      Geofence
                    </button>
                  </>
                ) : (
                  <span className="text-xs text-slate-400 italic">Officer Account</span>
                )}

                {currentUser?.id !== u.id && (
                  <button
                    onClick={() => setShowDeleteConfirm(u)}
                    title="Remove user"
                    className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors ml-auto"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Assign Officer Dialog */}
      {showAssignOfficerModal && selectedParolee && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
            <h3 className="font-bold text-base text-slate-900">Assign Officer</h3>
            <p className="text-xs text-slate-500 mt-1">Select officer for {selectedParolee.fullName}</p>

            <div className="mt-4 space-y-2 max-h-60 overflow-y-auto">
              {officers.map((o) => (
                <button
                  key={o.id}
                  onClick={() => {
                    assignOfficer(selectedParolee.id, o.id);
                    setShowAssignOfficerModal(false);
                  }}
                  className={`w-full p-3 rounded-xl text-left border flex items-center justify-between text-xs transition-colors ${
                    selectedParolee.officerId === o.id
                      ? 'bg-blue-50 border-blue-500 font-semibold text-blue-900'
                      : 'border-slate-200 hover:bg-slate-50'
                  }`}
                >
                  <div>
                    <p className="font-semibold">{o.fullName}</p>
                    <p className="text-[11px] text-slate-500">{o.department || 'Field Office'}</p>
                  </div>
                  {selectedParolee.officerId === o.id && <Check className="w-4 h-4 text-blue-600" />}
                </button>
              ))}
            </div>

            <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between">
              {selectedParolee.officerId && (
                <button
                  onClick={() => {
                    removeOfficer(selectedParolee.id);
                    setShowAssignOfficerModal(false);
                  }}
                  className="text-xs text-rose-600 hover:text-rose-800 font-semibold"
                >
                  Remove Officer
                </button>
              )}
              <button
                onClick={() => setShowAssignOfficerModal(false)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-xs font-semibold ml-auto"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Assign Tracker Dialog */}
      {showAssignTrackerModal && selectedParolee && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
            <h3 className="font-bold text-base text-slate-900">Assign GPS Tracker</h3>
            <p className="text-xs text-slate-500 mt-1">Bind wearable beacon to {selectedParolee.fullName}</p>

            <div className="mt-4 space-y-2 max-h-60 overflow-y-auto">
              {trackers.map((t) => {
                const isCurrent = t.paroleeId === selectedParolee.id;
                return (
                  <button
                    key={t.id}
                    onClick={() => {
                      assignTracker(t.id, selectedParolee.id);
                      setShowAssignTrackerModal(false);
                    }}
                    className={`w-full p-3 rounded-xl text-left border flex items-center justify-between text-xs transition-colors ${
                      isCurrent
                        ? 'bg-blue-50 border-blue-500 font-semibold text-blue-900'
                        : 'border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <div>
                      <p className="font-semibold">{t.id} ({t.deviceName || t.deviceIdentifier})</p>
                      <p className="text-[11px] text-slate-500">
                        Status: {t.status} • Battery: {t.batteryLevel ?? '—'}%
                        {t.paroleeId && !isCurrent ? ` (Assigned to ${t.paroleeName})` : ''}
                      </p>
                    </div>
                    {isCurrent && <Check className="w-4 h-4 text-blue-600" />}
                  </button>
                );
              })}
            </div>

            <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between">
              {selectedParolee.trackerId && (
                <button
                  onClick={() => {
                    unassignTracker(selectedParolee.trackerId!);
                    setShowAssignTrackerModal(false);
                  }}
                  className="text-xs text-rose-600 hover:text-rose-800 font-semibold"
                >
                  Unbind Tracker
                </button>
              )}
              <button
                onClick={() => setShowAssignTrackerModal(false)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-xs font-semibold ml-auto"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Geofence Dialog */}
      {showGeofenceModal && selectedParolee && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <form
            onSubmit={handleSaveGeofence}
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150"
          >
            <h3 className="font-bold text-base text-slate-900">Assign Geofence Zone</h3>
            <p className="text-xs text-slate-500 mt-1">Configure boundary for {selectedParolee.fullName}</p>

            <div className="mt-4 space-y-3">
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Zone Name</label>
                <input
                  type="text"
                  value={gfName}
                  onChange={(e) => setGfName(e.target.value)}
                  className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Center Lat</label>
                  <input
                    type="number"
                    step="any"
                    value={gfLat}
                    onChange={(e) => setGfLat(e.target.value)}
                    className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                    required
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Center Lng</label>
                  <input
                    type="number"
                    step="any"
                    value={gfLng}
                    onChange={(e) => setGfLng(e.target.value)}
                    className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase mb-1">Radius (Meters)</label>
                <input
                  type="number"
                  value={gfRadius}
                  onChange={(e) => setGfRadius(e.target.value)}
                  className="w-full text-xs px-3.5 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
                  required
                />
                <span className="text-[10px] text-slate-400 mt-0.5 block">
                  Default: 500m. 50m check-in perimeter is always enforced separately.
                </span>
              </div>
            </div>

            <div className="mt-5 pt-4 border-t border-slate-100 flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowGeofenceModal(false)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-semibold transition-colors"
              >
                Save Geofence
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Delete User Confirmation Dialog */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-sm w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
            <div className="w-10 h-10 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center mb-3">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-base text-slate-900">Remove User Account</h3>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              Are you sure you want to remove <strong>{showDeleteConfirm.fullName}</strong> ({showDeleteConfirm.role})
              from the PPA-TAC system?
            </p>
            <div className="mt-5 flex items-center justify-end gap-2">
              <button
                onClick={() => setShowDeleteConfirm(null)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  deleteUser(showDeleteConfirm.id);
                  setShowDeleteConfirm(null);
                }}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-semibold transition-colors"
              >
                Remove User
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
