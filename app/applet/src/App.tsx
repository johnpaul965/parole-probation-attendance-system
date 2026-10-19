import React from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { Header } from './components/common/Header';
import { OfficerDashboard } from './components/officer/OfficerDashboard';
import { LiveTrackingView } from './components/officer/LiveTrackingView';
import { ActivitiesManagement } from './components/officer/ActivitiesManagement';
import { TrackerManagement } from './components/officer/TrackerManagement';
import { ReportsScreen } from './components/officer/ReportsScreen';
import { ParoleeDashboard } from './components/parolee/ParoleeDashboard';
import { ParoleeCheckIn } from './components/parolee/ParoleeCheckIn';
import { ParoleeActivities } from './components/parolee/ParoleeActivities';
import { AttendanceHistory } from './components/parolee/AttendanceHistory';

const MainContent: React.FC = () => {
  const { role, activeView } = useApp();

  return (
    <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-1">
      {role === 'officer' ? (
        <>
          {activeView === 'dashboard' && <OfficerDashboard />}
          {activeView === 'tracking' && <LiveTrackingView />}
          {activeView === 'activities' && <ActivitiesManagement />}
          {activeView === 'trackers' && <TrackerManagement />}
          {activeView === 'reports' && <ReportsScreen />}
        </>
      ) : (
        <>
          {activeView === 'parolee-dashboard' && <ParoleeDashboard />}
          {activeView === 'check-in' && <ParoleeCheckIn />}
          {activeView === 'parolee-activities' && <ParoleeActivities />}
          {activeView === 'attendance-history' && <AttendanceHistory />}
        </>
      )}
    </main>
  );
};

export default function App() {
  return (
    <AppProvider>
      <div className="min-h-screen bg-slate-50 flex flex-col text-slate-900 font-sans">
        <Header />
        <MainContent />
        <footer className="bg-white border-t border-slate-200 py-6 mt-auto">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-3">
            <div className="flex items-center gap-2">
              <span className="font-semibold text-slate-700">Parole & Probation Attendance System</span>
              <span>·</span>
              <span>Central District Department of Corrections & Community Supervision</span>
            </div>
            <div className="flex items-center gap-4 text-slate-400">
              <span>SHA-256 Verified Ledger</span>
              <span>·</span>
              <span>Cellular IoT GPS Pro-V4 Protocol</span>
            </div>
          </div>
        </footer>
      </div>
    </AppProvider>
  );
}
