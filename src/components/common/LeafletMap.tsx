import React, { useEffect, useRef } from 'react';
import L from 'leaflet';
import { LocationRecord, Geofence } from '../../types';
import { APP_CONFIG } from '../../constants';

interface LeafletMapProps {
  location?: LocationRecord | null;
  geofences?: Geofence[];
  history?: LocationRecord[];
  centerOnLocation?: boolean;
  height?: string;
}

export const LeafletMap: React.FC<LeafletMapProps> = ({
  location,
  geofences = [],
  history = [],
  centerOnLocation = true,
  height = '380px',
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const paroleeMarkerRef = useRef<L.Marker | null>(null);
  const accuracyCircleRef = useRef<L.Circle | null>(null);
  const geofenceLayersRef = useRef<L.LayerGroup | null>(null);
  const historyPolylineRef = useRef<L.Polyline | null>(null);

  // Initialize Map
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapInstanceRef.current) return;

    const initialLat = location?.latitude || APP_CONFIG.taclobanLat;
    const initialLng = location?.longitude || APP_CONFIG.taclobanLng;

    const map = L.map(mapContainerRef.current, {
      center: [initialLat, initialLng],
      zoom: 16,
      zoomControl: true,
    });

    // Clean OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19,
    }).addTo(map);

    geofenceLayersRef.current = L.layerGroup().addTo(map);

    // Office check-in reference marker
    const officeIcon = L.divIcon({
      className: 'custom-office-pin',
      html: `
        <div style="background-color: #0f172a; color: white; width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); border: 2px solid white;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18M5 21V7l8-4v18M19 21V11l-6-3"/></svg>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });

    L.marker([APP_CONFIG.taclobanLat, APP_CONFIG.taclobanLng], { icon: officeIcon })
      .bindPopup(`<strong>PPA Tacloban Field Office</strong><br>Check-in Proximity Center (50m radius)`)
      .addTo(map);

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Update Geofence Circles
  useEffect(() => {
    const map = mapInstanceRef.current;
    const layerGroup = geofenceLayersRef.current;
    if (!map || !layerGroup) return;

    layerGroup.clearLayers();

    // 50m Proximity Circle (Strict perimeter)
    const proxCircle = L.circle([APP_CONFIG.taclobanLat, APP_CONFIG.taclobanLng], {
      radius: APP_CONFIG.proximityRadiusMeters,
      color: '#10b981',
      dashArray: '4, 6',
      fillColor: '#10b981',
      fillOpacity: 0.15,
      weight: 2,
    }).bindPopup('50m Check-in Proximity Radius');
    layerGroup.addLayer(proxCircle);

    // Custom assigned geofences
    geofences.forEach((gf) => {
      if (gf.name.toLowerCase().includes('check-in')) return;
      const circle = L.circle([gf.centerLat, gf.centerLng], {
        radius: gf.radiusMeters,
        color: '#2563eb',
        fillColor: '#3b82f6',
        fillOpacity: 0.08,
        weight: 1.5,
      }).bindPopup(`<strong>Geofence Zone: ${gf.name}</strong><br>Radius: ${gf.radiusMeters}m`);
      layerGroup.addLayer(circle);
    });
  }, [geofences]);

  // Update Parolee Position Marker & Trail
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map || !location) return;

    const latLng: [number, number] = [location.latitude, location.longitude];

    const paroleeIcon = L.divIcon({
      className: 'custom-parolee-pin',
      html: `
        <div style="position: relative; width: 28px; height: 28px;">
          <div style="position: absolute; inset: -4px; border-radius: 9999px; background-color: #3b82f6; opacity: 0.35; animation: ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>
          <div style="position: relative; width: 28px; height: 28px; border-radius: 9999px; background-color: #1d4ed8; border: 3px solid white; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; color: white;">
            <div style="width: 8px; height: 8px; border-radius: 9999px; background-color: #60a5fa;"></div>
          </div>
        </div>
      `,
      iconSize: [28, 28],
      iconAnchor: [14, 14],
    });

    if (!paroleeMarkerRef.current) {
      paroleeMarkerRef.current = L.marker(latLng, { icon: paroleeIcon }).addTo(map);
    } else {
      paroleeMarkerRef.current.setLatLng(latLng);
    }

    paroleeMarkerRef.current.bindPopup(`
      <div style="font-size: 12px; line-height: 1.4;">
        <strong style="font-size: 13px;">Parolee GPS Reading</strong><br>
        Source: ${location.source || 'simulated'}<br>
        Speed: ${location.speed ? `${location.speed} km/h` : '0 km/h'}<br>
        Battery: ${location.batteryLevel ? `${location.batteryLevel}%` : 'N/A'}<br>
        Accuracy: ±${location.accuracy ? `${location.accuracy}m` : '5m'}<br>
        Time: ${new Date(location.recordedAt).toLocaleTimeString()}
      </div>
    `);

    // Accuracy Circle
    const accuracy = location.accuracy || 8;
    if (!accuracyCircleRef.current) {
      accuracyCircleRef.current = L.circle(latLng, {
        radius: accuracy,
        color: '#3b82f6',
        fillColor: '#93c5fd',
        fillOpacity: 0.15,
        weight: 1,
      }).addTo(map);
    } else {
      accuracyCircleRef.current.setLatLng(latLng);
      accuracyCircleRef.current.setRadius(accuracy);
    }

    // Polyline for history trail
    if (history.length > 1) {
      const points = history.map((h) => [h.latitude, h.longitude] as [number, number]);
      if (!historyPolylineRef.current) {
        historyPolylineRef.current = L.polyline(points, {
          color: '#2563eb',
          weight: 3,
          opacity: 0.7,
          dashArray: '3, 6',
        }).addTo(map);
      } else {
        historyPolylineRef.current.setLatLngs(points);
      }
    }

    if (centerOnLocation) {
      map.panTo(latLng);
    }
  }, [location, history, centerOnLocation]);

  const handleCenterParolee = () => {
    if (mapInstanceRef.current && location) {
      mapInstanceRef.current.setView([location.latitude, location.longitude], 17);
    }
  };

  const handleCenterOffice = () => {
    if (mapInstanceRef.current) {
      mapInstanceRef.current.setView([APP_CONFIG.taclobanLat, APP_CONFIG.taclobanLng], 16);
    }
  };

  return (
    <div className="relative rounded-xl overflow-hidden border border-slate-200 shadow-xs" style={{ height }}>
      <div ref={mapContainerRef} className="w-full h-full" />

      {/* Floating map controls */}
      <div className="absolute top-3 right-3 z-[1000] flex flex-col gap-1.5 bg-white/90 backdrop-blur-xs p-1.5 rounded-lg shadow-md border border-slate-200">
        <button
          onClick={handleCenterParolee}
          title="Center on Parolee"
          className="px-2.5 py-1 text-xs font-medium text-slate-700 hover:text-blue-600 hover:bg-slate-100 rounded transition-colors text-left flex items-center gap-1.5"
        >
          <span className="w-2 h-2 rounded-full bg-blue-600 animate-pulse"></span>
          Parolee
        </button>
        <button
          onClick={handleCenterOffice}
          title="Center on Office"
          className="px-2.5 py-1 text-xs font-medium text-slate-700 hover:text-blue-600 hover:bg-slate-100 rounded transition-colors text-left flex items-center gap-1.5"
        >
          <span className="w-2 h-2 rounded-sm bg-slate-800"></span>
          Office
        </button>
      </div>

      {/* Legend Badge */}
      <div className="absolute bottom-3 left-3 z-[1000] bg-white/95 backdrop-blur-xs px-3 py-1.5 rounded-lg shadow-md border border-slate-200 text-[11px] text-slate-600 flex items-center gap-3">
        <div className="flex items-center gap-1">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 inline-block"></span>
          <span>50m Proximity</span>
        </div>
        <div className="flex items-center gap-1">
          <span className="w-2.5 h-2.5 rounded-full bg-blue-500 inline-block"></span>
          <span>Assigned Area</span>
        </div>
      </div>
    </div>
  );
};
