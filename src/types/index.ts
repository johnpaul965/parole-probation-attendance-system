export type UserRole = 'officer' | 'parolee';

export interface SupervisionSnapshot {
  isActive: boolean;
  label: string;
  shortLabel: string;
  daysRemaining: number;
  hasMissingDates: boolean;
  isSuspended: boolean;
}

export interface AppUser {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
  department?: string;
  caseNumber?: string;
  officerId?: string;
  trackerId?: string;
  avatarInitials?: string;
  phone?: string;
  isActive: boolean;
  supervisionStartDate?: string;
  supervisionEndDate?: string;
  supervisionIsSuspended?: boolean;
}

export type AttendanceStatus = 'checkedIn' | 'pending' | 'missed' | 'confirmed';

export interface AttendanceRecord {
  id: string;
  ticketId: string;
  paroleeId: string;
  paroleeName: string;
  officerId: string;
  status: AttendanceStatus;
  checkInTime?: string;
  scheduledTime?: string;
  location?: string;
  verified: boolean;
  qrPayload?: string;
  activityId?: string;
  activityTitle?: string;
}

export type ActivityType = 'treePlanting' | 'communityCleanup' | 'counselingSession' | 'other';
export type ActivityStatus = 'pending' | 'ongoing' | 'completed' | 'missed';

export interface ActivityModel {
  id: string;
  title: string;
  type: ActivityType;
  description: string;
  location: string;
  scheduleDate: string;
  assignedParoleeIds: string[];
  assignedOfficerId: string;
  status: ActivityStatus;
  createdAt: string;
  completedParoleeIds: string[];
  officerName?: string;
}

export type TrackerDeviceStatus = 'active' | 'inactive' | 'offline' | 'maintenance' | 'unassigned';
export type GpsSource = 'mobile' | 'esp32' | 'simulated';

export interface GpsTracker {
  id: string;
  deviceIdentifier: string;
  deviceName?: string;
  deviceType?: string;
  serialNumber?: string;
  paroleeId?: string;
  paroleeName?: string;
  status: TrackerDeviceStatus;
  batteryLevel?: number;
  lastSeenAt?: string;
  assignedAt?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface LocationRecord {
  id: string;
  trackerId: string;
  paroleeId: string;
  latitude: number;
  longitude: number;
  accuracy?: number;
  altitude?: number;
  speed?: number;
  heading?: number;
  batteryLevel?: number;
  recordedAt: string;
  receivedAt?: string;
  source?: GpsSource;
}

export interface Geofence {
  id: string;
  paroleeId: string;
  name: string;
  centerLat: number;
  centerLng: number;
  radiusMeters: number;
  isActive: boolean;
}

export type GeofenceStatus = 'inside' | 'outside' | 'noGeofence' | 'unknown';

export interface CheckInProximity {
  isWithinProximity: boolean;
  distanceMeters: number;
  isSimulated: boolean;
  targetLat: number;
  targetLng: number;
  targetName: string;
  timestamp: string;
}

export interface ParoleeTrackingSummary {
  paroleeId: string;
  fullName: string;
  caseNumber: string;
  officerId: string;
  trackingStatus: TrackerDeviceStatus;
  tracker?: GpsTracker;
  latestLocation?: LocationRecord;
  geofenceStatus: GeofenceStatus;
  geofences: Geofence[];
  checkInProximity: CheckInProximity;
}

export interface NotificationItem {
  id: string;
  title: string;
  message: string;
  type: 'proximity' | 'geofence' | 'battery' | 'activity' | 'checkin' | 'info';
  timestamp: string;
  isRead: boolean;
  link?: string;
  paroleeId?: string;
}

export interface DashboardStats {
  totalCases: number;
  checkedIn: number;
  pending: number;
  missed: number;
}
