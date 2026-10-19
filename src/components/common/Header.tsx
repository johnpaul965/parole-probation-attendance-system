import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { UserRole } from '../../types';
import {
  Shield,
  Bell,
  LogOut,
  UserCheck,
  Radio,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Compass,
  ArrowRightLeft,
  X,
  Database,
} from 'lucide-react';

interface HeaderProps {
  currentTab: string;
  onNavigate: (tab: string) => void;
}

export const Header: React.FC<HeaderProps> = ({ onNavigate }) => {
  const { currentUser, logout, quickSwitchRole, notifications, markNotificationRead, clearNotifications, isSimulating, setIsSimulating, isSupabaseLive } = useApp();
  const [showNotifications, setShowNotifications] = useState(false);

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  return (
    <header className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo & System Title */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#1565C0] to-[#0D1B2A] flex items-center justify-center text-white shadow-md shadow-blue-900/10">
              <Shield className="w-5 h-5 text-blue-200" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-bold tracking-tight text-slate-900 text-base sm:text-lg">PPA-TAC</span>
                <span className="text-[10px] font-semibold tracking-wider uppercase px-2 py-0.5 rounded-full bg-blue-50 text-blue-700 border border-blue-200/60">
                  Tacloban Field Office
                </span>
              </div>
              <p className="text-xs text-slate-500 hidden sm:block">Parole & Probation Attendance & Tracking System</p>
            </div>
          </div>

          {/* Right Header Actions */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Supabase Status Pill */}
            <div
              title="Connected to Supabase Project: iqltrfkyzbeepfpmsxci"
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold border transition-colors ${
                isSupabaseLive
                  ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                  : 'bg-slate-50 text-slate-600 border-slate-200'
              }`}
            >
              <Database className={`w-3.5 h-3.5 ${isSupabaseLive ? 'text-emerald-600 animate-pulse' : 'text-slate-400'}`} />
              <span className="hidden sm:inline">Supabase Live</span>
            </div>
            {/* Live GPS Simulator Toggle */}
            <button
              onClick={() => setIsSimulating(!isSimulating)}
              title={isSimulating ? 'GPS Simulator Running' : 'GPS Simulator Paused'}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
                isSimulating
                  ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                  : 'bg-slate-100 text-slate-600 border-slate-200'
              }`}
            >
              <Radio className={`w-3.5 h-3.5 ${isSimulating ? 'text-emerald-600 animate-pulse' : 'text-slate-400'}`} />
              <span className="hidden md:inline">{isSimulating ? 'Live GPS Active' : 'GPS Paused'}</span>
            </button>

            {/* Quick Role Switcher for instant testing */}
            <div className="relative">
              <button
                onClick={() => quickSwitchRole(currentUser?.role === 'officer' ? 'parolee' : 'officer')}
                className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 transition-colors"
                title="Switch between Officer and Parolee role"
              >
                <ArrowRightLeft className="w-3.5 h-3.5 text-blue-600" />
                <span className="hidden sm:inline">
                  Switch to {currentUser?.role === 'officer' ? 'Parolee' : 'Officer'}
                </span>
              </button>
            </div>

            {/* Notifications Bell */}
            <div className="relative">
              <button
                onClick={() => setShowNotifications(!showNotifications)}
                className="p-2 rounded-lg text-slate-600 hover:text-slate-900 hover:bg-slate-100 relative transition-colors"
                aria-label="Notifications"
              >
                <Bell className="w-5 h-5" />
                {unreadCount > 0 && (
                  <span className="absolute top-1 right-1 w-4 h-4 bg-red-600 text-white rounded-full text-[10px] font-bold flex items-center justify-center animate-pulse">
                    {unreadCount}
                  </span>
                )}
              </button>

              {/* Notifications Dropdown */}
              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white rounded-xl shadow-xl border border-slate-200 py-2 z-50 animate-in fade-in slide-in-from-top-2 duration-150">
                  <div className="flex items-center justify-between px-4 py-2 border-b border-slate-100">
                    <span className="text-sm font-semibold text-slate-900">Notifications ({notifications.length})</span>
                    <div className="flex items-center gap-2">
                      {notifications.length > 0 && (
                        <button
                          onClick={clearNotifications}
                          className="text-xs text-slate-500 hover:text-slate-700 font-medium"
                        >
                          Clear
                        </button>
                      )}
                      <button
                        onClick={() => setShowNotifications(false)}
                        className="text-slate-400 hover:text-slate-600"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <div className="max-h-80 overflow-y-auto divide-y divide-slate-100">
                    {notifications.length === 0 ? (
                      <div className="py-8 text-center text-slate-400 text-xs">No notifications</div>
                    ) : (
                      notifications.map((n) => (
                        <div
                          key={n.id}
                          onClick={() => {
                            markNotificationRead(n.id);
                            if (currentUser?.role === 'officer' && n.paroleeId) {
                              onNavigate('trackers');
                            }
                            setShowNotifications(false);
                          }}
                          className={`p-3 text-left hover:bg-slate-50 transition-colors cursor-pointer flex gap-3 ${
                            !n.isRead ? 'bg-blue-50/50' : ''
                          }`}
                        >
                          <div className="mt-0.5 shrink-0">
                            {n.type === 'proximity' && <Compass className="w-4 h-4 text-emerald-600" />}
                            {n.type === 'battery' && <AlertTriangle className="w-4 h-4 text-amber-600" />}
                            {n.type === 'activity' && <Clock className="w-4 h-4 text-blue-600" />}
                            {n.type === 'checkin' && <CheckCircle2 className="w-4 h-4 text-purple-600" />}
                            {n.type === 'info' && <Shield className="w-4 h-4 text-slate-500" />}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-semibold text-slate-900 truncate">{n.title}</p>
                            <p className="text-[11px] text-slate-600 mt-0.5 line-clamp-2">{n.message}</p>
                            <p className="text-[10px] text-slate-400 mt-1">
                              {new Date(n.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </p>
                          </div>
                          {!n.isRead && <span className="w-2 h-2 rounded-full bg-blue-600 mt-1.5 shrink-0" />}
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* User Profile Pill */}
            {currentUser && (
              <div className="flex items-center gap-2 pl-2 border-l border-slate-200">
                <div className="w-8 h-8 rounded-full bg-slate-800 text-white font-semibold text-xs flex items-center justify-center shadow-xs">
                  {currentUser.avatarInitials || currentUser.fullName.slice(0, 2).toUpperCase()}
                </div>
                <div className="hidden lg:block text-left">
                  <p className="text-xs font-semibold text-slate-900 leading-tight">{currentUser.fullName}</p>
                  <p className="text-[10px] font-medium text-slate-500 uppercase tracking-wider">
                    {currentUser.role === 'officer' ? 'Probation Officer' : `Parolee · ${currentUser.caseNumber || 'Active'}`}
                  </p>
                </div>
                <button
                  onClick={logout}
                  title="Sign out"
                  className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors ml-1"
                >
                  <LogOut className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
