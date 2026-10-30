-- ==============================================================================
-- SUPABASE DATABASE SETUP SCRIPT: Smart Fire Alarm IoT System
-- ==============================================================================

-- 1. Buat Tabel sensor_data
CREATE TABLE IF NOT EXISTS public.sensor_data (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gas1 NUMERIC NOT NULL DEFAULT 0,
    gas2 NUMERIC NOT NULL DEFAULT 0,
    flame1 BOOLEAN NOT NULL DEFAULT false,
    flame2 BOOLEAN NOT NULL DEFAULT false,
    temp1 NUMERIC NOT NULL DEFAULT 0,
    temp2 NUMERIC NOT NULL DEFAULT 0,
    status TEXT CHECK (status IN ('aman', 'waspada', 'bahaya')) DEFAULT 'aman',
    buzzer_on BOOLEAN NOT NULL DEFAULT false,
    fan_on BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Index untuk performa query realtime & riwayat
CREATE INDEX IF NOT EXISTS idx_sensor_data_created_at_desc 
ON public.sensor_data (created_at DESC);

-- 3. Aktifkan Row Level Security (RLS)
ALTER TABLE public.sensor_data ENABLE ROW LEVEL SECURITY;

-- 4. Policy RLS: SELECT untuk role anon (Publik tanpa login)
DROP POLICY IF EXISTS "Allow anon read sensor_data" ON public.sensor_data;
CREATE POLICY "Allow anon read sensor_data" 
ON public.sensor_data 
FOR SELECT 
TO anon 
USING (true);

-- 5. Policy RLS: INSERT untuk role anon (Node IoT / Simulasi tanpa login)
DROP POLICY IF EXISTS "Allow anon insert sensor_data" ON public.sensor_data;
CREATE POLICY "Allow anon insert sensor_data" 
ON public.sensor_data 
FOR INSERT 
TO anon 
WITH CHECK (true);

-- 6. Aktifkan Fitur Supabase Realtime untuk tabel sensor_data
-- Memungkinkan flutter realtime stream langsung menerima data baru saat di-insert
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'sensor_data'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sensor_data;
  END IF;
END $$;

-- 7. Seed Data Awal (Riwayat 20 data simulasi aman)
INSERT INTO public.sensor_data (gas1, gas2, flame1, flame2, temp1, temp2, status, buzzer_on, fan_on, created_at)
VALUES 
  (120, 115, false, false, 27.2, 27.5, 'aman', false, false, now() - INTERVAL '19 minutes'),
  (125, 118, false, false, 27.4, 27.6, 'aman', false, false, now() - INTERVAL '18 minutes'),
  (130, 122, false, false, 27.5, 27.8, 'aman', false, false, now() - INTERVAL '17 minutes'),
  (128, 120, false, false, 27.6, 27.7, 'aman', false, false, now() - INTERVAL '16 minutes'),
  (135, 125, false, false, 27.8, 28.0, 'aman', false, false, now() - INTERVAL '15 minutes'),
  (140, 132, false, false, 28.0, 28.2, 'aman', false, false, now() - INTERVAL '14 minutes'),
  (138, 130, false, false, 28.1, 28.1, 'aman', false, false, now() - INTERVAL '13 minutes'),
  (142, 135, false, false, 28.3, 28.4, 'aman', false, false, now() - INTERVAL '12 minutes'),
  (145, 138, false, false, 28.5, 28.6, 'aman', false, false, now() - INTERVAL '11 minutes'),
  (150, 140, false, false, 28.6, 28.7, 'aman', false, false, now() - INTERVAL '10 minutes'),
  (148, 142, false, false, 28.7, 28.8, 'aman', false, false, now() - INTERVAL '9 minutes'),
  (155, 146, false, false, 28.9, 29.0, 'aman', false, false, now() - INTERVAL '8 minutes'),
  (160, 150, false, false, 29.0, 29.1, 'aman', false, false, now() - INTERVAL '7 minutes'),
  (158, 152, false, false, 29.2, 29.3, 'aman', false, false, now() - INTERVAL '6 minutes'),
  (165, 155, false, false, 29.3, 29.4, 'aman', false, false, now() - INTERVAL '5 minutes'),
  (170, 160, false, false, 29.5, 29.6, 'aman', false, false, now() - INTERVAL '4 minutes'),
  (168, 162, false, false, 29.6, 29.7, 'aman', false, false, now() - INTERVAL '3 minutes'),
  (175, 165, false, false, 29.7, 29.8, 'aman', false, false, now() - INTERVAL '2 minutes'),
  (180, 170, false, false, 29.8, 30.0, 'aman', false, false, now() - INTERVAL '1 minute'),
  (185, 172, false, false, 30.0, 30.2, 'aman', false, false, now());
