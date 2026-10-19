# PPA-TAC: Parole & Probation Attendance & Tracking System

A comprehensive, production-grade web application rewritten in **React, TypeScript, Vite, Tailwind CSS, and Leaflet** for the Parole and Probation Administration (PPA) Tacloban Field Office.

## Overview

PPA-TAC enables biometric attendance verification, IoT wearable GPS tracking, geofence compliance monitoring, and community rehabilitation management for probation officers and parolees.

### Core Features

- **Role-Based Workflows**:
  - **Probation Officer Portal**: Complete supervision dashboard, caseload management, real-time GPS map tracking, 50-meter check-in proximity verification, geofencing configuration, activity management with QR attendance scanning, and official PPA audit report generation.
  - **Parolee Portal**: Supervision status countdown, scheduled community activities, instant QR check-in ticket generation, proximity verification, mobile GPS location sharing, and attendance history.
- **GPS Surveillance & Proximity Alerting**:
  - Real-time coordinates around Tacloban City (`11.240800, 125.003900`) with simulated or wearable IoT beacon telemetry.
  - Automatic alerts when a parolee enters the strict 50-meter perimeter of the PPA Tacloban Field Office.
  - Geofence zone violation evaluation (`INSIDE ASSIGNED AREA` vs `OUTSIDE ASSIGNED AREA`).
  - Route history breadcrumbs with interactive waypoint replay.
- **QR Code Attendance System**:
  - Secure QR tickets generated dynamically with Ticket IDs (`AT-2026-XXXX`).
  - Integrated QR scanner for officers with simulated scanning and manual ticket override.
- **Reporting & Compliance**:
  - Metric breakdown: Compliance Score (%), Attendance Rate (%), Total Check-ins, Missed, Pending.
  - Weekly attendance punctuality and 6-month compliance charts.
  - Printable official government report template formatted for the Department of Justice Parole and Probation Administration.

## Demo Accounts

| Role | Email | Password | Details |
|---|---|---|---|
| **Probation Officer** | `officer@ppa-attendance.com` | `password123` | Officer Maria Santos (District 4) |
| **Parolee** | `parolee@ppa-attendance.com` | `password123` | Juan Dela Cruz (Case # PP-2024-1847) |

Use the "Switch to Officer / Parolee" button in the top navigation to seamlessly toggle between experiences during testing.

## Technology Stack

- **Frontend**: React 19, TypeScript, Vite
- **Styling**: Tailwind CSS, Lucide Icons
- **Mapping**: Leaflet, OpenStreetMap
- **QR Code Engine**: `qrcode.react`
- **Port**: 3000 (`0.0.0.0`)
