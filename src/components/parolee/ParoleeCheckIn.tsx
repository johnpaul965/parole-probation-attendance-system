import React, { useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { useApp } from '../../context/AppContext';
import { APP_CONFIG } from '../../constants';
import {
  QrCode,
  RotateCw,
  CheckCircle2,
  AlertTriangle,
  Compass,
  MapPin,
  Calendar,
  Shield,
  Download,
} from 'lucide-react';

export const ParoleeCheckIn: React.FC = () => {
  const { currentUser, activities, getParoleeSummary, attendance } = useApp();
  const [tokenNonce, setTokenNonce] = useState(() => Math.floor(1000 + Math.random() * 9000));
  const [selectedActivityId, setSelectedActivityId] = useState<string>('');

  if (!currentUser) return null;

  const myActivities = activities.filter((a) => a.assignedParoleeIds.includes(currentUser.id));
  const currentActivity = myActivities.find((a) => a.id === selectedActivityId) || myActivities[0] || activities[0];

  const summary = getParoleeSummary(currentUser.id);
  const isWithinProximity = summary?.checkInProximity.isWithinProximity ?? false;
  const distance = summary?.checkInProximity.distanceMeters ?? 45;

  // Check if already checked in for this activity
  const isCheckedIn = currentActivity?.completedParoleeIds.includes(currentUser.id);

  // QR Payload format matching Flutter app
  const ticketId = `AT-2026-${tokenNonce}`;
  const qrPayload = JSON.stringify({
    ticketId,
    paroleeId: currentUser.id,
    paroleeName: currentUser.fullName,
    activityId: currentActivity?.id,
    timestamp: new Date().toISOString(),
  });

  const handleRotate = () => {
    setTokenNonce(Math.floor(1000 + Math.random() * 9000));
  };

  return (
    <div className="max-w-2xl mx-auto space-y-6 pb-12">
      {/* Top Header */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs text-center sm:text-left flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center justify-center sm:justify-start gap-2">
            <QrCode className="w-5 h-5 text-indigo-700" />
            <h1 className="text-xl font-bold text-slate-900">Attendance Verification Ticket</h1>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Present this biometric QR code to your supervising officer during check-in or community activities.
          </p>
        </div>

        {/* Proximity Pill */}
        <div
          className={`px-3 py-1.5 rounded-xl border text-xs font-semibold flex items-center justify-center gap-1.5 shrink-0 self-center sm:self-auto ${
            isWithinProximity
              ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
              : 'bg-amber-50 text-amber-800 border-amber-200'
          }`}
        >
          <Compass className={`w-4 h-4 ${isWithinProximity ? 'text-emerald-600' : 'text-amber-600'}`} />
          <span>{isWithinProximity ? 'Within 50m Proximity' : `${distance}m from Office`}</span>
        </div>
      </div>

      {/* Activity Selector */}
      {myActivities.length > 1 && (
        <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs">
          <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 mb-2">
            Select Assigned Activity
          </label>
          <select
            value={currentActivity?.id}
            onChange={(e) => setSelectedActivityId(e.target.value)}
            className="w-full text-xs sm:text-sm font-semibold px-3.5 py-2.5 bg-slate-50 border border-slate-300 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:outline-hidden"
          >
            {myActivities.map((act) => (
              <option key={act.id} value={act.id}>
                {act.title} ({act.type})
              </option>
            ))}
          </select>
        </div>
      )}

      {/* QR Card */}
      <div className="bg-white rounded-2xl border border-slate-200 p-8 shadow-sm text-center flex flex-col items-center">
        {/* Ticket ID Badge */}
        <div className="inline-flex items-center gap-2 bg-indigo-50 border border-indigo-100 px-4 py-1.5 rounded-full text-indigo-900 text-xs font-bold font-mono tracking-wider mb-6">
          <Shield className="w-3.5 h-3.5 text-indigo-600" />
          <span>Ticket: {ticketId}</span>
        </div>

        {/* Crisp QR Code Container */}
        <div className="p-5 bg-white rounded-2xl border-2 border-slate-900 shadow-md inline-block relative group">
          <QRCodeSVG
            value={qrPayload}
            size={230}
            level="H"
            includeMargin={true}
            className="rounded-lg"
          />

          {isCheckedIn && (
            <div className="absolute inset-0 bg-emerald-950/80 backdrop-blur-xs rounded-xl flex flex-col items-center justify-center text-white p-4 animate-in fade-in">
              <CheckCircle2 className="w-12 h-12 text-emerald-400 mb-2" />
              <p className="font-bold text-sm">Attendance Verified!</p>
              <p className="text-[11px] text-emerald-200 text-center mt-1">Recorded by Officer Maria Santos</p>
            </div>
          )}
        </div>

        {/* Parolee & Activity Info */}
        <div className="mt-6 max-w-sm space-y-1">
          <p className="font-bold text-base text-slate-900">{currentUser.fullName}</p>
          <p className="text-xs text-slate-500 font-mono">Case #{currentUser.caseNumber || 'PP-2024-1847'}</p>
          <p className="text-xs font-semibold text-indigo-800 pt-1">{currentActivity?.title}</p>
          <p className="text-[11px] text-slate-500 flex items-center justify-center gap-1">
            <MapPin className="w-3 h-3" /> {currentActivity?.location || 'PPA Tacloban Office'}
          </p>
        </div>

        {/* QR Actions */}
        <div className="mt-6 pt-5 border-t border-slate-100 flex items-center justify-center gap-3 w-full">
          <button
            onClick={handleRotate}
            className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold rounded-xl transition-colors flex items-center gap-1.5"
          >
            <RotateCw className="w-3.5 h-3.5" />
            <span>Regenerate Token</span>
          </button>
        </div>
      </div>

      {/* Proximity Compliance Instructions */}
      <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 text-xs text-slate-600 space-y-1.5">
        <p className="font-bold text-slate-900">Check-in Compliance Instructions:</p>
        <ul className="list-disc list-inside space-y-1 text-[11px] text-slate-600">
          <li>Keep your screen brightness high when presenting your QR code to the officer.</li>
          <li>Ensure you are within the 50 m perimeter of PPA Tacloban Field Office during check-in hours.</li>
          <li>Your unique cryptographic ticket rotates automatically after verification.</li>
        </ul>
      </div>
    </div>
  );
};
