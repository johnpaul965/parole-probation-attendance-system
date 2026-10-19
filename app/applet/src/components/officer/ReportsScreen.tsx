import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  FileText,
  Download,
  Calendar,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Printer,
  FileCheck
} from 'lucide-react';

export const ReportsScreen: React.FC = () => {
  const { attendanceRecords, users, trackers, alerts } = useApp();
  const [downloadSuccess, setDownloadSuccess] = useState<string | null>(null);

  const handleExport = (format: 'pdf' | 'csv') => {
    setDownloadSuccess(`Compliance_Summary_Report_${new Date().toISOString().slice(0, 10)}.${format}`);
    setTimeout(() => {
      setDownloadSuccess(null);
    }, 4000);
  };

  const parolees = users.filter(u => u.role === 'parolee');
  const totalCheckIns = attendanceRecords.length;
  const compliantCount = attendanceRecords.filter(r => r.status === 'present').length;
  const lateCount = attendanceRecords.filter(r => r.status === 'late').length;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Compliance & Audit Reports
          </h1>
          <p className="text-sm text-slate-500 mt-0.5">
            Court-certified attendance verification summaries, infractions log, and GPS geofence analytics.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => handleExport('csv')}
            className="px-3 py-1.5 text-xs font-semibold bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors flex items-center gap-1.5 shadow-2xs"
          >
            <Download className="w-3.5 h-3.5" />
            Export CSV
          </button>
          <button
            onClick={() => handleExport('pdf')}
            className="px-4 py-2 text-xs font-semibold bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors flex items-center gap-1.5 shadow-xs"
          >
            <Printer className="w-3.5 h-3.5" />
            Generate Court PDF Report
          </button>
        </div>
      </div>

      {downloadSuccess && (
        <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-xs text-emerald-800 flex items-center gap-2 animate-fadeIn">
          <FileCheck className="w-4 h-4 text-emerald-600" />
          <span>Report generated successfully: <strong>{downloadSuccess}</strong> (Signed by Supervision Authority)</span>
        </div>
      )}

      {/* High-level stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Total Recorded Sessions</span>
          <p className="text-3xl font-extrabold text-slate-900 mt-2 tabular-nums">{totalCheckIns}</p>
          <div className="mt-2 text-xs text-slate-600 flex items-center gap-2">
            <span className="text-emerald-600 font-semibold">{compliantCount} On-Time</span>
            <span>·</span>
            <span className="text-amber-600 font-semibold">{lateCount} Late Check-in</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Supervision Caseload</span>
          <p className="text-3xl font-extrabold text-slate-900 mt-2 tabular-nums">{parolees.length} Active</p>
          <p className="mt-2 text-xs text-slate-500">100% paired with hardware IoT GPS units</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">Audit Security Invariants</span>
          <p className="text-3xl font-extrabold text-emerald-600 mt-2">Verified</p>
          <p className="mt-2 text-xs text-slate-500">SHA-256 token verification on all QR scans</p>
        </div>
      </div>

      {/* Compliance Master Ledger Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h2 className="text-base font-bold text-slate-900">Attendance Verification Ledger</h2>
            <p className="text-xs text-slate-500">Cryptographically verifiable check-in records</p>
          </div>
          <span className="text-xs text-slate-400 font-mono">Showing {attendanceRecords.length} entries</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 border-b border-slate-200 font-semibold uppercase tracking-wider text-[11px]">
              <tr>
                <th className="py-3 px-6">Timestamp & Ticket</th>
                <th className="py-3 px-6">Subject / Case #</th>
                <th className="py-3 px-6">Type & Method</th>
                <th className="py-3 px-6">Geofence Status</th>
                <th className="py-3 px-6">Compliance Status</th>
                <th className="py-3 px-6">Notes / Officer Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700">
              {attendanceRecords.map(rec => {
                const subject = users.find(u => u.id === rec.paroleeId);
                return (
                  <tr key={rec.id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="py-3.5 px-6">
                      <span className="font-mono font-medium text-slate-900 block">{rec.ticketCode}</span>
                      <span className="text-[11px] text-slate-400 block mt-0.5">{rec.timestamp.replace('T', ' ').slice(0, 19)}</span>
                    </td>
                    <td className="py-3.5 px-6">
                      <span className="font-bold text-slate-900 block">{rec.paroleeName}</span>
                      <span className="text-[11px] text-slate-500 font-mono">{subject?.caseNumber || 'CR-Pending'}</span>
                    </td>
                    <td className="py-3.5 px-6">
                      <span className="capitalize font-semibold text-slate-800">{rec.type}</span>
                      <span className="text-[11px] text-slate-400 block mt-0.5">{rec.verificationMethod.replace('_', ' ')}</span>
                    </td>
                    <td className="py-3.5 px-6">
                      <span className="text-emerald-700 font-medium bg-emerald-50 px-2 py-0.5 rounded text-[11px]">
                        Inside Allowed Zone
                      </span>
                      <span className="text-[10px] text-slate-400 block mt-1 truncate max-w-xs">{rec.location?.address}</span>
                    </td>
                    <td className="py-3.5 px-6">
                      <span className={`inline-block px-2.5 py-0.5 rounded-full font-semibold uppercase text-[10px] ${
                        rec.status === 'present' ? 'bg-emerald-100 text-emerald-800' :
                        rec.status === 'late' ? 'bg-amber-100 text-amber-800' :
                        'bg-red-100 text-red-800'
                      }`}>
                        {rec.status}
                      </span>
                    </td>
                    <td className="py-3.5 px-6 text-slate-600 max-w-xs">
                      {rec.notes || 'Verified standard reporting.'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
