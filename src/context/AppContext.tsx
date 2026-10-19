import React, { createContext, useContext, useState, useEffect, useMemo, useCallback } from 'react';
import {
  AppUser,
  UserRole,
  GpsTracker,
  Geofence,
  ActivityModel,
  AttendanceRecord,
  NotificationItem,
  LocationRecord,
  DashboardStats,
  ParoleeTrackingSummary,
  AttendanceStatus,
  ActivityType,
  ActivityStatus,
  GeofenceStatus,
  CheckInProximity,
} from '../types';
import {
  APP_CONFIG,
  DEMO_CREDENTIALS,
  INITIAL_USERS,
  INITIAL_TRACKERS,
  INITIAL_GEOFENCES,
  INITIAL_ACTIVITIES,
  INITIAL_ATTENDANCE,
  INITIAL_NOTIFICATIONS,
  calculateDistanceMeters,
} from '../constants';
import { supabase, isSupabaseConfigured } from '../utils/supabase';

interface AppContextType {
  currentUser: AppUser | null;
  users: AppUser[];
  trackers: GpsTracker[];
  geofences: Geofence[];
  activities: ActivityModel[];
  attendance: AttendanceRecord[];
  notifications: NotificationItem[];
  liveLocations: Record<string, LocationRecord>;
  locationHistories: Record<string, LocationRecord[]>;
  stats: DashboardStats;
  isSimulating: boolean;
  isSupabaseLive: boolean;
  setIsSimulating: (v: boolean) => void;
  // Auth
  login: (email: string, pass: string, role: UserRole) => Promise<boolean>;
  logout: () => void;
  quickSwitchRole: (role: UserRole) => void;
  // Admin & User actions
  toggleUserActive: (userId: string, isActive: boolean) => void;
  deleteUser: (userId: string) => boolean;
  assignOfficer: (paroleeId: string, officerId: string) => void;
  removeOfficer: (paroleeId: string) => void;
  // Tracker actions
  assignTracker: (trackerId: string, paroleeId: string) => void;
  unassignTracker: (trackerId: string) => void;
  createTracker: (trackerId: string, deviceIdentifier: string) => void;
  assignGeofence: (data: Omit<Geofence, 'id'>) => void;
  // Activity actions
  createActivity: (data: {
    title: string;
    type: ActivityType;
    description: string;
    location: string;
    scheduleDate: string;
    assignedParoleeIds: string[];
  }) => void;
  updateActivityStatus: (activityId: string, status: ActivityStatus) => void;
  // Attendance actions
  verifyAttendanceByQr: (payloadString: string) => { success: boolean; message: string; record?: AttendanceRecord };
  markAttendanceManual: (activityId: string, paroleeId: string, status: AttendanceStatus) => void;
  submitParoleeSelfCheckIn: (activityId: string) => AttendanceRecord;
  // GPS & Live Tracking
  shareParoleeLocation: (paroleeId: string, lat: number, lng: number) => void;
  getParoleeSummary: (paroleeId: string) => ParoleeTrackingSummary | null;
  // Notifications
  markNotificationRead: (id: string) => void;
  clearNotifications: () => void;
}

