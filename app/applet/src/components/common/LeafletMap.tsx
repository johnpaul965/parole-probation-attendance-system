import React, { useEffect, useRef } from 'react';
import L from 'leaflet';
import { GpsTracker } from '../../types';

interface LeafletMapProps {
  trackers: GpsTracker[];
  selectedTrackerId?: string;
  onSelectTracker?: (tracker: GpsTracker) => void;
  showBreadcrumbs?: boolean;
  center?: [number, number];
  zoom?: number;
  height?: string;
}

export const LeafletMap: React.FC<LeafletMapProps> = ({
  trackers,
  selectedTrackerId,
  onSelectTracker,
  center,
  zoom = 13,
  height = '420px',
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersRef = useRef<{ [key: string]: L.Marker }>({});
  const circlesRef = useRef<{ [key: string]: L.Circle }>({});

  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Default center to first tracker or SF coordinates
    const initialCenter: [number, number] = center || (
      trackers.length > 0
        ? [trackers[0].currentLocation.latitude, trackers[0].currentLocation.longitude]
        : [37.7749, -122.4194]
    );

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: initialCenter,
        zoom: zoom,
        zoomControl: true,
      });

      // CartoDB Positron clean map tiles
      L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
        attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
        subdomains: 'abcd',
        maxZoom: 19
      }).addTo(map);

      mapInstanceRef.current = map;
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // Update markers and circles when trackers change
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    // Clear old markers & circles
    Object.values(markersRef.current).forEach(m => m.remove());
    Object.values(circlesRef.current).forEach(c => c.remove());
    markersRef.current = {};
    circlesRef.current = {};

    trackers.forEach(t => {
      const isSelected = t.id === selectedTrackerId;
      const isBreach = t.status === 'breach' || t.isTampered;
      const isLowBattery = t.batteryLevel < 25;

      // Color scheme
      let pinColor = '#10B981'; // green
      if (isBreach) pinColor = '#EF4444'; // red
      else if (isLowBattery) pinColor = '#F59E0B'; // amber

      // Custom HTML Pin
      const icon = L.divIcon({
        className: 'custom-div-icon',
        html: `
          <div style="
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            width: ${isSelected ? '36px' : '30px'};
            height: ${isSelected ? '36px' : '30px'};
            background-color: ${pinColor};
            border-radius: 50%;
            border: 3px solid white;
            box-shadow: 0 4px 10px rgba(0,0,0,0.3);
            cursor: pointer;
            transition: all 0.2s ease;
          ">
            <span style="color: white; font-size: 11px; font-weight: bold;">
              ${isBreach ? '!' : (t.assignedParoleeName ? t.assignedParoleeName.charAt(0) : 'P')}
            </span>
            ${isSelected ? `
              <div style="
                position: absolute;
                inset: -6px;
                border-radius: 50%;
                border: 2px dashed ${pinColor};
                animation: spin 6s linear infinite;
              "></div>
            ` : ''}
          </div>
        `,
        iconSize: [isSelected ? 36 : 30, isSelected ? 36 : 30],
        iconAnchor: [isSelected ? 18 : 15, isSelected ? 18 : 15],
      });

      const marker = L.marker([t.currentLocation.latitude, t.currentLocation.longitude], { icon })
        .addTo(map)
        .bindPopup(`
          <div style="font-family: 'Plus Jakarta Sans', sans-serif; font-size: 12px; min-width: 170px;">
            <div style="font-weight: 700; font-size: 13px; color: #0F172A; margin-bottom: 2px;">
              ${t.assignedParoleeName || 'Unassigned Tracker'}
            </div>
            <div style="color: #64748B; margin-bottom: 6px;">Device: ${t.id} (${t.model})</div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
              <span style="color: #64748B;">Battery:</span>
              <span style="font-weight: 600; color: ${t.batteryLevel < 25 ? '#EF4444' : '#10B981'};">${t.batteryLevel}%</span>
            </div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
              <span style="color: #64748B;">Speed:</span>
              <span style="font-weight: 600;">${t.currentLocation.speedKmH} km/h</span>
            </div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
              <span style="color: #64748B;">Status:</span>
              <span style="font-weight: 600; text-transform: uppercase; color: ${pinColor};">${t.status}</span>
            </div>
            <div style="font-size: 11px; color: #475569; margin-top: 6px; border-top: 1px solid #E2E8F0; padding-top: 4px;">
              ${t.currentLocation.address}
            </div>
          </div>
        `);

      marker.on('click', () => {
        if (onSelectTracker) onSelectTracker(t);
      });

      markersRef.current[t.id] = marker;

      // Draw geofence circle around home base
      const circle = L.circle([t.homeBaseLocation.latitude, t.homeBaseLocation.longitude], {
        radius: t.geofenceRadiusMeters,
        color: isBreach ? '#EF4444' : '#3B82F6',
        fillColor: isBreach ? '#FEE2E2' : '#DBEAFE',
        fillOpacity: 0.18,
        weight: isSelected ? 2.5 : 1.5,
        dashArray: isBreach ? '6, 6' : undefined
      }).addTo(map);

      circle.bindTooltip(`Geofence: ${t.homeBaseLocation.name} (${t.geofenceRadiusMeters}m)`, {
        permanent: false,
        direction: 'top'
      });

      circlesRef.current[t.id] = circle;
    });

    // If tracker is selected, center on it
    if (selectedTrackerId && markersRef.current[selectedTrackerId]) {
      const selected = trackers.find(t => t.id === selectedTrackerId);
      if (selected) {
        map.setView([selected.currentLocation.latitude, selected.currentLocation.longitude], 14, {
          animate: true
        });
        markersRef.current[selectedTrackerId].openPopup();
      }
    }
  }, [trackers, selectedTrackerId]);

  return (
    <div className="relative rounded-xl overflow-hidden border border-slate-200 shadow-sm">
      <div ref={mapContainerRef} style={{ height, width: '100%' }} />
      <div className="absolute bottom-3 left-3 z-[1000] bg-white/90 backdrop-blur-sm px-3 py-1.5 rounded-lg border border-slate-200 text-xs flex items-center gap-4 text-slate-700 shadow-sm font-medium">
        <span className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Compliant (Inside Zone)
        </span>
        <span className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span> Low Battery (&lt;25%)
        </span>
        <span className="flex items-center gap-1.5">
          <span className="w-2.5 h-2.5 rounded-full bg-red-500"></span> Geofence Excursion
        </span>
      </div>
    </div>
  );
};
