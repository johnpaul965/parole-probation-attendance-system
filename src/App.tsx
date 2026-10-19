import React, { useState } from 'react';
import { useApp } from './context/AppContext';
import { Header } from './components/common/Header';
import { Navigation } from './components/common/Navigation';
import { LoginScreen } from './components/auth/LoginScreen';
import { OfficerDashboard } from './components/officer/OfficerDashboard';
import { UserManagement } from './components/officer/UserManagement';
import { TrackerManagement } from './components/officer/TrackerManagement';
import { ActivitiesManagement } from './components/officer/ActivitiesManagement';
import { ReportsScreen } from './components/officer/ReportsScreen';
import { LiveTrackingModal } from './components/officer/LiveTrackingModal';
import { LocationHistoryModal } from './components/officer/LocationHistoryModal';
import { ParoleeDashboard } from './components/parolee/ParoleeDashboard';
import { ParoleeCheckIn } from './components/parolee/ParoleeCheckIn';
import { ParoleeActivities } from './components/parolee/ParoleeActivities';
import { AttendanceHistory } from './components/parolee/AttendanceHistory';
import { ProfileView } from './components/common/ProfileView';

export const App: React.FC = () => {
  const { currentUser } = useApp();
  const [currentTab, setCurrentTab] = useState<string>('dashboard');

  // Tracking modals
  const [activeTrackingParoleeId, setActiveTrackingParoleeId] = useState<string | null>(null);
  const [activeHistoryParoleeId, setActiveHistoryParoleeId] = useState<string | null>(null);

  if (!currentUser) {
    return <LoginScreen />;
  }

  const isOfficer = currentUser.role === 'officer';

  return (
    <div className="min-h-screen bg-[#F5F7FA] flex flex-col font-sans">
      {/* Top Header */}
      <Header currentTab={currentTab} onNavigate={setCurrentTab} />

      {/* Role Navigation Bar */}
      <Navigation currentTab={currentTab} onNavigate={setCurrentTab} />

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        {isOfficer ? (
          <>
            {currentTab === 'dashboard' && (
              <OfficerDashboard
                onNavigate={setCurrentTab}
                onOpenLiveTracking={(id) => setActiveTrackingParoleeId(id)}
                onOpenHistory={(id) => setActiveHistoryParoleeId(id)}
              />
            )}
            {currentTab === 'activities' && <ActivitiesManagement />}
            {currentTab === 'trackers' && (
              <TrackerManagement
                onOpenLiveTracking={(id) => setActiveTrackingParoleeId(id)}
                onOpenHistory={(id) => setActiveHistoryParoleeId(id)}
              />
            )}
            {currentTab === 'users' && <UserManagement />}
            {currentTab === 'reports' && <ReportsScreen />}
            {currentTab === 'profile' && <ProfileView />}
          </>
        ) : (
          <>
            {currentTab === 'dashboard' && <ParoleeDashboard onNavigate={setCurrentTab} />}
            {currentTab === 'activities' && <ParoleeActivities onNavigate={setCurrentTab} />}
            {currentTab === 'check-in' && <ParoleeCheckIn />}
            {currentTab === 'history' && <AttendanceHistory />}
            {currentTab === 'profile' && <ProfileView />}
          </>
        )}
      </main>

      {/* Live Tracking Modal */}
      {activeTrackingParoleeId && (
        <LiveTrackingModal
          paroleeId={activeTrackingParoleeId}
          isOpen={true}
          onClose={() => setActiveTrackingParoleeId(null)}
          onOpenHistory={(id) => setActiveHistoryParoleeId(id)}
        />
      )}

      {/* Location History Modal */}
      {activeHistoryParoleeId && (
        <LocationHistoryModal
          paroleeId={activeHistoryParoleeId}
          isOpen={true}
          onClose={() => setActiveHistoryParoleeId(null)}
        />
      )}
    </div>
  );
};
export default App;
