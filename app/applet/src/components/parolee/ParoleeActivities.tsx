import React from 'react';
import { useApp } from '../../context/AppContext';
import { Calendar, MapPin, Clock, Award, AlertCircle, CheckCircle2 } from 'lucide-react';

export const ParoleeActivities: React.FC = () => {
  const { currentUser, activities } = useApp();

  const myActivities = activities.filter(a => a.paroleeIds.includes(currentUser.id));
  const totalEarnedHours = myActivities.reduce((acc, curr) => acc + curr.pointsOrHours, 0);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Assigned Rehabilitation Programs
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Court-ordered community service, vocational classes, and recovery counseling sessions.
          </p>
        </div>

        <div className="bg-white border border-slate-200 px-4 py-2 rounded-xl text-xs flex items-center gap-2 shadow-2xs">
          <Award className="w-4 h-4 text-emerald-600" />
          <span className="text-slate-600">Assigned Credits:</span>
          <span className="font-bold text-slate-900">{totalEarnedHours} Hours</span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {myActivities.length === 0 ? (
          <div className="col-span-2 p-8 text-center text-slate-400 text-xs bg-white rounded-xl border border-slate-200">
            No mandatory activities currently assigned to your case number.
          </div>
        ) : (
          myActivities.map(activity => (
            <div key={activity.id} className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between">
                  <span className="text-[11px] font-bold text-purple-700 bg-purple-50 border border-purple-200 px-2.5 py-0.5 rounded-full uppercase">
                    {activity.category.replace('_', ' ')}
                  </span>
                  {activity.mandatory && (
                    <span className="text-[11px] text-red-600 font-semibold flex items-center gap-1">
                      <AlertCircle className="w-3.5 h-3.5" /> Required
                    </span>
                  )}
                </div>

                <h3 className="font-bold text-slate-900 text-base mt-2.5">{activity.title}</h3>
                <p className="text-xs text-slate-600 mt-1.5">{activity.description}</p>

                <div className="mt-4 space-y-2 text-xs text-slate-600 pt-3 border-t border-slate-100">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-slate-400 shrink-0" />
                    <span>{activity.scheduledDate} ({activity.startTime} - {activity.endTime})</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-slate-400 shrink-0" />
                    <span>{activity.location}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Award className="w-4 h-4 text-slate-400 shrink-0" />
                    <span className="font-semibold text-slate-900">+{activity.pointsOrHours} Hours Compliance Credit</span>
                  </div>
                </div>
              </div>

              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-400">Officer: {activity.assignedOfficerName}</span>
                <span className="text-emerald-700 font-semibold flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" /> Enrolled
                </span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
