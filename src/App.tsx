import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  Flame,
  Shield,
  ShieldAlert,
  ShieldCheck,
  Volume2,
  VolumeX,
  Fan,
  Activity,
  Radio,
  Sliders,
  Code2,
  Copy,
  Check,
  Smartphone,
  Monitor,
  RefreshCw,
  Thermometer,
  Cloud,
  Zap,
  Play,
  Pause,
  Download,
  ChevronLeft,
  ChevronRight,
  Inbox,
  Lightbulb,
  LayoutDashboard
} from 'lucide-react';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Types matching Flutter SensorData Model
export interface SensorData {
  id?: number;
  gas1: number;
  gas2: number;
  flame1: boolean;
  flame2: boolean;
  temp1: number;
  temp2: number;
  status: 'aman' | 'waspada' | 'bahaya';
  buzzer_on: boolean;
  fan_on: boolean;
  created_at: string;
}

export type NavTab = 'dashboard' | 'gas' | 'flame' | 'temp' | 'buzzer' | 'fan' | 'led';

// Threshold helper identical to SensorThreshold in Dart
function calculateStatus(g1: number, g2: number, f1: boolean, f2: boolean, t1: number, t2: number): 'aman' | 'waspada' | 'bahaya' {
  if (f1 || f2 || g1 >= 500 || g2 >= 500 || t1 >= 45 || t2 >= 45) {
    return 'bahaya';
  }
  if (g1 >= 300 || g2 >= 300 || t1 >= 35 || t2 >= 35) {
    return 'waspada';
  }
  return 'aman';
}

function getTriggerReason(data: SensorData): string {
  const reasons: string[] = [];
  if (data.flame1 && data.flame2) reasons.push('Api terdeteksi di Sensor 1 & 2');
  else if (data.flame1) reasons.push('Api IR 1 terdeteksi');
  else if (data.flame2) reasons.push('Api IR 2 terdeteksi');

  if (data.gas1 >= 500) reasons.push(`Gas Sensor 1 = ${data.gas1.toFixed(0)} ppm`);
  if (data.gas2 >= 500) reasons.push(`Gas Sensor 2 = ${data.gas2.toFixed(0)} ppm`);
  else if (data.gas1 >= 300) reasons.push(`Gas Sensor 1 = ${data.gas1.toFixed(0)} ppm`);
  else if (data.gas2 >= 300) reasons.push(`Gas Sensor 2 = ${data.gas2.toFixed(0)} ppm`);

  if (data.temp1 >= 45) reasons.push(`Suhu Sensor 1 = ${data.temp1.toFixed(1)} °C`);
  if (data.temp2 >= 45) reasons.push(`Suhu Sensor 2 = ${data.temp2.toFixed(1)} °C`);
  else if (data.temp1 >= 35) reasons.push(`Suhu Sensor 1 = ${data.temp1.toFixed(1)} °C`);
  else if (data.temp2 >= 35) reasons.push(`Suhu Sensor 2 = ${data.temp2.toFixed(1)} °C`);

  if (reasons.length === 0) return 'Kondisi normal / Kembali aman';
  return reasons.join(', ');
}

// Generate 60 realistic rows for history
function generateInitialHistory(): SensorData[] {
  const list: SensorData[] = [];
  const now = Date.now();
  for (let i = 59; i >= 0; i--) {
    const time = new Date(now - i * 60000 * 2).toISOString();
    let g1 = Math.round(120 + Math.sin(i * 0.3) * 20 + (Math.random() * 8 - 4));
    let g2 = Math.round(115 + Math.cos(i * 0.3) * 18 + (Math.random() * 6 - 3));
    let t1 = +(27.5 + (Math.random() * 1.5 - 0.75)).toFixed(1);
    let t2 = +(27.8 + (Math.random() * 1.5 - 0.75)).toFixed(1);
    let f1 = false;
    let f2 = false;

    // Introduce varied history states
    if (i >= 8 && i <= 12) {
      g1 = 540 + (i * 3);
      g2 = 490;
    } else if (i >= 22 && i <= 25) {
      f1 = true;
    } else if (i >= 38 && i <= 41) {
      t1 = 37.8;
      t2 = 36.5;
    }

    const st = calculateStatus(g1, g2, f1, f2, t1, t2);
    const buzzer = st === 'bahaya';
    const fan = st === 'bahaya' || st === 'waspada';

    list.push({
      id: 60 - i,
      gas1: g1,
      gas2: g2,
      flame1: f1,
      flame2: f2,
      temp1: t1,
      temp2: t2,
      status: st,
      buzzer_on: buzzer,
      fan_on: fan,
      created_at: time
    });
  }
  return list;
}

interface EventLogItem {
  time: string;
  status: string;
  trigger: string;
  duration: string;
  durationSeconds?: number;
  isActive: boolean;
}

