import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  BarChart3,
  FileSpreadsheet,
  Printer,
  Download,
  Calendar,
  CheckCircle2,
  AlertOctagon,
  Clock,
  TrendingUp,
  Shield,
  X,
} from 'lucide-react';

export const ReportsScreen: React.FC = () => {
  const { users, attendance, activities, currentUser } = useApp();
  const [showPreviewModal, setShowPreviewModal] = useState(false);

  const totalCheckIns = attendance.filter((a) => a.status === 'checkedIn').length;
  const missedCount = attendance.filter((a) => a.status === 'missed').length;
  const pendingCount = attendance.filter((a) => a.status === 'pending').length;
  const totalEvents = totalCheckIns + missedCount + pendingCount || 1;

  const complianceRate = Math.round((totalCheckIns / (totalCheckIns + missedCount || 1)) * 100);
  const attendanceRate = Math.round((totalCheckIns / totalEvents) * 100);

  // Weekly data bars
  const weeklyData = [
    { day: 'Mon', checked: 8, missed: 1 },
    { day: 'Tue', checked: 12, missed: 0 },
    { day: 'Wed', checked: 10, missed: 2 },
    { day: 'Thu', checked: 14, missed: 1 },
    { day: 'Fri', checked: 15, missed: 0 },
    { day: 'Sat', checked: 6, missed: 0 },
    { day: 'Sun', checked: 4, missed: 0 },
  ];

  // Monthly data bars
  const monthlyData = [
    { month: 'May', rate: 82 },
    { month: 'Jun', rate: 86 },
    { month: 'Jul', rate: 91 },
    { month: 'Aug', rate: 89 },
    { month: 'Sep', rate: 94 },
    { month: 'Oct', rate: 92 },
  ];

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-emerald-700" />
            <h1 className="text-xl font-bold text-slate-900">Reports & Supervision Analytics</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Official compliance auditing, monthly reporting periods, and printable PPA reports
          </p>
        </div>

        <button
          onClick={() => setShowPreviewModal(true)}
          className="px-4 py-2.5 bg-emerald-700 hover:bg-emerald-800 text-white font-semibold rounded-xl text-xs sm:text-sm shadow-md transition-all flex items-center gap-2 self-start sm:self-auto"
        >
          <FileSpreadsheet className="w-4 h-4" />
          <span>Export Official PDF Report</span>
        </button>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3 sm:gap-4">
        <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs">
          <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block mb-1">
            Compliance Score
          </span>
          <p className="text-2xl font-bold text-emerald-600">{complianceRate}%</p>
          <span className="text-[11px] text-slate-500 flex items-center gap-1 mt-1">
            <TrendingUp className="w-3.5 h-3.5 text-emerald-500" /> On-time check-ins
          </span>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs">
          <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block mb-1">
            Attendance Rate
          </span>
          <p className="text-2xl font-bold text-blue-600">{attendanceRate}%</p>
          <span className="text-[11px] text-slate-500 mt-1 block">Active participation</span>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs">
          <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block mb-1">
            Verified Check-ins
          </span>
          <p className="text-2xl font-bold text-slate-900">{totalCheckIns}</p>
          <span className="text-[11px] text-emerald-600 mt-1 block font-medium">QR Scans recorded</span>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs">
          <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block mb-1">
            Missed Check-ins
          </span>
          <p className="text-2xl font-bold text-rose-600">{missedCount}</p>
          <span className="text-[11px] text-slate-500 mt-1 block">Flagged for review</span>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs">
          <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block mb-1">
            Pending Scheduled
          </span>
          <p className="text-2xl font-bold text-amber-600">{pendingCount}</p>
          <span className="text-[11px] text-slate-500 mt-1 block">Upcoming sessions</span>
        </div>
      </div>

      {/* Analytics Charts */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Weekly Chart */}
        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <h3 className="font-bold text-sm text-slate-800">Weekly Attendance & Punctuality</h3>
            <span className="text-xs text-slate-500">Current Week</span>
          </div>

          <div className="mt-6 flex items-end justify-between h-44 pt-4 px-2">
            {weeklyData.map((d) => (
              <div key={d.day} className="flex flex-col items-center gap-2 flex-1">
                <div className="w-full max-w-[28px] bg-slate-100 rounded-t-lg flex flex-col justify-end h-32 overflow-hidden">
                  <div
                    className="bg-emerald-600 w-full transition-all duration-300"
                    style={{ height: `${(d.checked / 16) * 100}%` }}
                    title={`${d.checked} Checked In`}
                  />
                  {d.missed > 0 && (
                    <div
                      className="bg-rose-500 w-full transition-all duration-300"
                      style={{ height: `${(d.missed / 16) * 100}%` }}
                      title={`${d.missed} Missed`}
                    />
                  )}
                </div>
                <span className="text-xs font-semibold text-slate-600">{d.day}</span>
              </div>
            ))}
          </div>

          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-center gap-6 text-xs text-slate-600">
            <div className="flex items-center gap-1.5">
              <span className="w-3 h-3 rounded-sm bg-emerald-600"></span>
              <span>Verified Check-in</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-3 h-3 rounded-sm bg-rose-500"></span>
              <span>Missed Check-in</span>
            </div>
          </div>
        </div>

        {/* Monthly Chart */}
        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <h3 className="font-bold text-sm text-slate-800">Monthly Compliance Trend (%)</h3>
            <span className="text-xs text-slate-500">Last 6 Months</span>
          </div>

          <div className="mt-6 flex items-end justify-between h-44 pt-4 px-2">
            {monthlyData.map((m) => (
              <div key={m.month} className="flex flex-col items-center gap-2 flex-1">
                <span className="text-[10px] font-bold text-blue-600">{m.rate}%</span>
                <div className="w-full max-w-[28px] bg-slate-100 rounded-t-lg flex flex-col justify-end h-28 overflow-hidden">
                  <div
                    className="bg-blue-600 w-full transition-all duration-300 rounded-t-md"
                    style={{ height: `${m.rate}%` }}
                  />
                </div>
                <span className="text-xs font-semibold text-slate-600">{m.month}</span>
              </div>
            ))}
          </div>

          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-center text-xs text-slate-500">
            <span>Target benchmark: 85% compliance threshold</span>
          </div>
        </div>
      </div>

      {/* Official PDF Report Preview Modal */}
      {showPreviewModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-3 sm:p-6 overflow-y-auto">
          <div className="bg-white rounded-2xl max-w-3xl w-full shadow-2xl border border-slate-200 overflow-hidden flex flex-col my-auto max-h-[92vh]">
            {/* Modal Header */}
            <div className="bg-slate-900 text-white px-6 py-4 flex items-center justify-between shrink-0">
              <div className="flex items-center gap-2.5">
                <FileSpreadsheet className="w-5 h-5 text-emerald-400" />
                <h3 className="font-bold text-base">Official Attendance & Tracking Report</h3>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={handlePrint}
                  className="px-3 py-1.5 bg-white/10 hover:bg-white/20 text-white text-xs font-semibold rounded-lg flex items-center gap-1.5 transition-colors"
                >
                  <Printer className="w-4 h-4" /> Print / Save PDF
                </button>
                <button
                  onClick={() => setShowPreviewModal(false)}
                  className="p-1.5 rounded-lg text-white/80 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Document Body (Printable Government Format) */}
            <div className="p-8 space-y-6 overflow-y-auto text-slate-800 bg-white">
              {/* Document Letterhead */}
              <div className="text-center pb-4 border-b-2 border-slate-800">
                <p className="text-[10px] font-bold uppercase tracking-widest text-slate-600">
                  Republic of the Philippines • Department of Justice
                </p>
                <h2 className="text-lg font-bold uppercase tracking-tight text-slate-900">
                  PAROLE AND PROBATION ADMINISTRATION
                </h2>
                <p className="text-xs font-semibold text-slate-700">District 4 Field Office • Tacloban City</p>
                <p className="text-[11px] text-slate-500 mt-1">
                  OFFICIAL SUPERVISION & BIOMETRIC ATTENDANCE COMPLIANCE AUDIT
                </p>
              </div>

              {/* Report Metadata */}
              <div className="grid grid-cols-2 gap-4 text-xs bg-slate-50 p-4 rounded-xl border border-slate-200">
                <div>
                  <p><strong>Reporting Officer:</strong> {currentUser?.fullName || 'Maria Santos'}</p>
                  <p><strong>Station ID:</strong> TAC-FO-04</p>
                  <p><strong>Date Generated:</strong> {new Date().toLocaleDateString()}</p>
                </div>
                <div>
                  <p><strong>Supervision Caseload:</strong> {users.filter((u) => u.role === 'parolee').length} active parolees</p>
                  <p><strong>Overall Compliance:</strong> {complianceRate}%</p>
                  <p><strong>GPS Proximity Zone:</strong> 50 Meters Perimeter</p>
                </div>
              </div>

              {/* Records Table */}
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-800 mb-2">
                  Audited Attendance Log
                </h4>
                <table className="w-full text-xs text-left border border-slate-200 rounded-lg overflow-hidden">
                  <thead className="bg-slate-100 text-slate-700 uppercase font-semibold text-[10px]">
                    <tr>
                      <th className="p-2 border-b">Ticket ID</th>
                      <th className="p-2 border-b">Parolee Name</th>
                      <th className="p-2 border-b">Activity / Session</th>
                      <th className="p-2 border-b">Timestamp</th>
                      <th className="p-2 border-b">Verification Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200">
                    {attendance.map((rec) => (
                      <tr key={rec.id}>
                        <td className="p-2 font-mono font-semibold">{rec.ticketId}</td>
                        <td className="p-2 font-medium">{rec.paroleeName}</td>
                        <td className="p-2 text-slate-600">{rec.activityTitle || 'Office Check-in'}</td>
                        <td className="p-2 text-slate-500">
                          {rec.checkInTime ? new Date(rec.checkInTime).toLocaleString() : 'N/A'}
                        </td>
                        <td className="p-2">
                          <span
                            className={`font-semibold ${
                              rec.status === 'checkedIn' ? 'text-emerald-700' : 'text-rose-700'
                            }`}
                          >
                            {rec.status === 'checkedIn' ? 'Verified (QR Checked)' : rec.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Sign-off footer */}
              <div className="pt-8 flex justify-between text-xs border-t border-slate-200">
                <div>
                  <p className="font-semibold">Prepared By:</p>
                  <div className="mt-8 border-b border-slate-400 w-48"></div>
                  <p className="mt-1 font-bold">{currentUser?.fullName || 'Maria Santos'}</p>
                  <p className="text-[11px] text-slate-500">Probation and Parole Officer II</p>
                </div>
                <div>
                  <p className="font-semibold">Approved By:</p>
                  <div className="mt-8 border-b border-slate-400 w-48"></div>
                  <p className="mt-1 font-bold">Atty. Ricardo Gonzales</p>
                  <p className="text-[11px] text-slate-500">Chief Probation Officer</p>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="bg-slate-50 px-6 py-3 border-t border-slate-200 flex items-center justify-end gap-2 shrink-0">
              <button
                onClick={() => setShowPreviewModal(false)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-semibold"
              >
                Close
              </button>
              <button
                onClick={handlePrint}
                className="px-4 py-2 bg-emerald-700 hover:bg-emerald-800 text-white rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-xs"
              >
                <Printer className="w-4 h-4" /> Print Document
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
