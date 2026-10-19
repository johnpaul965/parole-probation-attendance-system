import { AppUser, GpsTracker, ActivityModel, AttendanceRecord, Geofence, SupervisionSnapshot } from '../types';

export const APP_CONFIG = {
  appName: 'PPA-TAC',
  appSubtitle: 'Parole & Probation Monitoring',
  ticketPrefix: 'AT',
  ticketYear: 2026,
  taclobanLat: 11.240800,
  taclobanLng: 125.003900,
  proximityRadiusMeters: 50,
  defaultGeofenceRadiusMeters: 500,
  lowBatteryThreshold: 20,
};

export const DEMO_CREDENTIALS = {
  officerEmail: 'officer@ppa-attendance.com',
  paroleeEmail: 'parolee@ppa-attendance.com',
  password: 'password123',
};

// Haversine formula for distance in meters
export function calculateDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return Math.round(R * c);
}

export function computeSupervision(
  startDate?: string,
  endDate?: string,
  isSuspended: boolean = false
): SupervisionSnapshot {
  if (!startDate || !endDate) {
    return {
      isActive: !isSuspended,
      label: 'Supervision Period Undefined',
      shortLabel: 'Not Configured',
      daysRemaining: 0,
      hasMissingDates: true,
      isSuspended,
    };
  }

  const end = new Date(endDate).getTime();
  const now = Date.now();
  const diffDays = Math.max(0, Math.ceil((end - now) / (1000 * 60 * 60 * 24)));

  if (isSuspended) {
    return {
      isActive: false,
      label: 'Supervision Suspended',
      shortLabel: 'Suspended',
      daysRemaining: diffDays,
      hasMissingDates: false,
      isSuspended: true,
    };
  }

  if (diffDays <= 0) {
    return {
      isActive: false,
      label: 'Supervision Completed',
      shortLabel: 'Completed',
      daysRemaining: 0,
      hasMissingDates: false,
      isSuspended: false,
    };
  }

  return {
    isActive: true,
    label: `${diffDays} days remaining`,
    shortLabel: `${diffDays}d left`,
    daysRemaining: diffDays,
    hasMissingDates: false,
    isSuspended: false,
  };
}

export const INITIAL_USERS: AppUser[] = [
  {
    id: 'demo-officer',
    email: 'officer@ppa-attendance.com',
    fullName: 'Maria Santos',
    role: 'officer',
    department: 'District 4 - Tacloban Field Office',
    avatarInitials: 'MS',
    phone: '+63 917 555 0192',
    isActive: true,
  },
  {
    id: 'demo-parolee',
    email: 'parolee@ppa-attendance.com',
    fullName: 'Juan Dela Cruz',
    role: 'parolee',
    department: 'District 4',
    caseNumber: 'PP-2024-1847',
    officerId: 'demo-officer',
    trackerId: 'TRK-001',
    avatarInitials: 'JD',
    phone: '+63 920 123 4567',
    isActive: true,
    supervisionStartDate: '2024-06-01',
    supervisionEndDate: '2027-06-01',
    supervisionIsSuspended: false,
  },
  {
    id: 'demo-parolee-2',
    email: 'parolee2@ppa-attendance.com',
    fullName: 'Roberto Mendoza',
    role: 'parolee',
    department: 'District 4',
    caseNumber: 'PP-2025-0412',
    officerId: 'demo-officer',
    trackerId: 'TRK-002',
    avatarInitials: 'RM',
    phone: '+63 918 234 5678',
    isActive: true,
    supervisionStartDate: '2025-01-15',
    supervisionEndDate: '2026-12-31',
    supervisionIsSuspended: false,
  },
  {
    id: 'demo-parolee-3',
    email: 'parolee3@ppa-attendance.com',
    fullName: 'Elena Garcia',
    role: 'parolee',
    department: 'District 4',
    caseNumber: 'PP-2024-2109',
    officerId: 'demo-officer',
    trackerId: 'TRK-003',
    avatarInitials: 'EG',
    phone: '+63 922 987 6543',
    isActive: true,
    supervisionStartDate: '2024-10-01',
    supervisionEndDate: '2028-04-15',
    supervisionIsSuspended: false,
  },
];