export default function App() {
  const [history, setHistory] = useState<SensorData[]>(generateInitialHistory);
  const [latestData, setLatestData] = useState<SensorData>(() => history[history.length - 1]);
  const [activeTab, setActiveTab] = useState<NavTab>('dashboard');
  const [activeMetricTab, setActiveMetricTab] = useState<'gas' | 'temp'>('gas');
  const [isSimulating, setIsSimulating] = useState<boolean>(true);
  const [audioEnabled, setAudioEnabled] = useState<boolean>(false);
  const [deviceMode, setDeviceMode] = useState<'desktop' | 'mobile'>('desktop');
  const [showConfigModal, setShowConfigModal] = useState<boolean>(false);
  const [showFlutterCodeModal, setShowFlutterCodeModal] = useState<boolean>(false);
  const [showSimulationDrawer, setShowSimulationDrawer] = useState<boolean>(false);
  const [activeCodeTab, setActiveCodeTab] = useState<string>('main.dart');
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  // Pagination for History Tables
  const [tablePage, setTablePage] = useState<number>(1);
  const pageSize = 10;

  // Supabase connection state
  const [supabaseUrl, setSupabaseUrl] = useState<string>('');
  const [supabaseKey, setSupabaseKey] = useState<string>('');
  const [supabaseConnected, setSupabaseConnected] = useState<boolean>(false);
  const [supabaseStatusMsg, setSupabaseStatusMsg] = useState<string>('Menggunakan data telemetri realtime (500 baris simulasi).');
  const supabaseRef = useRef<SupabaseClient | null>(null);

  // Audio buzzer generator using Web Audio API
  const audioCtxRef = useRef<AudioContext | null>(null);
  const buzzerOscRef = useRef<OscillatorNode | null>(null);

  // Reset pagination when switching tabs
  useEffect(() => {
    setTablePage(1);
  }, [activeTab]);

  useEffect(() => {
    if (audioEnabled && latestData.buzzer_on) {
      try {
        if (!audioCtxRef.current) {
          const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
          audioCtxRef.current = new AudioCtx();
        }
        if (audioCtxRef.current.state === 'suspended') {
          audioCtxRef.current.resume();
        }
        if (!buzzerOscRef.current) {
          const osc = audioCtxRef.current.createOscillator();
          const gain = audioCtxRef.current.createGain();
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(880, audioCtxRef.current.currentTime);
          gain.gain.setValueAtTime(0.08, audioCtxRef.current.currentTime);
          osc.connect(gain);
          gain.connect(audioCtxRef.current.destination);
          osc.start();
          buzzerOscRef.current = osc;
        }
      } catch (err) {
        console.warn('Audio buzzer error:', err);
      }
    } else {
      if (buzzerOscRef.current) {
        try {
          buzzerOscRef.current.stop();
          buzzerOscRef.current.disconnect();
        } catch (_) {}
        buzzerOscRef.current = null;
      }
    }
  }, [audioEnabled, latestData.buzzer_on]);

  // Realtime Simulation Loop
  useEffect(() => {
    if (!isSimulating || supabaseConnected) return;

    const interval = setInterval(() => {
      setLatestData(prev => {
        const deltaG1 = (Math.random() * 12 - 6);
        const deltaG2 = (Math.random() * 10 - 5);
        const deltaT1 = (Math.random() * 0.3 - 0.15);
        const deltaT2 = (Math.random() * 0.3 - 0.15);

        let g1 = Math.round(Math.max(80, Math.min(850, prev.gas1 + deltaG1)));
        let g2 = Math.round(Math.max(80, Math.min(850, prev.gas2 + deltaG2)));
        let t1 = +(Math.max(24, Math.min(65, prev.temp1 + deltaT1))).toFixed(1);
        let t2 = +(Math.max(24, Math.min(65, prev.temp2 + deltaT2))).toFixed(1);

        const st = calculateStatus(g1, g2, prev.flame1, prev.flame2, t1, t2);
        const buzzer = st === 'bahaya';
        const fan = st === 'bahaya' || st === 'waspada';

        const updated: SensorData = {
          ...prev,
          gas1: g1,
          gas2: g2,
          temp1: t1,
          temp2: t2,
          status: st,
          buzzer_on: buzzer,
          fan_on: fan,
          created_at: new Date().toISOString()
        };

        setHistory(hist => [...hist.slice(-499), updated]);
        return updated;
      });
    }, 2800);

    return () => clearInterval(interval);
  }, [isSimulating, supabaseConnected]);

  // Quick Scenarios
  const applyScenario = (type: 'aman' | 'waspada-gas' | 'waspada-suhu' | 'bahaya-api' | 'bahaya-gas' | 'bahaya-suhu') => {
    let g1 = 140, g2 = 135, f1 = false, f2 = false, t1 = 28.5, t2 = 28.8;

    if (type === 'waspada-gas') {
      g1 = 365;
      g2 = 340;
    } else if (type === 'waspada-suhu') {
      t1 = 37.5;
      t2 = 36.2;
    } else if (type === 'bahaya-api') {
      f1 = true;
      f2 = false;
      g1 = 280;
      t1 = 34.0;
    } else if (type === 'bahaya-gas') {
      g1 = 580;
      g2 = 520;
    } else if (type === 'bahaya-suhu') {
      t1 = 48.5;
      t2 = 47.0;
    }

    const st = calculateStatus(g1, g2, f1, f2, t1, t2);
    const buzzer = st === 'bahaya';
    const fan = st === 'bahaya' || st === 'waspada';

    const newData: SensorData = {
      gas1: g1,
      gas2: g2,
      flame1: f1,
      flame2: f2,
      temp1: t1,
      temp2: t2,
      status: st,
      buzzer_on: buzzer,
      fan_on: fan,
      created_at: new Date().toISOString()
    };

    setLatestData(newData);
    setHistory(hist => [...hist.slice(-499), newData]);
  };

  // Connect to Supabase
  const handleConnectSupabase = async () => {
    if (!supabaseUrl || !supabaseKey) {
      setSupabaseStatusMsg('Masukkan URL dan Anon Key Supabase terlebih dahulu.');
      return;
    }
    try {
      setSupabaseStatusMsg('Menghubungkan ke Supabase...');
      const client = createClient(supabaseUrl, supabaseKey);
      const { data, error } = await client
        .from('sensor_data')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(500);

      if (error) throw error;

      supabaseRef.current = client;
      setSupabaseConnected(true);
      setSupabaseStatusMsg('Terhubung ke Supabase Realtime.');

      if (data && data.length > 0) {
        const reversed = [...data].reverse().map(row => ({
          ...row,
          status: row.status || calculateStatus(row.gas1, row.gas2, row.flame1, row.flame2, row.temp1, row.temp2)
        }));
        setHistory(reversed);
        setLatestData(reversed[reversed.length - 1]);
      }

      client
        .channel('public:sensor_data')
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'sensor_data' }, payload => {
          const newRow = payload.new as SensorData;
          const fullData: SensorData = {
            ...newRow,
            status: newRow.status || calculateStatus(newRow.gas1, newRow.gas2, newRow.flame1, newRow.flame2, newRow.temp1, newRow.temp2)
          };
          setLatestData(fullData);
          setHistory(h => [...h.slice(-499), fullData]);
        })
        .subscribe();

    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setSupabaseStatusMsg(`Gagal koneksi: ${msg}`);
      setSupabaseConnected(false);
    }
  };

  const bgGradient = useMemo(() => {
    switch (latestData.status) {
      case 'bahaya':
        return 'from-[#45141C] via-[#751E2B] to-[#A63445]';
      case 'waspada':
        return 'from-[#3B2E1E] via-[#6B4D2C] to-[#9E7745]';
      case 'aman':
      default:
        return 'from-[#2E3B55] via-[#505C7B] to-[#7C86A8]';
    }
  }, [latestData.status]);

  const triggerText = useMemo(() => `Pemicu: ${getTriggerReason(latestData)}`, [latestData]);

  // History in descending order (newest first)
  const historyDescending = useMemo(() => [...history].reverse(), [history]);

  // Format date dd/MM/yyyy HH:mm:ss
  const formatDateTime = (iso: string) => {
    const d = new Date(iso);
    const day = String(d.getDate()).padStart(2, '0');
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const year = d.getFullYear();
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    const seconds = String(d.getSeconds()).padStart(2, '0');
    return `${day}/${month}/${year} ${hours}:${minutes}:${seconds}`;
  };

  const formatDuration = (seconds: number) => {
    if (seconds < 60) return `${seconds} dtk`;
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return s > 0 ? `${m} mnt ${s} dtk` : `${m} mnt`;
  };

  // Event Log Builders (Buzzer, Fan, LED)
  const buzzerEvents = useMemo<EventLogItem[]>(() => {
    const chrono = [...history];
    const intervals: { val: boolean; start: string; end?: string; sample: SensorData }[] = [];
    let currVal: boolean | null = null;
    let start: string | null = null;
    let sample: SensorData | null = null;

    for (const d of chrono) {
      if (currVal === null || d.buzzer_on !== currVal) {
        if (currVal !== null && start && sample) {
          intervals.push({ val: currVal, start, end: d.created_at, sample });
        }
        currVal = d.buzzer_on;
        start = d.created_at;
        sample = d;
      }
    }
    if (currVal !== null && start && sample) {
      intervals.push({ val: currVal, start, sample });
    }

    return intervals.reverse().map(iv => {
      let durStr = 'Sedang berlangsung';
      let sec: number | undefined;
      if (iv.end) {
        sec = Math.max(0, Math.round((new Date(iv.end).getTime() - new Date(iv.start).getTime()) / 1000));
        durStr = formatDuration(sec);
      }
      return {
        time: iv.start,
        status: iv.val ? 'NYALA' : 'MATI',
        trigger: getTriggerReason(iv.sample),
        duration: durStr,
        durationSeconds: sec,
        isActive: iv.val,
      };
    });
  }, [history]);

  const fanEvents = useMemo<EventLogItem[]>(() => {
    const chrono = [...history];
    const intervals: { val: boolean; start: string; end?: string; sample: SensorData }[] = [];
    let currVal: boolean | null = null;
    let start: string | null = null;
    let sample: SensorData | null = null;

    for (const d of chrono) {
      if (currVal === null || d.fan_on !== currVal) {
        if (currVal !== null && start && sample) {
          intervals.push({ val: currVal, start, end: d.created_at, sample });
        }
        currVal = d.fan_on;
        start = d.created_at;
        sample = d;
      }
    }
    if (currVal !== null && start && sample) {
      intervals.push({ val: currVal, start, sample });
    }

    return intervals.reverse().map(iv => {
      let durStr = 'Sedang berlangsung';
      let sec: number | undefined;
      if (iv.end) {
        sec = Math.max(0, Math.round((new Date(iv.end).getTime() - new Date(iv.start).getTime()) / 1000));
        durStr = formatDuration(sec);
      }
      return {
        time: iv.start,
        status: iv.val ? 'ON' : 'OFF',
        trigger: getTriggerReason(iv.sample),
        duration: durStr,
        durationSeconds: sec,
        isActive: iv.val,
      };
    });
  }, [history]);

  const ledEvents = useMemo<EventLogItem[]>(() => {
    const chrono = [...history];
    const intervals: { val: string; start: string; end?: string; sample: SensorData }[] = [];
    let currVal: string | null = null;
    let start: string | null = null;
    let sample: SensorData | null = null;

    for (const d of chrono) {
      const st = d.status.toLowerCase();
      if (currVal === null || st !== currVal) {
        if (currVal !== null && start && sample) {
          intervals.push({ val: currVal, start, end: d.created_at, sample });
        }
        currVal = st;
        start = d.created_at;
        sample = d;
      }
    }
    if (currVal !== null && start && sample) {
      intervals.push({ val: currVal, start, sample });
    }

    return intervals.reverse().map(iv => {
      let durStr = 'Sedang berlangsung';
      let sec: number | undefined;
      if (iv.end) {
        sec = Math.max(0, Math.round((new Date(iv.end).getTime() - new Date(iv.start).getTime()) / 1000));
        durStr = formatDuration(sec);
      }
      let statusStr = 'HIJAU';
      let isActive = false;
      if (iv.val === 'bahaya') {
        statusStr = 'MERAH';
        isActive = true;
      } else if (iv.val === 'waspada') {
        statusStr = 'KUNING';
        isActive = true;
      }
      return {
        time: iv.start,
        status: statusStr,
        trigger: getTriggerReason(iv.sample),
        duration: durStr,
        durationSeconds: sec,
        isActive,
      };
    });
  }, [history]);

  // Export CSV
  const handleExportCSV = (type: NavTab) => {
    let csv = '';
    if (type === 'gas') {
      csv = 'Waktu,Gas Sensor 1 (ppm),Gas Sensor 2 (ppm),Status\n' +
        historyDescending.map(d => `"${formatDateTime(d.created_at)}",${d.gas1},${d.gas2},${d.status}`).join('\n');
    } else if (type === 'flame') {
      csv = 'Waktu,IR Sensor 1,IR Sensor 2,Status\n' +
        historyDescending.map(d => `"${formatDateTime(d.created_at)}","${d.flame1 ? 'API TERDETEKSI' : 'AMAN'}","${d.flame2 ? 'API TERDETEKSI' : 'AMAN'}","${d.flame1 || d.flame2 ? 'API TERDETEKSI' : 'AMAN'}"`).join('\n');
    } else if (type === 'temp') {
      csv = 'Waktu,Suhu Sensor 1 (°C),Suhu Sensor 2 (°C),Status\n' +
        historyDescending.map(d => `"${formatDateTime(d.created_at)}",${d.temp1},${d.temp2},${d.status}`).join('\n');
    } else if (type === 'buzzer') {
      csv = 'Waktu,Status,Pemicu,Durasi\n' +
        buzzerEvents.map(e => `"${formatDateTime(e.time)}",${e.status},"${e.trigger}",${e.duration}`).join('\n');
    } else if (type === 'fan') {
      csv = 'Waktu,Status,Pemicu,Durasi\n' +
        fanEvents.map(e => `"${formatDateTime(e.time)}",${e.status},"${e.trigger}",${e.duration}`).join('\n');
    } else if (type === 'led') {
      csv = 'Waktu,Warna LED,Pemicu,Durasi\n' +
        ledEvents.map(e => `"${formatDateTime(e.time)}",${e.status},"${e.trigger}",${e.duration}`).join('\n');
    }

    navigator.clipboard.writeText(csv);
    setCopiedKey(`csv-${type}`);
    setTimeout(() => setCopiedKey(null), 2500);

    // Also download file
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `riwayat_${type}_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const copyToClipboard = (key: string, text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  return (
    <div className={`min-h-screen w-full bg-gradient-to-br ${bgGradient} text-white font-['Plus_Jakarta_Sans',sans-serif] transition-colors duration-700 relative overflow-x-hidden select-none`}>
      
      {/* Decorative Blur Orbs */}
      <div className="absolute -top-24 -left-24 w-96 h-96 rounded-full bg-blue-400/20 blur-3xl pointer-events-none" />
      <div className="absolute top-1/3 -right-24 w-96 h-96 rounded-full bg-indigo-500/20 blur-3xl pointer-events-none" />
      <div className="absolute -bottom-24 left-1/4 w-80 h-80 rounded-full bg-cyan-400/15 blur-3xl pointer-events-none" />

      {/* Top App Control Bar */}
      <header className="sticky top-0 z-40 backdrop-blur-md bg-black/25 border-b border-white/10 px-4 py-2.5">
        <div className="max-w-[1200px] mx-auto flex items-center justify-between flex-wrap gap-2 text-xs">
          <div className="flex items-center gap-3">
            <span className="flex items-center gap-1.5 font-bold tracking-tight text-sm text-white">
              <Flame className="w-4 h-4 text-rose-400" />
              Smart Fire Alarm IoT
            </span>
            <span className="hidden sm:inline-block px-2 py-0.5 rounded-full bg-white/10 text-white/80 text-[11px] font-medium border border-white/15">
              Flutter Web & Android Engine
            </span>
          </div>

          <div className="flex items-center gap-2 flex-wrap">
            <button
              onClick={() => setIsSimulating(!isSimulating)}
              className={`flex items-center gap-1 px-2.5 py-1 rounded-lg border transition ${isSimulating ? 'bg-emerald-500/20 border-emerald-400/40 text-emerald-300' : 'bg-white/10 border-white/20 text-white/70'}`}
              title="Toggle generator simulasi telemetri"
            >
              {isSimulating ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
              <span>{isSimulating ? 'Simulasi Aktif' : 'Simulasi Jeda'}</span>
            </button>

            <div className="hidden md:flex items-center gap-1 bg-black/20 p-0.5 rounded-lg border border-white/10">
              <button
                onClick={() => applyScenario('aman')}
                className={`px-2 py-0.5 rounded text-[11px] font-medium transition ${latestData.status === 'aman' ? 'bg-emerald-500/40 text-white' : 'text-white/60 hover:text-white'}`}
              >
                Aman
              </button>
              <button
                onClick={() => applyScenario('waspada-gas')}
                className={`px-2 py-0.5 rounded text-[11px] font-medium transition ${latestData.status === 'waspada' ? 'bg-amber-500/40 text-white' : 'text-white/60 hover:text-white'}`}
              >
                Gas Waspada
              </button>
              <button
                onClick={() => applyScenario('bahaya-api')}
                className={`px-2 py-0.5 rounded text-[11px] font-medium transition ${latestData.status === 'bahaya' && (latestData.flame1 || latestData.flame2) ? 'bg-rose-500/50 text-white' : 'text-white/60 hover:text-white'}`}
              >
                Api IR Bahaya
              </button>
            </div>

            <button
              onClick={() => setShowSimulationDrawer(!showSimulationDrawer)}
              className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white/10 hover:bg-white/15 border border-white/20 text-white/90 transition"
              title="Atur parameter sensor secara presisi"
            >
              <Sliders className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Uji Sensor</span>
            </button>

            <button
              onClick={() => setAudioEnabled(!audioEnabled)}
              className={`p-1.5 rounded-lg border transition ${audioEnabled ? 'bg-amber-500/30 border-amber-400 text-amber-300' : 'bg-white/10 border-white/20 text-white/60'}`}
              title={audioEnabled ? 'Audio Sirine Aktif' : 'Audio Sirine Hening'}
            >
              {audioEnabled ? <Volume2 className="w-3.5 h-3.5" /> : <VolumeX className="w-3.5 h-3.5" />}
            </button>

            <div className="flex items-center bg-black/30 rounded-lg p-0.5 border border-white/10">
              <button
                onClick={() => setDeviceMode('desktop')}
                className={`p-1 rounded ${deviceMode === 'desktop' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white'}`}
                title="Tampilan Desktop (2 Kolom)"
              >
                <Monitor className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => setDeviceMode('mobile')}
                className={`p-1 rounded ${deviceMode === 'mobile' ? 'bg-white/20 text-white' : 'text-white/50 hover:text-white'}`}
                title="Tampilan HP / Mobile (< 700px, 1 Kolom)"
              >
                <Smartphone className="w-3.5 h-3.5" />
              </button>
            </div>

            <button
              onClick={() => setShowFlutterCodeModal(true)}
              className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-sky-500/25 hover:bg-sky-500/35 border border-sky-400/40 text-sky-200 transition font-semibold"
            >
              <Code2 className="w-3.5 h-3.5" />
              <span>Kode Flutter</span>
            </button>

            <button
              onClick={() => setShowConfigModal(true)}
              className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-500/25 hover:bg-emerald-500/35 border border-emerald-400/40 text-emerald-200 transition font-semibold"
            >
              <Zap className="w-3.5 h-3.5" />
              <span>Supabase</span>
            </button>
          </div>
        </div>
      </header>

      {/* Manual Sensor Slider Drawer */}
      {showSimulationDrawer && (
        <div className="bg-black/60 backdrop-blur-xl border-b border-white/15 px-4 py-3 transition animate-in slide-in-from-top-2">
          <div className="max-w-[1200px] mx-auto grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 text-xs">
            <div>
              <div className="flex justify-between text-white/80 mb-1">
                <span>Gas Sensor 1 (MQ2)</span>
                <span className="font-bold text-amber-300">{latestData.gas1} ppm</span>
              </div>
              <input
                type="range"
                min="50"
                max="900"
                value={latestData.gas1}
                onChange={e => {
                  const val = +e.target.value;
                  const st = calculateStatus(val, latestData.gas2, latestData.flame1, latestData.flame2, latestData.temp1, latestData.temp2);
                  setLatestData(prev => ({
                    ...prev,
                    gas1: val,
                    status: st,
                    buzzer_on: st === 'bahaya',
                    fan_on: st === 'bahaya' || st === 'waspada'
                  }));
                }}
                className="w-full accent-amber-400"
              />
            </div>
            <div>
              <div className="flex justify-between text-white/80 mb-1">
                <span>Gas Sensor 2 (MQ2)</span>
                <span className="font-bold text-amber-300">{latestData.gas2} ppm</span>
              </div>
              <input
                type="range"
                min="50"
                max="900"
                value={latestData.gas2}
                onChange={e => {
                  const val = +e.target.value;
                  const st = calculateStatus(latestData.gas1, val, latestData.flame1, latestData.flame2, latestData.temp1, latestData.temp2);
                  setLatestData(prev => ({
                    ...prev,
                    gas2: val,
                    status: st,
                    buzzer_on: st === 'bahaya',
                    fan_on: st === 'bahaya' || st === 'waspada'
                  }));
                }}
                className="w-full accent-amber-400"
              />
            </div>
            <div>
              <div className="flex justify-between text-white/80 mb-1">
                <span>Suhu Sensor 1 (DHT22)</span>
                <span className="font-bold text-cyan-300">{latestData.temp1} °C</span>
              </div>
              <input
                type="range"
                min="20"
                max="65"
                step="0.5"
                value={latestData.temp1}
                onChange={e => {
                  const val = +e.target.value;
                  const st = calculateStatus(latestData.gas1, latestData.gas2, latestData.flame1, latestData.flame2, val, latestData.temp2);
                  setLatestData(prev => ({
                    ...prev,
                    temp1: val,
                    status: st,
                    buzzer_on: st === 'bahaya',
                    fan_on: st === 'bahaya' || st === 'waspada'
                  }));
                }}
                className="w-full accent-cyan-400"
              />
            </div>
            <div className="flex items-center justify-between gap-2">
              <label className="flex items-center gap-2 cursor-pointer bg-white/10 px-3 py-2 rounded-xl border border-white/20">
                <input
                  type="checkbox"
                  checked={latestData.flame1}
                  onChange={e => {
                    const f1 = e.target.checked;
                    const st = calculateStatus(latestData.gas1, latestData.gas2, f1, latestData.flame2, latestData.temp1, latestData.temp2);
                    setLatestData(prev => ({
                      ...prev,
                      flame1: f1,
                      status: st,
                      buzzer_on: st === 'bahaya',
                      fan_on: st === 'bahaya' || st === 'waspada'
                    }));
                  }}
                  className="rounded text-rose-500 accent-rose-500"
                />
                <span className="text-[11px] font-semibold text-rose-300">Api IR 1</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer bg-white/10 px-3 py-2 rounded-xl border border-white/20">
                <input
                  type="checkbox"
                  checked={latestData.flame2}
                  onChange={e => {
                    const f2 = e.target.checked;
                    const st = calculateStatus(latestData.gas1, latestData.gas2, latestData.flame1, f2, latestData.temp1, latestData.temp2);
                    setLatestData(prev => ({
                      ...prev,
                      flame2: f2,
                      status: st,
                      buzzer_on: st === 'bahaya',
                      fan_on: st === 'bahaya' || st === 'waspada'
                    }));
                  }}
                  className="rounded text-rose-500 accent-rose-500"
                />
                <span className="text-[11px] font-semibold text-rose-300">Api IR 2</span>
              </label>
            </div>
          </div>
        </div>
      )}

      {/* Main Container Wrapper (Desktop or Mobile preview) */}
      <div className={`mx-auto transition-all duration-300 ${deviceMode === 'mobile' ? 'max-w-[420px] my-6 p-4 rounded-[40px] border-[6px] border-black/40 shadow-2xl bg-black/30' : 'max-w-[1200px] p-6'}`}>
        
        {/* Device Notch simulation if mobile */}
        {deviceMode === 'mobile' && (
          <div className="w-32 h-4 bg-black/70 rounded-full mx-auto mb-4 border border-white/10 flex items-center justify-center">
            <div className="w-3 h-3 rounded-full bg-black/90 mr-2 border border-white/20" />
            <div className="w-8 h-1 bg-white/20 rounded-full" />
          </div>
        )}

        {/* Dashboard Header */}
        <div className="flex items-center justify-between mb-4 flex-wrap gap-3">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-white/12 border border-white/20 flex items-center justify-center backdrop-blur-md shadow-sm">
              <Flame className="w-6 h-6 text-rose-400 animate-pulse" />
            </div>
            <div>
              <h1 className="text-xl md:text-2xl font-extrabold tracking-tight text-white drop-shadow-sm">
                Smart Fire Alarm
              </h1>
              <p className="text-xs text-white/70 font-medium">
                Deteksi Kebakaran Dini Berbasis IoT
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-2xl bg-white/10 border border-white/20 backdrop-blur-sm text-xs font-semibold text-white/90">
              <span className="w-2 h-2 rounded-full bg-sky-300" />
              Ruangan Utama
            </div>
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-2xl bg-emerald-500/20 border border-emerald-400/40 backdrop-blur-sm text-xs font-bold text-emerald-300">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
              REALTIME
            </div>
          </div>
        </div>

        {/* MENU ATAS (Top Navigation) - widgets/top_nav.dart replica */}
        <div className="mb-6 rounded-2xl bg-white/[0.08] border border-white/20 backdrop-blur-md p-1.5 overflow-x-auto">
          <div className="flex items-center gap-1 min-w-max">
            {[
              { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
              { id: 'gas', label: 'Gas MQ2', icon: Cloud },
              { id: 'flame', label: 'Api IR', icon: Flame },
              { id: 'temp', label: 'Suhu DHT22', icon: Thermometer },
              { id: 'buzzer', label: 'Buzzer', icon: Volume2 },
              { id: 'fan', label: 'Kipas', icon: Fan },
              { id: 'led', label: 'LED Status', icon: Lightbulb },
            ].map(tab => {
              const IconComp = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as NavTab)}
                  className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all duration-200 ${
                    isActive
                      ? 'bg-white/25 text-white border border-white/35 shadow-md'
                      : 'text-white/70 hover:text-white hover:bg-white/10'
                  }`}
                >
                  <IconComp className="w-3.5 h-3.5" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* CONDITIONAL CONTENT: DASHBOARD vs RIWAYAT TABEL */}
        {activeTab === 'dashboard' ? (
          /* PRIMARY DASHBOARD LAYOUT */
          <div className={`grid gap-6 ${deviceMode === 'desktop' ? 'grid-cols-1 lg:grid-cols-12 items-start' : 'grid-cols-1'}`}>
            
            {/* LEFT COLUMN: Status Ruangan + Aktuator Otomatis */}
            <div className={`${deviceMode === 'desktop' ? 'lg:col-span-5 space-y-6' : 'order-1 space-y-6'}`}>
              
              {/* 1. KARTU STATUS RUANGAN */}
              <div className="rounded-[24px] bg-white/[0.12] border border-white/20 backdrop-blur-[16px] p-5 shadow-[0_8px_32px_rgba(0,0,0,0.12)]">
                <div className="flex items-center justify-between mb-4">
                  <span className="text-lg font-bold text-white tracking-tight">Status Ruangan</span>
                  <div className="flex items-center gap-1 px-2.5 py-1 rounded-xl bg-white/12 border border-white/20 text-[11px] font-semibold text-white/90">
                    <Shield className="w-3.5 h-3.5 text-white/80" />
                    Smart Guard
                  </div>
                </div>

                <div className={`rounded-2xl p-5 border text-center transition-all duration-500 ${
                  latestData.status === 'bahaya'
                    ? 'bg-rose-500/20 border-rose-400/50 shadow-[0_0_24px_rgba(239,68,68,0.25)]'
                    : latestData.status === 'waspada'
                    ? 'bg-amber-500/20 border-amber-400/50 shadow-[0_0_24px_rgba(245,158,11,0.2)]'
                    : 'bg-emerald-500/20 border-emerald-400/50 shadow-[0_0_24px_rgba(16,185,129,0.2)]'
                }`}>
                  <span className={`text-[11px] font-extrabold tracking-widest block mb-2 ${
                    latestData.status === 'bahaya' ? 'text-rose-300' : latestData.status === 'waspada' ? 'text-amber-300' : 'text-emerald-300'
                  }`}>
                    KONDISI SAAT INI
                  </span>

                  <div className="flex items-center justify-center gap-3 mb-2">
                    {latestData.status === 'bahaya' ? (
                      <ShieldAlert className="w-9 h-9 text-rose-400 animate-bounce" />
                    ) : latestData.status === 'waspada' ? (
                      <Activity className="w-9 h-9 text-amber-400 animate-pulse" />
                    ) : (
                      <ShieldCheck className="w-9 h-9 text-emerald-400" />
                    )}
                    <span className={`text-2xl md:text-3xl font-black tracking-tight ${
                      latestData.status === 'bahaya' ? 'text-rose-400' : latestData.status === 'waspada' ? 'text-amber-400' : 'text-emerald-400'
                    }`}>
                      {latestData.status === 'bahaya' ? 'SANGAT BAHAYA' : latestData.status === 'waspada' ? 'WASPADA' : 'AMAN'}
                    </span>
                  </div>

                  <p className="text-xs text-white/85 font-medium leading-relaxed">
                    {latestData.status === 'bahaya'
                      ? 'Deteksi potensi kebakaran aktif! Evakuasi & periksa ruangan segera.'
                      : latestData.status === 'waspada'
                      ? 'Anomali terdeteksi melebihi ambang batas normal. Tetap pantau.'
                      : 'Kondisi ruangan stabil, tidak terdeteksi asap pekat atau api.'}
                  </p>
                </div>

                <div className="mt-4 bg-black/20 rounded-2xl p-3.5 flex items-center justify-around border border-white/5">
                  <div className="flex flex-col items-center gap-1.5">
                    <div className={`w-5 h-5 rounded-full transition-all duration-300 border-2 ${
                      latestData.status === 'aman'
                        ? 'bg-emerald-400 border-emerald-300 shadow-[0_0_14px_#10B981] scale-110'
                        : 'bg-white/15 border-white/20 opacity-30'
                    }`} />
                    <span className={`text-xs font-bold ${latestData.status === 'aman' ? 'text-white' : 'text-white/40'}`}>
                      Aman
                    </span>
                  </div>

                  <div className="flex flex-col items-center gap-1.5">
                    <div className={`w-5 h-5 rounded-full transition-all duration-300 border-2 ${
                      latestData.status === 'waspada'
                        ? 'bg-amber-400 border-amber-300 shadow-[0_0_14px_#F59E0B] scale-110'
                        : 'bg-white/15 border-white/20 opacity-30'
                    }`} />
                    <span className={`text-xs font-bold ${latestData.status === 'waspada' ? 'text-white' : 'text-white/40'}`}>
                      Waspada
                    </span>
                  </div>

                  <div className="flex flex-col items-center gap-1.5">
                    <div className={`w-5 h-5 rounded-full transition-all duration-300 border-2 ${
                      latestData.status === 'bahaya'
                        ? 'bg-rose-500 border-rose-300 shadow-[0_0_18px_#EF4444] scale-110 animate-pulse'
                        : 'bg-white/15 border-white/20 opacity-30'
                    }`} />
                    <span className={`text-xs font-bold ${latestData.status === 'bahaya' ? 'text-white' : 'text-white/40'}`}>
                      Bahaya
                    </span>
                  </div>
                </div>

                <div className="h-px bg-white/15 my-4" />

                <div className="space-y-2 text-xs">
                  <div className="flex items-center gap-1.5 text-white/80 font-medium">
                    <RefreshCw className="w-3.5 h-3.5 text-white/60" />
                    <span>Update terakhir: {new Date(latestData.created_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}</span>
                  </div>
                  <div className="bg-white/5 rounded-xl p-2.5 border border-white/10 flex items-start gap-2">
                    <Activity className="w-3.5 h-3.5 text-white/70 mt-0.5 shrink-0" />
                    <span className="text-white/95 font-medium leading-snug">
                      {triggerText}
                    </span>
                  </div>
                </div>
              </div>

              {/* 2. KARTU AKTUATOR OTOMATIS */}
              <div className={`rounded-[24px] bg-white/[0.12] border border-white/20 backdrop-blur-[16px] p-5 shadow-[0_8px_32px_rgba(0,0,0,0.12)] ${deviceMode === 'mobile' ? 'order-3' : ''}`}>
                <div className="flex items-center justify-between mb-4">
                  <span className="text-lg font-bold text-white tracking-tight">Aktuator Otomatis</span>
                  <div className="flex items-center gap-1 px-2.5 py-1 rounded-xl bg-white/12 border border-white/20 text-[11px] font-semibold text-white/90">
                    <Zap className="w-3.5 h-3.5 text-amber-300" />
                    Relay IoT
                  </div>
                </div>

                <div className="space-y-3.5">
                  <div className="flex items-center justify-between p-3 rounded-2xl bg-black/15 border border-white/10">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-xl flex items-center justify-center border transition-all ${
                        latestData.buzzer_on
                          ? 'bg-rose-500/30 border-rose-400 text-rose-300 shadow-[0_0_16px_rgba(239,68,68,0.5)] animate-pulse'
                          : 'bg-white/10 border-white/15 text-white/40'
                      }`}>
                        <Volume2 className={`w-5 h-5 ${latestData.buzzer_on ? 'animate-bounce' : ''}`} />
                      </div>
                      <div>
                        <div className="text-sm font-bold text-white">Buzzer Alarm</div>
                        <div className="text-[11px] text-white/60">
                          {latestData.buzzer_on ? 'Sirine peringatan aktif bersuara' : 'Mode siaga nonaktif'}
                        </div>
                      </div>
                    </div>
                    <span className={`px-3 py-1 rounded-full text-xs font-black tracking-wider border ${
                      latestData.buzzer_on
                        ? 'bg-rose-500/25 border-rose-400 text-rose-300 shadow-[0_0_10px_rgba(239,68,68,0.3)]'
                        : 'bg-white/10 border-white/20 text-white/50'
                    }`}>
                      {latestData.buzzer_on ? 'NYALA' : 'MATI'}
                    </span>
                  </div>

                  <div className="flex items-center justify-between p-3 rounded-2xl bg-black/15 border border-white/10">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-xl flex items-center justify-center border transition-all ${
                        latestData.fan_on
                          ? 'bg-sky-500/30 border-sky-400 text-sky-300 shadow-[0_0_16px_rgba(56,189,248,0.5)]'
                          : 'bg-white/10 border-white/15 text-white/40'
                      }`}>
                        <Fan className={`w-5 h-5 ${latestData.fan_on ? 'animate-spin' : ''}`} style={{ animationDuration: '0.8s' }} />
                      </div>
                      <div>
                        <div className="text-sm font-bold text-white">Kipas Exhaust</div>
                        <div className="text-[11px] text-white/60">
                          {latestData.fan_on ? 'Membuang asap & gas keluar' : 'Mati / Siaga otomatis'}
                        </div>
                      </div>
                    </div>
                    <span className={`px-3 py-1 rounded-full text-xs font-black tracking-wider border ${
                      latestData.fan_on
                        ? 'bg-sky-500/25 border-sky-400 text-sky-300 shadow-[0_0_10px_rgba(56,189,248,0.3)]'
                        : 'bg-white/10 border-white/20 text-white/50'
                    }`}>
                      {latestData.fan_on ? 'ON' : 'OFF'}
                    </span>
                  </div>
                </div>
              </div>

            </div>

            {/* RIGHT COLUMN: 3. Monitoring Sensor (Telemetry Hub) */}
            <div className={`${deviceMode === 'desktop' ? 'lg:col-span-7' : 'order-2'}`}>
              <div className="rounded-[24px] bg-white/[0.12] border border-white/20 backdrop-blur-[16px] p-5 shadow-[0_8px_32px_rgba(0,0,0,0.12)] space-y-5">
                
                <div className="flex items-center justify-between">
                  <span className="text-lg font-bold text-white tracking-tight">Monitoring Sensor</span>
                  <div className="flex items-center gap-1 px-2.5 py-1 rounded-xl bg-white/12 border border-white/20 text-[11px] font-semibold text-white/90">
                    <Radio className="w-3.5 h-3.5 text-cyan-300" />
                    Telemetry Hub
                  </div>
                </div>

                {/* GRUP 1: GAS MQ2 */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between text-xs">
                    <div className="flex items-center gap-1.5 font-bold text-white/90">
                      <Cloud className="w-4 h-4 text-amber-400" />
                      <span>Gas & Asap (MQ2)</span>
                    </div>
                    <span className="text-white/50 font-medium">Satuan: ppm</span>
                  </div>

                  {/* Sensor 1 Row */}
                  <div className="bg-black/15 rounded-2xl p-3 border border-white/10">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-semibold text-white/80">Sensor 1</span>
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${
                          latestData.gas1 >= 500
                            ? 'bg-rose-500/20 border-rose-400 text-rose-300'
                            : latestData.gas1 >= 300
                            ? 'bg-amber-500/20 border-amber-400 text-amber-300'
                            : 'bg-emerald-500/20 border-emerald-400 text-emerald-300'
                        }`}>
                          {latestData.gas1 >= 500 ? 'Bahaya' : latestData.gas1 >= 300 ? 'Waspada' : 'Normal'}
                        </span>
                      </div>
                      <div className="flex items-baseline gap-1">
                        <span className={`text-xl font-black ${
                          latestData.gas1 >= 500 ? 'text-rose-400' : latestData.gas1 >= 300 ? 'text-amber-400' : 'text-emerald-400'
                        }`}>
                          {latestData.gas1}
                        </span>
                        <span className="text-[11px] text-white/60 font-medium">ppm</span>
                      </div>
                    </div>

                    <div className="relative pt-1 pb-1">
                      <div className="h-2 rounded-full overflow-hidden flex bg-white/10">
                        <div className="w-[30%] bg-emerald-500" title="0 - 300 Normal" />
                        <div className="w-[20%] bg-amber-500" title="300 - 500 Waspada" />
                        <div className="w-[50%] bg-rose-500" title="500 - 1000 Bahaya" />
                      </div>
                      <div
                        className="absolute top-1/2 -translate-y-1/2 w-3.5 h-3.5 bg-white rounded-full border-2 border-black/80 shadow-md transition-all duration-300"
                        style={{
                          left: `calc(${Math.min(100, Math.max(0, (latestData.gas1 / 1000) * 100))}% - 7px)`
                        }}
                      />
                    </div>
                    <div className="flex justify-between text-[9px] text-white/40 mt-1">
                      <span>0</span>
                      <span>300</span>
                      <span>500</span>
                      <span>1000 ppm</span>
                    </div>
                  </div>

                  {/* Sensor 2 Row */}
                  <div className="bg-black/15 rounded-2xl p-3 border border-white/10">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-semibold text-white/80">Sensor 2</span>
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${
                          latestData.gas2 >= 500
                            ? 'bg-rose-500/20 border-rose-400 text-rose-300'
                            : latestData.gas2 >= 300
                            ? 'bg-amber-500/20 border-amber-400 text-amber-300'
                            : 'bg-emerald-500/20 border-emerald-400 text-emerald-300'
                        }`}>
                          {latestData.gas2 >= 500 ? 'Bahaya' : latestData.gas2 >= 300 ? 'Waspada' : 'Normal'}
                        </span>
                      </div>
                      <div className="flex items-baseline gap-1">
                        <span className={`text-xl font-black ${
                          latestData.gas2 >= 500 ? 'text-rose-400' : latestData.gas2 >= 300 ? 'text-amber-400' : 'text-emerald-400'
                        }`}>
                          {latestData.gas2}
                        </span>
                        <span className="text-[11px] text-white/60 font-medium">ppm</span>
                      </div>
                    </div>

                    <div className="relative pt-1 pb-1">
                      <div className="h-2 rounded-full overflow-hidden flex bg-white/10">
                        <div className="w-[30%] bg-emerald-500" title="0 - 300 Normal" />
                        <div className="w-[20%] bg-amber-500" title="300 - 500 Waspada" />
                        <div className="w-[50%] bg-rose-500" title="500 - 1000 Bahaya" />
                      </div>
                      <div
                        className="absolute top-1/2 -translate-y-1/2 w-3.5 h-3.5 bg-white rounded-full border-2 border-black/80 shadow-md transition-all duration-300"
                        style={{
                          left: `calc(${Math.min(100, Math.max(0, (latestData.gas2 / 1000) * 100))}% - 7px)`
                        }}
                      />
                    </div>
                    <div className="flex justify-between text-[9px] text-white/40 mt-1">
                      <span>0</span>
                      <span>300</span>
                      <span>500</span>
                      <span>1000 ppm</span>
                    </div>
                  </div>
                </div>

                <div className="h-px bg-white/10" />

                {/* GRUP 2: API IR */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between text-xs">
                    <div className="flex items-center gap-1.5 font-bold text-white/90">
                      <Flame className="w-4 h-4 text-rose-400" />
                      <span>Deteksi Api (Infrared Flame)</span>
                    </div>
                    <span className="text-white/50 font-medium">Digital IR</span>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div className={`rounded-2xl p-3.5 text-center border transition-all ${
                      latestData.flame1
                        ? 'bg-rose-500/25 border-rose-400 shadow-[0_0_20px_rgba(239,68,68,0.4)]'
                        : 'bg-black/15 border-white/10'
                    }`}>
                      <div className="text-xs font-semibold text-white/75 mb-2">Sensor 1</div>
                      <div className={`w-12 h-12 rounded-full mx-auto flex items-center justify-center mb-2.5 transition-all ${
                        latestData.flame1
                          ? 'bg-rose-500 text-white animate-ping'
                          : 'bg-emerald-500/20 text-emerald-400 border border-emerald-400/40'
                      }`}>
                        <Flame className="w-6 h-6" />
                      </div>
                      <span className={`inline-block px-2.5 py-0.5 rounded-full text-[10px] font-black tracking-wider border ${
                        latestData.flame1
                          ? 'bg-rose-500/30 border-rose-400 text-rose-200'
                          : 'bg-emerald-500/20 border-emerald-400/40 text-emerald-300'
                      }`}>
                        {latestData.flame1 ? 'API TERDETEKSI' : 'AMAN'}
                      </span>
                    </div>

                    <div className={`rounded-2xl p-3.5 text-center border transition-all ${
                      latestData.flame2
                        ? 'bg-rose-500/25 border-rose-400 shadow-[0_0_20px_rgba(239,68,68,0.4)]'
                        : 'bg-black/15 border-white/10'
                    }`}>
                      <div className="text-xs font-semibold text-white/75 mb-2">Sensor 2</div>
                      <div className={`w-12 h-12 rounded-full mx-auto flex items-center justify-center mb-2.5 transition-all ${
                        latestData.flame2
                          ? 'bg-rose-500 text-white animate-ping'
                          : 'bg-emerald-500/20 text-emerald-400 border border-emerald-400/40'
                      }`}>
                        <Flame className="w-6 h-6" />
                      </div>
                      <span className={`inline-block px-2.5 py-0.5 rounded-full text-[10px] font-black tracking-wider border ${
                        latestData.flame2
                          ? 'bg-rose-500/30 border-rose-400 text-rose-200'
                          : 'bg-emerald-500/20 border-emerald-400/40 text-emerald-300'
                      }`}>
                        {latestData.flame2 ? 'API TERDETEKSI' : 'AMAN'}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="h-px bg-white/10" />

                {/* GRUP 3: SUHU DHT22 */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between text-xs">
                    <div className="flex items-center gap-1.5 font-bold text-white/90">
                      <Thermometer className="w-4 h-4 text-cyan-400" />
                      <span>Suhu Ruangan (DHT22)</span>
                    </div>
                    <span className="text-white/50 font-medium">Ambang: 35° / 45°C</span>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div className="bg-black/15 rounded-2xl p-3.5 border border-white/10">
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-xs font-semibold text-white/80">Sensor 1</span>
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${
                          latestData.temp1 >= 45
                            ? 'bg-rose-500/20 border-rose-400 text-rose-300'
                            : latestData.temp1 >= 35
                            ? 'bg-amber-500/20 border-amber-400 text-amber-300'
                            : 'bg-emerald-500/20 border-emerald-400 text-emerald-300'
                        }`}>
                          {latestData.temp1 >= 45 ? 'Bahaya' : latestData.temp1 >= 35 ? 'Waspada' : 'Normal'}
                        </span>
                      </div>
                      <div className="flex items-baseline gap-1">
                        <span className={`text-3xl font-black tracking-tight ${
                          latestData.temp1 >= 45 ? 'text-rose-400' : latestData.temp1 >= 35 ? 'text-amber-400' : 'text-emerald-400'
                        }`}>
                          {latestData.temp1.toFixed(1)}
                        </span>
                        <span className="text-sm font-semibold text-white/60">°C</span>
                      </div>
                    </div>

                    <div className="bg-black/15 rounded-2xl p-3.5 border border-white/10">
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-xs font-semibold text-white/80">Sensor 2</span>
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${
                          latestData.temp2 >= 45
                            ? 'bg-rose-500/20 border-rose-400 text-rose-300'
                            : latestData.temp2 >= 35
                            ? 'bg-amber-500/20 border-amber-400 text-amber-300'
                            : 'bg-emerald-500/20 border-emerald-400 text-emerald-300'
                        }`}>
                          {latestData.temp2 >= 45 ? 'Bahaya' : latestData.temp2 >= 35 ? 'Waspada' : 'Normal'}
                        </span>
                      </div>
                      <div className="flex items-baseline gap-1">
                        <span className={`text-3xl font-black tracking-tight ${
                          latestData.temp2 >= 45 ? 'text-rose-400' : latestData.temp2 >= 35 ? 'text-amber-400' : 'text-emerald-400'
                        }`}>
                          {latestData.temp2.toFixed(1)}
                        </span>
                        <span className="text-sm font-semibold text-white/60">°C</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="h-px bg-white/10" />

                {/* BAGIAN BAWAH: RIWAYAT GRAFIK 20 DATA */}
                <div className="space-y-3 pt-1">
                  <div className="flex items-center justify-between flex-wrap gap-2">
                    <div>
                      <div className="text-sm font-bold text-white">Riwayat Telemetri</div>
                      <div className="text-[11px] text-white/50">20 data terakhir grafik</div>
                    </div>

                    <div className="flex items-center bg-black/30 p-1 rounded-xl border border-white/15">
                      <button
                        onClick={() => setActiveMetricTab('gas')}
                        className={`px-3 py-1 rounded-lg text-xs font-bold transition ${
                          activeMetricTab === 'gas'
                            ? 'bg-white/20 text-white shadow-sm'
                            : 'text-white/60 hover:text-white'
                        }`}
                      >
                        Gas (ppm)
                      </button>
                      <button
                        onClick={() => setActiveMetricTab('temp')}
                        className={`px-3 py-1 rounded-lg text-xs font-bold transition ${
                          activeMetricTab === 'temp'
                            ? 'bg-white/20 text-white shadow-sm'
                            : 'text-white/60 hover:text-white'
                        }`}
                      >
                        Suhu (°C)
                      </button>
                    </div>
                  </div>

                  <div className="flex items-center gap-4 text-xs">
                    <div className="flex items-center gap-1.5">
                      <span className={`w-2.5 h-2.5 rounded-full ${activeMetricTab === 'gas' ? 'bg-sky-400' : 'bg-emerald-400'}`} />
                      <span className="text-white/80 font-medium">Sensor 1</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <span className={`w-2.5 h-2.5 rounded-full ${activeMetricTab === 'gas' ? 'bg-amber-400' : 'bg-purple-400'}`} />
                      <span className="text-white/80 font-medium">Sensor 2</span>
                    </div>
                  </div>

                  <div className="h-36 w-full relative">
                    <svg className="w-full h-full overflow-visible" viewBox="0 0 400 130" preserveAspectRatio="none">
                      <defs>
                        <linearGradient id="grad1" x1="0%" y1="0%" x2="0%" y2="100%">
                          <stop offset="0%" stopColor={activeMetricTab === 'gas' ? '#38BDF8' : '#34D399'} stopOpacity="0.4" />
                          <stop offset="100%" stopColor={activeMetricTab === 'gas' ? '#38BDF8' : '#34D399'} stopOpacity="0.0" />
                        </linearGradient>
                        <linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%">
                          <stop offset="0%" stopColor={activeMetricTab === 'gas' ? '#FBBF24' : '#A78BFA'} stopOpacity="0.3" />
                          <stop offset="100%" stopColor={activeMetricTab === 'gas' ? '#FBBF24' : '#A78BFA'} stopOpacity="0.0" />
                        </linearGradient>
                      </defs>

                      <line x1="0" y1="20" x2="400" y2="20" stroke="rgba(255,255,255,0.06)" strokeDasharray="3 3" />
                      <line x1="0" y1="65" x2="400" y2="65" stroke="rgba(255,255,255,0.06)" strokeDasharray="3 3" />
                      <line x1="0" y1="110" x2="400" y2="110" stroke="rgba(255,255,255,0.06)" strokeDasharray="3 3" />

                      {(() => {
                        const slice20 = history.slice(-20);
                        const len = slice20.length;
                        if (len < 2) return null;
                        const isGas = activeMetricTab === 'gas';
                        const vals1 = slice20.map(d => isGas ? d.gas1 : d.temp1);
                        const vals2 = slice20.map(d => isGas ? d.gas2 : d.temp2);
                        const minV = Math.min(...vals1, ...vals2) * 0.85;
                        const maxV = Math.max(...vals1, ...vals2) * 1.15 || (isGas ? 600 : 50);

                        const getCoords = (vals: number[]) => {
                          return vals.map((v, i) => {
                            const x = (i / (len - 1)) * 400;
                            const norm = (v - minV) / (maxV - minV || 1);
                            const y = 120 - norm * 105;
                            return { x, y };
                          });
                        };

                        const c1 = getCoords(vals1);
                        const c2 = getCoords(vals2);

                        const path1 = c1.reduce((acc, pt, i) => `${acc} ${i === 0 ? 'M' : 'L'} ${pt.x} ${pt.y}`, '');
                        const area1 = `${path1} L 400 130 L 0 130 Z`;

                        const path2 = c2.reduce((acc, pt, i) => `${acc} ${i === 0 ? 'M' : 'L'} ${pt.x} ${pt.y}`, '');
                        const area2 = `${path2} L 400 130 L 0 130 Z`;

                        const last1 = c1[c1.length - 1];
                        const last2 = c2[c2.length - 1];

                        return (
                          <>
                            <path d={area1} fill="url(#grad1)" />
                            <path d={area2} fill="url(#grad2)" />
                            <path d={path2} fill="none" stroke={isGas ? '#FBBF24' : '#A78BFA'} strokeWidth="2.5" strokeLinecap="round" />
                            <path d={path1} fill="none" stroke={isGas ? '#38BDF8' : '#34D399'} strokeWidth="2.5" strokeLinecap="round" />
                            <circle cx={last2.x} cy={last2.y} r="5" fill="#FFFFFF" stroke={isGas ? '#FBBF24' : '#A78BFA'} strokeWidth="3" />
                            <circle cx={last1.x} cy={last1.y} r="5" fill="#FFFFFF" stroke={isGas ? '#38BDF8' : '#34D399'} strokeWidth="3" />
                          </>
                        );
                      })()}
                    </svg>
                  </div>

                  <div className="flex items-center justify-between text-[10px] text-white/50 font-medium">
                    <span>-5 mnt lalu</span>
                    <span className="font-bold text-white/80">Saat Ini</span>
                  </div>
                </div>

              </div>
            </div>

          </div>
        ) : (
          /* TABEL RIWAYAT PER TAB (views/history_view.dart replica) */
          <div className="space-y-5">
            {/* 3 Kotak Ringkasan Kecil Bergaya Kaca (HistorySummary) */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {(() => {
                if (activeTab === 'gas') {
                  const totalG1 = history.reduce((acc, r) => acc + r.gas1, 0);
                  const totalG2 = history.reduce((acc, r) => acc + r.gas2, 0);
                  const avg = Math.round((totalG1 + totalG2) / (history.length * 2));
                  const max = Math.max(...history.map(r => Math.max(r.gas1, r.gas2)));
                  return (
                    <>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-sky-500/20 border border-sky-400/30 text-sky-300">
                          <Cloud className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Rata-rata Gas</div>
                          <div className="text-lg font-black text-white">{avg} ppm</div>
                          <div className="text-[10px] text-sky-300">Dari {history.length} baris sampel</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-amber-500/20 border border-amber-400/30 text-amber-300">
                          <Activity className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Gas Tertinggi</div>
                          <div className="text-lg font-black text-white">{max} ppm</div>
                          <div className="text-[10px] text-amber-300">{max >= 500 ? 'Bahaya asap pekat' : 'Batas waspada'}</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-emerald-500/20 border border-emerald-400/30 text-emerald-300">
                          <ShieldCheck className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Status Terkini</div>
                          <div className="text-lg font-black text-white uppercase">{latestData.status}</div>
                          <div className="text-[10px] text-emerald-300">S1: {latestData.gas1} | S2: {latestData.gas2} ppm</div>
                        </div>
                      </div>
                    </>
                  );
                } else if (activeTab === 'flame') {
                  const flameTotal = history.filter(r => r.flame1 || r.flame2).length;
                  const lastFlame = history.slice().reverse().find(r => r.flame1 || r.flame2);
                  return (
                    <>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-rose-500/20 border border-rose-400/30 text-rose-300">
                          <Flame className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Total Deteksi Api</div>
                          <div className="text-lg font-black text-white">{flameTotal} kali</div>
                          <div className="text-[10px] text-rose-300">Sensor IR 1 & 2</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-amber-500/20 border border-amber-400/30 text-amber-300">
                          <RefreshCw className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Deteksi Terakhir</div>
                          <div className="text-lg font-black text-white">
                            {lastFlame ? new Date(lastFlame.created_at).toLocaleTimeString('id-ID') : 'Nihil'}
                          </div>
                          <div className="text-[10px] text-amber-300">
                            {lastFlame ? formatDateTime(lastFlame.created_at).split(' ')[0] : 'Bebas api'}
                          </div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-emerald-500/20 border border-emerald-400/30 text-emerald-300">
                          <Shield className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Status Terkini</div>
                          <div className="text-lg font-black text-white">
                            {latestData.flame1 || latestData.flame2 ? 'API TERDETEKSI' : 'AMAN'}
                          </div>
                          <div className="text-[10px] text-emerald-300">Optik IR siaga</div>
                        </div>
                      </div>
                    </>
                  );
                } else if (activeTab === 'temp') {
                  const totalT1 = history.reduce((acc, r) => acc + r.temp1, 0);
                  const totalT2 = history.reduce((acc, r) => acc + r.temp2, 0);
                  const avg = ((totalT1 + totalT2) / (history.length * 2)).toFixed(1);
                  const max = Math.max(...history.map(r => Math.max(r.temp1, r.temp2))).toFixed(1);
                  return (
                    <>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-cyan-500/20 border border-cyan-400/30 text-cyan-300">
                          <Thermometer className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Rata-rata Suhu</div>
                          <div className="text-lg font-black text-white">{avg} °C</div>
                          <div className="text-[10px] text-cyan-300">DHT22 Sensor 1 & 2</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-amber-500/20 border border-amber-400/30 text-amber-300">
                          <Activity className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Suhu Tertinggi</div>
                          <div className="text-lg font-black text-white">{max} °C</div>
                          <div className="text-[10px] text-amber-300">{+max >= 45 ? 'Bahaya overheat' : 'Batas wajar'}</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-emerald-500/20 border border-emerald-400/30 text-emerald-300">
                          <ShieldCheck className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Suhu Terkini</div>
                          <div className="text-lg font-black text-white">{latestData.temp1} °C</div>
                          <div className="text-[10px] text-emerald-300">S2: {latestData.temp2} °C</div>
                        </div>
                      </div>
                    </>
                  );
                } else if (activeTab === 'buzzer') {
                  const nyalaCount = buzzerEvents.filter(e => e.isActive).length;
                  const totalDurSec = buzzerEvents.filter(e => e.isActive && e.durationSeconds).reduce((acc, e) => acc + (e.durationSeconds || 0), 0);
                  return (
                    <>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-rose-500/20 border border-rose-400/30 text-rose-300">
                          <Volume2 className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Total NYALA</div>
                          <div className="text-lg font-black text-white">{nyalaCount} kali</div>
                          <div className="text-[10px] text-rose-300">Aktivasi alarm sirine</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-amber-500/20 border border-amber-400/30 text-amber-300">
                          <Activity className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Total Durasi NYALA</div>
                          <div className="text-lg font-black text-white">{formatDuration(totalDurSec)}</div>
                          <div className="text-[10px] text-amber-300">Akumulasi durasi suara</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-emerald-500/20 border border-emerald-400/30 text-emerald-300">
                          <ShieldCheck className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Terakhir NYALA</div>
                          <div className="text-lg font-black text-white">
                            {latestData.buzzer_on ? 'SEDANG NYALA' : (buzzerEvents.find(e => e.isActive) ? new Date(buzzerEvents.find(e => e.isActive)!.time).toLocaleTimeString('id-ID') : 'Nihil')}
                          </div>
                          <div className="text-[10px] text-emerald-300">Relay sirine otomatis</div>
                        </div>
                      </div>
                    </>
                  );
                } else if (activeTab === 'fan') {
                  const onCount = fanEvents.filter(e => e.isActive).length;
                  const totalDurSec = fanEvents.filter(e => e.isActive && e.durationSeconds).reduce((acc, e) => acc + (e.durationSeconds || 0), 0);
                  return (
                    <>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-sky-500/20 border border-sky-400/30 text-sky-300">
                          <Fan className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Total ON</div>
                          <div className="text-lg font-black text-white">{onCount} kali</div>
                          <div className="text-[10px] text-sky-300">Buang gas/asap keluar</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-cyan-500/20 border border-cyan-400/30 text-cyan-300">
                          <Activity className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Total Durasi ON</div>
                          <div className="text-lg font-black text-white">{formatDuration(totalDurSec)}</div>
                          <div className="text-[10px] text-cyan-300">Akumulasi rotasi kipas</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-emerald-500/20 border border-emerald-400/30 text-emerald-300">
                          <ShieldCheck className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Kondisi Terkini</div>
                          <div className="text-lg font-black text-white">{latestData.fan_on ? 'ON (BERPUTAR)' : 'OFF (MATI)'}</div>
                          <div className="text-[10px] text-emerald-300">Relay exhaust otomatis</div>
                        </div>
                      </div>
                    </>
                  );
                } else if (activeTab === 'led') {
                  const merahCount = ledEvents.filter(e => e.status === 'MERAH').length;
                  const kuningCount = ledEvents.filter(e => e.status === 'KUNING').length;
                  const currentLed = latestData.status === 'bahaya' ? 'MERAH' : (latestData.status === 'waspada' ? 'KUNING' : 'HIJAU');
                  return (
                    <>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-rose-500/20 border border-rose-400/30 text-rose-300">
                          <Lightbulb className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Total Bahaya (Merah)</div>
                          <div className="text-lg font-black text-white">{merahCount} kali</div>
                          <div className="text-[10px] text-rose-300">LED merah berkedip</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-amber-500/20 border border-amber-400/30 text-amber-300">
                          <Lightbulb className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Total Waspada (Kuning)</div>
                          <div className="text-lg font-black text-white">{kuningCount} kali</div>
                          <div className="text-[10px] text-amber-300">LED kuning menyala</div>
                        </div>
                      </div>
                      <div className="rounded-2xl bg-white/[0.12] border border-white/20 p-4 backdrop-blur-md flex items-center gap-3">
                        <div className="p-2.5 rounded-xl bg-emerald-500/20 border border-emerald-400/30 text-emerald-300">
                          <ShieldCheck className="w-5 h-5" />
                        </div>
                        <div>
                          <div className="text-[11px] text-white/60">Status LED Terkini</div>
                          <div className="text-lg font-black text-white">{currentLed}</div>
                          <div className="text-[10px] text-emerald-300">Aktif dengan glow</div>
                        </div>
                      </div>
                    </>
                  );
                }
                return null;
              })()}
            </div>

            {/* TABEL GLASS DENGAN PAGINATION (widgets/history_table.dart replica) */}
            <div className="rounded-[24px] bg-white/[0.12] border border-white/20 backdrop-blur-[16px] p-5 shadow-[0_8px_32px_rgba(0,0,0,0.12)] space-y-4">
              
              {/* Header Tabel & Tombol Action */}
              <div className="flex items-center justify-between flex-wrap gap-2">
                <div>
                  <h3 className="text-base font-bold text-white tracking-tight">
                    {activeTab === 'gas' && 'Riwayat Telemetri Gas MQ2'}
                    {activeTab === 'flame' && 'Riwayat Deteksi Api IR'}
                    {activeTab === 'temp' && 'Riwayat Suhu Ruangan DHT22'}
                    {activeTab === 'buzzer' && 'Log Perubahan Buzzer Alarm'}
                    {activeTab === 'fan' && 'Log Perubahan Kipas Exhaust'}
                    {activeTab === 'led' && 'Log Perubahan LED Status'}
                  </h3>
                  <p className="text-xs text-white/60">
                    {activeTab === 'buzzer' || activeTab === 'fan' || activeTab === 'led'
                      ? 'Mencatat perubahan status berurutan (pemicu & durasi)'
                      : 'Data telemetri berurutan dari yang paling baru (newest di atas)'}
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => {
                      setTablePage(1);
                    }}
                    className="p-2 rounded-xl bg-white/10 hover:bg-white/20 text-white/80 transition"
                    title="Segarkan Data"
                  >
                    <RefreshCw className="w-4 h-4" />
                  </button>

                  <button
                    onClick={() => handleExportCSV(activeTab)}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/12 hover:bg-white/20 border border-white/20 text-xs font-bold text-white transition"
                    title="Unduh data dalam format CSV"
                  >
                    {copiedKey === `csv-${activeTab}` ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Download className="w-3.5 h-3.5" />}
                    <span>{copiedKey === `csv-${activeTab}` ? 'Tersalin!' : 'Unduh CSV'}</span>
                  </button>
                </div>
              </div>

              {/* Render Tabel Sesuai Tab */}
              {(() => {
                let rowsData: React.ReactNode[] = [];
                let headers: string[] = [];
                let totalItems = 0;

                if (activeTab === 'gas') {
                  headers = ['Waktu', 'Gas Sensor 1 (ppm)', 'Gas Sensor 2 (ppm)', 'Status'];
                  totalItems = historyDescending.length;
                  const slice = historyDescending.slice((tablePage - 1) * pageSize, tablePage * pageSize);
                  rowsData = slice.map((row, idx) => (
                    <tr key={idx} className="border-t border-white/10 hover:bg-white/5 transition text-xs">
                      <td className="py-3 px-4 font-mono text-white/90">{formatDateTime(row.created_at)}</td>
                      <td className="py-3 px-4 text-center font-bold text-amber-300">{row.gas1} ppm</td>
                      <td className="py-3 px-4 text-center font-bold text-amber-300">{row.gas2} ppm</td>
                      <td className="py-3 px-4 text-right">
                        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
                          row.status === 'bahaya' ? 'bg-rose-500/25 border-rose-400 text-rose-300' :
                          row.status === 'waspada' ? 'bg-amber-500/25 border-amber-400 text-amber-300' :
                          'bg-emerald-500/25 border-emerald-400 text-emerald-300'
                        }`}>
                          {row.status.toUpperCase()}
                        </span>
                      </td>
                    </tr>
                  ));
                } else if (activeTab === 'flame') {
                  headers = ['Waktu', 'IR Sensor 1', 'IR Sensor 2', 'Status'];
                  totalItems = historyDescending.length;
                  const slice = historyDescending.slice((tablePage - 1) * pageSize, tablePage * pageSize);
                  rowsData = slice.map((row, idx) => (
                    <tr key={idx} className="border-t border-white/10 hover:bg-white/5 transition text-xs">
                      <td className="py-3 px-4 font-mono text-white/90">{formatDateTime(row.created_at)}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${row.flame1 ? 'bg-rose-500/25 border-rose-400 text-rose-300' : 'bg-emerald-500/25 border-emerald-400 text-emerald-300'}`}>
                          {row.flame1 ? 'API TERDETEKSI' : 'AMAN'}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${row.flame2 ? 'bg-rose-500/25 border-rose-400 text-rose-300' : 'bg-emerald-500/25 border-emerald-400 text-emerald-300'}`}>
                          {row.flame2 ? 'API TERDETEKSI' : 'AMAN'}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-right">
                        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${row.flame1 || row.flame2 ? 'bg-rose-500/25 border-rose-400 text-rose-300' : 'bg-emerald-500/25 border-emerald-400 text-emerald-300'}`}>
                          {row.flame1 || row.flame2 ? 'API TERDETEKSI' : 'AMAN'}
                        </span>
                      </td>
                    </tr>
                  ));
                } else if (activeTab === 'temp') {
                  headers = ['Waktu', 'Suhu Sensor 1 (°C)', 'Suhu Sensor 2 (°C)', 'Status'];
                  totalItems = historyDescending.length;
                  const slice = historyDescending.slice((tablePage - 1) * pageSize, tablePage * pageSize);
                  rowsData = slice.map((row, idx) => (
                    <tr key={idx} className="border-t border-white/10 hover:bg-white/5 transition text-xs">
                      <td className="py-3 px-4 font-mono text-white/90">{formatDateTime(row.created_at)}</td>
                      <td className="py-3 px-4 text-center font-bold text-cyan-300">{row.temp1.toFixed(1)} °C</td>
                      <td className="py-3 px-4 text-center font-bold text-cyan-300">{row.temp2.toFixed(1)} °C</td>
                      <td className="py-3 px-4 text-right">
                        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
                          row.status === 'bahaya' ? 'bg-rose-500/25 border-rose-400 text-rose-300' :
                          row.status === 'waspada' ? 'bg-amber-500/25 border-amber-400 text-amber-300' :
                          'bg-emerald-500/25 border-emerald-400 text-emerald-300'
                        }`}>
                          {row.status.toUpperCase()}
                        </span>
                      </td>
                    </tr>
                  ));
                } else if (activeTab === 'buzzer') {
                  headers = ['Waktu', 'Status', 'Pemicu', 'Durasi'];
                  totalItems = buzzerEvents.length;
                  const slice = buzzerEvents.slice((tablePage - 1) * pageSize, tablePage * pageSize);
                  rowsData = slice.map((row, idx) => (
                    <tr key={idx} className="border-t border-white/10 hover:bg-white/5 transition text-xs">
                      <td className="py-3 px-4 font-mono text-white/90">{formatDateTime(row.time)}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${row.isActive ? 'bg-rose-500/25 border-rose-400 text-rose-300' : 'bg-emerald-500/25 border-emerald-400 text-emerald-300'}`}>
                          {row.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-white/90">{row.trigger}</td>
                      <td className="py-3 px-4 text-right font-medium text-white/70">{row.duration}</td>
                    </tr>
                  ));
                } else if (activeTab === 'fan') {
                  headers = ['Waktu', 'Status', 'Pemicu', 'Durasi'];
                  totalItems = fanEvents.length;
                  const slice = fanEvents.slice((tablePage - 1) * pageSize, tablePage * pageSize);
                  rowsData = slice.map((row, idx) => (
                    <tr key={idx} className="border-t border-white/10 hover:bg-white/5 transition text-xs">
                      <td className="py-3 px-4 font-mono text-white/90">{formatDateTime(row.time)}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${row.isActive ? 'bg-sky-500/25 border-sky-400 text-sky-300' : 'bg-emerald-500/25 border-emerald-400 text-emerald-300'}`}>
                          {row.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-white/90">{row.trigger}</td>
                      <td className="py-3 px-4 text-right font-medium text-white/70">{row.duration}</td>
                    </tr>
                  ));
                } else if (activeTab === 'led') {
                  headers = ['Waktu', 'Warna LED', 'Pemicu', 'Durasi'];
                  totalItems = ledEvents.length;
                  const slice = ledEvents.slice((tablePage - 1) * pageSize, tablePage * pageSize);
                  rowsData = slice.map((row, idx) => (
                    <tr key={idx} className="border-t border-white/10 hover:bg-white/5 transition text-xs">
                      <td className="py-3 px-4 font-mono text-white/90">{formatDateTime(row.time)}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`px-2.5 py-0.5 rounded-full font-bold text-[10px] border ${
                          row.status === 'MERAH' ? 'bg-rose-500/25 border-rose-400 text-rose-300' :
                          row.status === 'KUNING' ? 'bg-amber-500/25 border-amber-400 text-amber-300' :
                          'bg-emerald-500/25 border-emerald-400 text-emerald-300'
                        }`}>
                          {row.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-white/90">{row.trigger}</td>
                      <td className="py-3 px-4 text-right font-medium text-white/70">{row.duration}</td>
                    </tr>
                  ));
                }

                const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));

                if (totalItems === 0) {
                  return (
                    <div className="py-12 text-center text-white/50">
                      <Inbox className="w-8 h-8 mx-auto mb-2 opacity-40" />
                      <div>Belum ada riwayat</div>
                    </div>
                  );
                }

                return (
                  <div>
                    {/* Responsive Table Container */}
                    <div className="overflow-x-auto rounded-xl border border-white/10 bg-black/20">
                      <table className="w-full text-left border-collapse">
                        <thead>
                          <tr className="bg-white/10 text-white font-extrabold text-xs">
                            {headers.map((h, i) => (
                              <th key={i} className={`py-3 px-4 ${i === 1 || i === 2 ? 'text-center' : i === headers.length - 1 ? 'text-right' : ''}`}>
                                {h}
                              </th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {rowsData}
                        </tbody>
                      </table>
                    </div>

                    {/* Pagination Bar */}
                    <div className="flex items-center justify-between text-xs text-white/60 mt-4 px-1">
                      <div>
                        Menampilkan {Math.min(totalItems, (tablePage - 1) * pageSize + 1)} - {Math.min(totalItems, tablePage * pageSize)} dari {totalItems} baris
                      </div>
                      <div className="flex items-center gap-2">
                        <span>Halaman {tablePage} dari {totalPages}</span>
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => setTablePage(p => Math.max(1, p - 1))}
                            disabled={tablePage === 1}
                            className="p-1.5 rounded-lg bg-white/10 hover:bg-white/20 disabled:opacity-30 disabled:cursor-not-allowed text-white transition"
                          >
                            <ChevronLeft className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => setTablePage(p => Math.min(totalPages, p + 1))}
                            disabled={tablePage === totalPages}
                            className="p-1.5 rounded-lg bg-white/10 hover:bg-white/20 disabled:opacity-30 disabled:cursor-not-allowed text-white transition"
                          >
                            <ChevronRight className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })()}

            </div>
          </div>
        )}

      </div>

      {/* Supabase Config & SQL Modal */}
      {showConfigModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md">
          <div className="bg-[#1F293D] border border-white/20 rounded-[28px] max-w-lg w-full p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto text-xs">
            <div className="flex items-center justify-between border-b border-white/10 pb-3">
              <div className="flex items-center gap-2">
                <Zap className="w-5 h-5 text-emerald-400" />
                <span className="text-base font-bold text-white">Konfigurasi Supabase</span>
              </div>
              <button
                onClick={() => setShowConfigModal(false)}
                className="w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/70"
              >
                ✕
              </button>
            </div>

            <p className="text-white/75 leading-relaxed">
              Aplikasi ini membaca data dari tabel <code className="bg-black/30 px-1 py-0.5 rounded text-emerald-300">sensor_data</code> secara realtime tanpa autentikasi (role anon).
            </p>

            <div className="space-y-3">
              <div>
                <label className="block text-white/80 font-semibold mb-1">Supabase URL</label>
                <input
                  type="text"
                  placeholder="https://xyzcompany.supabase.co"
                  value={supabaseUrl}
                  onChange={e => setSupabaseUrl(e.target.value)}
                  className="w-full bg-black/30 border border-white/20 rounded-xl px-3 py-2 text-white placeholder-white/30 focus:outline-none focus:border-emerald-400"
                />
              </div>
              <div>
                <label className="block text-white/80 font-semibold mb-1">Anon Public Key</label>
                <input
                  type="password"
                  placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                  value={supabaseKey}
                  onChange={e => setSupabaseKey(e.target.value)}
                  className="w-full bg-black/30 border border-white/20 rounded-xl px-3 py-2 text-white placeholder-white/30 focus:outline-none focus:border-emerald-400"
                />
              </div>

              <div className="flex gap-2">
                <button
                  onClick={handleConnectSupabase}
                  className="flex-1 py-2 rounded-xl bg-emerald-500 hover:bg-emerald-600 font-bold text-white transition flex items-center justify-center gap-1.5"
                >
                  <Zap className="w-4 h-4" />
                  Hubungkan Sekarang
                </button>
              </div>

              <div className="p-2.5 rounded-xl bg-black/30 border border-white/10 text-white/70">
                <strong>Status:</strong> {supabaseStatusMsg}
              </div>
            </div>

            <div className="border-t border-white/10 pt-3">
              <span className="font-bold text-white block mb-1">Script Database Supabase:</span>
              <p className="text-white/60 mb-2">File <code className="text-amber-300">supabase_setup.sql</code> sudah dibuat di root project untuk tabel, index, RLS, policy anon, dan realtime publication.</p>
              <button
                onClick={() => {
                  setShowConfigModal(false);
                  setActiveCodeTab('supabase_setup.sql');
                  setShowFlutterCodeModal(true);
                }}
                className="w-full py-1.5 rounded-xl bg-white/10 hover:bg-white/15 text-white/90 border border-white/20 font-semibold"
              >
                Lihat & Salin supabase_setup.sql
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Flutter Code Explorer Modal */}
      {showFlutterCodeModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-black/75 backdrop-blur-md">
          <div className="bg-[#182032] border border-white/20 rounded-[28px] max-w-4xl w-full max-h-[92vh] flex flex-col shadow-2xl overflow-hidden">
            <div className="p-4 border-b border-white/10 flex items-center justify-between bg-black/20">
              <div className="flex items-center gap-2">
                <Code2 className="w-5 h-5 text-sky-400" />
                <div>
                  <span className="text-base font-bold text-white block">File Proyek Flutter & Supabase</span>
                  <span className="text-[11px] text-white/60">Semua file telah siap di repository untuk build Web & Android</span>
                </div>
              </div>
              <button
                onClick={() => setShowFlutterCodeModal(false)}
                className="w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/70"
              >
                ✕
              </button>
            </div>

            <div className="flex overflow-x-auto border-b border-white/10 bg-black/30 px-3 py-1 text-xs gap-1">
              {[
                { name: 'main.dart', path: 'lib/main.dart' },
                { name: 'dashboard_view.dart', path: 'lib/views/dashboard_view.dart' },
                { name: 'history_view.dart', path: 'lib/views/history_view.dart' },
                { name: 'top_nav.dart', path: 'lib/widgets/top_nav.dart' },
                { name: 'history_table.dart', path: 'lib/widgets/history_table.dart' },
                { name: 'history_summary.dart', path: 'lib/widgets/history_summary.dart' },
                { name: 'history_builder.dart', path: 'lib/utils/history_builder.dart' },
                { name: 'history_event.dart', path: 'lib/models/history_event.dart' },
                { name: 'sensor_data_model.dart', path: 'lib/models/sensor_data_model.dart' },
                { name: 'sensor_service.dart', path: 'lib/services/sensor_service.dart' },
                { name: 'supabase_setup.sql', path: 'supabase_setup.sql' },
                { name: 'pubspec.yaml', path: 'pubspec.yaml' },
              ].map(file => (
                <button
                  key={file.name}
                  onClick={() => setActiveCodeTab(file.name)}
                  className={`px-3 py-1.5 rounded-lg whitespace-nowrap font-medium transition ${
                    activeCodeTab === file.name
                      ? 'bg-sky-500/30 text-sky-200 border border-sky-400/40'
                      : 'text-white/60 hover:text-white'
                  }`}
                >
                  {file.name}
                </button>
              ))}
            </div>

            <div className="p-4 flex-1 overflow-y-auto font-mono text-[11px] bg-black/40 text-emerald-300 space-y-2">
              <div className="flex justify-between items-center mb-2 pb-1 border-b border-white/10 text-white/60 text-xs">
                <span>File: {activeCodeTab}</span>
                <button
                  onClick={() => copyToClipboard(activeCodeTab, getCodePreview(activeCodeTab))}
                  className="flex items-center gap-1 px-2.5 py-1 rounded bg-white/10 hover:bg-white/20 text-white transition text-xs"
                >
                  {copiedKey === activeCodeTab ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  <span>{copiedKey === activeCodeTab ? 'Disalin!' : 'Salin Kode'}</span>
                </button>
              </div>
              <pre className="whitespace-pre overflow-x-auto p-2 leading-relaxed">
                {getCodePreview(activeCodeTab)}
              </pre>
            </div>

            <div className="p-3 border-t border-white/10 bg-black/20 flex items-center justify-between text-xs text-white/60">
              <span>Perintah jalankan Flutter: <code className="bg-black/40 px-1 py-0.5 rounded text-amber-300">flutter run -d chrome</code> atau <code className="bg-black/40 px-1 py-0.5 rounded text-amber-300">flutter run</code></span>
              <button
                onClick={() => setShowFlutterCodeModal(false)}
                className="px-4 py-1.5 rounded-xl bg-white/10 hover:bg-white/20 text-white font-semibold"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

function getCodePreview(filename: string): string {
  switch (filename) {
    case 'top_nav.dart':
      return `enum NavTab { dashboard, gas, flame, temp, buzzer, fan, led }

class TopNav extends StatelessWidget {
  final NavTab activeTab;
  final ValueChanged<NavTab> onTabSelected;
  // Glassmorphism tab chip horizontal with responsive horizontal scroll
}`;

    case 'history_view.dart':
      return `class HistoryView extends StatefulWidget {
  final NavTab tab;
  final SensorService sensorService;

  // Menampilkan 3 kartu ringkasan kecil dan tabel riwayat per tab
  // Mengambil 500 baris terbaru dari sensor_data via SensorService.fetchHistory()
}`;

    case 'history_table.dart':
      return `class HistoryTable extends StatefulWidget {
  // Pagination 10 baris per halaman, tombol Segarkan, unduh CSV, dan status chip
}`;

    case 'history_builder.dart':
      return `class HistoryBuilder {
  static List<HistoryEvent> buildBuzzerHistory(List<SensorData> rawDescending) { ... }
  static List<HistoryEvent> buildFanHistory(List<SensorData> rawDescending) { ... }
  static List<HistoryEvent> buildLedHistory(List<SensorData> rawDescending) { ... }
}`;

    case 'history_event.dart':
      return `class HistoryEvent {
  final DateTime time;
  final String status;
  final String trigger;
  final String duration;
  final Duration? durationValue;
  final bool isActiveState;
}`;

    case 'supabase_setup.sql':
      return `-- Tabel sensor_data & Supabase Realtime publication
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
);`;

    default:
      return `// Silakan periksa file lengkap di direktori proyek ini.`;
  }
}
