import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import {
  QrCode,
  ShieldCheck,
  MapPin,
  Clock,
  CheckCircle2,
  RefreshCw,
  Camera,
  Download,
  AlertTriangle,
  Award
} from 'lucide-react';

export const ParoleeCheckIn: React.FC = () => {
  const { currentUser, recordCheckIn, setActiveView } = useApp();
  const [token, setToken] = useState<string>('');
  const [timeRemaining, setTimeRemaining] = useState<number>(300); // 5 mins
  const [currentGps, setCurrentGps] = useState<{ lat: number; lng: number; address: string }>({
    lat: 37.7749,
    lng: -122.4194,
    address: 'Central District Supervision Office / Market St Corridor'
  });
  const [verifying, setVerifying] = useState(false);
  const [verifiedRecord, setVerifiedRecord] = useState<any | null>(null);

  // Generate dynamic QR token
  const generateNewToken = () => {
    const raw = `PAROLE-QR|${currentUser.id}|${currentUser.caseNumber}|${Date.now()}`;
    const code = `CHK-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
    setToken(code);
    setTimeRemaining(300);
  };

  useEffect(() => {
    generateNewToken();
  }, []);

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeRemaining(prev => {
        if (prev <= 1) {
          generateNewToken();
          return 300;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const handleSimulateSelfCheckIn = () => {
    setVerifying(true);
    setTimeout(() => {
      const record = recordCheckIn({
        paroleeId: currentUser.id,
        paroleeName: currentUser.name,
        officerId: currentUser.assignedOfficerId,
        officerName: currentUser.assignedOfficerName,
        type: 'scheduled',
        status: 'present',
        verificationMethod: 'qr_code',
        location: {
          latitude: currentGps.lat,
          longitude: currentGps.lng,
          address: currentGps.address,
          accuracyMeters: 3.2,
          isWithinGeofence: true
        },
        notes: `Digital self check-in completed via authenticated biometric device. Token verified: ${token}`
      });
      setVerifiedRecord(record);
      setVerifying(false);
    }, 1200);
  };

  const minutes = Math.floor(timeRemaining / 60);
  const seconds = timeRemaining % 60;

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="text-center pb-2 border-b border-slate-200">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">
          Supervision QR Attendance Check-In
        </h1>
        <p className="text-sm text-slate-500 mt-1">
          Present this dynamic cryptographically signed QR code to your supervising officer or scan at the kiosk.
        </p>
      </div>

      {verifiedRecord ? (
        <div className="bg-white rounded-2xl border border-emerald-200 p-8 shadow-lg text-center space-y-5 animate-fadeIn">
          <div className="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto">
            <CheckCircle2 className="w-10 h-10" />
          </div>

          <div>
            <h2 className="text-xl font-bold text-slate-900">Attendance Successfully Recorded</h2>
            <p className="text-xs text-slate-500 mt-1">
              Your biometric verification has been permanently logged to the district supervision registry.
            </p>
          </div>

          <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 text-left text-xs space-y-2">
            <div className="flex justify-between">
              <span className="text-slate-500">Verification Ticket:</span>
              <span className="font-mono font-bold text-slate-900">{verifiedRecord.ticketCode}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Timestamp:</span>
              <span className="font-medium text-slate-800">{new Date(verifiedRecord.timestamp).toLocaleString()}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">Subject:</span>
              <span className="font-semibold text-slate-900">{verifiedRecord.paroleeName}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500">GPS Latch:</span>
              <span className="font-medium text-emerald-600">Within Authorized Zone (±3.2m)</span>
            </div>
          </div>

          <div className="flex items-center justify-center gap-3 pt-2">
            <button
              onClick={() => {
                setVerifiedRecord(null);
                generateNewToken();
              }}
              className="px-4 py-2 border border-slate-300 rounded-xl text-xs font-semibold text-slate-700 hover:bg-slate-50"
            >
              Done / Generate New QR
            </button>
            <button
              onClick={() => setActiveView('attendance-history')}
              className="px-5 py-2 bg-slate-900 text-white rounded-xl text-xs font-semibold hover:bg-slate-800"
            >
              View Attendance History
            </button>
          </div>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-slate-200 p-8 shadow-sm flex flex-col items-center text-center">
          {/* Token Timer Header */}
          <div className="flex items-center gap-2 text-xs font-semibold text-slate-600 bg-slate-100 px-3 py-1.5 rounded-full mb-6">
            <Clock className="w-3.5 h-3.5 text-slate-500" />
            <span>Token expires in: </span>
            <span className="font-mono font-bold text-slate-900">
              {minutes}:{seconds < 10 ? `0${seconds}` : seconds}
            </span>
          </div>

          {/* Realistic Visual QR Code Canvas / SVG */}
          <div className="relative p-6 bg-slate-50 rounded-2xl border-2 border-dashed border-slate-300 flex flex-col items-center">
            {/* SVG Representation of a real dynamic 2D QR Code */}
            <svg
              className="w-56 h-56 text-slate-900"
              viewBox="0 0 100 100"
              fill="currentColor"
            >
              {/* Outer Corners */}
              <rect x="5" y="5" width="25" height="25" rx="3" fill="none" stroke="currentColor" strokeWidth="4" />
              <rect x="11" y="11" width="13" height="13" rx="1.5" fill="currentColor" />

              <rect x="70" y="5" width="25" height="25" rx="3" fill="none" stroke="currentColor" strokeWidth="4" />
              <rect x="76" y="11" width="13" height="13" rx="1.5" fill="currentColor" />

              <rect x="5" y="70" width="25" height="25" rx="3" fill="none" stroke="currentColor" strokeWidth="4" />
              <rect x="11" y="76" width="13" height="13" rx="1.5" fill="currentColor" />

              {/* Data dots simulating cryptographic hash */}
              <rect x="35" y="10" width="6" height="6" />
              <rect x="45" y="10" width="6" height="6" />
              <rect x="55" y="10" width="6" height="6" />
              <rect x="35" y="20" width="6" height="6" />
              <rect x="50" y="22" width="6" height="6" />
              <rect x="40" y="32" width="6" height="6" />
              <rect x="55" y="35" width="6" height="6" />

              <rect x="10" y="40" width="6" height="6" />
              <rect x="22" y="45" width="6" height="6" />
              <rect x="12" y="55" width="6" height="6" />

              <rect x="70" y="40" width="6" height="6" />
              <rect x="85" y="42" width="6" height="6" />
              <rect x="75" y="55" width="6" height="6" />

              <rect x="35" y="50" width="6" height="6" />
              <rect x="45" y="50" width="6" height="6" />
              <rect x="55" y="50" width="6" height="6" />

              <rect x="40" y="70" width="6" height="6" />
              <rect x="55" y="75" width="6" height="6" />
              <rect x="75" y="72" width="6" height="6" />
              <rect x="85" y="85" width="6" height="6" />
              <rect x="45" y="85" width="6" height="6" />
            </svg>

            {/* Token Badge */}
            <div className="mt-4 font-mono font-bold text-sm tracking-wider text-slate-800 bg-white px-4 py-1 rounded-md border border-slate-200">
              {token}
            </div>
          </div>

          {/* Refresh Token Button */}
          <button
            onClick={generateNewToken}
            className="mt-4 text-xs text-slate-500 hover:text-slate-800 font-semibold flex items-center gap-1.5 transition-colors"
          >
            <RefreshCw className="w-3.5 h-3.5" /> Generate Fresh Token
          </button>

          {/* GPS Proximity Anchor */}
          <div className="mt-6 w-full max-w-md bg-slate-50 rounded-xl p-4 border border-slate-200 text-left text-xs space-y-1.5">
            <div className="flex items-center gap-2 font-bold text-slate-800">
              <MapPin className="w-4 h-4 text-emerald-600" />
              <span>Current GPS Anchor Verified</span>
            </div>
            <p className="text-slate-600">{currentGps.address}</p>
            <p className="text-[11px] text-slate-400 font-mono">
              Coordinates: {currentGps.lat.toFixed(4)}, {currentGps.lng.toFixed(4)} (Accuracy ±3.2m)
            </p>
          </div>

          {/* Scan / Complete Check-in Simulation */}
          <div className="mt-6 w-full max-w-md">
            <button
              disabled={verifying}
              onClick={handleSimulateSelfCheckIn}
              className="w-full py-3 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 transition-colors flex items-center justify-center gap-2 shadow-sm disabled:opacity-75"
            >
              {verifying ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin text-emerald-400" />
                  Verifying Biometric QR Signature...
                </>
              ) : (
                <>
                  <ShieldCheck className="w-4 h-4 text-emerald-400" />
                  Simulate Officer Scan & Confirm Attendance
                </>
              )}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
