import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  AppUser,
  AttendanceRecord,
  ActivityModel,
  GpsTracker,
  TrackingAlert,
  AppNotification,
  UserRole
} from '../types';
import {
  DEMO_OFFICER,
  DEMO_PAROLEES,
  INITIAL_TRACKERS,
  INITIAL_ACTIVITIES,
  INITIAL_ATTENDANCE,
  INITIAL_ALERTS,
  INITIAL_NOTIFICATIONS
} from '../constants';

interface AppContextType {
  currentUser: AppUser;
  switchUser: (userId: string) => void;
  users: AppUser[];
  role: UserRole;
  setRole: (role: UserRole) => void;
  trackers: GpsTracker[];
  updateTracker: (trackerId: string, updates: Partial<GpsTracker>) => void;
  activities: ActivityModel[];
  createActivity: (activity: Omit<ActivityModel, 'id'>) => void;
  assignParoleeToActivity: (activityId: string, paroleeId: string) => void;
  attendanceRecords: AttendanceRecord[];
  recordCheckIn: (record: Omit<AttendanceRecord, 'id' | 'timestamp'>) => AttendanceRecord;
  alerts: TrackingAlert[];
  acknowledgeAlert: (alertId: string, note?: string) => void;
  notifications: AppNotification[];
  markNotificationRead: (id: string) => void;
  markAllNotificationsRead: () => void;
  simulateGpsMovement: (trackerId: string) => void;
  simulateGeofenceBreach: (trackerId: string) => void;
  activeView: string;
  setActiveView: (view: string) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [users, setUsers] = useState<AppUser[]>([DEMO_OFFICER, ...DEMO_PAROLEES]);
  const [currentUser, setCurrentUser] = useState<AppUser>(DEMO_OFFICER);
  const [role, setRole] = useState<UserRole>('officer');
  const [trackers, setTrackers] = useState<GpsTracker[]>(INITIAL_TRACKERS);
  const [activities, setActivities] = useState<ActivityModel[]>(INITIAL_ACTIVITIES);
  const [attendanceRecords, setAttendanceRecords] = useState<AttendanceRecord[]>(INITIAL_ATTENDANCE);
  const [alerts, setAlerts] = useState<TrackingAlert[]>(INITIAL_ALERTS);
  const [notifications, setNotifications] = useState<AppNotification[]>(INITIAL_NOTIFICATIONS);
  const [activeView, setActiveView] = useState<string>('dashboard');

  const switchUser = (userId: string) => {
    const target = users.find(u => u.id === userId);
    if (target) {
      setCurrentUser(target);
      setRole(target.role);
    }
  };

  const updateTracker = (trackerId: string, updates: Partial<GpsTracker>) => {
    setTrackers(prev => prev.map(t => t.id === trackerId ? { ...t, ...updates } : t));
  };

  const createActivity = (activityData: Omit<ActivityModel, 'id'>) => {
    const newActivity: ActivityModel = {
      ...activityData,
      id: `act-${Date.now()}`
    };
    setActivities(prev => [newActivity, ...prev]);

    // Send notification to assigned parolees
    activityData.paroleeIds.forEach(pId => {
      const parolee = users.find(u => u.id === pId);
      if (parolee) {
        setNotifications(prev => [
          {
            id: `notif-${Date.now()}-${pId}`,
            title: `New Mandatory Activity Assigned: ${activityData.title}`,
            message: `Scheduled for ${activityData.scheduledDate} at ${activityData.startTime}. Location: ${activityData.location}`,
            type: 'reminder',
            timestamp: 'Just now',
            read: false,
          },
          ...prev
        ]);
      }
    });
  };

  const assignParoleeToActivity = (activityId: string, paroleeId: string) => {
    setActivities(prev => prev.map(a => {
      if (a.id === activityId && !a.paroleeIds.includes(paroleeId)) {
        return { ...a, paroleeIds: [...a.paroleeIds, paroleeId] };
      }
      return a;
    }));
  };

