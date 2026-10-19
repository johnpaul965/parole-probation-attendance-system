import React from 'react';
import { useApp } from '../../context/AppContext';
import { computeSupervision } from '../../constants';
import {
  User,
  Shield,
  Phone,
  Mail,
  MapPin,
  Calendar,
  Radio,
  FileText,
  BadgeCheck,
  CheckCircle2,
} from 'lucide-react';

export const ProfileView: React.FC = () => {
  const { currentUser, users, trackers } = useApp();

  if (!currentUser) return null;

  const isOfficer = currentUser.role === 'officer';
  const assignedOfficer = users.find((u) => u.id === currentUser.officerId);
  const assignedTracker = trackers.find((t) => t.paroleeId === currentUser.id || t.id === currentUser.trackerId);
  const supervision = computeSupervision(
    currentUser.supervisionStartDate,
    currentUser.supervisionEndDate,
    currentUser.supervisionIsSuspended
  );

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-12">
      {/* Header Banner */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs">
        <div
          className={`h-24 ${
            isOfficer
              ? 'bg-gradient-to-r from-[#1565C0] to-[#0D1B2A]'
              : 'bg-gradient-to-r from-[#1A237E] to-[#0D1B2A]'
          }`}
        />
        <div className="px-6 pb-6 pt-0 relative flex flex-col sm:flex-row sm:items-end justify-between gap-4">
          <div className="flex items-end gap-4 -mt-10">
            <div
              className={`w-20 h-20 rounded-2xl border-4 border-white font-bold text-xl flex items-center justify-center text-white shadow-md ${
                isOfficer ? 'bg-[#1565C0]' : 'bg-[#1A237E]'
              }`}
            >
              {currentUser.avatarInitials || currentUser.fullName.slice(0, 2).toUpperCase()}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold text-slate-900">{currentUser.fullName}</h1>
                <BadgeCheck className="w-5 h-5 text-blue-600" />
              </div>
              <p className="text-xs text-slate-500 font-medium">
                {isOfficer ? 'Probation & Parole Officer II' : `Parolee · Case ${currentUser.caseNumber || 'Active'}`}
              </p>
            </div>
          </div>

          <span
            className={`self-start sm:self-auto text-xs font-semibold px-3 py-1 rounded-full capitalize ${
              isOfficer ? 'bg-blue-50 text-blue-700' : 'bg-indigo-50 text-indigo-700'
            }`}
          >
            {currentUser.role} Account Active
          </span>
        </div>
      </div>

      {/* Profile Details Sections */}
      <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs space-y-6">
        <div>
          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-1.5">
            <User className="w-4 h-4 text-blue-600" /> Account & Contact Information
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
              <Mail className="w-4 h-4 text-slate-400" />
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Email Address</span>
                <span className="font-semibold text-slate-800">{currentUser.email}</span>
              </div>
            </div>

            <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
              <Phone className="w-4 h-4 text-slate-400" />
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Mobile Phone</span>
                <span className="font-semibold text-slate-800">{currentUser.phone || '+63 920 123 4567'}</span>
              </div>
            </div>

            <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
              <MapPin className="w-4 h-4 text-slate-400" />
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Office / Station</span>
                <span className="font-semibold text-slate-800">{currentUser.department || 'District 4 - Tacloban'}</span>
              </div>
            </div>

            <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
              <Shield className="w-4 h-4 text-slate-400" />
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Account Status</span>
                <span className="font-semibold text-emerald-700">Verified & Active</span>
              </div>
            </div>
          </div>
        </div>

        {!isOfficer && (
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-1.5">
              <FileText className="w-4 h-4 text-indigo-700" /> Supervision & Legal Mandates
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
                <Calendar className="w-4 h-4 text-slate-400" />
                <div>
                  <span className="text-slate-400 block text-[10px] uppercase font-semibold">Supervision Term</span>
                  <span className="font-semibold text-slate-800">{supervision.label}</span>
                </div>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
                <Radio className="w-4 h-4 text-slate-400" />
                <div>
                  <span className="text-slate-400 block text-[10px] uppercase font-semibold">GPS Tracker Device</span>
                  <span className="font-semibold text-slate-800">
                    {assignedTracker ? `${assignedTracker.id} (${assignedTracker.status})` : 'Unassigned'}
                  </span>
                </div>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
                <User className="w-4 h-4 text-slate-400" />
                <div>
                  <span className="text-slate-400 block text-[10px] uppercase font-semibold">Assigned Probation Officer</span>
                  <span className="font-semibold text-slate-800">{assignedOfficer?.fullName || 'Maria Santos'}</span>
                </div>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 flex items-center gap-3">
                <MapPin className="w-4 h-4 text-slate-400" />
                <div>
                  <span className="text-slate-400 block text-[10px] uppercase font-semibold">Designated Check-in Post</span>
                  <span className="font-semibold text-slate-800">PPA Tacloban Office (50m Radius)</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
