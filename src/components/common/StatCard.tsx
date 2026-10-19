import React from 'react';

interface StatCardProps {
  label: string;
  value: string | number;
  isSelected?: boolean;
  color?: string;
  onClick?: () => void;
  icon?: React.ReactNode;
}

export const StatCard: React.FC<StatCardProps> = ({
  label,
  value,
  isSelected = false,
  color = 'blue',
  onClick,
  icon,
}) => {
  return (
    <button
      onClick={onClick}
      className={`flex-1 min-w-[130px] p-3.5 sm:p-4 rounded-xl border text-left transition-all duration-150 ${
        isSelected
          ? 'bg-blue-50/80 border-blue-500 shadow-xs ring-2 ring-blue-500/20'
          : 'bg-white border-slate-200/90 hover:border-slate-300 hover:bg-slate-50/50 shadow-xs'
      }`}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{label}</span>
        {icon && <div className="text-slate-400">{icon}</div>}
      </div>
      <p className="text-2xl sm:text-3xl font-bold text-slate-900 mt-1">{value}</p>
    </button>
  );
};
