import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { Shield, Bell, CheckCircle2, AlertTriangle, UserCheck, Smartphone } from 'lucide-react';

export const Header: React.FC = () => {
  const {
    currentUser,
    switchUser,
    users,
    role,
    setRole,
    notifications,
    markAllNotificationsRead,
    activeView,
    setActiveView
  } = useApp();

  const [showNotifications, setShowNotifications] = useState(false);
  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <header className="sticky top-0 z-30 bg-white border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between gap-8 h-16">
          {/* Zone 1: Brand Wordmark */}
          <div className="flex items-center gap-3 shrink-0">
            <div className="w-9 h-9 rounded-lg bg-slate-900 text-white flex items-center justify-center font-bold shadow-sm">
              <Shield className="w-5 h-5 text-emerald-400" />
            </div>
            <div>
              <span className="text-base font-bold tracking-tight text-slate-900 whitespace-nowrap block">
                Probation & Parole Supervision
              </span>
              <span className="text-[11px] text-slate-500 font-medium tracking-normal block -mt-0.5">
                Attendance & GPS Monitoring Platform
              </span>
            </div>
          </div>

          {/* Zone 2: Navigation Links */}
          <nav className="hidden md:flex items-center gap-6 text-sm font-medium text-slate-600">
            {role === 'officer' ? (
              <>
                <button
                  onClick={() => setActiveView('dashboard')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'dashboard' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  Officer Dashboard
                </button>
                <button
                  onClick={() => setActiveView('tracking')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'tracking' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  GPS Live Tracking
                </button>
                <button
                  onClick={() => setActiveView('activities')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'activities' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  Activities & Community Service
                </button>
                <button
                  onClick={() => setActiveView('trackers')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'trackers' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  Hardware Tracker Registry
                </button>
                <button
                  onClick={() => setActiveView('reports')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'reports' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  Compliance Reports
                </button>
              </>
            ) : (
              <>
                <button
                  onClick={() => setActiveView('parolee-dashboard')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'parolee-dashboard' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  My Supervision
                </button>
                <button
                  onClick={() => setActiveView('check-in')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'check-in' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  QR Check-in
                </button>
                <button
                  onClick={() => setActiveView('parolee-activities')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'parolee-activities' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  Assigned Activities
                </button>
                <button
                  onClick={() => setActiveView('attendance-history')}
                  className={`hover:text-slate-900 transition-colors whitespace-nowrap shrink-0 py-1 ${activeView === 'attendance-history' ? 'text-slate-900 font-semibold border-b-2 border-slate-900' : ''}`}
                >
                  Attendance History
                </button>
              </>
            )}
          </nav>

          {/* Zone 3: Actions & Role / User Switcher */}
          <div className="flex items-center gap-3 shrink-0">
            {/* Quick Demo Switcher */}
            <div className="flex items-center bg-slate-100 p-0.5 rounded-lg border border-slate-200">
              <button
                onClick={() => {
                  switchUser('off-101');
                  setActiveView('dashboard');
                }}
                className={`px-2.5 py-1 text-xs font-semibold rounded-md transition-colors whitespace-nowrap ${role === 'officer' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-900'}`}
                title="Switch to Officer Mode"
              >
                Officer View
              </button>
              <button
                onClick={() => {
                  switchUser('par-201');
                  setActiveView('parolee-dashboard');
                }}
                className={`px-2.5 py-1 text-xs font-semibold rounded-md transition-colors whitespace-nowrap ${role === 'parolee' ? 'bg-white text-slate-900 shadow-xs' : 'text-slate-500 hover:text-slate-900'}`}
                title="Switch to Parolee Mode"
              >
                Parolee View
              </button>
            </div>

            {/* Notification Dropdown */}
            <div className="relative">
              <button
                onClick={() => setShowNotifications(!showNotifications)}
                className="relative p-2 text-slate-600 hover:text-slate-900 rounded-lg hover:bg-slate-100 transition-colors"
                aria-label="Notifications"
              >
                <Bell className="w-5 h-5" />
                {unreadCount > 0 && (
                  <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full"></span>
                )}
              </button>

              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 bg-white rounded-xl shadow-xl border border-slate-200 py-2 z-50">
                  <div className="px-4 py-2 border-b border-slate-100 flex items-center justify-between">
                    <span className="text-xs font-semibold text-slate-900">Notifications ({unreadCount} new)</span>
                    <button
                      onClick={markAllNotificationsRead}
                      className="text-[11px] text-blue-600 hover:underline font-medium"
                    >
                      Mark all read
                    </button>
                  </div>
                  <div className="max-h-72 overflow-y-auto divide-y divide-slate-100">
                    {notifications.length === 0 ? (
                      <div className="p-4 text-xs text-slate-500 text-center">No notifications</div>
                    ) : (
                      notifications.map(n => (
                        <div key={n.id} className={`p-3 text-xs ${n.read ? 'bg-white' : 'bg-slate-50'}`}>
                          <div className="flex items-start gap-2">
                            {n.type === 'alert' && <AlertTriangle className="w-4 h-4 text-red-500 shrink-0 mt-0.5" />}
                            {n.type === 'checkIn' && <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />}
                            {n.type === 'reminder' && <Shield className="w-4 h-4 text-blue-500 shrink-0 mt-0.5" />}
                            {n.type === 'info' && <Smartphone className="w-4 h-4 text-slate-500 shrink-0 mt-0.5" />}
                            <div className="flex-1">
                              <p className="font-semibold text-slate-900">{n.title}</p>
                              <p className="text-slate-600 mt-0.5">{n.message}</p>
                              <span className="text-[10px] text-slate-400 mt-1 block">{n.timestamp}</span>
                            </div>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* User Profile summary */}
            <div className="flex items-center gap-2 pl-2 border-l border-slate-200">
              <img
                src={currentUser.avatarUrl || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'}
                alt={currentUser.name}
                className="w-8 h-8 rounded-full object-cover border border-slate-200"
              />
              <div className="hidden lg:block text-left">
                <span className="text-xs font-semibold text-slate-900 block leading-tight">{currentUser.name}</span>
                <span className="text-[10px] text-slate-500 block leading-tight">{currentUser.caseNumber || currentUser.role}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};