  const recordCheckIn = (recordData: Omit<AttendanceRecord, 'id' | 'timestamp'>): AttendanceRecord => {
    const newRecord: AttendanceRecord = {
      ...recordData,
      id: `att-${Date.now()}`,
      timestamp: new Date().toISOString(),
      ticketCode: `TKT-${Math.floor(1000 + Math.random() * 9000)}-VERIFIED`
    };

    setAttendanceRecords(prev => [newRecord, ...prev]);

    // Add notification
    setNotifications(prev => [
      {
        id: `notif-${Date.now()}`,
        title: 'Check-in Verified Successfully',
        message: `${newRecord.paroleeName} completed ${newRecord.type} check-in via ${newRecord.verificationMethod}. Code: ${newRecord.ticketCode}`,
        type: 'checkIn',
        timestamp: 'Just now',
        read: false,
      },
      ...prev
    ]);

    return newRecord;
  };

  const acknowledgeAlert = (alertId: string, note?: string) => {
    setAlerts(prev => prev.map(a => {
      if (a.id === alertId) {
        return {
          ...a,
          acknowledged: true,
          acknowledgedBy: currentUser.name,
          acknowledgedAt: 'Just now',
          notes: note || a.notes
        };
      }
      return a;
    }));
  };

  const markNotificationRead = (id: string) => {
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, read: true } : n));
  };

  const markAllNotificationsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  // Simulate movement for GPS tracker
  const simulateGpsMovement = (trackerId: string) => {
    setTrackers(prev => prev.map(t => {
      if (t.id === trackerId) {
        // Jiggle latitude & longitude slightly
        const deltaLat = (Math.random() - 0.5) * 0.003;
        const deltaLng = (Math.random() - 0.5) * 0.003;
        const newLat = t.currentLocation.latitude + deltaLat;
        const newLng = t.currentLocation.longitude + deltaLng;
        const speed = Math.floor(Math.random() * 45);

        return {
          ...t,
          lastPing: 'Just now',
          batteryLevel: Math.max(5, t.batteryLevel - (Math.random() > 0.7 ? 1 : 0)),
          currentLocation: {
            ...t.currentLocation,
            latitude: parseFloat(newLat.toFixed(6)),
            longitude: parseFloat(newLng.toFixed(6)),
            speedKmH: speed,
            accuracy: parseFloat((3 + Math.random() * 3).toFixed(1))
          }
        };
      }
      return t;
    }));
  };

  // Simulate Geofence breach
  const simulateGeofenceBreach = (trackerId: string) => {
    const tracker = trackers.find(t => t.id === trackerId);
    if (!tracker) return;

    // Move outside radius
    const breachedLat = tracker.homeBaseLocation.latitude + 0.015;
    const breachedLng = tracker.homeBaseLocation.longitude + 0.015;

    setTrackers(prev => prev.map(t => {
      if (t.id === trackerId) {
        return {
          ...t,
          status: 'breach',
          lastPing: 'Just now',
          currentLocation: {
            ...t.currentLocation,
            latitude: breachedLat,
            longitude: breachedLng,
            speedKmH: 52,
            address: 'EXCURSION: 1.8km outside authorized perimeter'
          }
        };
      }
      return t;
    }));

    // Trigger tracking alert
    const newAlert: TrackingAlert = {
      id: `alt-${Date.now()}`,
      trackerId: tracker.id,
      paroleeId: tracker.assignedParoleeId || 'unknown',
      paroleeName: tracker.assignedParoleeName || 'Supervised Subject',
      type: 'geofence_breach',
      severity: 'critical',
      timestamp: 'Just now',
      latitude: breachedLat,
      longitude: breachedLng,
      acknowledged: false,
      notes: `AUTOMATED GEOFENCE BREACH: Subject moved beyond ${tracker.geofenceRadiusMeters}m authorized perimeter threshold.`
    };

    setAlerts(prev => [newAlert, ...prev]);

    setNotifications(prev => [
      {
        id: `notif-${Date.now()}`,
        title: `🚨 CRITICAL: Geofence Breach Detected (${tracker.assignedParoleeName})`,
        message: `Device ${tracker.id} has breached perimeter bounds. Immediate officer intervention required.`,
        type: 'alert',
        timestamp: 'Just now',
        read: false,
      },
      ...prev
    ]);
  };

  return (
    <AppContext.Provider
      value={{
        currentUser,
        switchUser,
        users,
        role,
        setRole,
        trackers,
        updateTracker,
        activities,
        createActivity,
        assignParoleeToActivity,
        attendanceRecords,
        recordCheckIn,
        alerts,
        acknowledgeAlert,
        notifications,
        markNotificationRead,
        markAllNotificationsRead,
        simulateGpsMovement,
        simulateGeofenceBreach,
        activeView,
        setActiveView
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
