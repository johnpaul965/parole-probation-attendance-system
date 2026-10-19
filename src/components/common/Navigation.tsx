import React from 'react';
import { useApp } from '../../context/AppContext';
import {
  LayoutDashboard,
  CalendarCheck,
  MapPin,
  Users,
  BarChart3,
  QrCode,
  History,
  User,
  ShieldCheck,
} from 'lucide-react';

interface NavigationProps {
  currentTab: string;
  onNavigate: (tab: string) => void;
}

export const Navigation: React.FC<NavigationProps> = ({ currentTab, onNavigate }) => {
  const { currentUser } = useApp();
  const isOfficer = currentUser?.role === 'officer';

  const officerTabs = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'activities', label: 'Activities', icon: CalendarCheck },
    { id: 'trackers', label: 'GPS Trackers', icon: MapPin },
    { id: 'users', label: 'User Management', icon: Users },
    { id: 'reports', label: 'Reports', icon: BarChart3 },
    { id: 'profile', label: 'Officer Profile', icon: User },
  ];

  const paroleeTabs = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'activities', label: 'My Activities', icon: CalendarCheck },
    { id: 'check-in', label: 'Check-in QR', icon: QrCode },
    { id: 'history', label: 'History', icon: History },
    { id: 'profile', label: 'My Profile', icon: User },
  ];

  const tabs = isOfficer ? officerTabs : paroleeTabs;

  return (
    <nav className="bg-white border-b border-slate-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex space-x-1 sm:space-x-4 overflow-x-auto py-2 no-scrollbar">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const active = currentTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => onNavigate(tab.id)}
                className={`flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs sm:text-sm font-medium transition-all shrink-0 ${
                  active
                    ? isOfficer
                      ? 'bg-blue-50 text-blue-700 shadow-xs'
                      : 'bg-indigo-50 text-indigo-800 shadow-xs'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <Icon
                  className={`w-4 h-4 ${
                    active ? (isOfficer ? 'text-blue-600' : 'text-indigo-700') : 'text-slate-400'
                  }`}
                />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
};
