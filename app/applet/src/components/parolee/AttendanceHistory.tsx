import React from 'react';
import { useApp } from '../../context/AppContext';
import { Calendar, CheckCircle2, Clock, AlertTriangle, QrCode } from 'lucide-react';

export const AttendanceHistory: React.FC = () => {
  const { currentUser, attendanceRecords } = useApp();

  const myRecords = attendanceRecords.filter(r => r.paroleeId === currentUser.id);

  return (
    <div className="space-y-6">
      <div className="pb-2 border-b border-slate-200">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">
          My Supervision Attendance History
        </h1>
        <p className="text-sm text-slate-500 mt-0.5">
          Official record of all verified check-ins, program attendances, and supervision credits.
        </p>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
        {myRecords.length === 0 ? (
          <div className="p-8 text-center text-slate-400 text-xs">
            No check-in history recorded yet. Use the Check-In tab to complete your first session.
          </div>
        ) : (
          <div className="divide-y divide-slate-100">
            {myRecords.map(rec => (
              <div key={rec.id} className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50/60 transition-colors text-xs">
                <div className="flex items-start gap-3.5">
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                    rec.status === 'present' ? 'bg-emerald-100 text-emerald-700' :
                    rec.status === 'late' ? 'bg-amber-100 text-amber-700' :
                    'bg-red-100 text-red-700'
                  }`}>
                    <QrCode className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-slate-900 text-sm capitalize">{rec.type} Check-In</span>
                      <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase ${
                        rec.status === 'present' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' :
                        rec.status === 'late' ? 'bg-amber-50 text-amber-700 border border-amber-200' :
                        'bg-red-50 text-red-700 border border-red-200'
                      }`}>
                        {rec.status}
                      </span>
                    </div>
                    <p className="text-slate-600 mt-1">{rec.notes || 'Verified standard reporting.'}</p>
                    <div className="flex flex-wrap items-center gap-3 text-slate-400 text-[11px] mt-2">
                      <span>Location: {rec.location?.address}</span>
                      <span>·</span>
                      <span>Verification: {rec.verificationMethod.replace('_', ' ')}</span>
                    </div>
                  </div>
                </div>

                <div className="text-left sm:text-right shrink-0">
                  <span className="text-[11px] text-slate-400 block font-mono">
                    {new Date(rec.timestamp).toLocaleDateString()} at {new Date(rec.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                  <span className="font-mono font-semibold text-slate-800 text-xs block mt-1">
                    {rec.ticketCode}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