const AppContext = createContext<AppContextType | null>(null);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Persistence in localStorage
  const [currentUser, setCurrentUser] = useState<AppUser | null>(() => {
    const saved = localStorage.getItem('ppa_tac_user');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {
        return INITIAL_USERS[0];
      }
    }
    return INITIAL_USERS[0];
  });

  const [users, setUsers] = useState<AppUser[]>(() => {
    const saved = localStorage.getItem('ppa_tac_users');
    return saved ? JSON.parse(saved) : INITIAL_USERS;
  });

  const [trackers, setTrackers] = useState<GpsTracker[]>(() => {
    const saved = localStorage.getItem('ppa_tac_trackers');
    return saved ? JSON.parse(saved) : INITIAL_TRACKERS;
  });

  const [geofences, setGeofences] = useState<Geofence[]>(() => {
    const saved = localStorage.getItem('ppa_tac_geofences');
    return saved ? JSON.parse(saved) : INITIAL_GEOFENCES;
  });

  const [activities, setActivities] = useState<ActivityModel[]>(() => {
    const saved = localStorage.getItem('ppa_tac_activities');
    return saved ? JSON.parse(saved) : INITIAL_ACTIVITIES;
  });

  const [attendance, setAttendance] = useState<AttendanceRecord[]>(() => {
    const saved = localStorage.getItem('ppa_tac_attendance');
    return saved ? JSON.parse(saved) : INITIAL_ATTENDANCE;
  });

  const [notifications, setNotifications] = useState<NotificationItem[]>(() => {
    const saved = localStorage.getItem('ppa_tac_notifications');
    return saved ? JSON.parse(saved) : INITIAL_NOTIFICATIONS;
  });

  const [isSimulating, setIsSimulating] = useState<boolean>(true);
  const [isSupabaseLive, setIsSupabaseLive] = useState<boolean>(isSupabaseConfigured);
  const [tick, setTick] = useState<number>(0);

  // Initial positions around Tacloban City
  const [liveLocations, setLiveLocations] = useState<Record<string, LocationRecord>>(() => {
    const now = new Date().toISOString();
    return {
      'demo-parolee': {
        id: 'loc-init-1',
        trackerId: 'TRK-001',
        paroleeId: 'demo-parolee',
        latitude: APP_CONFIG.taclobanLat + 0.00015,
        longitude: APP_CONFIG.taclobanLng + 0.00015,
        accuracy: 4.8,
        speed: 2.1,
        heading: 45,
        batteryLevel: 84,
        recordedAt: now,
        source: 'simulated',
      },
      'demo-parolee-2': {
        id: 'loc-init-2',
        trackerId: 'TRK-002',
        paroleeId: 'demo-parolee-2',
        latitude: 11.2360,
        longitude: 125.0110,
        accuracy: 12.0,
        speed: 0.0,
        batteryLevel: 14,
        recordedAt: new Date(Date.now() - 35 * 60 * 1000).toISOString(),
        source: 'esp32',
      },
      'demo-parolee-3': {
        id: 'loc-init-3',
        trackerId: 'TRK-003',
        paroleeId: 'demo-parolee-3',
        latitude: APP_CONFIG.taclobanLat - 0.00025,
        longitude: APP_CONFIG.taclobanLng + 0.00020,
        accuracy: 5.2,
        speed: 3.4,
        heading: 180,
        batteryLevel: 68,
        recordedAt: now,
        source: 'simulated',
      },
    };
  });

  const [locationHistories, setLocationHistories] = useState<Record<string, LocationRecord[]>>(() => {
    const now = Date.now();
    const generateHistory = (paroleeId: string, trackerId: string, centerLat: number, centerLng: number) => {
      const records: LocationRecord[] = [];
      for (let i = 12; i >= 0; i--) {
        const angle = i * 0.5;
        records.push({
          id: `hist-${paroleeId}-${i}`,
          trackerId,
          paroleeId,
          latitude: centerLat + Math.sin(angle) * 0.0004,
          longitude: centerLng + Math.cos(angle) * 0.0004,
          accuracy: 5.0,
          speed: 1.5 + (i % 3),
          batteryLevel: 80 - Math.floor(i / 2),
          recordedAt: new Date(now - i * 5 * 60 * 1000).toISOString(),
          source: 'simulated',
        });
      }
      return records;
    };

    return {
      'demo-parolee': generateHistory('demo-parolee', 'TRK-001', APP_CONFIG.taclobanLat, APP_CONFIG.taclobanLng),
      'demo-parolee-2': generateHistory('demo-parolee-2', 'TRK-002', 11.2360, 125.0110),
      'demo-parolee-3': generateHistory('demo-parolee-3', 'TRK-003', APP_CONFIG.taclobanLat, APP_CONFIG.taclobanLng),
    };
  });

  // Supabase Real-Time Location Listener & Initial Log Fetch
  useEffect(() => {
    if (!isSupabaseConfigured) return;

    // 1. Fetch latest location logs recorded by ESP32 firmware
    void supabase
      .from('location_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50)
      .then(({ data, error }) => {
        if (!error && data && data.length > 0) {
          setIsSupabaseLive(true);
          const latest = data[0];
          const targetParoleeId = (latest as any).parolee_id || 'demo-parolee';

          const mappedLatest: LocationRecord = {
            id: `sb-${latest.id || Date.now()}`,
            trackerId: (latest as any).tracker_id || 'TRK-001',
            paroleeId: targetParoleeId,
            latitude: Number(latest.latitude),
            longitude: Number(latest.longitude),
            accuracy: Number((latest as any).accuracy || 4.2),
            speed: Number((latest as any).speed || 0),
            batteryLevel: (latest as any).battery_level ? Number((latest as any).battery_level) : undefined,
            recordedAt: (latest as any).created_at || new Date().toISOString(),
            source: 'esp32',
          };

          setLiveLocations((prev) => ({ ...prev, [targetParoleeId]: mappedLatest }));
          setLocationHistories((prev) => ({
            ...prev,
            [targetParoleeId]: data.map((d: any) => ({
              id: `sb-${d.id || Math.random()}`,
              trackerId: d.tracker_id || 'TRK-001',
              paroleeId: d.parolee_id || targetParoleeId,
              latitude: Number(d.latitude),
              longitude: Number(d.longitude),
              accuracy: Number(d.accuracy || 4.5),
              speed: Number(d.speed || 0),
              batteryLevel: d.battery_level ? Number(d.battery_level) : undefined,
              recordedAt: d.created_at || new Date().toISOString(),
              source: 'esp32',
            })),
          }));
        }
      });

    // 2. Real-time Subscription to location_logs from ESP32
    const channel = supabase
      .channel('public:location_logs')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'location_logs' },
        (payload) => {
          const row: any = payload.new;
          if (!row) return;

          setIsSupabaseLive(true);
          const pId = row.parolee_id || 'demo-parolee';
          const newLoc: LocationRecord = {
            id: `sb-realtime-${row.id || Date.now()}`,
            trackerId: row.tracker_id || 'TRK-001',
            paroleeId: pId,
            latitude: Number(row.latitude),
            longitude: Number(row.longitude),
            accuracy: Number(row.accuracy || 4.5),
            speed: Number(row.speed || 0),
            batteryLevel: row.battery_level ? Number(row.battery_level) : undefined,
            recordedAt: row.created_at || new Date().toISOString(),
            source: 'esp32',
          };

          setLiveLocations((prev) => ({ ...prev, [pId]: newLoc }));
          setLocationHistories((prev) => ({
            ...prev,
            [pId]: [newLoc, ...(prev[pId] || [])].slice(0, 50),
          }));

          // Notify officer if real reading crosses 50m check-in radius
          const dist = calculateDistanceMeters(
            Number(row.latitude),
            Number(row.longitude),
            APP_CONFIG.taclobanLat,
            APP_CONFIG.taclobanLng
          );
          if (dist <= APP_CONFIG.proximityRadiusMeters) {
            setNotifications((prev) => [
              {
                id: `notif-sb-prox-${Date.now()}`,
                title: 'Live Hardware Proximity Ping',
                message: `Hardware Beacon reported within ${dist}m of PPA Tacloban Check-in Office.`,
                type: 'proximity',
                timestamp: new Date().toISOString(),
                isRead: false,
                paroleeId: pId,
              },
              ...prev.slice(0, 20),
            ]);
          }
        }
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, []);

  // Sync state to localStorage
  useEffect(() => {
    if (currentUser) {
      localStorage.setItem('ppa_tac_user', JSON.stringify(currentUser));
    } else {
      localStorage.removeItem('ppa_tac_user');
    }
  }, [currentUser]);

  useEffect(() => {
    localStorage.setItem('ppa_tac_users', JSON.stringify(users));
  }, [users]);

  useEffect(() => {
    localStorage.setItem('ppa_tac_trackers', JSON.stringify(trackers));
  }, [trackers]);

  useEffect(() => {
    localStorage.setItem('ppa_tac_geofences', JSON.stringify(geofences));
  }, [geofences]);

  useEffect(() => {
    localStorage.setItem('ppa_tac_activities', JSON.stringify(activities));
  }, [activities]);

  useEffect(() => {
    localStorage.setItem('ppa_tac_attendance', JSON.stringify(attendance));
  }, [attendance]);

  useEffect(() => {
    localStorage.setItem('ppa_tac_notifications', JSON.stringify(notifications));
  }, [notifications]);

  // Background GPS simulation loop (when live ESP32 is idle or offline)
  useEffect(() => {
    if (!isSimulating) return;

    const interval = setInterval(() => {
      setTick((prev) => prev + 1);

      setLiveLocations((prev) => {
        const next = { ...prev };
        const now = new Date().toISOString();
        const t = tick + 1;

        // Juan Dela Cruz (demo-parolee) orbits close to the 50m check-in radius
        const angle1 = t * 0.25;
        const orbit1 = 0.00042 + Math.sin(t * 0.1) * 0.0001;
        const lat1 = APP_CONFIG.taclobanLat + Math.sin(angle1) * orbit1;
        const lng1 = APP_CONFIG.taclobanLng + Math.cos(angle1) * orbit1;

        const juanRecord: LocationRecord = {
          id: `loc-juan-${t}`,
          trackerId: 'TRK-001',
          paroleeId: 'demo-parolee',
          latitude: Number(lat1.toFixed(6)),
          longitude: Number(lng1.toFixed(6)),
          accuracy: Number((4.0 + Math.sin(t) * 1.5).toFixed(1)),
          speed: Number((2.5 + Math.cos(t) * 1.2).toFixed(1)),
          heading: Math.floor((angle1 * 180) / Math.PI) % 360,
          batteryLevel: Math.max(15, 84 - Math.floor(t / 20)),
          recordedAt: now,
          source: 'simulated',
        };
        next['demo-parolee'] = juanRecord;

        // Elena Garcia (demo-parolee-3)
        const angle3 = t * 0.2 + 2.1;
        const orbit3 = 0.00035;
        const lat3 = APP_CONFIG.taclobanLat + Math.sin(angle3) * orbit3;
        const lng3 = APP_CONFIG.taclobanLng + Math.cos(angle3) * orbit3;

        const elenaRecord: LocationRecord = {
          id: `loc-elena-${t}`,
          trackerId: 'TRK-003',
          paroleeId: 'demo-parolee-3',
          latitude: Number(lat3.toFixed(6)),
          longitude: Number(lng3.toFixed(6)),
          accuracy: 5.1,
          speed: 1.8,
          heading: Math.floor((angle3 * 180) / Math.PI) % 360,
          batteryLevel: 68,
          recordedAt: now,
          source: 'simulated',
        };
        next['demo-parolee-3'] = elenaRecord;

        // Append to history
        setLocationHistories((h) => {
          const newHist = { ...h };
          newHist['demo-parolee'] = [juanRecord, ...(newHist['demo-parolee'] || [])].slice(0, 50);
          newHist['demo-parolee-3'] = [elenaRecord, ...(newHist['demo-parolee-3'] || [])].slice(0, 50);
          return newHist;
        });

        // Trigger proximity alert if crossed
        const dist = calculateDistanceMeters(lat1, lng1, APP_CONFIG.taclobanLat, APP_CONFIG.taclobanLng);
        if (dist <= APP_CONFIG.proximityRadiusMeters && t % 12 === 0) {
          setNotifications((notifs) => [
            {
              id: `notif-prox-${Date.now()}`,
              title: 'Check-in Proximity Alert',
              message: `Parolee Juan Dela Cruz is within ${dist} meters of PPA Tacloban Office.`,
              type: 'proximity',
              timestamp: now,
              isRead: false,
              paroleeId: 'demo-parolee',
            },
            ...notifs.slice(0, 20),
          ]);
        }

        return next;
      });
    }, 4000);

    return () => clearInterval(interval);
  }, [isSimulating, tick]);

  // Auth Methods
  const login = async (email: string, pass: string, role: UserRole): Promise<boolean> => {
    const normalized = email.trim().toLowerCase();
    if (pass !== DEMO_CREDENTIALS.password && pass !== 'password') {
      throw new Error('Invalid email or password. Use password: password123');
    }
    const found = users.find((u) => u.email.toLowerCase() === normalized);
    if (!found) {
      throw new Error('Account not found. Use test credentials or register.');
    }
    if (found.role !== role) {
      throw new Error(`Role mismatch. Please select the '${found.role}' role tab.`);
    }
    setCurrentUser(found);
    return true;
  };

  const logout = () => {
    setCurrentUser(null);
  };

  const quickSwitchRole = (role: UserRole) => {
    const target = users.find((u) => u.role === role);
    if (target) {
      setCurrentUser(target);
    }
  };

  // User Actions
  const toggleUserActive = (userId: string, isActive: boolean) => {
    setUsers((prev) => prev.map((u) => (u.id === userId ? { ...u, isActive } : u)));
    if (currentUser?.id === userId) {
      setCurrentUser((prev) => (prev ? { ...prev, isActive } : null));
    }
  };

  const deleteUser = (userId: string): boolean => {
    if (currentUser?.id === userId) return false;
    setUsers((prev) => prev.filter((u) => u.id !== userId));
    setTrackers((prev) =>
      prev.map((t) => (t.paroleeId === userId ? { ...t, paroleeId: undefined, paroleeName: undefined, status: 'unassigned' } : t))
    );
    return true;
  };

  const assignOfficer = (paroleeId: string, officerId: string) => {
    setUsers((prev) => prev.map((u) => (u.id === paroleeId ? { ...u, officerId } : u)));
  };

  const removeOfficer = (paroleeId: string) => {
    setUsers((prev) => prev.map((u) => (u.id === paroleeId ? { ...u, officerId: undefined } : u)));
  };

  // Tracker Actions
  const assignTracker = (trackerId: string, paroleeId: string) => {
    const targetParolee = users.find((u) => u.id === paroleeId);
    if (!targetParolee) return;

    setTrackers((prev) =>
      prev.map((t) => {
        if (t.id === trackerId) {
          return {
            ...t,
            paroleeId: targetParolee.id,
            paroleeName: targetParolee.fullName,
            status: 'active',
            assignedAt: new Date().toISOString(),
          };
        }
        if (t.paroleeId === paroleeId && t.id !== trackerId) {
          return { ...t, paroleeId: undefined, paroleeName: undefined, status: 'unassigned' };
        }
        return t;
      })
    );

    setUsers((prev) => prev.map((u) => (u.id === paroleeId ? { ...u, trackerId } : u)));
  };

  const unassignTracker = (trackerId: string) => {
    const tracker = trackers.find((t) => t.id === trackerId);
    if (!tracker) return;

    setTrackers((prev) =>
      prev.map((t) => (t.id === trackerId ? { ...t, paroleeId: undefined, paroleeName: undefined, status: 'unassigned' } : t))
    );

    if (tracker.paroleeId) {
      setUsers((prev) => prev.map((u) => (u.id === tracker.paroleeId ? { ...u, trackerId: undefined } : u)));
    }
  };

  const createTracker = (trackerId: string, deviceIdentifier: string) => {
    const newTracker: GpsTracker = {
      id: trackerId,
      deviceIdentifier: deviceIdentifier || `dev-${trackerId.toLowerCase()}`,
      deviceName: `ESP32 Tracker ${trackerId}`,
      deviceType: 'Wearable Ankle Tracker',
      serialNumber: `SN-TAC-${Date.now().toString().slice(-6)}`,
      status: 'unassigned',
      batteryLevel: 100,
      createdAt: new Date().toISOString(),
    };
    setTrackers((prev) => [newTracker, ...prev]);
  };

  const assignGeofence = (data: Omit<Geofence, 'id'>) => {
    const newGf: Geofence = {
      ...data,
      id: `gf-${Date.now()}`,
    };
    setGeofences((prev) => [...prev, newGf]);
  };

  // Activity Actions with Supabase Sync
  const createActivity = (data: {
    title: string;
    type: ActivityType;
    description: string;
    location: string;
    scheduleDate: string;
    assignedParoleeIds: string[];
  }) => {
    const newAct: ActivityModel = {
      id: `act-${Date.now()}`,
      title: data.title,
      type: data.type,
      description: data.description,
      location: data.location,
      scheduleDate: data.scheduleDate,
      assignedParoleeIds: data.assignedParoleeIds,
      assignedOfficerId: currentUser?.id || 'demo-officer',
      officerName: currentUser?.fullName || 'Maria Santos',
      status: 'pending',
      createdAt: new Date().toISOString(),
      completedParoleeIds: [],
    };
    setActivities((prev) => [newAct, ...prev]);

    // Asynchronously replicate to Supabase activities table
    if (isSupabaseConfigured) {
      void supabase
        .from('activities')
        .insert({
          title: newAct.title,
          description: newAct.description,
          activity_type: newAct.type,
          location_name: newAct.location,
          start_time: newAct.scheduleDate,
          end_time: newAct.scheduleDate,
        })
        .then(({ error }) => {
          if (error) {
            console.warn('[Supabase] activities insert notification:', error.message);
          }
        });
    }
  };

  const updateActivityStatus = (activityId: string, status: ActivityStatus) => {
    setActivities((prev) => prev.map((a) => (a.id === activityId ? { ...a, status } : a)));
  };

  // Attendance Actions with Supabase Sync
  const verifyAttendanceByQr = (payloadString: string) => {
    try {
      let parsed: { ticketId?: string; paroleeId?: string; activityId?: string } = {};
      try {
        parsed = JSON.parse(payloadString);
      } catch {
        parsed = { ticketId: payloadString };
      }

      const pId = parsed.paroleeId || 'demo-parolee';
      const parolee = users.find((u) => u.id === pId);
      const actId = parsed.activityId || activities[0]?.id;
      const activity = activities.find((a) => a.id === actId);

      const ticketId = parsed.ticketId || `AT-2026-${Math.floor(1000 + Math.random() * 9000)}`;

      const newRecord: AttendanceRecord = {
        id: `att-${Date.now()}`,
        ticketId,
        paroleeId: pId,
        paroleeName: parolee?.fullName || 'Juan Dela Cruz',
        officerId: currentUser?.id || 'demo-officer',
        status: 'checkedIn',
        checkInTime: new Date().toISOString(),
        scheduledTime: activity?.scheduleDate || new Date().toISOString(),
        location: activity?.location || 'PPA Tacloban Office',
        verified: true,
        qrPayload: payloadString,
        activityId: actId,
        activityTitle: activity?.title || 'Scheduled Check-in',
      };

      setAttendance((prev) => [newRecord, ...prev.filter((r) => r.ticketId !== ticketId)]);

      if (actId) {
        setActivities((prev) =>
          prev.map((a) => {
            if (a.id === actId) {
              const comp = a.completedParoleeIds.includes(pId)
                ? a.completedParoleeIds
                : [...a.completedParoleeIds, pId];
              return {
                ...a,
                completedParoleeIds: comp,
                status: comp.length >= a.assignedParoleeIds.length ? 'completed' : 'ongoing',
              };
            }
            return a;
          })
        );
      }

      // Record in Supabase attendance_records table
      if (isSupabaseConfigured) {
        void supabase
          .from('attendance_records')
          .insert({
            ticket_id: newRecord.ticketId,
            parolee_id: newRecord.paroleeId,
            officer_id: newRecord.officerId,
            status: newRecord.status,
            check_in_time: newRecord.checkInTime,
            location: newRecord.location,
            verified: newRecord.verified,
          })
          .then(({ error }) => {
            if (error) {
              console.warn('[Supabase] attendance_records insert note:', error.message);
            }
          });
      }

      return {
        success: true,
        message: `Verified check-in for ${parolee?.fullName || 'Parolee'} (Ticket: ${ticketId})`,
        record: newRecord,
      };
    } catch (e: any) {
      return { success: false, message: e.message || 'QR validation failed' };
    }
  };

  const markAttendanceManual = (activityId: string, paroleeId: string, status: AttendanceStatus) => {
    const parolee = users.find((u) => u.id === paroleeId);
    const activity = activities.find((a) => a.id === activityId);
    if (!parolee || !activity) return;

    const ticketId = `AT-2026-${Math.floor(1000 + Math.random() * 9000)}`;
    const newRecord: AttendanceRecord = {
      id: `att-${Date.now()}`,
      ticketId,
      paroleeId,
      paroleeName: parolee.fullName,
      officerId: currentUser?.id || 'demo-officer',
      status,
      checkInTime: status === 'checkedIn' ? new Date().toISOString() : undefined,
      scheduledTime: activity.scheduleDate,
      location: activity.location,
      verified: status === 'checkedIn',
      activityId,
      activityTitle: activity.title,
    };

    setAttendance((prev) => [newRecord, ...prev]);

    if (status === 'checkedIn') {
      setActivities((prev) =>
        prev.map((a) => {
          if (a.id === activityId) {
            const comp = a.completedParoleeIds.includes(paroleeId)
              ? a.completedParoleeIds
              : [...a.completedParoleeIds, paroleeId];
            return {
              ...a,
              completedParoleeIds: comp,
              status: comp.length >= a.assignedParoleeIds.length ? 'completed' : 'ongoing',
            };
          }
          return a;
        })
      );
    }

    if (isSupabaseConfigured) {
      void supabase
        .from('attendance_records')
        .insert({
          ticket_id: newRecord.ticketId,
          parolee_id: newRecord.paroleeId,
          officer_id: newRecord.officerId,
          status: newRecord.status,
          check_in_time: newRecord.checkInTime,
          location: newRecord.location,
          verified: newRecord.verified,
        })
        .then(({ error }) => {
          if (error) {
            console.warn('[Supabase] attendance_records insert note:', error.message);
          }
        });
    }
  };

  const submitParoleeSelfCheckIn = (activityId: string): AttendanceRecord => {
    if (!currentUser) throw new Error('Not logged in');
    const act = activities.find((a) => a.id === activityId) || activities[0];
    const ticketId = `AT-2026-${Math.floor(1000 + Math.random() * 9000)}`;

    const newRecord: AttendanceRecord = {
      id: `att-${Date.now()}`,
      ticketId,
      paroleeId: currentUser.id,
      paroleeName: currentUser.fullName,
      officerId: currentUser.officerId || 'demo-officer',
      status: 'pending',
      scheduledTime: act?.scheduleDate || new Date().toISOString(),
      location: act?.location || 'PPA Tacloban Office',
      verified: false,
      activityId: act?.id,
      activityTitle: act?.title,
    };

    setAttendance((prev) => [newRecord, ...prev]);

    if (isSupabaseConfigured) {
      void supabase
        .from('attendance_records')
        .insert({
          ticket_id: newRecord.ticketId,
          parolee_id: newRecord.paroleeId,
          officer_id: newRecord.officerId,
          status: newRecord.status,
          location: newRecord.location,
          verified: false,
        })
        .then(({ error }) => {
          if (error) {
            console.warn('[Supabase] self check-in note:', error.message);
          }
        });
    }

    return newRecord;
  };

  // Location & Proximity Helpers
  const shareParoleeLocation = (paroleeId: string, lat: number, lng: number) => {
    const loc: LocationRecord = {
      id: `loc-mobile-${Date.now()}`,
      trackerId: 'MOBILE-GPS',
      paroleeId,
      latitude: lat,
      longitude: lng,
      accuracy: 6.0,
      recordedAt: new Date().toISOString(),
      source: 'mobile',
    };
    setLiveLocations((prev) => ({ ...prev, [paroleeId]: loc }));
    setLocationHistories((prev) => ({
      ...prev,
      [paroleeId]: [loc, ...(prev[paroleeId] || [])],
    }));

    if (isSupabaseConfigured) {
      void supabase
        .from('location_logs')
        .insert({
          parolee_id: paroleeId,
          tracker_id: 'MOBILE-GPS',
          latitude: lat,
          longitude: lng,
          accuracy: 6.0,
          speed: 0,
        })
        .then(({ error }) => {
          if (error) {
            console.warn('[Supabase] location_logs insert note:', error.message);
          }
        });
    }
  };

  const getParoleeSummary = useCallback(
    (paroleeId: string): ParoleeTrackingSummary | null => {
      const p = users.find((u) => u.id === paroleeId);
      if (!p) return null;

      const tracker = trackers.find((t) => t.paroleeId === paroleeId || t.id === p.trackerId);
      const loc = liveLocations[paroleeId];
      const pGeofences = geofences.filter((g) => g.paroleeId === paroleeId);

      let geofenceStatus: GeofenceStatus = 'unknown';
      if (pGeofences.length === 0) {
        geofenceStatus = 'noGeofence';
      } else if (loc) {
        const monitoringZone = pGeofences.find((g) => !g.name.toLowerCase().includes('check-in'));
        if (monitoringZone) {
          const d = calculateDistanceMeters(loc.latitude, loc.longitude, monitoringZone.centerLat, monitoringZone.centerLng);
          geofenceStatus = d <= monitoringZone.radiusMeters ? 'inside' : 'outside';
        } else {
          geofenceStatus = 'inside';
        }
      }

      const checkInZone = pGeofences.find((g) => g.name.toLowerCase().includes('check-in')) || {
        centerLat: APP_CONFIG.taclobanLat,
        centerLng: APP_CONFIG.taclobanLng,
        name: 'PPA Tacloban Check-in Office',
      };

      const dist = loc
        ? calculateDistanceMeters(loc.latitude, loc.longitude, checkInZone.centerLat, checkInZone.centerLng)
        : 9999;

      const checkInProximity: CheckInProximity = {
        isWithinProximity: dist <= APP_CONFIG.proximityRadiusMeters,
        distanceMeters: dist,
        isSimulated: loc?.source === 'simulated',
        targetLat: checkInZone.centerLat,
        targetLng: checkInZone.centerLng,
        targetName: checkInZone.name,
        timestamp: loc?.recordedAt || new Date().toISOString(),
      };

      return {
        paroleeId: p.id,
        fullName: p.fullName,
        caseNumber: p.caseNumber || 'N/A',
        officerId: p.officerId || '',
        trackingStatus: tracker?.status || 'unassigned',
        tracker,
        latestLocation: loc,
        geofenceStatus,
        geofences: pGeofences,
        checkInProximity,
      };
    },
    [users, trackers, geofences, liveLocations]
  );

  const stats: DashboardStats = useMemo(() => {
    const parolees = users.filter((u) => u.role === 'parolee');
    const checkedIn = attendance.filter((a) => a.status === 'checkedIn').length;
    const pending = attendance.filter((a) => a.status === 'pending').length;
    const missed = attendance.filter((a) => a.status === 'missed').length;

    return {
      totalCases: parolees.length,
      checkedIn,
      pending,
      missed,
    };
  }, [users, attendance]);

  const markNotificationRead = (id: string) => {
    setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, isRead: true } : n)));
  };

  const clearNotifications = () => {
    setNotifications([]);
  };

  return (
    <AppContext.Provider
      value={{
        currentUser,
        users,
        trackers,
        geofences,
        activities,
        attendance,
        notifications,
        liveLocations,
        locationHistories,
        stats,
        isSimulating,
        isSupabaseLive,
        setIsSimulating,
        login,
        logout,
        quickSwitchRole,
        toggleUserActive,
        deleteUser,
        assignOfficer,
        removeOfficer,
        assignTracker,
        unassignTracker,
        createTracker,
        assignGeofence,
        createActivity,
        updateActivityStatus,
        verifyAttendanceByQr,
        markAttendanceManual,
        submitParoleeSelfCheckIn,
        shareParoleeLocation,
        getParoleeSummary,
        markNotificationRead,
        clearNotifications,
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
