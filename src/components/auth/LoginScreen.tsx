import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { UserRole } from '../../types';
import { DEMO_CREDENTIALS, APP_CONFIG } from '../../constants';
import { Shield, Eye, EyeOff, Lock, Mail, CheckCircle2, ArrowRight, UserCheck } from 'lucide-react';

export const LoginScreen: React.FC = () => {
  const { login } = useApp();
  const [role, setRole] = useState<UserRole>('officer');
  const [email, setEmail] = useState<string>(DEMO_CREDENTIALS.officerEmail);
  const [password, setPassword] = useState<string>(DEMO_CREDENTIALS.password);
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const handleRoleChange = (newRole: UserRole) => {
    setRole(newRole);
    setError(null);
    if (newRole === 'officer') {
      setEmail(DEMO_CREDENTIALS.officerEmail);
      setPassword(DEMO_CREDENTIALS.password);
    } else {
      setEmail(DEMO_CREDENTIALS.paroleeEmail);
      setPassword(DEMO_CREDENTIALS.password);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      await login(email, password, role);
    } catch (err: any) {
      setError(err.message || 'Login failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0F3460] via-[#16213E] to-[#0D1B2A] flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-2xl overflow-hidden border border-slate-700/30 animate-in fade-in zoom-in-95 duration-200">
        {/* Card Header */}
        <div className="bg-slate-900 px-8 pt-8 pb-6 text-center text-white relative">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-700 mx-auto flex items-center justify-center shadow-lg shadow-blue-500/20 mb-3 border border-white/10">
            <Shield className="w-7 h-7 text-blue-100" />
          </div>
          <span className="text-[10px] font-bold uppercase tracking-widest text-blue-300">
            Republic of the Philippines • DOJ
          </span>
          <h1 className="text-xl font-bold tracking-tight mt-0.5">{APP_CONFIG.appName}</h1>
          <p className="text-xs text-slate-400 mt-1">{APP_CONFIG.appSubtitle} • Tacloban City</p>
        </div>

        {/* Role Selection Tabs */}
        <div className="flex border-b border-slate-200 bg-slate-50 p-1.5 gap-1.5">
          <button
            type="button"
            onClick={() => handleRoleChange('officer')}
            className={`flex-1 py-2.5 rounded-xl text-xs font-bold transition-all ${
              role === 'officer'
                ? 'bg-blue-600 text-white shadow-xs'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'
            }`}
          >
            Probation Officer
          </button>
          <button
            type="button"
            onClick={() => handleRoleChange('parolee')}
            className={`flex-1 py-2.5 rounded-xl text-xs font-bold transition-all ${
              role === 'parolee'
                ? 'bg-indigo-900 text-white shadow-xs'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'
            }`}
          >
            Parolee / Probationer
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-8 space-y-4">
          {error && (
            <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs">
              {error}
            </div>
          )}

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
              Account Email
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@ppa-attendance.com"
                required
                className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs sm:text-sm focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full pl-10 pr-10 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs sm:text-sm focus:ring-2 focus:ring-blue-500 focus:outline-hidden"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Quick Demo Pre-fill Pill */}
          <div className="pt-1">
            <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider block mb-1.5">
              Quick Test Credentials:
            </span>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => handleRoleChange('officer')}
                className={`flex-1 p-2 rounded-lg text-[11px] font-semibold border text-left transition-colors ${
                  role === 'officer'
                    ? 'bg-blue-50 border-blue-300 text-blue-900'
                    : 'bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100'
                }`}
              >
                <p className="font-bold">Maria Santos</p>
                <p className="text-[10px] text-slate-500">officer@ppa-attendance.com</p>
              </button>
              <button
                type="button"
                onClick={() => handleRoleChange('parolee')}
                className={`flex-1 p-2 rounded-lg text-[11px] font-semibold border text-left transition-colors ${
                  role === 'parolee'
                    ? 'bg-indigo-50 border-indigo-300 text-indigo-900'
                    : 'bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100'
                }`}
              >
                <p className="font-bold">Juan Dela Cruz</p>
                <p className="text-[10px] text-slate-500">parolee@ppa-attendance.com</p>
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className={`w-full py-3 text-white rounded-xl font-bold text-xs sm:text-sm shadow-md transition-all flex items-center justify-center gap-2 mt-4 ${
              role === 'officer'
                ? 'bg-blue-600 hover:bg-blue-700'
                : 'bg-indigo-900 hover:bg-indigo-950'
            }`}
          >
            {isLoading ? (
              <span>Authenticating...</span>
            ) : (
              <>
                <span>Sign In as {role === 'officer' ? 'Probation Officer' : 'Parolee'}</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        <div className="bg-slate-50 px-8 py-4 border-t border-slate-200 text-center text-[11px] text-slate-500">
          Official Government Surveillance & Reporting System • Strict Access
        </div>
      </div>
    </div>
  );
};
