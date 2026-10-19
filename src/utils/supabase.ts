import { createClient } from '@supabase/supabase-js';

const metaEnv = (import.meta as unknown as { env?: Record<string, string> }).env || {};

export const SUPABASE_URL =
  metaEnv.VITE_SUPABASE_URL || 'https://iqltrfkyzbeepfpmsxci.supabase.co';
export const SUPABASE_ANON_KEY =
  metaEnv.VITE_SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxbHRyZmt5emJlZXBmcG1zeGNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyMTg1OTUsImV4cCI6MjEwNzc5NDU5NX0.aYfh--wAJP1Fua_VrqgXn5kKIaVE-jnK9ZqqVrBTgIU';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

export const isSupabaseConfigured = Boolean(SUPABASE_URL && SUPABASE_ANON_KEY);
