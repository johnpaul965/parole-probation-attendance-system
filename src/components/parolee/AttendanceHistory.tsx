import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { AttendanceStatus } from '../../types';
import {
  History,
  CheckCircle2,
  Clock,
  AlertOctagon,
  MapPin,
  Calendar,
  Filter,
} from 'lucide-react';

export const AttendanceHistory: React.FC = () => {
  const { currentUser, attendance } = useApp();
  const [filter, setFilter] = useState<AttendanceStatus | 'all'>('all');

  if (!currentUser) return null;

  const myRecords = attendance.filter((a) => {
    if (a.paroleeId !== currentUser.id) return false;
    if (filter === 'all') return true;
    return a.status === filter;
  });

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <History className="w-5 h-5 text-indigo-700" />
            <h1 className="text-xl font-bold text-slate-900">Attendance Check-in History</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Official chronological log of past check-in sessions, biometric verifications, and compliance states
          </p>
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-1.5 bg-slate-100 p-1 rounded-xl self-start sm:self-auto">
          <button
            onClick={() => setFilter('all')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              filter === 'all' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setFilter('checkedIn')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              filter === 'checkedIn' ? 'bg-white text-emerald-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Verified
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              filter === 'pending' ? 'bg-white text-amber-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Pending
          </button>
          <button
            onClick={() => setFilter('missed')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
              filter === 'missed' ? 'bg-white text-rose-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Missed
          </button>
        </div>
      </div>

      {/* History List */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="divide-y divide-slate-100">
          {myRecords.length === 0 ? (
            <div className="p-12 text-center text-slate-400 text-xs">
              No attendance records found matching this filter
            </div>
          ) : (
            myRecords.map((rec) => {
              const isCheckedIn = rec.status === 'checkedIn';
              const isMissed = rec.status === 'missed';

              return (
                <div
                  key={rec.id}
                  className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50/80 transition-colors"
                >
                  <div className="flex items-start gap-3.5">
                    <div
                      className={`p-2.5 rounded-xl shrink-0 mt-0.5 ${
                        isCheckedIn
                          ? 'bg-emerald-50 text-emerald-600'
                          : isMissed
                          ? 'bg-rose-50 text-rose-600'
                          : 'bg-amber-50 text-amber-600'
                      }`}
                    >
                      {isCheckedIn && <CheckCircle2 className="w-5 h-5" />}
                      {isMissed && <AlertOctagon className="w-5 h-5" />}
                      {!isCheckedIn && !isMissed && <Clock className="w-5 h-5" />}
                    </div>

                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-mono font-bold text-slate-900 text-sm">{rec.ticketId}</span>
                        <span className="text-xs text-slate-400">•</span>
                        <span className="text-xs font-semibold text-slate-700">
                          {rec.activityTitle || 'Office Check-in'}
                        </span>
                      </div>

                      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-1 text-xs text-slate-500">
                        {rec.checkInTime && (
                          <span className="flex items-center gap-1">
                            <Clock className="w-3.5 h-3.5 text-slate-400" />
                            {new Date(rec.checkInTime).toLocaleString([], {
                              month: 'short',
                              day: 'numeric',
                              year: 'numeric',
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </span>
                        )}
                        {rec.location && (
                          <span className="flex items-center gap-1">
                            <MapPin className="w-3.5 h-3.5 text-slate-400" />
                            {rec.location}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Status Badge */}
                  <div className="flex items-center gap-2 self-start sm:self-auto shrink-0">
                    <span
                      className={`text-xs font-semibold px-3 py-1 rounded-full ${
                        isCheckedIn
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : isMissed
                          ? 'bg-rose-50 text-rose-700 border border-rose-200'
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}
                    >
                      {isCheckedIn ? 'Verified & Approved' : isMissed ? 'Marked Missed' : 'Awaiting Check-in'}
                    </span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
};
