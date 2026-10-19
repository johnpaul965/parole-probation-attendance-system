import React from 'react';
import { useApp } from '../../context/AppContext';
import { CalendarCheck, MapPin, Clock, Users, CheckCircle2, QrCode } from 'lucide-react';

interface Props {
  onNavigate: (tab: string) => void;
}

export const ParoleeActivities: React.FC<Props> = ({ onNavigate }) => {
  const { currentUser, activities } = useApp();

  if (!currentUser) return null;

  const myActivities = activities.filter((a) => a.assignedParoleeIds.includes(currentUser.id));

  return (
    <div className="space-y-6 pb-12">
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <CalendarCheck className="w-5 h-5 text-indigo-700" />
            <h1 className="text-xl font-bold text-slate-900">My Assigned Activities</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Mandatory community service, coastal rehabilitation, and counseling sessions assigned to you
          </p>
        </div>

        <button
          onClick={() => onNavigate('check-in')}
          className="px-4 py-2.5 bg-indigo-700 hover:bg-indigo-800 text-white font-semibold rounded-xl text-xs sm:text-sm shadow-md transition-all flex items-center gap-2 self-start sm:self-auto"
        >
          <QrCode className="w-4 h-4" />
          <span>Show Check-in QR</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {myActivities.length === 0 ? (
          <div className="col-span-2 bg-white rounded-xl border border-slate-200 p-12 text-center text-slate-400 text-xs">
            No activities assigned to you yet. Your supervising officer will post schedules here.
          </div>
        ) : (
          myActivities.map((act) => {
            const isCompleted = act.completedParoleeIds.includes(currentUser.id);

            return (
              <div
                key={act.id}
                className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col justify-between hover:border-indigo-300 transition-colors"
              >
                <div>
                  <div className="flex items-start justify-between gap-2">
                    <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md bg-indigo-50 text-indigo-800">
                      {act.type}
                    </span>
                    <span
                      className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize ${
                        isCompleted
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}
                    >
                      {isCompleted ? 'Completed' : act.status}
                    </span>
                  </div>

                  <h3 className="font-bold text-base text-slate-900 mt-2">{act.title}</h3>
                  <p className="text-xs text-slate-600 mt-1.5 leading-relaxed">{act.description}</p>

                  <div className="mt-4 pt-3 border-t border-slate-100 space-y-1.5 text-xs text-slate-600">
                    <p className="flex items-center gap-2">
                      <Clock className="w-3.5 h-3.5 text-indigo-600 shrink-0" />
                      <span>
                        {new Date(act.scheduleDate).toLocaleString([], {
                          weekday: 'short',
                          month: 'short',
                          day: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                    </p>
                    <p className="flex items-center gap-2">
                      <MapPin className="w-3.5 h-3.5 text-indigo-600 shrink-0" />
                      <span>{act.location}</span>
                    </p>
                    <p className="flex items-center gap-2">
                      <Users className="w-3.5 h-3.5 text-indigo-600 shrink-0" />
                      <span>Supervising Officer: {act.officerName || 'Maria Santos'}</span>
                    </p>
                  </div>
                </div>

                <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between">
                  {isCompleted ? (
                    <span className="text-xs font-semibold text-emerald-700 flex items-center gap-1.5">
                      <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                      Attendance Recorded
                    </span>
                  ) : (
                    <button
                      onClick={() => onNavigate('check-in')}
                      className="w-full py-2 bg-indigo-50 hover:bg-indigo-100 text-indigo-800 rounded-lg text-xs font-semibold transition-colors flex items-center justify-center gap-1.5"
                    >
                      <QrCode className="w-3.5 h-3.5" />
                      <span>Present Check-in QR</span>
                    </button>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