export const INITIAL_TRACKERS: GpsTracker[] = [
  {
    id: 'TRK-001',
    deviceIdentifier: 'ESP32-TAC-01',
    deviceName: 'Ankle Beacon 01',
    deviceType: 'Wearable Ankle Tracker',
    serialNumber: 'SN-TAC-2026-001',
    paroleeId: 'demo-parolee',
    paroleeName: 'Juan Dela Cruz',
    status: 'active',
    batteryLevel: 84,
    lastSeenAt: new Date().toISOString(),
    assignedAt: '2025-02-01T08:00:00Z',
  },
  {
    id: 'TRK-002',
    deviceIdentifier: 'ESP32-TAC-02',
    deviceName: 'Ankle Beacon 02',
    deviceType: 'Wearable Ankle Tracker',
    serialNumber: 'SN-TAC-2026-002',
    paroleeId: 'demo-parolee-2',
    paroleeName: 'Roberto Mendoza',
    status: 'offline',
    batteryLevel: 14,
    lastSeenAt: new Date(Date.now() - 35 * 60 * 1000).toISOString(),
    assignedAt: '2025-03-01T09:30:00Z',
  },
  {
    id: 'TRK-003',
    deviceIdentifier: 'ESP32-TAC-03',
    deviceName: 'Ankle Beacon 03',
    deviceType: 'Wearable Ankle Tracker',
    serialNumber: 'SN-TAC-2026-003',
    paroleeId: 'demo-parolee-3',
    paroleeName: 'Elena Garcia',
    status: 'active',
    batteryLevel: 68,
    lastSeenAt: new Date().toISOString(),
    assignedAt: '2025-01-20T10:00:00Z',
  },
  {
    id: 'TRK-004',
    deviceIdentifier: 'ESP32-TAC-04',
    deviceName: 'Ankle Beacon 04',
    deviceType: 'Wearable Ankle Tracker',
    serialNumber: 'SN-TAC-2026-004',
    status: 'unassigned',
    batteryLevel: 98,
    lastSeenAt: new Date(Date.now() - 120 * 60 * 1000).toISOString(),
  },
];

export const INITIAL_GEOFENCES: Geofence[] = [
  {
    id: 'gf-checkin-demo-parolee',
    paroleeId: 'demo-parolee',
    name: 'PPA Tacloban Check-in Office',
    centerLat: APP_CONFIG.taclobanLat,
    centerLng: APP_CONFIG.taclobanLng,
    radiusMeters: APP_CONFIG.proximityRadiusMeters,
    isActive: true,
  },
  {
    id: 'gf-zone-demo-parolee',
    paroleeId: 'demo-parolee',
    name: 'Tacloban City Monitoring Zone',
    centerLat: APP_CONFIG.taclobanLat,
    centerLng: APP_CONFIG.taclobanLng,
    radiusMeters: 1500,
    isActive: true,
  },
  {
    id: 'gf-checkin-demo-parolee-2',
    paroleeId: 'demo-parolee-2',
    name: 'PPA Tacloban Check-in Office',
    centerLat: APP_CONFIG.taclobanLat,
    centerLng: APP_CONFIG.taclobanLng,
    radiusMeters: APP_CONFIG.proximityRadiusMeters,
    isActive: true,
  },
  {
    id: 'gf-zone-demo-parolee-2',
    paroleeId: 'demo-parolee-2',
    name: 'San Jose District Perimeter',
    centerLat: 11.2350,
    centerLng: 125.0100,
    radiusMeters: 1200,
    isActive: true,
  },
  {
    id: 'gf-checkin-demo-parolee-3',
    paroleeId: 'demo-parolee-3',
    name: 'PPA Tacloban Check-in Office',
    centerLat: APP_CONFIG.taclobanLat,
    centerLng: APP_CONFIG.taclobanLng,
    radiusMeters: APP_CONFIG.proximityRadiusMeters,
    isActive: true,
  },
];

