export type UserRole = 'officer' | 'parolee' | 'admin';

export type AttendanceStatus = 'present' | 'absent' | 'late' | 'excused' | 'pending';

export type TrackerStatus = 'online' | 'offline' | 'tampered' | 'low_battery' | 'breach';

export type NotificationType = 'alert' | 'success' | 'reminder' | 'info' | 'checkIn';

export interface AppUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatarUrl?: string;
  phone?: string;
  caseNumber?: string;
  assignedOfficerId?: string;
  assignedOfficerName?: string;
  supervisionStartDate?: string;
  supervisionEndDate?: string;
  riskLevel?: 'low' | 'medium' | 'high';
  assignedTrackerId?: string;
  currentAddress?: string;
}

export interface AttendanceRecord {
  id: string;
  paroleeId: string;
  paroleeName: string;
  officerId?: string;
  officerName?: string;
  timestamp: string;
  type: 'scheduled' | 'random' | 'activity' | 'office_visit';
  status: AttendanceStatus;
  location?: {
    latitude: number;
    longitude: number;
    address: string;
    accuracyMeters: number;
    isWithinGeofence: boolean;
  };
  notes?: string;
  verificationMethod: 'qr_code' | 'biometric' | 'gps_latch' | 'manual';
  ticketCode?: string;
}

export interface ActivityModel {
  id: string;
  title: string;
  description: string;
  category: 'counseling' | 'community_service' | 'drug_test' | 'court_hearing' | 'job_training';
  location: string;
  latitude: number;
  longitude: number;
  scheduledDate: string;
  startTime: string;
  endTime: string;
  assignedOfficerId: string;
  assignedOfficerName: string;
  paroleeIds: string[];
  mandatory: boolean;
  pointsOrHours: number;
  status: 'upcoming' | 'in_progress' | 'completed' | 'cancelled';
}

export interface GpsTracker {
  id: string;
  serialNumber: string;
  imei: string;
  model: string;
  batteryLevel: number;
  isCharging: boolean;
  status: TrackerStatus;
  lastPing: string;
  assignedParoleeId?: string;
  assignedParoleeName?: string;
  currentLocation: {
    latitude: number;
    longitude: number;
    accuracy: number;
    speedKmH: number;
    heading: number;
    address: string;
  };
  geofenceRadiusMeters: number;
  homeBaseLocation: {
    latitude: number;
    longitude: number;
    name: string;
  };
  firmwareVersion: string;
  isTampered: boolean;
}

export interface TrackingAlert {
  id: string;
  trackerId: string;
  paroleeId: string;
  paroleeName: string;
  type: 'geofence_breach' | 'device_offline' | 'tamper_detected' | 'low_battery' | 'missed_curfew';
  severity: 'low' | 'medium' | 'critical';
  timestamp: string;
  latitude: number;
  longitude: number;
  acknowledged: boolean;
  acknowledgedBy?: string;
  acknowledgedAt?: string;
  notes?: string;
}

export interface AppNotification {
  id: string;
  title: string;
  message: string;
  type: NotificationType;
  timestamp: string;
  read: boolean;
  actionUrl?: string;
}
