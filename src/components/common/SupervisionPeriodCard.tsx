import React from 'react';
import { SupervisionSnapshot } from '../../types';
import { Calendar, Clock, AlertCircle, ShieldAlert, CheckCircle2 } from 'lucide-react';

interface Props {
  snapshot: SupervisionSnapshot;
  startDate?: string;
  endDate?: string;
  paroleeFacing?: boolean;
}

export const SupervisionPeriodCard: React.FC<Props> = ({
  snapshot,
  startDate,
  endDate,
  paroleeFacing = false,
}) => {
  return (
    <div className="bg-white rounded-xl border border-slate-200/80 p-4 sm:p-5 shadow-xs">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Calendar className="w-4 h-4 text-blue-600" />
          <span className="text-xs font-semibold tracking-wider uppercase text-slate-500">
            {paroleeFacing ? 'My Supervision Term' : 'Supervision Period'}
          </span>
        </div>
        <span
          className={`text-xs font-semibold px-2.5 py-0.5 rounded-full inline-flex items-center gap-1 ${
            snapshot.isSuspended
              ? 'bg-amber-50 text-amber-700 border border-amber-200'
              : snapshot.isActive
              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
              : 'bg-slate-100 text-slate-700 border border-slate-200'
          }`}
        >
          {snapshot.isSuspended ? (
            <ShieldAlert className="w-3 h-3 text-amber-600" />
          ) : snapshot.isActive ? (
            <CheckCircle2 className="w-3 h-3 text-emerald-600" />
          ) : (
            <AlertCircle className="w-3 h-3 text-slate-500" />
          )}
          {snapshot.shortLabel}
        </span>
      </div>

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pt-1">
        <div>
          <p className="text-xl font-bold text-slate-900 tracking-tight">{snapshot.label}</p>
          <div className="flex items-center gap-4 mt-1.5 text-xs text-slate-500">
            <span>
              Start: <strong className="text-slate-700 font-medium">{startDate ? new Date(startDate).toLocaleDateString() : 'N/A'}</strong>
            </span>
            <span>•</span>
            <span>
              End: <strong className="text-slate-700 font-medium">{endDate ? new Date(endDate).toLocaleDateString() : 'N/A'}</strong>
            </span>
          </div>
        </div>

        {snapshot.isActive && !snapshot.hasMissingDates && (
          <div className="bg-blue-50/70 border border-blue-100 rounded-lg p-2.5 sm:text-right shrink-0">
            <span className="text-[11px] text-blue-700 font-medium flex items-center gap-1 sm:justify-end">
              <Clock className="w-3.5 h-3.5" /> Compliance Window
            </span>
            <span className="text-xs text-slate-600 font-normal">Active Reporting Required</span>
          </div>
        )}
      </div>
    </div>
  );
};