export const INITIAL_ACTIVITIES: ActivityModel[] = [
  {
    id: 'act-001',
    title: 'Community Mangrove & Tree Planting Drive',
    type: 'treePlanting',
    description: 'Mandatory rehabilitation and community service initiative planting mangrove saplings along Cancabato Bay.',
    location: 'Cancabato Bay Coastal Area, Tacloban City',
    scheduleDate: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
    assignedParoleeIds: ['demo-parolee', 'demo-parolee-3'],
    assignedOfficerId: 'demo-officer',
    officerName: 'Maria Santos',
    status: 'ongoing',
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    completedParoleeIds: [],
  },
  {
    id: 'act-002',
    title: 'Monthly Cognitive Behavioral Counseling Session',
    type: 'counselingSession',
    description: 'Individual rehabilitation progress check and life reintegration counseling session with assigned officer.',
    location: 'PPA Tacloban Field Office, Room 204',
    scheduleDate: new Date(Date.now() + 3 * 86400000).toISOString(),
    assignedParoleeIds: ['demo-parolee', 'demo-parolee-2'],
    assignedOfficerId: 'demo-officer',
    officerName: 'Maria Santos',
    status: 'pending',
    createdAt: new Date(Date.now() - 4 * 86400000).toISOString(),
    completedParoleeIds: [],
  },
  {
    id: 'act-003',
    title: 'Barangay San Jose Public Park Clean-Up',
    type: 'communityCleanup',
    description: 'Civic engagement and sanitation activity organized jointly with the local barangay council.',
    location: 'San Jose Barangay Plaza, Tacloban City',
    scheduleDate: new Date(Date.now() - 5 * 86400000).toISOString(),
    assignedParoleeIds: ['demo-parolee', 'demo-parolee-2', 'demo-parolee-3'],
    assignedOfficerId: 'demo-officer',
    officerName: 'Maria Santos',
    status: 'completed',
    createdAt: new Date(Date.now() - 7 * 86400000).toISOString(),
    completedParoleeIds: ['demo-parolee', 'demo-parolee-3'],
  },
];

export const INITIAL_ATTENDANCE: AttendanceRecord[] = [
  {
    id: 'att-001',
    ticketId: 'AT-2026-9821',
    paroleeId: 'demo-parolee',
    paroleeName: 'Juan Dela Cruz',
    officerId: 'demo-officer',
    status: 'checkedIn',
    checkInTime: new Date(Date.now() - 2 * 3600000).toISOString(),
    scheduledTime: new Date(Date.now() - 2.5 * 3600000).toISOString(),
    location: 'PPA Tacloban Field Office',
    verified: true,
    activityId: 'act-001',
    activityTitle: 'Community Mangrove & Tree Planting Drive',
  },
  {
    id: 'att-002',
    ticketId: 'AT-2026-9742',
    paroleeId: 'demo-parolee-3',
    paroleeName: 'Elena Garcia',
    officerId: 'demo-officer',
    status: 'checkedIn',
    checkInTime: new Date(Date.now() - 3 * 3600000).toISOString(),
    scheduledTime: new Date(Date.now() - 3 * 3600000).toISOString(),
    location: 'Cancabato Bay Coastal Area',
    verified: true,
    activityId: 'act-001',
    activityTitle: 'Community Mangrove & Tree Planting Drive',
  },
  {
    id: 'att-003',
    ticketId: 'AT-2026-9630',
    paroleeId: 'demo-parolee-2',
    paroleeName: 'Roberto Mendoza',
    officerId: 'demo-officer',
    status: 'missed',
    scheduledTime: new Date(Date.now() - 24 * 3600000).toISOString(),
    location: 'PPA Tacloban Field Office',
    verified: false,
    activityTitle: 'Bi-Weekly Office Verification',
  },
];

export const INITIAL_NOTIFICATIONS = [
  {
    id: 'notif-1',
    title: 'Check-in Proximity Alert',
    message: 'Juan Dela Cruz entered the 50 m check-in zone at PPA Tacloban Office.',
    type: 'proximity' as const,
    timestamp: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
    isRead: false,
    paroleeId: 'demo-parolee',
  },
  {
    id: 'notif-2',
    title: 'Low Battery Warning',
    message: 'Tracker TRK-002 (Roberto Mendoza) battery level dropped to 14%.',
    type: 'battery' as const,
    timestamp: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
    isRead: false,
    paroleeId: 'demo-parolee-2',
  },
  {
    id: 'notif-3',
    title: 'Upcoming Activity Reminder',
    message: 'Community Mangrove & Tree Planting Drive is scheduled for tomorrow at 8:00 AM.',
    type: 'activity' as const,
    timestamp: new Date(Date.now() - 3 * 3600000).toISOString(),
    isRead: true,
  },
];
