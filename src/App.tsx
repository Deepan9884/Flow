import React, { useState, useEffect } from 'react';
import {
  Folder,
  FileCode,
  Copy,
  Check,
  CheckCircle2,
  Settings,
  Calendar,
  LayoutGrid,
  Plus,
  X,
  ChevronRight,
  Trash2,
  Palette,
  Moon,
  Sun,
  Sparkles,
  Info,
  CheckSquare,
  Square,
  ArrowRight,
  ArrowLeft,
  Bookmark,
  Smartphone,
  Sliders,
  Play,
  RotateCcw,
  Volume2,
  Send,
  MessageSquare,
  Cpu,
  Bot,
  Zap
} from 'lucide-react';
import {
  pubspecTemplate,
  mainTemplate,
  appTemplate,
  themeTemplate,
  dbTemplate,
  taskTemplate,
  subtaskTemplate,
  recurrenceTemplate,
  categoryTemplate
} from './codeTemplates';
import { Task, Category, ThemeConfig, SettingsState, PriorityLevel, Subtask } from './types';

// Web Audio API synthesizer for clean, zero-external-dependency, platform-native audio previews
const playSyntheticSound = (type: string) => {
  try {
    const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);

    const now = ctx.currentTime;
    if (type === 'Bell') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, now); // A5
      osc.frequency.exponentialRampToValueAtTime(1320, now + 0.15); // E6
      gain.gain.setValueAtTime(0.4, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 1.2);
      osc.start(now);
      osc.stop(now + 1.2);
    } else if (type === 'Digital') {
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(587.33, now); // D5
      osc.frequency.setValueAtTime(880, now + 0.1); // A5
      gain.gain.setValueAtTime(0.3, now);
      gain.gain.setValueAtTime(0.3, now + 0.1);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.5);
      osc.start(now);
      osc.stop(now + 0.5);
    } else if (type === 'Marimba') {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(523.25, now); // C5
      osc.frequency.setValueAtTime(659.25, now + 0.08); // E5
      osc.frequency.setValueAtTime(783.99, now + 0.16); // G5
      gain.gain.setValueAtTime(0.5, now);
      gain.gain.setValueAtTime(0.5, now + 0.16);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);
      osc.start(now);
      osc.stop(now + 0.6);
    } else {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.exponentialRampToValueAtTime(880, now + 0.3);
      gain.gain.setValueAtTime(0.3, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.8);
      osc.start(now);
      osc.stop(now + 0.8);
    }
  } catch (e) {
    console.warn("Audio Context blocked or not supported yet", e);
  }
};

const playSound = (soundPath: string) => {
  if (!soundPath) return;
  if (soundPath.startsWith('data:audio/') || soundPath.startsWith('http://') || soundPath.startsWith('https://')) {
    try {
      const audio = new Audio(soundPath);
      audio.play().catch(e => console.warn("Failed to play custom sound", e));
    } catch (e) {
      console.warn("Audio element blocked or error", e);
    }
  } else {
    playSyntheticSound(soundPath);
  }
};

// Premium, fully interactive React equivalent to TaskBannerCard / TiltBanner 
// Implements absolute perspective rotations, cursor track, and pan offset triggers.
function TaskBannerCardReact({ 
  task, 
  onToggle, 
  onPlaySound, 
  getPriorityColor, 
  categories, 
  appSurfaceColor, 
  appBorderColor, 
  appTextColor, 
  appTextMutedColor,
  appPrimaryColor,
  onCardClick
}: { 
  task: Task; 
  onToggle: () => void; 
  onPlaySound: () => void; 
  getPriorityColor: (p: any) => string; 
  categories: any[]; 
  appSurfaceColor: string; 
  appBorderColor: string; 
  appTextColor: string; 
  appTextMutedColor: string; 
  appPrimaryColor: string;
  key?: any;
  onCardClick?: () => void;
}) {
  const [tilt, setTilt] = React.useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = React.useState(false);
  const dragStart = React.useRef({ x: 0, y: 0 });
  const accumulatedDrag = React.useRef(0);

  const handleMouseMove = (e: React.MouseEvent) => {
    if (isDragging) return;
    const card = e.currentTarget;
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    const rotateY = ((x - centerX) / centerX) * 8;
    const rotateX = -((y - centerY) / centerY) * 8;
    setTilt({ x: rotateX, y: rotateY });
  };

  const handleMouseLeave = () => {
    setTilt({ x: 0, y: 0 });
  };

  const handleMouseDown = (e: React.MouseEvent) => {
    setIsDragging(true);
    dragStart.current = { x: e.clientX, y: e.clientY };
    accumulatedDrag.current = 0;
  };

  const handleMouseMoveGlobal = React.useCallback((e: MouseEvent) => {
    if (!dragStart.current) return;
    const dx = e.clientX - dragStart.current.x;
    const dy = e.clientY - dragStart.current.y;
    accumulatedDrag.current += Math.sqrt(dx * dx + dy * dy);
    dragStart.current = { x: e.clientX, y: e.clientY };
    
    const rotateY = Math.min(Math.max(dx * 0.1, -8), 8);
    const rotateX = Math.min(Math.max(-dy * 0.1, -8), 8);
    setTilt({ x: rotateX, y: rotateY });
  }, []);

  const handleMouseUp = React.useCallback(() => {
    setIsDragging(false);
    setTilt({ x: 0, y: 0 });
    if (accumulatedDrag.current < 8) {
      onCardClick?.();
    }
  }, [onCardClick]);

  React.useEffect(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleMouseMoveGlobal);
      window.addEventListener('mouseup', handleMouseUp);
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMoveGlobal);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, handleMouseMoveGlobal, handleMouseUp]);

  const hasWallpaper = !!task.wallpaperPath;
  const totalSubtasks = task.subtasks?.length || 0;
  const completedSubtasks = task.subtasks?.filter(s => s.isDone).length || 0;
  const hasSubtasks = totalSubtasks > 0;
  const progressPct = hasSubtasks ? Math.round((completedSubtasks / totalSubtasks) * 100) : 0;

  return (
    <div
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      onMouseDown={handleMouseDown}
      className="relative rounded-2xl h-[120px] w-full overflow-hidden transition-all duration-200 select-none cursor-grab active:cursor-grabbing border shadow-[0_4px_12px_rgba(0,0,0,0.04)]"
      style={{
        transform: `perspective(1000px) rotateX(${tilt.x}deg) rotateY(${tilt.y}deg) scale3d(${isDragging ? 0.98 : 1}, ${isDragging ? 0.98 : 1}, 1)`,
        borderColor: appBorderColor,
        backgroundColor: hasWallpaper ? 'transparent' : appSurfaceColor,
      }}
    >
      {/* Background Layer with Parallax speed offset */}
      {hasWallpaper && (
        <div 
          className="absolute inset-0 w-[110%] h-[110%] -left-[5%] -top-[5%] ease-out bg-cover pointer-events-none"
          style={{
            backgroundImage: `url(${task.wallpaperPath})`,
            backgroundPosition: `center ${50 + (task.wallpaperOffsetY !== undefined ? task.wallpaperOffsetY : (task.customFields?.wallpaperOffsetY !== undefined ? task.customFields.wallpaperOffsetY : 0.0)) * 50}%`,
            transform: `translate3d(${tilt.y * 0.4}px, ${-tilt.x * 0.4}px, 0)`,
          }}
        />
      )}

      {/* Scrim Overlay for Contrast legibility */}
      <div 
        className="absolute inset-0 pointer-events-none"
        style={{
          background: hasWallpaper 
            ? 'linear-gradient(to top, rgba(0,0,0,0.85) 0%, rgba(0,0,0,0.3) 65%, rgba(0,0,0,0.15) 100%)'
            : 'transparent'
        }}
      />

      {/* Content Layer with dynamic contrast matching */}
      <div 
        className="absolute inset-0 p-3.5 flex flex-col justify-between"
        style={{
          transform: `translate3d(${tilt.y * 0.3}px, ${-tilt.x * 0.3}px, 0)`,
          color: hasWallpaper ? '#ffffff' : appTextColor,
        }}
      >
        <div className="flex items-start justify-between gap-2">
          <div className="flex items-start gap-2.5">
            <button 
              onMouseDown={(e) => e.stopPropagation()} 
              onClick={(e) => {
                e.stopPropagation();
                onToggle();
              }}
              className="w-5.5 h-5.5 rounded-full border-2 flex items-center justify-center shrink-0 mt-0.5 transition-all bg-white/5 active:scale-90"
              style={{ 
                borderColor: hasWallpaper ? 'rgba(255,255,255,0.7)' : appBorderColor,
              }}
            >
              <div className="w-2.5 h-2.5 rounded-full bg-transparent hover:bg-white/40"></div>
            </button>
            <div className="flex-1 pr-1">
              <h3 className="font-bold text-sm leading-tight line-clamp-2">
                {task.title}
              </h3>
              {task.notes && (
                <p 
                  className="text-[11px] mt-0.5 line-clamp-1 opacity-80"
                  style={{ color: hasWallpaper ? '#f3f4f6' : appTextMutedColor }}
                >
                  {task.notes}
                </p>
              )}
            </div>
          </div>

          <div className="flex items-center gap-1.5 shrink-0" onMouseDown={(e) => e.stopPropagation()}>
            {task.soundPath && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onPlaySound();
                }}
                className="p-1 rounded-full hover:bg-white/20 transition-all text-current active:scale-95"
                title="Play Audio Notification Preview"
              >
                <Volume2 className="w-3.5 h-3.5 text-current animate-pulse" />
              </button>
            )}
            <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: getPriorityColor(task.priority) }}></span>
          </div>
        </div>

        <div className="flex items-center justify-between mt-2 pt-1.5 border-t" style={{ borderColor: hasWallpaper ? 'rgba(255,255,255,0.1)' : appBorderColor }}>
          <div className="flex gap-1">
            {task.categoryIds.map(catId => {
              const cat = categories.find(c => c.id === catId);
              return (
                <span 
                  key={catId} 
                  className="text-[9px] px-2 py-0.5 rounded-full font-semibold uppercase tracking-wider"
                  style={{ 
                    backgroundColor: hasWallpaper ? 'rgba(255,255,255,0.15)' : appBorderColor, 
                    color: hasWallpaper ? '#ffffff' : appTextMutedColor,
                    border: hasWallpaper ? '1px solid rgba(255,255,255,0.1)' : 'none'
                  }}
                >
                  {cat ? cat.name : catId}
                </span>
              );
            })}
          </div>

          {/* Subtask interactive mini-progress bar */}
          {hasSubtasks && (
            <div className="flex items-center gap-1.5 ml-auto mr-3">
              <span className="text-[8px] font-bold opacity-80">{completedSubtasks}/{totalSubtasks}</span>
              <div className="w-10 h-1 bg-current/20 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-current transition-all duration-300" 
                  style={{ 
                    width: `${progressPct}%`, 
                    backgroundColor: hasWallpaper ? '#22c55e' : appPrimaryColor 
                  }}
                />
              </div>
            </div>
          )}

          {task.dueDate && (
            <span className="text-[9px] font-bold opacity-80 flex items-center gap-1 shrink-0">
              <Calendar className="w-3 h-3" />
              {task.dueDate}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

// Design specification constants extracted directly from the Stitch designs
const DESIGN_SPEC = {
  name: "Flow Design System",
  colors: {
    primary: "#0058be",
    background: "#f8f9fa",
    surface: "#f8f9fa",
    onSurface: "#191c1d",
    onSurfaceVariant: "#424754",
    outline: "#727785",
    outlineVariant: "#c2c6d6",
    surfaceContainerLowest: "#ffffff",
    surfaceContainerLow: "#f3f4f5",
    surfaceContainer: "#edeeef",
    surfaceContainerHigh: "#e7e8e9",
    surfaceContainerHighest: "#e1e3e4",
    primaryContainer: "#2170e4",
    onPrimaryContainer: "#fefcff",
    onPrimary: "#ffffff",
    secondaryContainer: "#b6ccff",
    onSecondaryContainer: "#405682",
    tertiary: "#924700",
    tertiaryContainer: "#b75b00",
    onTertiaryContainer: "#fffbff",
    error: "#ba1a1a",
    errorContainer: "#ffdad6",
  },
  presets: [
    { name: "Flow (Default)", id: "flow_default", primary: "#0058be", bg: "#f8f9fa", text: "#191c1d", isDark: false },
    { name: "Nordic Blue", id: "nordic_blue", primary: "#4338CA", bg: "#E0E7FF", text: "#1E3A8A", isDark: false },
    { name: "Forest", id: "forest", primary: "#15803D", bg: "#F0FDF4", text: "#14532D", isDark: false },
    { name: "Sunset", id: "sunset", primary: "#EA580C", bg: "#FFF7ED", text: "#7C2D12", isDark: false },
    { name: "Deep Night", id: "deep_night", primary: "#818CF8", bg: "#111827", text: "#F9FAFB", isDark: true }
  ]
};

export default function App() {
  // Database Initialized flag simulation
  const [dbInitialized, setDbInitialized] = useState<boolean>(true);
  const [copiedText, setCopiedText] = useState<string | null>(null);

  // Core application states
  const [tasks, setTasks] = useState<Task[]>([
    {
      id: '1',
      title: 'Review project proposal',
      notes: 'Read pages 4-12 and write feedback before meeting',
      priority: 2, // High
      isCompleted: false,
      categoryIds: ['work', 'strategy'],
      subtasks: [
        { id: '1-1', title: 'Read executive summary', isDone: true },
        { id: '1-2', title: 'Highlight constraints', isDone: false },
      ],
      createdAt: '2026-07-01T00:00:00Z',
      updatedAt: '2026-07-01T00:00:00Z',
      kanbanStatus: 'todo',
      dueDate: 'Today',
      wallpaperPath: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&auto=format&fit=crop&q=60',
      soundPath: 'Marimba'
    },
    {
      id: '2',
      title: 'Buy groceries',
      notes: 'Fruits, milk, eggs, whole wheat bread',
      priority: 0, // Low
      isCompleted: false,
      categoryIds: ['personal'],
      subtasks: [
        { id: '2-1', title: 'Organic bananas', isDone: true },
        { id: '2-2', title: 'Almond milk', isDone: true },
        { id: '2-3', title: 'Greek yogurt', isDone: false },
        { id: '2-4', title: 'Avocados', isDone: false },
        { id: '2-5', title: 'Fresh spinach', isDone: false }
      ],
      createdAt: '2026-07-01T01:00:00Z',
      updatedAt: '2026-07-01T01:00:00Z',
      kanbanStatus: 'todo',
      dueDate: 'Low Priority'
    },
    {
      id: '3',
      title: 'Morning yoga',
      notes: '15 mins stretch and core routine',
      priority: 1, // Medium
      isCompleted: true,
      categoryIds: ['health'],
      subtasks: [],
      createdAt: '2026-06-30T07:00:00Z',
      updatedAt: '2026-06-30T07:15:00Z',
      kanbanStatus: 'done'
    },
    {
      id: '4',
      title: 'Call mom',
      notes: 'Catch up and discuss weekend dinner plans',
      priority: 1, // Medium
      isCompleted: false,
      categoryIds: [],
      subtasks: [],
      createdAt: '2026-07-01T02:00:00Z',
      updatedAt: '2026-07-01T02:00:00Z',
      kanbanStatus: 'todo',
      dueDate: 'Tomorrow'
    },
    {
      id: '5',
      title: 'Finalize Q4 Marketing Deck',
      notes: 'Review slides 12-15 and update metrics from last month',
      priority: 3, // Critical
      isCompleted: false,
      categoryIds: ['work', 'presentation'],
      subtasks: [
        { id: '5-1', title: 'Update metrics', isDone: true },
        { id: '5-2', title: 'Export PDF', isDone: true },
        { id: '5-3', title: 'Send draft link', isDone: false }
      ],
      createdAt: '2026-07-01T02:30:00Z',
      updatedAt: '2026-07-01T02:30:00Z',
      kanbanStatus: 'todo',
      dueDate: 'Today, 2:00 PM',
      wallpaperPath: 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?w=400&auto=format&fit=crop&q=60',
      soundPath: 'Bell'
    },
    {
      id: '6',
      title: 'Weekly Team Sync',
      notes: '14:00 - 15:00 Google Meet',
      priority: 1, // Medium
      isCompleted: false,
      categoryIds: ['meeting'],
      subtasks: [],
      createdAt: '2026-07-01T02:40:00Z',
      updatedAt: '2026-07-01T02:40:00Z',
      kanbanStatus: 'in_progress',
      dueDate: '14:00 - 15:00'
    }
  ]);

  const [categories, setCategories] = useState<Category[]>([
    { id: 'work', name: 'Work', colorValue: '#0058be' },
    { id: 'personal', name: 'Personal', colorValue: '#495e8a' },
    { id: 'strategy', name: 'Strategy', colorValue: '#924700' },
    { id: 'health', name: 'Health', colorValue: '#059669' },
    { id: 'meeting', name: 'Meeting', colorValue: '#7c3aed' },
    { id: 'presentation', name: 'Presentation', colorValue: '#ea580c' }
  ]);

  // Simulated visual preference state
  const [themeConfig, setThemeConfig] = useState<ThemeConfig>({
    id: 'flow_default',
    name: 'Flow (Default)',
    primaryColor: '#0058be',
    backgroundColor: '#f8f9fa',
    fontFamily: 'Inter',
    densityScale: 2, // Comfortable
    isDark: false
  });

  const [settings, setSettings] = useState<SettingsState>({
    showPriorityIndicator: true,
    showNotesPreview: true,
    showDueTime: true,
    showSubtaskProgress: true,
    swipeRight: 'Complete',
    swipeLeft: 'Delete',
    dailyReminders: true,
    smartSuggestions: true,
    notificationsEnabled: true,
    defaultSortOrder: 'dueDate',
    themeMode: 'system'
  });

  // Simulator navigation state
  const [selectedView, setSelectedView] = useState<'list' | 'kanban' | 'calendar' | 'new_task' | 'settings' | 'appearance'>('list');
  const [activeDetailTaskId, setActiveDetailTaskId] = useState<string | null>(null);

  // Detail task drawer state hoisted to top-level to avoid Hook ordering violations
  const [newSubtaskText, setNewSubtaskText] = useState('');

  // Reset the drawer input field when active task details changes
  useEffect(() => {
    setNewSubtaskText('');
  }, [activeDetailTaskId]);

  // Persistent storage synchronization
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    const storedTasks = localStorage.getItem('flow_tasks');
    const storedCategories = localStorage.getItem('flow_categories');
    const storedTheme = localStorage.getItem('flow_themeConfig');
    const storedSettings = localStorage.getItem('flow_settings');

    if (storedTasks) {
      try { setTasks(JSON.parse(storedTasks)); } catch (e) { console.error(e); }
    }
    if (storedCategories) {
      try { setCategories(JSON.parse(storedCategories)); } catch (e) { console.error(e); }
    }
    if (storedTheme) {
      try { setThemeConfig(JSON.parse(storedTheme)); } catch (e) { console.error(e); }
    }
    if (storedSettings) {
      try { setSettings(JSON.parse(storedSettings)); } catch (e) { console.error(e); }
    }
    setIsMounted(true);
  }, []);

  useEffect(() => {
    if (isMounted) {
      localStorage.setItem('flow_tasks', JSON.stringify(tasks));
    }
  }, [tasks, isMounted]);

  useEffect(() => {
    if (isMounted) {
      localStorage.setItem('flow_categories', JSON.stringify(categories));
    }
  }, [categories, isMounted]);

  useEffect(() => {
    if (isMounted) {
      localStorage.setItem('flow_themeConfig', JSON.stringify(themeConfig));
    }
  }, [themeConfig, isMounted]);

  useEffect(() => {
    if (isMounted) {
      localStorage.setItem('flow_settings', JSON.stringify(settings));
    }
  }, [settings, isMounted]);

  const [activeKanbanCol, setActiveKanbanCol] = useState<'todo' | 'in_progress' | 'done'>('todo');

  // Search / Filter / Sort reactive state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [sortBy, setSortBy] = useState<'dueDate' | 'priority' | 'alphabetical' | 'createdDate'>('dueDate');

  // Import / Export states
  const [pendingImport, setPendingImport] = useState<{ tasks: Task[], categories: Category[], themeConfig: ThemeConfig, settings: SettingsState } | null>(null);
  const [importError, setImportError] = useState<string | null>(null);

  // Mode states for image/sound uploads
  const [bannerWpMode, setBannerWpMode] = useState<'preloaded' | 'upload' | 'url'>('preloaded');
  const [bannerSoundMode, setBannerSoundMode] = useState<'preset' | 'upload'>('preset');
  const [globalWpMode, setGlobalWpMode] = useState<'preloaded' | 'upload' | 'url'>('preloaded');

  // Code explorer state
  const [activeCodeTab, setActiveCodeTab] = useState<'pubspec' | 'main' | 'app' | 'theme' | 'db' | 'task' | 'subtask' | 'recurrence' | 'category'>('pubspec');

  // New task creation state helper
  const [taskForm, setTaskForm] = useState<{
    title: string;
    notes: string;
    priority: PriorityLevel;
    dueDate: string;
    categoryIds: string[];
    subtasks: { title: string; isDone: boolean }[];
    tempSubtask: string;
    wallpaperPath?: string;
    soundPath?: string;
    wallpaperOffsetY?: number;
  }>({
    title: '',
    notes: '',
    priority: 1, // High (matching Stitch default screenshot)
    dueDate: 'Today, 2:00 PM',
    categoryIds: ['work'],
    subtasks: [
      { title: 'Draft initial outline', isDone: false },
      { title: 'Review with team', isDone: false }
    ],
    tempSubtask: '',
    wallpaperPath: undefined,
    soundPath: undefined,
    wallpaperOffsetY: 0.0
  });

  const handleApplyPreset = (preset: typeof DESIGN_SPEC.presets[0]) => {
    setThemeConfig({
      ...themeConfig,
      id: preset.id,
      name: preset.name,
      primaryColor: preset.primary,
      backgroundColor: preset.bg,
      isDark: preset.isDark
    });
  };

  const handleExportData = () => {
    const backupData = {
      version: '1.0.0',
      tasks,
      categories,
      themeConfig,
      settings
    };
    const jsonString = `data:text/json;charset=utf-8,${encodeURIComponent(
      JSON.stringify(backupData, null, 2)
    )}`;
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute('href', jsonString);
    downloadAnchor.setAttribute('download', `flow_todo_backup_${new Date().toISOString().slice(0, 10)}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  const handleImportFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;
    const file = files[0];
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const text = event.target?.result as string;
        const parsed = JSON.parse(text);
        
        // Basic schema validation
        if (
          !parsed || 
          typeof parsed !== 'object' || 
          !Array.isArray(parsed.tasks) || 
          !Array.isArray(parsed.categories) || 
          !parsed.themeConfig || 
          !parsed.settings
        ) {
          setImportError('Invalid JSON Schema. Make sure this file was exported from Flow Todo.');
          return;
        }

        // Prepare import summary
        setPendingImport({
          tasks: parsed.tasks,
          categories: parsed.categories,
          themeConfig: parsed.themeConfig,
          settings: parsed.settings
        });
        setImportError(null);
      } catch (err) {
        setImportError('Failed to parse file. Corrupt or invalid JSON file.');
      }
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  const handleCommitImport = () => {
    if (!pendingImport) return;
    setTasks(pendingImport.tasks);
    setCategories(pendingImport.categories);
    setThemeConfig(pendingImport.themeConfig);
    setSettings(pendingImport.settings);
    setPendingImport(null);
  };

  const handleAddSubtask = () => {
    if (!taskForm.tempSubtask.trim()) return;
    setTaskForm({
      ...taskForm,
      subtasks: [...taskForm.subtasks, { title: taskForm.tempSubtask, isDone: false }],
      tempSubtask: ''
    });
  };

  const handleRemoveSubtask = (index: number) => {
    setTaskForm({
      ...taskForm,
      subtasks: taskForm.subtasks.filter((_, i) => i !== index)
    });
  };

  const handleSaveTask = () => {
    if (!taskForm.title.trim()) return;
    const newTaskObj: Task = {
      id: String(Date.now()),
      title: taskForm.title,
      notes: taskForm.notes || undefined,
      priority: taskForm.priority,
      isCompleted: false,
      categoryIds: taskForm.categoryIds,
      subtasks: taskForm.subtasks.map((s, idx) => ({ id: `${Date.now()}-${idx}`, title: s.title, isDone: s.isDone })),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      kanbanStatus: 'todo',
      dueDate: taskForm.dueDate || undefined,
      wallpaperPath: taskForm.wallpaperPath,
      soundPath: taskForm.soundPath,
      wallpaperOffsetY: taskForm.wallpaperOffsetY,
      customFields: taskForm.wallpaperPath ? { wallpaperOffsetY: taskForm.wallpaperOffsetY } : undefined
    };

    setTasks([newTaskObj, ...tasks]);
    setSelectedView('list');
    // Reset form
    setTaskForm({
      title: '',
      notes: '',
      priority: 1,
      dueDate: 'Today, 2:00 PM',
      categoryIds: ['work'],
      subtasks: [
        { title: 'Draft initial outline', isDone: false },
        { title: 'Review with team', isDone: false }
      ],
      tempSubtask: '',
      wallpaperPath: undefined,
      soundPath: undefined,
      wallpaperOffsetY: 0.0
    });
  };

  const toggleTaskCompleted = (id: string) => {
    setTasks(tasks.map(t => {
      if (t.id === id) {
        return { ...t, isCompleted: !t.isCompleted };
      }
      return t;
    }));
  };

  const toggleSubtaskDone = (taskId: string, subtaskId: string) => {
    setTasks(tasks.map(t => {
      if (t.id === taskId) {
        return {
          ...t,
          subtasks: t.subtasks.map(s => s.id === subtaskId ? { ...s, isDone: !s.isDone } : s)
        };
      }
      return t;
    }));
  };

  const moveKanban = (id: string, dir: 'left' | 'right') => {
    setTasks(tasks.map(t => {
      if (t.id === id) {
        let nextStatus: 'todo' | 'in_progress' | 'done' = t.kanbanStatus;
        if (t.kanbanStatus === 'todo' && dir === 'right') nextStatus = 'in_progress';
        else if (t.kanbanStatus === 'in_progress' && dir === 'right') nextStatus = 'done';
        else if (t.kanbanStatus === 'in_progress' && dir === 'left') nextStatus = 'todo';
        else if (t.kanbanStatus === 'done' && dir === 'left') nextStatus = 'in_progress';
        return { ...t, kanbanStatus: nextStatus };
      }
      return t;
    }));
  };

  const handleCopyCode = (code: string, tabName: string) => {
    navigator.clipboard.writeText(code);
    setCopiedText(tabName);
    setTimeout(() => setCopiedText(null), 2000);
  };

  // Maps active code tabs to actual contents
  const getCodeContent = () => {
    switch (activeCodeTab) {
      case 'pubspec': return pubspecTemplate;
      case 'main': return mainTemplate;
      case 'app': return appTemplate;
      case 'theme': return themeTemplate;
      case 'db': return dbTemplate;
      case 'task': return taskTemplate;
      case 'subtask': return subtaskTemplate;
      case 'recurrence': return recurrenceTemplate;
      case 'category': return categoryTemplate;
      default: return pubspecTemplate;
    }
  };

  const getCodePath = () => {
    switch (activeCodeTab) {
      case 'pubspec': return 'pubspec.yaml';
      case 'main': return 'lib/main.dart';
      case 'app': return 'lib/app.dart';
      case 'theme': return 'lib/core/theme/theme_config.dart';
      case 'db': return 'lib/core/db/app_database.dart';
      case 'task': return 'lib/features/tasks/models/task.dart';
      case 'subtask': return 'lib/features/tasks/models/subtask.dart';
      case 'recurrence': return 'lib/features/tasks/models/recurrence_rule.dart';
      case 'category': return 'lib/features/categories/models/category.dart';
    }
  };

  const getPriorityColor = (level: PriorityLevel) => {
    switch (level) {
      case 3: return '#ba1a1a'; // Critical
      case 2: return '#ea580c'; // High / Orange-Brown
      case 1: return '#495e8a'; // Medium / Muted Slate
      case 0: return '#727785'; // Low / Gray
    }
  };

  const getPriorityLabel = (level: PriorityLevel) => {
    switch (level) {
      case 3: return 'Critical';
      case 2: return 'High';
      case 1: return 'Medium';
      case 0: return 'Low';
    }
  };

  // Apply visual settings from themeConfig dynamically
  const appPrimaryColor = themeConfig.primaryColor;
  const appBgColor = themeConfig.isDark ? '#111827' : themeConfig.backgroundColor;
  const appSurfaceColor = themeConfig.isDark ? '#1f2937' : '#ffffff';
  const appTextColor = themeConfig.isDark ? '#f9fafb' : '#191c1d';
  const appTextMutedColor = themeConfig.isDark ? '#9ca3af' : '#424754';
  const appBorderColor = themeConfig.isDark ? '#374151' : '#edeeef';

  // Dynamic reactive search, filter, and sort logic
  const filteredAndSortedActiveTasks = tasks
    .filter(t => !t.isCompleted)
    .filter(t => {
      const matchesSearch = !searchQuery.trim() || 
        t.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
        (t.notes && t.notes.toLowerCase().includes(searchQuery.toLowerCase()));
      const matchesCategory = !selectedCategory || t.categoryIds.includes(selectedCategory);
      return matchesSearch && matchesCategory;
    })
    .sort((a, b) => {
      const effectiveSortBy = sortBy || settings.defaultSortOrder || 'dueDate';
      if (effectiveSortBy === 'dueDate') {
        const dateA = a.dueDate ? new Date(a.dueDate).getTime() : Infinity;
        const dateB = b.dueDate ? new Date(b.dueDate).getTime() : Infinity;
        if (isNaN(dateA) && isNaN(dateB)) {
          return (a.dueDate || '').localeCompare(b.dueDate || '');
        }
        if (dateA !== dateB) return dateA - dateB;
      } else if (effectiveSortBy === 'priority') {
        if (a.priority !== b.priority) return b.priority - a.priority;
      } else if (effectiveSortBy === 'alphabetical') {
        return a.title.localeCompare(b.title);
      } else if (effectiveSortBy === 'createdDate') {
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      }
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });

  const filteredAndSortedCompletedTasks = tasks
    .filter(t => t.isCompleted)
    .filter(t => {
      const matchesSearch = !searchQuery.trim() || 
        t.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
        (t.notes && t.notes.toLowerCase().includes(searchQuery.toLowerCase()));
      const matchesCategory = !selectedCategory || t.categoryIds.includes(selectedCategory);
      return matchesSearch && matchesCategory;
    });

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 font-sans selection:bg-blue-600 selection:text-white flex flex-col">
      
      {/* Top Banner & Title Panel */}
      <header className="border-b border-slate-800 bg-slate-950/70 backdrop-blur px-6 py-4 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center shadow-lg shadow-blue-500/20">
              <Sparkles className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="font-display text-xl font-bold tracking-tight">Flow Workspace</h1>
              <p className="text-xs text-slate-400">Phase 1 Flutter Todo Scaffold &amp; Stitch Design Verification</p>
            </div>
          </div>
          
          <div className="flex flex-wrap items-center gap-2">
            <div className="flex items-center gap-1.5 px-3 py-1 bg-emerald-950/50 border border-emerald-500/30 rounded-full">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              <span className="text-xs font-mono text-emerald-300">Database Active (Isar v3)</span>
            </div>
            <button
              onClick={() => setDbInitialized(!dbInitialized)}
              className={`text-xs px-3 py-1.5 rounded-lg border font-medium flex items-center gap-1 transition-colors ${
                dbInitialized 
                  ? 'bg-slate-800 border-slate-700 hover:bg-slate-700' 
                  : 'bg-amber-950 border-amber-500/30 text-amber-300 hover:bg-amber-900/60'
              }`}
            >
              <RotateCcw className="w-3.5 h-3.5" />
              {dbInitialized ? "Simulate Reboot" : "Seed Default Isar Theme"}
            </button>
          </div>
        </div>
      </header>

      {/* Main Dual-Panel Layout */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 lg:p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Left Column: Stitch Phone Simulator (Span 5) */}
        <section className="lg:col-span-5 flex flex-col items-center">
          
          {/* Section Header */}
          <div className="w-full flex items-center justify-between mb-3 px-1">
            <div className="flex items-center gap-2">
              <Smartphone className="w-5 h-5 text-blue-400" />
              <h2 className="text-sm font-semibold uppercase tracking-wider text-slate-400">Interactive Phone Screen</h2>
            </div>
            <div className="flex items-center gap-1 bg-slate-800/80 p-1 rounded-lg">
              {(['list', 'kanban', 'calendar', 'settings', 'appearance'] as const).map((view) => (
                <button
                  key={view}
                  onClick={() => setSelectedView(view)}
                  className={`text-xs px-1.5 py-1 rounded-md font-medium capitalize transition-all ${
                    selectedView === view 
                      ? 'bg-blue-600 text-white shadow-sm' 
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {view === 'list' ? 'List' : view === 'kanban' ? 'Kanban' : view === 'calendar' ? 'Cal' : view === 'appearance' ? 'Style' : 'Set'}
                </button>
              ))}
            </div>
          </div>

          {/* Clean Phone Border Mockup */}
          <div className="relative w-full max-w-[370px] aspect-[9/19] rounded-[42px] border-8 border-slate-950 bg-slate-950 shadow-2xl overflow-hidden ring-4 ring-slate-800 flex flex-col">
            
            {/* Phone Speaker Notch */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-5 bg-slate-950 rounded-b-2xl z-50 flex justify-center items-center">
              <div className="w-10 h-1 bg-slate-800 rounded-full"></div>
            </div>

            {/* Simulated App Frame Container */}
            <div 
              className={`flex-1 flex flex-col overflow-hidden relative transition-all duration-300 select-none z-0 ${themeConfig.isDark ? 'dark' : ''}`}
              style={{ 
                backgroundColor: themeConfig.appWallpaperPath ? 'transparent' : appBgColor, 
                color: appTextColor,
                fontFamily: themeConfig.fontFamily === 'Inter' ? 'Inter, sans-serif' : 'serif'
              }}
            >
              {/* Global App Background Wallpaper Layer */}
              {themeConfig.appWallpaperPath && (
                <div 
                  className="absolute inset-0 bg-cover bg-center -z-20 transition-all duration-500 scale-105"
                  style={{ backgroundImage: `url(${themeConfig.appWallpaperPath})` }}
                />
              )}
              {/* Blur and contrast matching scrim overlay */}
              {themeConfig.appWallpaperPath && (
                <div 
                  className="absolute inset-0 bg-white/45 dark:bg-slate-900/60 backdrop-blur-[2px] -z-10"
                />
              )}
              
              {/* App Status Bar spacer */}
              <div className="h-7 w-full shrink-0 flex justify-between items-center px-6 pt-1 text-[11px] font-bold z-10" style={{ color: appTextColor }}>
                <span>9:41</span>
                <div className="flex items-center gap-1.5">
                  <span>LTE</span>
                  <div className="w-5 h-2.5 border rounded-sm p-0.5 flex items-center" style={{ borderColor: appTextColor }}>
                    <div className="w-3.5 h-full bg-current rounded-2xs"></div>
                  </div>
                </div>
              </div>

              {/* View Rendering Logic */}

              {/* VIEW 1: TASK LIST */}
              {selectedView === 'list' && (
                <div className="flex-grow flex flex-col overflow-hidden">
                  {/* Top Bar */}
                  <header className="px-5 py-2 flex justify-between items-center shrink-0">
                    <button className="p-2 rounded-full hover:bg-slate-100/10 transition" style={{ color: appPrimaryColor }}>
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M3 4h13M3 8h9m-9 4h6m4 0l4-4m0 0l4 4m-4-4v12"></path></svg>
                    </button>
                    <span className="font-bold text-lg tracking-tight" style={{ color: appPrimaryColor }}>Flow</span>
                    <button onClick={() => setSelectedView('settings')} className="p-2 rounded-full hover:bg-slate-100/10 transition" style={{ color: appPrimaryColor }}>
                      <Settings className="w-5 h-5" />
                    </button>
                  </header>

                  {/* Search and Filters Controls Block */}
                  <div className="px-5 pb-3 shrink-0 space-y-2">
                    {/* Search Input Box */}
                    <div className="relative">
                      <input
                        type="text"
                        placeholder="Search tasks..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full text-xs rounded-xl pl-8 pr-8 py-1.5 focus:outline-none focus:ring-1 transition-all"
                        style={{ 
                          backgroundColor: appSurfaceColor, 
                          borderColor: appBorderColor, 
                          color: appTextColor,
                          borderWidth: '1px'
                        }}
                      />
                      <svg className="absolute left-2.5 top-2 w-3.5 h-3.5 opacity-60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                      </svg>
                      {searchQuery && (
                        <button onClick={() => setSearchQuery('')} className="absolute right-2.5 top-1.5 p-0.5 hover:opacity-80">
                          <X className="w-3 h-3 opacity-60" />
                        </button>
                      )}
                    </div>

                    {/* Filter Category Chips & Sort Dropdown */}
                    <div className="flex items-center justify-between gap-1">
                      {/* Horizontal Category filter chips */}
                      <div className="flex gap-1 overflow-x-auto no-scrollbar py-0.5 flex-1 max-w-[70%]">
                        <button
                          onClick={() => setSelectedCategory(null)}
                          className="text-[10px] font-bold px-2.5 py-1 rounded-full border transition-all whitespace-nowrap"
                          style={{
                            backgroundColor: !selectedCategory ? appPrimaryColor : 'transparent',
                            borderColor: !selectedCategory ? appPrimaryColor : appBorderColor,
                            color: !selectedCategory ? '#ffffff' : appTextColor
                          }}
                        >
                          All
                        </button>
                        {categories.map(cat => {
                          const isSelected = selectedCategory === cat.id;
                          return (
                            <button
                              key={cat.id}
                              onClick={() => setSelectedCategory(isSelected ? null : cat.id)}
                              className="text-[10px] font-bold px-2.5 py-1 rounded-full border transition-all whitespace-nowrap"
                              style={{
                                backgroundColor: isSelected ? appPrimaryColor : 'transparent',
                                borderColor: isSelected ? appPrimaryColor : appBorderColor,
                                color: isSelected ? '#ffffff' : appTextColor
                              }}
                            >
                              {cat.name}
                            </button>
                          );
                        })}
                      </div>

                      {/* Sort Dropdown Selector */}
                      <div className="relative">
                        <select
                          value={sortBy}
                          onChange={(e) => setSortBy(e.target.value as any)}
                          className="text-[10px] font-bold bg-transparent border rounded-lg py-1 px-1.5 focus:outline-none cursor-pointer"
                          style={{ borderColor: appBorderColor, color: appTextColor }}
                        >
                          <option value="dueDate" className="text-black">📅 Due</option>
                          <option value="priority" className="text-black">🔥 Priority</option>
                          <option value="alphabetical" className="text-black">🔤 A-Z</option>
                          <option value="createdDate" className="text-black">🆕 Created</option>
                        </select>
                      </div>
                    </div>
                  </div>

                  {/* Scrollable Tasks */}
                  <div className="flex-grow overflow-y-auto px-5 py-2 space-y-4 no-scrollbar">
                    {/* Active Tasks list */}
                    <div className="space-y-3">
                      {filteredAndSortedActiveTasks.map(task => (
                        <TaskBannerCardReact
                          key={task.id}
                          task={task}
                          onToggle={() => toggleTaskCompleted(task.id)}
                          onPlaySound={() => task.soundPath && playSound(task.soundPath)}
                          getPriorityColor={getPriorityColor}
                          categories={categories}
                          appSurfaceColor={appSurfaceColor}
                          appBorderColor={appBorderColor}
                          appTextColor={appTextColor}
                          appTextMutedColor={appTextMutedColor}
                          appPrimaryColor={appPrimaryColor}
                          onCardClick={() => setActiveDetailTaskId(task.id)}
                        />
                      ))}
                      {filteredAndSortedActiveTasks.length === 0 && (
                        <div className="text-center py-6 text-xs text-slate-400">
                          No active tasks found
                        </div>
                      )}
                    </div>

                    {/* Divider for completed */}
                    <div className="pt-2">
                      <h4 className="text-xs uppercase tracking-wider mb-2 font-semibold" style={{ color: appTextMutedColor }}>Completed</h4>
                      <div className="space-y-2 opacity-50">
                        {filteredAndSortedCompletedTasks.map(task => (
                          <div 
                            key={task.id} 
                            className="rounded-xl p-3 border flex items-center justify-between"
                            style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}
                          >
                            <div className="flex items-center gap-3">
                              <button 
                                onClick={() => toggleTaskCompleted(task.id)}
                                className="w-6 h-6 rounded-full flex items-center justify-center shrink-0 border"
                                style={{ backgroundColor: appPrimaryColor, borderColor: appPrimaryColor }}
                              >
                                <Check className="w-3.5 h-3.5 text-white" />
                              </button>
                              <span className="text-sm font-medium line-through">{task.title}</span>
                            </div>
                          </div>
                        ))}
                        {filteredAndSortedCompletedTasks.length === 0 && (
                          <div className="text-center py-4 text-xs text-slate-400">
                            No completed tasks found
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Add Floating Action Button inside standard bottom row spacer */}
                  <div className="p-4 flex justify-between items-center shrink-0 border-t" style={{ borderColor: appBorderColor, backgroundColor: appSurfaceColor }}>
                    <span className="text-xs font-semibold" style={{ color: appTextColor }}>{filteredAndSortedActiveTasks.length} Tasks Active</span>
                    <button 
                      onClick={() => setSelectedView('new_task')} 
                      className="w-12 h-12 rounded-2xl flex items-center justify-center text-white shadow-md active:scale-95 transition"
                      style={{ backgroundColor: appPrimaryColor }}
                    >
                      <Plus className="w-6 h-6" />
                    </button>
                  </div>
                </div>
              )}

              {/* VIEW 2: KANBAN BOARD */}
              {selectedView === 'kanban' && (
                <div className="flex-1 flex flex-col overflow-hidden">
                  {/* Top Bar */}
                  <header className="px-5 py-3 flex justify-between items-center shrink-0">
                    <span className="font-bold text-lg">Sprint Backlog</span>
                    <button className="text-xs font-semibold flex items-center gap-1 hover:opacity-80" style={{ color: appPrimaryColor }}>
                      <Sliders className="w-3.5 h-3.5" /> Filter
                    </button>
                  </header>

                  {/* Column tabs segmented controller for desktop accessibility and high fidelity */}
                  <div className="mx-5 mb-3 p-1 bg-slate-100/80 dark:bg-slate-800/40 rounded-xl flex items-center justify-between border" style={{ borderColor: appBorderColor }}>
                    {(['todo', 'in_progress', 'done'] as const).map((col) => {
                      const isActive = activeKanbanCol === col;
                      return (
                        <button
                          key={col}
                          onClick={() => {
                            setActiveKanbanCol(col);
                            // Scroll to column smoothly
                            const container = document.getElementById('kanban-columns-container');
                            const column = document.getElementById(`kanban-col-${col}`);
                            if (container && column) {
                              const leftPos = column.offsetLeft - container.offsetLeft - 16;
                              container.scrollTo({ left: leftPos, behavior: 'smooth' });
                            }
                          }}
                          className={`flex-1 text-[11px] font-bold py-1.5 rounded-lg transition-all capitalize ${
                            isActive 
                              ? 'bg-white dark:bg-slate-700 shadow-sm text-slate-800 dark:text-white' 
                              : 'text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
                          }`}
                          style={{ color: isActive ? appPrimaryColor : undefined }}
                        >
                          {col.replace('_', ' ')}
                        </button>
                      );
                    })}
                  </div>

                  {/* Columns Horizontal Grid Scroll */}
                  <div 
                    id="kanban-columns-container"
                    className="flex-grow overflow-x-auto flex gap-4 px-5 py-2 no-scrollbar snap-x snap-mandatory scroll-smooth"
                    onScroll={(e) => {
                      // Throttle column detection
                      const container = e.currentTarget;
                      const scrollLeft = container.scrollLeft;
                      const colWidth = 286; // column width + gap
                      const colIndex = Math.round(scrollLeft / colWidth);
                      const columns: ('todo' | 'in_progress' | 'done')[] = ['todo', 'in_progress', 'done'];
                      if (columns[colIndex] && columns[colIndex] !== activeKanbanCol) {
                        setActiveKanbanCol(columns[colIndex]);
                      }
                    }}
                  >
                    {(['todo', 'in_progress', 'done'] as const).map(col => {
                      const colTasks = tasks.filter(t => t.kanbanStatus === col);
                      return (
                        <div 
                          key={col} 
                          id={`kanban-col-${col}`}
                          className="w-[270px] shrink-0 flex flex-col snap-center max-h-full"
                        >
                          {/* Column Title */}
                          <div className="flex items-center justify-between mb-3 px-1">
                            <div className="flex items-center gap-2">
                              <span className={`w-2.5 h-2.5 rounded-full ${col === 'todo' ? 'bg-slate-400' : col === 'in_progress' ? 'bg-blue-500 animate-pulse' : 'bg-emerald-500'}`}></span>
                              <h3 className="font-bold text-sm capitalize">{col.replace('_', ' ')}</h3>
                              <span className="text-xs px-2 py-0.5 rounded-full font-medium" style={{ backgroundColor: appBorderColor, color: appTextMutedColor }}>{colTasks.length}</span>
                            </div>
                          </div>

                          {/* Column Cards list */}
                          <div className="flex-1 overflow-y-auto space-y-4 pb-4 no-scrollbar">
                            {colTasks.map(task => (
                              <div 
                                key={task.id}
                                className="rounded-2xl p-5 border shadow-[0_4px_12px_rgba(0,0,0,0.03)] flex flex-col gap-2 group relative transition-all"
                                style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}
                              >
                                <div className="flex justify-between items-start gap-2">
                                  <h4 className="font-bold text-base leading-snug pr-2" style={{ color: appTextColor }}>{task.title}</h4>
                                  <span className="w-3 h-3 rounded-full shrink-0 mt-1" style={{ backgroundColor: getPriorityColor(task.priority) }}></span>
                                </div>
                                
                                {task.notes && (
                                  <p className="text-sm mt-1 leading-relaxed" style={{ color: appTextMutedColor }}>{task.notes}</p>
                                )}

                                <div className="flex items-center justify-between mt-3 pt-3 border-t" style={{ borderColor: appBorderColor }}>
                                  <div className="flex gap-1">
                                    {task.categoryIds.map(catId => {
                                      const cat = categories.find(c => c.id === catId);
                                      return (
                                        <span 
                                          key={catId}
                                          className="text-[10px] px-2.5 py-1 rounded-full font-semibold capitalize"
                                          style={{ backgroundColor: appBorderColor, color: appTextMutedColor }}
                                        >
                                          {cat ? cat.name.toLowerCase() : catId}
                                        </span>
                                      );
                                    })}
                                    {task.categoryIds.length === 0 && (
                                      <span 
                                        className="text-[10px] px-2.5 py-1 rounded-full font-semibold capitalize"
                                        style={{ backgroundColor: appBorderColor, color: appTextMutedColor }}
                                      >
                                        general
                                      </span>
                                    )}
                                  </div>
                                  
                                  <div className="flex items-center gap-1">
                                    {col !== 'todo' && (
                                      <button 
                                        onClick={() => moveKanban(task.id, 'left')} 
                                        className="p-1 rounded-lg hover:bg-slate-100/10 text-slate-400 transition"
                                        title="Move back"
                                      >
                                        <ArrowLeft className="w-3.5 h-3.5" />
                                      </button>
                                    )}
                                    {col !== 'done' ? (
                                      <button 
                                        onClick={() => moveKanban(task.id, 'right')} 
                                        className="p-1 rounded-lg hover:bg-slate-100/10 text-slate-400 hover:text-blue-600 transition"
                                        title="Move forward"
                                      >
                                        <ChevronRight className="w-4 h-4" />
                                      </button>
                                    ) : (
                                      <span className="p-1 text-emerald-500">
                                        <Check className="w-4 h-4" />
                                      </span>
                                    )}
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* VIEW 3: CALENDAR */}
              {selectedView === 'calendar' && (
                <div className="flex-1 flex flex-col overflow-hidden">
                  <header className="px-5 py-3 flex justify-between items-center shrink-0">
                    <h2 className="font-bold text-lg">October 2023</h2>
                    <div className="flex gap-1.5">
                      <button className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-slate-200/20"><svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 19l-7-7 7-7"></path></svg></button>
                      <button className="w-7 h-7 flex items-center justify-center rounded-full hover:bg-slate-200/20"><svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M9 5l7 7-7 7"></path></svg></button>
                    </div>
                  </header>

                  {/* Calendar Widget Grid */}
                  <div className="px-4 shrink-0">
                    <div className="rounded-2xl p-4 border" style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}>
                      {/* Weekday labels */}
                      <div className="grid grid-cols-7 text-center gap-1 mb-2 text-[10px] font-bold tracking-wider" style={{ color: appTextMutedColor }}>
                        <span>S</span><span>M</span><span>T</span><span>W</span><span>T</span><span>F</span><span>S</span>
                      </div>
                      
                      {/* Calendar days */}
                      <div className="grid grid-cols-7 gap-x-1 gap-y-2 text-center text-xs font-semibold">
                        {/* Empty grey days */}
                        <span className="py-2 opacity-25">1</span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          2 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full" style={{ backgroundColor: appPrimaryColor }}></span>
                        </span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          3 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-amber-500"></span>
                        </span>
                        <span className="py-2">4</span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          5 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-rose-500"></span>
                        </span>
                        <span className="py-2">6</span><span className="py-2">7</span>
                        
                        <span className="py-2">8</span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          9 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full" style={{ backgroundColor: appPrimaryColor }}></span>
                        </span>
                        
                        {/* Day 10 - Highlighted active day! */}
                        <span className="py-1 flex flex-col items-center justify-center relative">
                          <span className="w-7 h-7 rounded-full flex items-center justify-center text-white font-bold" style={{ backgroundColor: appPrimaryColor }}>10</span>
                        </span>

                        <span className="py-2">11</span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          12 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-amber-500"></span>
                        </span>
                        <span className="py-2">13</span><span className="py-2">14</span>
                        <span className="py-2">15</span><span className="py-2">16</span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          17 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-rose-500"></span>
                        </span>
                        <span className="py-2">18</span><span className="py-2">19</span><span className="py-2">20</span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          21 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full" style={{ backgroundColor: appPrimaryColor }}></span>
                        </span>
                        <span className="py-2">22</span><span className="py-2">23</span><span className="py-2">24</span><span className="py-2">25</span><span className="py-2">26</span><span className="py-2">27</span><span className="py-2">28</span>
                        <span className="py-2">29</span>
                        <span className="py-2 hover:bg-slate-100/10 rounded-full cursor-pointer relative">
                          30 <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-amber-500"></span>
                        </span>
                        <span className="py-2">31</span>
                        <span className="py-2 opacity-25">1</span><span className="py-2 opacity-25">2</span><span className="py-2 opacity-25">3</span><span className="py-2 opacity-25">4</span>
                      </div>
                    </div>
                  </div>

                  {/* Day's Tasks container */}
                  <div className="flex-1 overflow-y-auto px-5 py-4 space-y-3 no-scrollbar mt-2">
                    <div className="flex items-center justify-between mb-1 shrink-0">
                      <span className="text-sm font-bold">Tasks for Oct 10</span>
                      <span className="text-[11px] px-2 py-0.5 rounded-full text-white font-bold" style={{ backgroundColor: appPrimaryColor }}>3 Tasks</span>
                    </div>

                    <div className="space-y-3">
                      {tasks.slice(4, 6).map(task => (
                        <div key={task.id} className="rounded-xl p-3 border shadow-sm flex flex-col gap-2 relative overflow-hidden" style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}>
                          {/* Progress indicator strip */}
                          <div className="absolute top-0 left-0 right-0 h-[3px]" style={{ backgroundColor: appBorderColor }}>
                            <div className="h-full" style={{ backgroundColor: appPrimaryColor, width: task.id === '5' ? '66%' : '30%' }}></div>
                          </div>
                          
                          <div className="flex items-start gap-2.5 mt-1">
                            <span className="w-2.5 h-2.5 rounded-full mt-1.5 shrink-0" style={{ backgroundColor: getPriorityColor(task.priority) }}></span>
                            <div>
                              <h4 className="font-bold text-sm leading-tight">{task.title}</h4>
                              {task.dueDate && <span className="text-[10px] mt-0.5 block" style={{ color: appTextMutedColor }}>{task.dueDate}</span>}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* VIEW 4: ADD TASK DIALOG (CREATOR) */}
              {selectedView === 'new_task' && (
                <div className="flex-1 flex flex-col overflow-hidden bg-white text-slate-950">
                  <header className="px-5 py-3 flex justify-between items-center border-b border-slate-100 shrink-0">
                    <button onClick={() => setSelectedView('list')} className="text-slate-500 text-sm font-semibold">Cancel</button>
                    <span className="font-bold text-base text-slate-800">New Task</span>
                    <button onClick={handleSaveTask} className="font-bold text-base hover:opacity-80" style={{ color: appPrimaryColor }}>Save</button>
                  </header>

                  <div className="flex-1 overflow-y-auto px-5 py-4 space-y-6 no-scrollbar">
                    {/* Input Titles */}
                    <div className="space-y-2">
                      <input 
                        type="text" 
                        placeholder="What needs to be done?"
                        className="w-full border-none p-0 text-xl font-bold placeholder:text-slate-300 focus:ring-0 text-slate-800"
                        value={taskForm.title}
                        onChange={(e) => setTaskForm({ ...taskForm, title: e.target.value })}
                      />
                      <textarea 
                        placeholder="Add notes..."
                        className="w-full border-none p-0 text-sm placeholder:text-slate-300 focus:ring-0 text-slate-500 resize-none"
                        rows={2}
                        value={taskForm.notes}
                        onChange={(e) => setTaskForm({ ...taskForm, notes: e.target.value })}
                      />
                    </div>

                    {/* Details Cards */}
                    <div className="space-y-4">
                      {/* Due date card */}
                      <div className="bg-slate-50 rounded-2xl p-4 flex items-center justify-between border border-slate-100">
                        <div className="flex items-center gap-3 text-slate-700">
                          <Calendar className="w-5 h-5 text-slate-400" />
                          <span className="font-semibold text-sm">Due Date &amp; Time</span>
                        </div>
                        <span className="text-xs px-3 py-1 rounded-full font-bold bg-blue-50 text-blue-600">Today, 2:00 PM</span>
                      </div>

                      {/* Priority choose grid */}
                      <div className="bg-slate-50 rounded-2xl p-4 border border-slate-100">
                        <span className="text-xs text-slate-400 font-bold block mb-3 uppercase tracking-wider">Priority</span>
                        <div className="grid grid-cols-4 gap-2">
                          {([3, 2, 1, 0] as PriorityLevel[]).map(level => {
                            const isSelected = taskForm.priority === level;
                            return (
                              <button 
                                key={level}
                                onClick={() => setTaskForm({ ...taskForm, priority: level })}
                                className={`py-2 px-1 rounded-xl flex flex-col items-center justify-center border text-[11px] font-bold transition-all ${
                                  isSelected 
                                    ? 'bg-blue-50 border-blue-600 text-blue-600 scale-105 shadow-sm' 
                                    : 'bg-white border-slate-200 text-slate-500 hover:bg-slate-100'
                                }`}
                              >
                                <span className="w-3.5 h-3.5 rounded-full mb-1.5" style={{ backgroundColor: getPriorityColor(level) }}></span>
                                {getPriorityLabel(level)}
                              </button>
                            );
                          })}
                        </div>
                      </div>

                      {/* Horizontal Category Tag list select */}
                      <div className="bg-slate-50 rounded-2xl p-4 border border-slate-100">
                        <span className="text-xs text-slate-400 font-bold block mb-2 uppercase tracking-wider">Categories</span>
                        <div className="flex gap-2 overflow-x-auto no-scrollbar py-1">
                          {categories.slice(0, 4).map(cat => {
                            const isSelected = taskForm.categoryIds.includes(cat.id);
                            return (
                              <button
                                key={cat.id}
                                onClick={() => {
                                  const updated = isSelected 
                                    ? taskForm.categoryIds.filter(id => id !== cat.id) 
                                    : [...taskForm.categoryIds, cat.id];
                                  setTaskForm({ ...taskForm, categoryIds: updated });
                                }}
                                className={`px-4 py-1.5 rounded-full text-xs font-bold transition whitespace-nowrap border ${
                                  isSelected 
                                    ? 'bg-blue-600 text-white border-blue-600' 
                                    : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-100'
                                }`}
                              >
                                {cat.name}
                              </button>
                            );
                          })}
                        </div>
                      </div>

                      {/* Subtasks dynamic builder */}
                      <div className="bg-slate-50 rounded-2xl p-4 border border-slate-100 space-y-3">
                        <span className="text-xs text-slate-400 font-bold block uppercase tracking-wider">Subtasks</span>
                        
                        <div className="space-y-2">
                          {taskForm.subtasks.map((sub, idx) => (
                            <div key={idx} className="flex items-center justify-between py-1 border-b border-slate-100">
                              <span className="text-xs text-slate-700 font-medium">{sub.title}</span>
                              <button onClick={() => handleRemoveSubtask(idx)} className="text-slate-400 hover:text-red-500 transition">
                                <X className="w-4 h-4" />
                              </button>
                            </div>
                          ))}
                        </div>

                        <div className="flex gap-2 mt-2">
                          <input 
                            type="text" 
                            placeholder="Add subtask title..."
                            className="flex-1 border border-slate-200 rounded-lg text-xs py-1.5 px-3 focus:outline-none focus:ring-1 focus:ring-blue-600"
                            value={taskForm.tempSubtask}
                            onChange={(e) => setTaskForm({ ...taskForm, tempSubtask: e.target.value })}
                            onKeyDown={(e) => { if (e.key === 'Enter') handleAddSubtask(); }}
                          />
                          <button 
                            onClick={handleAddSubtask}
                            className="text-white text-xs px-3 rounded-lg font-bold hover:opacity-90"
                            style={{ backgroundColor: appPrimaryColor }}
                          >
                            Add
                          </button>
                        </div>
                      </div>

                      {/* Task Banner Wallpaper and Notification Sound picker card */}
                      <div className="bg-slate-50 rounded-2xl p-4 border border-slate-100 space-y-4">
                        <div>
                          <div className="flex justify-between items-center mb-2.5">
                            <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Banner Wallpaper</span>
                            <div className="flex gap-1 bg-slate-200/50 p-0.5 rounded-lg border border-slate-200">
                              <button 
                                type="button"
                                onClick={() => setBannerWpMode('preloaded')}
                                className={`text-[9px] font-bold px-2 py-1 rounded-md transition ${bannerWpMode === 'preloaded' ? 'bg-white shadow-sm text-slate-800' : 'text-slate-500 hover:text-slate-800'}`}
                              >
                                Themes
                              </button>
                              <button 
                                type="button"
                                onClick={() => setBannerWpMode('upload')}
                                className={`text-[9px] font-bold px-2 py-1 rounded-md transition ${bannerWpMode === 'upload' ? 'bg-white shadow-sm text-slate-800' : 'text-slate-500 hover:text-slate-800'}`}
                              >
                                Upload
                              </button>
                              <button 
                                type="button"
                                onClick={() => setBannerWpMode('url')}
                                className={`text-[9px] font-bold px-2 py-1 rounded-md transition ${bannerWpMode === 'url' ? 'bg-white shadow-sm text-slate-800' : 'text-slate-500 hover:text-slate-800'}`}
                              >
                                URL
                              </button>
                            </div>
                          </div>

                          {bannerWpMode === 'preloaded' && (
                            <div className="grid grid-cols-4 gap-2">
                              <button
                                type="button"
                                onClick={() => setTaskForm({ ...taskForm, wallpaperPath: undefined })}
                                className={`py-1.5 px-1 rounded-xl border text-[10px] font-bold transition-all ${
                                  !taskForm.wallpaperPath 
                                    ? 'bg-blue-50 border-blue-600 text-blue-600' 
                                    : 'bg-white border-slate-200 text-slate-500 hover:bg-slate-100'
                                }`}
                              >
                                Standard
                              </button>
                              {[
                                { name: 'Warm', url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&auto=format&fit=crop&q=60' },
                                { name: 'Cosmic', url: 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?w=400&auto=format&fit=crop&q=60' },
                                { name: 'Forest', url: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=400&auto=format&fit=crop&q=60' }
                              ].map(wp => {
                                const isSelected = taskForm.wallpaperPath === wp.url;
                                return (
                                  <button
                                    type="button"
                                    key={wp.name}
                                    onClick={() => setTaskForm({ ...taskForm, wallpaperPath: wp.url })}
                                    className={`py-1.5 px-1 rounded-xl border text-[10px] font-bold bg-cover bg-center text-white transition-all relative overflow-hidden ${
                                      isSelected 
                                        ? 'border-blue-600 ring-2 ring-blue-500/20' 
                                        : 'border-slate-200 hover:scale-105'
                                    }`}
                                    style={{ backgroundImage: `url(${wp.url})` }}
                                  >
                                    <span className="bg-black/40 px-1 rounded">{wp.name}</span>
                                  </button>
                                );
                              })}
                            </div>
                          )}

                          {bannerWpMode === 'upload' && (
                            <div className="space-y-2">
                              <label className="flex flex-col items-center justify-center border-2 border-dashed border-slate-200 rounded-xl p-3 cursor-pointer bg-white hover:bg-slate-50 hover:border-slate-300 transition text-center">
                                <Plus className="w-5 h-5 text-slate-400 mb-1" />
                                <span className="text-[10px] font-semibold text-slate-600">Choose wallpaper image file...</span>
                                <span className="text-[8px] text-slate-400 mt-0.5">Supports PNG, JPG, WebP</span>
                                <input 
                                  type="file" 
                                  accept="image/*" 
                                  className="hidden" 
                                  onChange={(e) => {
                                    const file = e.target.files?.[0];
                                    if (file) {
                                      const reader = new FileReader();
                                      reader.onloadend = () => {
                                        setTaskForm({ ...taskForm, wallpaperPath: reader.result as string });
                                      };
                                      reader.readAsDataURL(file);
                                    }
                                  }}
                                />
                              </label>
                              {taskForm.wallpaperPath?.startsWith('data:image/') && (
                                <div className="flex items-center justify-between bg-white px-2.5 py-1.5 rounded-lg border border-slate-100">
                                  <span className="text-[9px] font-medium text-green-600 flex items-center gap-1">
                                    <Check className="w-3 h-3" /> Custom image uploaded
                                  </span>
                                  <button 
                                    type="button" 
                                    onClick={() => setTaskForm({ ...taskForm, wallpaperPath: undefined })}
                                    className="text-[9px] font-bold text-red-500 hover:underline"
                                  >
                                    Remove
                                  </button>
                                </div>
                              )}
                            </div>
                          )}

                          {bannerWpMode === 'url' && (
                            <input 
                              type="text" 
                              placeholder="Paste custom wallpaper image URL..."
                              className="w-full text-xs border border-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-blue-500 bg-white"
                              value={taskForm.wallpaperPath && !taskForm.wallpaperPath.includes('unsplash.com') && !taskForm.wallpaperPath.startsWith('data:') ? taskForm.wallpaperPath : ''}
                              onChange={(e) => setTaskForm({ ...taskForm, wallpaperPath: e.target.value || undefined })}
                            />
                          )}

                          {taskForm.wallpaperPath && (
                            <div className="mt-4 p-3 bg-white border border-slate-100 rounded-xl space-y-3">
                              <div className="text-xs text-slate-400 font-bold uppercase tracking-wider mb-1">Live Banner Crop Preview</div>
                              
                              <div
                                className="relative rounded-2xl h-[90px] w-full overflow-hidden border border-slate-100 shadow-sm"
                                style={{ backgroundColor: 'transparent' }}
                              >
                                <div 
                                  className="absolute inset-0 w-full h-full bg-cover pointer-events-none"
                                  style={{
                                    backgroundImage: `url(${taskForm.wallpaperPath})`,
                                    backgroundPosition: `center ${50 + (taskForm.wallpaperOffsetY ?? 0.0) * 50}%`,
                                  }}
                                />
                                <div 
                                  className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-black/15 pointer-events-none"
                                />
                                <div className="absolute bottom-3 left-4 text-white">
                                  <h4 className="font-bold text-sm leading-tight">{taskForm.title || "Your Task Title"}</h4>
                                  <p className="text-[10px] opacity-80 mt-0.5">{taskForm.notes || "Live preview notes..."}</p>
                                </div>
                              </div>

                              <div>
                                <div className="flex justify-between items-center text-xs text-slate-500 font-medium">
                                  <span>Vertical Alignment (Crop)</span>
                                  <span className="font-mono text-blue-600 font-bold bg-blue-50 px-1.5 py-0.5 rounded text-[10px]">
                                    {taskForm.wallpaperOffsetY === 0 ? 'Center' : taskForm.wallpaperOffsetY! < 0 ? `Top ${Math.round(Math.abs(taskForm.wallpaperOffsetY!) * 100)}%` : `Bottom ${Math.round(taskForm.wallpaperOffsetY! * 100)}%`}
                                  </span>
                                </div>
                                <div className="flex items-center gap-3 mt-1.5">
                                  <span className="text-[10px] text-slate-400 font-semibold uppercase">Top</span>
                                  <input 
                                    type="range" 
                                    min="-1.0" 
                                    max="1.0" 
                                    step="0.1" 
                                    className="flex-1 accent-blue-600 h-1.5 bg-slate-100 rounded-lg appearance-none cursor-pointer"
                                    value={taskForm.wallpaperOffsetY ?? 0.0}
                                    onChange={(e) => setTaskForm({ ...taskForm, wallpaperOffsetY: parseFloat(e.target.value) })}
                                  />
                                  <span className="text-[10px] text-slate-400 font-semibold uppercase">Bottom</span>
                                </div>
                                <p className="text-[10px] text-slate-400 leading-normal mt-2">
                                  Drag the slider to adjust the vertical alignment of your custom wallpaper image to center the perfect section within the task banner.
                                </p>
                              </div>
                            </div>
                          )}
                        </div>

                        <div className="border-t border-slate-200/60 pt-3">
                          <div className="flex justify-between items-center mb-2.5">
                            <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Custom Sound</span>
                            <div className="flex gap-1 bg-slate-200/50 p-0.5 rounded-lg border border-slate-200">
                              <button 
                                type="button"
                                onClick={() => setBannerSoundMode('preset')}
                                className={`text-[9px] font-bold px-2 py-1 rounded-md transition ${bannerSoundMode === 'preset' ? 'bg-white shadow-sm text-slate-800' : 'text-slate-500 hover:text-slate-800'}`}
                              >
                                Presets
                              </button>
                              <button 
                                type="button"
                                onClick={() => setBannerSoundMode('upload')}
                                className={`text-[9px] font-bold px-2 py-1 rounded-md transition ${bannerSoundMode === 'upload' ? 'bg-white shadow-sm text-slate-800' : 'text-slate-500 hover:text-slate-800'}`}
                              >
                                Upload
                              </button>
                            </div>
                          </div>

                          {bannerSoundMode === 'preset' && (
                            <div className="grid grid-cols-4 gap-2">
                              {[
                                { label: 'None', value: undefined },
                                { label: 'Bell 🔔', value: 'Bell' },
                                { label: 'Digital ⚡', value: 'Digital' },
                                { label: 'Marimba 🎶', value: 'Marimba' }
                              ].map((sound) => {
                                const isSelected = taskForm.soundPath === sound.value;
                                return (
                                  <button
                                    type="button"
                                    key={sound.label}
                                    onClick={() => {
                                      setTaskForm({ ...taskForm, soundPath: sound.value });
                                      if (sound.value) {
                                        playSound(sound.value);
                                      }
                                    }}
                                    className={`py-1.5 px-1 rounded-xl border text-[10px] font-bold transition-all ${
                                      isSelected 
                                        ? 'bg-blue-50 border-blue-600 text-blue-600 scale-105' 
                                        : 'bg-white border-slate-200 text-slate-500 hover:bg-slate-100'
                                    }`}
                                  >
                                    {sound.label}
                                  </button>
                                );
                              })}
                            </div>
                          )}

                          {bannerSoundMode === 'upload' && (
                            <div className="space-y-2">
                              <label className="flex flex-col items-center justify-center border-2 border-dashed border-slate-200 rounded-xl p-3 cursor-pointer bg-white hover:bg-slate-50 hover:border-slate-300 transition text-center">
                                <Plus className="w-5 h-5 text-slate-400 mb-1" />
                                <span className="text-[10px] font-semibold text-slate-600">Choose audio file from device...</span>
                                <span className="text-[8px] text-slate-400 mt-0.5">Supports MP3, WAV, AAC, etc.</span>
                                <input 
                                  type="file" 
                                  accept="audio/*" 
                                  className="hidden" 
                                  onChange={(e) => {
                                    const file = e.target.files?.[0];
                                    if (file) {
                                      const reader = new FileReader();
                                      reader.onloadend = () => {
                                        const result = reader.result as string;
                                        setTaskForm({ ...taskForm, soundPath: result });
                                        // Play uploaded sound preview
                                        playSound(result);
                                      };
                                      reader.readAsDataURL(file);
                                    }
                                  }}
                                />
                              </label>
                              {taskForm.soundPath?.startsWith('data:audio/') && (
                                <div className="flex items-center justify-between bg-white px-2.5 py-1.5 rounded-lg border border-slate-100">
                                  <span className="text-[9px] font-medium text-green-600 flex items-center gap-1">
                                    <Check className="w-3 h-3" /> Custom sound uploaded
                                  </span>
                                  <div className="flex gap-2">
                                    <button
                                      type="button"
                                      onClick={() => taskForm.soundPath && playSound(taskForm.soundPath)}
                                      className="text-[9px] font-bold text-blue-600 hover:underline"
                                    >
                                      Test Play
                                    </button>
                                    <button 
                                      type="button" 
                                      onClick={() => setTaskForm({ ...taskForm, soundPath: undefined })}
                                      className="text-[9px] font-bold text-red-500 hover:underline"
                                    >
                                      Remove
                                    </button>
                                  </div>
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* VIEW 5: SETTINGS */}
              {selectedView === 'settings' && (
                <div 
                  className="flex-grow flex flex-col overflow-hidden"
                  style={{ backgroundColor: themeConfig.appWallpaperPath ? 'transparent' : appBgColor, color: appTextColor }}
                >
                  <header className="px-5 py-3 flex justify-between items-center border-b shrink-0" style={{ borderColor: appBorderColor }}>
                    <button onClick={() => setSelectedView('list')} className="p-1 rounded-full hover:bg-slate-200/10 text-slate-400">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 19l-7-7 7-7"></path></svg>
                    </button>
                    <span className="font-bold text-sm tracking-tight">Settings</span>
                    <div className="w-7 h-7"></div>
                  </header>

                  <div className="flex-grow overflow-y-auto px-4 py-4 space-y-5 no-scrollbar">
                    {/* Appearance card navigates to view */}
                    <div className="space-y-1.5">
                      <span className="text-[10px] uppercase font-bold tracking-wider px-2" style={{ color: appTextMutedColor }}>Appearance</span>
                      <button 
                        onClick={() => setSelectedView('appearance')}
                        className="w-full flex items-center justify-between p-3 rounded-2xl border text-left shadow-sm hover:bg-slate-100/5 transition"
                        style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-blue-500/10 text-blue-500 flex items-center justify-center">
                            <Palette className="w-4 h-4" />
                          </div>
                          <div>
                            <span className="text-xs font-semibold">Themes &amp; Styling</span>
                            <span className="text-[9px] block opacity-60">Accent color, backgrounds, dark mode...</span>
                          </div>
                        </div>
                        <ChevronRight className="w-4 h-4 text-slate-400 font-bold" />
                      </button>
                    </div>

                    {/* System Preferences Section */}
                    <div className="space-y-1.5">
                      <span className="text-[10px] uppercase font-bold tracking-wider px-2" style={{ color: appTextMutedColor }}>System Preferences</span>
                      
                      <div className="rounded-2xl border p-2 space-y-1 shadow-sm" style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}>
                        {/* Toggle Global Notifications */}
                        <div className="flex items-center justify-between p-2">
                          <div className="flex flex-col">
                            <span className="text-xs font-semibold">Global Notifications</span>
                            <span className="text-[9px] opacity-60">Toggle reminder triggers globally</span>
                          </div>
                          <button 
                            onClick={() => setSettings({ ...settings, notificationsEnabled: !settings.notificationsEnabled })}
                            className={`w-9 h-5 rounded-full transition-all relative shrink-0 ${settings.notificationsEnabled ? 'bg-blue-600' : 'bg-slate-400 dark:bg-slate-600'}`}
                          >
                            <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-all ${settings.notificationsEnabled ? 'translate-x-4' : ''}`}></span>
                          </button>
                        </div>

                        {/* Theme Mode Selector */}
                        <div className="flex items-center justify-between p-2 border-t" style={{ borderColor: appBorderColor }}>
                          <div className="flex flex-col">
                            <span className="text-xs font-semibold">Theme Mode</span>
                            <span className="text-[9px] opacity-60">Select visual mode preference</span>
                          </div>
                          <select
                            value={settings.themeMode || 'system'}
                            onChange={(e) => {
                              const mode = e.target.value as 'light' | 'dark' | 'system';
                              let nextIsDark = themeConfig.isDark;
                              if (mode === 'light') nextIsDark = false;
                              else if (mode === 'dark') nextIsDark = true;
                              else if (mode === 'system') {
                                nextIsDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
                              }
                              setSettings({ ...settings, themeMode: mode });
                              setThemeConfig({ ...themeConfig, isDark: nextIsDark });
                            }}
                            className="text-[10px] font-bold bg-transparent border rounded-md py-1 px-1.5 focus:outline-none cursor-pointer"
                            style={{ borderColor: appBorderColor, color: appTextColor }}
                          >
                            <option value="light" className="text-black">☀️ Light</option>
                            <option value="dark" className="text-black">🌙 Dark</option>
                            <option value="system" className="text-black">⚙️ System</option>
                          </select>
                        </div>

                        {/* Default Sort Order Selector */}
                        <div className="flex items-center justify-between p-2 border-t" style={{ borderColor: appBorderColor }}>
                          <div className="flex flex-col">
                            <span className="text-xs font-semibold">Default Sort Order</span>
                            <span className="text-[9px] opacity-60">Initial tasks layout order</span>
                          </div>
                          <select
                            value={settings.defaultSortOrder || 'dueDate'}
                            onChange={(e) => {
                              const order = e.target.value as any;
                              setSettings({ ...settings, defaultSortOrder: order });
                              setSortBy(order);
                            }}
                            className="text-[10px] font-bold bg-transparent border rounded-md py-1 px-1.5 focus:outline-none cursor-pointer"
                            style={{ borderColor: appBorderColor, color: appTextColor }}
                          >
                            <option value="dueDate" className="text-black">📅 Due Date</option>
                            <option value="priority" className="text-black">🔥 Priority</option>
                            <option value="alphabetical" className="text-black">🔤 A-Z</option>
                            <option value="createdDate" className="text-black">🆕 Created</option>
                          </select>
                        </div>
                      </div>
                    </div>

                    {/* Task switches preferences */}
                    <div className="space-y-1.5">
                      <span className="text-[10px] uppercase font-bold tracking-wider px-2" style={{ color: appTextMutedColor }}>Task Display</span>
                      
                      <div className="rounded-2xl border p-2 space-y-1 shadow-sm" style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}>
                        {/* Toggle 1 */}
                        <div className="flex items-center justify-between p-2">
                          <span className="text-xs font-semibold">Show Priority Indicator</span>
                          <button 
                            onClick={() => setSettings({ ...settings, showPriorityIndicator: !settings.showPriorityIndicator })}
                            className={`w-9 h-5 rounded-full transition-all relative shrink-0 ${settings.showPriorityIndicator ? 'bg-blue-600' : 'bg-slate-400 dark:bg-slate-600'}`}
                          >
                            <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-all ${settings.showPriorityIndicator ? 'translate-x-4' : ''}`}></span>
                          </button>
                        </div>

                        {/* Toggle 2 */}
                        <div className="flex items-center justify-between p-2 border-t" style={{ borderColor: appBorderColor }}>
                          <span className="text-xs font-semibold">Show Notes Preview</span>
                          <button 
                            onClick={() => setSettings({ ...settings, showNotesPreview: !settings.showNotesPreview })}
                            className={`w-9 h-5 rounded-full transition-all relative shrink-0 ${settings.showNotesPreview ? 'bg-blue-600' : 'bg-slate-400 dark:bg-slate-600'}`}
                          >
                            <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-all ${settings.showNotesPreview ? 'translate-x-4' : ''}`}></span>
                          </button>
                        </div>

                        {/* Toggle 3 */}
                        <div className="flex items-center justify-between p-2 border-t" style={{ borderColor: appBorderColor }}>
                          <span className="text-xs font-semibold">Show Due Time</span>
                          <button 
                            onClick={() => setSettings({ ...settings, showDueTime: !settings.showDueTime })}
                            className={`w-9 h-5 rounded-full transition-all relative shrink-0 ${settings.showDueTime ? 'bg-blue-600' : 'bg-slate-400 dark:bg-slate-600'}`}
                          >
                            <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-all ${settings.showDueTime ? 'translate-x-4' : ''}`}></span>
                          </button>
                        </div>

                        {/* Toggle 4 */}
                        <div className="flex items-center justify-between p-2 border-t" style={{ borderColor: appBorderColor }}>
                          <span className="text-xs font-semibold">Show Subtask Progress</span>
                          <button 
                            onClick={() => setSettings({ ...settings, showSubtaskProgress: !settings.showSubtaskProgress })}
                            className={`w-9 h-5 rounded-full transition-all relative shrink-0 ${settings.showSubtaskProgress ? 'bg-blue-600' : 'bg-slate-400 dark:bg-slate-600'}`}
                          >
                            <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-all ${settings.showSubtaskProgress ? 'translate-x-4' : ''}`}></span>
                          </button>
                        </div>
                      </div>
                    </div>

                    {/* Data Backup & Restore */}
                    <div className="space-y-1.5">
                      <span className="text-[10px] uppercase font-bold tracking-wider px-2" style={{ color: appTextMutedColor }}>Data Backup &amp; Restore</span>
                      
                      <div className="rounded-2xl border p-3 space-y-3 shadow-sm" style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}>
                        <div className="flex flex-col gap-1">
                          <span className="text-xs font-semibold">Persist App Data</span>
                          <span className="text-[9px] opacity-60">Export and import all Isar task states, styling configurations, and settings presets as JSON files.</span>
                        </div>
                        
                        <div className="flex gap-2">
                          <button 
                            onClick={handleExportData}
                            className="flex-1 text-center py-2 px-3 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-semibold text-xs transition"
                          >
                            Export JSON
                          </button>
                          
                          <button 
                            onClick={() => document.getElementById('backup-import-file-input')?.click()}
                            className="flex-1 text-center py-2 px-3 rounded-xl bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-800 dark:text-white font-semibold text-xs border border-slate-200 dark:border-slate-700 transition"
                          >
                            Import JSON
                          </button>
                        </div>
                        
                        <input 
                          type="file" 
                          id="backup-import-file-input" 
                          accept=".json" 
                          onChange={handleImportFile} 
                          className="hidden" 
                        />
                      </div>
                    </div>

                  </div>
                </div>
              )}

              {/* VIEW 6: APPEARANCE (STYLING CONTROLS) */}
              {selectedView === 'appearance' && (
                <div 
                  className="flex-grow flex flex-col overflow-hidden"
                  style={{ backgroundColor: themeConfig.appWallpaperPath ? 'transparent' : appBgColor, color: appTextColor }}
                >
                  <header className="px-5 py-3 flex justify-between items-center border-b shrink-0" style={{ borderColor: appBorderColor }}>
                    <button onClick={() => setSelectedView('settings')} className="p-1 rounded-full text-slate-400 hover:bg-slate-200/10">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 19l-7-7 7-7"></path></svg>
                    </button>
                    <span className="font-bold text-sm tracking-tight" style={{ color: appTextColor }}>Appearance</span>
                    <button onClick={() => setSelectedView('list')} className="font-bold text-xs" style={{ color: appPrimaryColor }}>Done</button>
                  </header>

                  <div className="flex-grow overflow-y-auto px-4 py-4 space-y-5 no-scrollbar">
                    
                    {/* Theme presets grid list */}
                    <div className="space-y-1.5">
                      <h3 className="text-[10px] font-bold uppercase tracking-wider pl-1" style={{ color: appTextMutedColor }}>Presets</h3>
                      <div className="grid grid-cols-2 gap-3">
                        {DESIGN_SPEC.presets.map((p) => {
                          const isActive = themeConfig.id === p.id;
                          return (
                            <button
                              key={p.id}
                              onClick={() => handleApplyPreset(p)}
                              className="rounded-xl p-3 border text-left flex flex-col justify-between h-20 transition-all"
                              style={{ 
                                backgroundColor: appSurfaceColor, 
                                borderColor: isActive ? appPrimaryColor : appBorderColor,
                                boxShadow: isActive ? `0 0 0 2px ${appPrimaryColor}20` : 'none'
                              }}
                            >
                              <div className="flex items-center justify-between w-full">
                                <span className="font-bold text-sm" style={{ color: p.primary }}>Aa</span>
                                {isActive && <Check className="w-3.5 h-3.5" style={{ color: appPrimaryColor }} />}
                              </div>
                              <span className="text-[10px] font-bold mt-1" style={{ color: appTextMutedColor }}>{p.name}</span>
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    {/* Global App Wallpaper Picker */}
                    <div className="space-y-3 p-3 rounded-2xl border shadow-sm" style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}>
                      <div className="flex justify-between items-center">
                        <h3 className="text-[10px] font-bold uppercase tracking-wider" style={{ color: appTextMutedColor }}>Global Background Wallpaper</h3>
                        <div className="flex gap-1 bg-black/10 dark:bg-white/10 p-0.5 rounded-lg border animate-none" style={{ borderColor: appBorderColor }}>
                          <button 
                            type="button"
                            onClick={() => setGlobalWpMode('preloaded')}
                            className={`text-[8px] font-bold px-2 py-0.5 rounded-md transition ${globalWpMode === 'preloaded' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400 hover:text-slate-200'}`}
                          >
                            Themes
                          </button>
                          <button 
                            type="button"
                            onClick={() => setGlobalWpMode('upload')}
                            className={`text-[8px] font-bold px-2 py-0.5 rounded-md transition ${globalWpMode === 'upload' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400 hover:text-slate-200'}`}
                          >
                            Upload
                          </button>
                          <button 
                            type="button"
                            onClick={() => setGlobalWpMode('url')}
                            className={`text-[8px] font-bold px-2 py-0.5 rounded-md transition ${globalWpMode === 'url' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400 hover:text-slate-200'}`}
                          >
                            URL
                          </button>
                        </div>
                      </div>

                      {globalWpMode === 'preloaded' && (
                        <div className="grid grid-cols-4 gap-2">
                          {/* Clear Wallpaper */}
                          <button
                            type="button"
                            onClick={() => setThemeConfig({ ...themeConfig, appWallpaperPath: undefined })}
                            className="aspect-video rounded-lg border text-[10px] font-bold flex items-center justify-center transition-all"
                            style={{
                              borderColor: !themeConfig.appWallpaperPath ? appPrimaryColor : appBorderColor,
                              backgroundColor: !themeConfig.appWallpaperPath ? `${appPrimaryColor}15` : appSurfaceColor,
                              color: !themeConfig.appWallpaperPath ? appPrimaryColor : appTextColor
                            }}
                          >
                            Solid Bg
                          </button>
                          {[
                            { name: 'Warm', url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&auto=format&fit=crop&q=60' },
                            { name: 'Cosmic', url: 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?w=400&auto=format&fit=crop&q=60' },
                            { name: 'Forest', url: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=400&auto=format&fit=crop&q=60' }
                          ].map((wp) => {
                            const isActive = themeConfig.appWallpaperPath === wp.url;
                            return (
                              <button
                                type="button"
                                key={wp.name}
                                onClick={() => setThemeConfig({ ...themeConfig, appWallpaperPath: wp.url })}
                                className="aspect-video rounded-lg bg-cover bg-center border transition-all relative overflow-hidden"
                                style={{ 
                                  backgroundImage: `url(${wp.url})`,
                                  borderColor: isActive ? appPrimaryColor : appBorderColor,
                                  boxShadow: isActive ? `0 0 0 2px ${appPrimaryColor}20` : 'none'
                                }}
                                title={wp.name}
                              >
                                <span className="absolute bottom-0.5 left-1 text-[8px] font-bold text-white bg-black/50 px-1 rounded">{wp.name}</span>
                              </button>
                            );
                          })}
                        </div>
                      )}

                      {globalWpMode === 'upload' && (
                        <div className="space-y-2">
                          <label 
                            className="flex flex-col items-center justify-center border border-dashed rounded-xl p-2.5 cursor-pointer hover:opacity-95 transition text-center"
                            style={{ backgroundColor: appBgColor, borderColor: appBorderColor }}
                          >
                            <Plus className="w-4 h-4 text-slate-400 mb-0.5" />
                            <span className="text-[10px] font-semibold">Choose global wallpaper file...</span>
                            <span className="text-[8px] text-slate-400 mt-0.5">PNG, JPG, WebP</span>
                            <input 
                              type="file" 
                              accept="image/*" 
                              className="hidden" 
                              onChange={(e) => {
                                const file = e.target.files?.[0];
                                if (file) {
                                  const reader = new FileReader();
                                  reader.onloadend = () => {
                                    setThemeConfig({ ...themeConfig, appWallpaperPath: reader.result as string });
                                  };
                                  reader.readAsDataURL(file);
                                }
                              }}
                            />
                          </label>
                          {themeConfig.appWallpaperPath?.startsWith('data:image/') && (
                            <div className="flex items-center justify-between px-2.5 py-1.5 rounded-lg border text-[10px]" style={{ backgroundColor: appBgColor, borderColor: appBorderColor }}>
                              <span className="font-medium text-green-600 flex items-center gap-1">
                                <Check className="w-3 h-3" /> Custom global wallpaper active
                              </span>
                              <button 
                                type="button" 
                                onClick={() => setThemeConfig({ ...themeConfig, appWallpaperPath: undefined })}
                                className="font-bold text-red-500 hover:underline"
                              >
                                Remove
                              </button>
                            </div>
                          )}
                        </div>
                      )}

                      {globalWpMode === 'url' && (
                        <input 
                          type="text" 
                          placeholder="Paste custom wallpaper image URL..."
                          className="w-full text-xs border rounded-lg px-2.5 py-1.5 focus:outline-none transition"
                          style={{ 
                            backgroundColor: appBgColor, 
                            borderColor: appBorderColor, 
                            color: appTextColor 
                          }}
                          value={themeConfig.appWallpaperPath && !themeConfig.appWallpaperPath.includes('unsplash.com') && !themeConfig.appWallpaperPath.startsWith('data:') ? themeConfig.appWallpaperPath : ''}
                          onChange={(e) => setThemeConfig({ ...themeConfig, appWallpaperPath: e.target.value || undefined })}
                        />
                      )}
                    </div>

                    {/* Custom configurations selector panel */}
                    <div className="space-y-4 p-3 rounded-2xl border shadow-sm" style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor }}>
                      <h3 className="text-[10px] font-bold uppercase tracking-wider" style={{ color: appTextMutedColor }}>Custom Preferences</h3>
                      
                      {/* Primary colors list */}
                      <div className="space-y-1.5">
                        <span className="text-[11px] font-bold block" style={{ color: appTextMutedColor }}>Primary Color</span>
                        <div className="flex gap-2 flex-wrap">
                          {['#0058be', '#059669', '#7c3aed', '#ea580c', '#dc2626'].map((color) => (
                            <button
                              key={color}
                              onClick={() => setThemeConfig({ ...themeConfig, primaryColor: color })}
                              className={`w-7 h-7 rounded-full border transition-all ${themeConfig.primaryColor === color ? 'ring-2 ring-blue-500 ring-offset-2' : 'hover:scale-105'}`}
                              style={{ backgroundColor: color, borderColor: 'rgba(0,0,0,0.1)' }}
                            ></button>
                          ))}
                        </div>
                      </div>

                      {/* Font selector */}
                      <div className="space-y-1.5">
                        <span className="text-[11px] font-bold block" style={{ color: appTextMutedColor }}>Font Family</span>
                        <select 
                          value={themeConfig.fontFamily} 
                          onChange={(e) => setThemeConfig({ ...themeConfig, fontFamily: e.target.value })}
                          className="w-full text-xs rounded-lg border py-1.5 px-2 focus:outline-none"
                          style={{ backgroundColor: appBgColor, borderColor: appBorderColor, color: appTextColor }}
                        >
                          <option value="Inter" className="text-black">Inter (System Default)</option>
                          <option value="Merriweather" className="text-black">Merriweather (Serif)</option>
                        </select>
                      </div>

                      {/* Dark mode toggle */}
                      <div className="flex items-center justify-between pt-2 border-t" style={{ borderColor: appBorderColor }}>
                        <span className="text-xs font-bold" style={{ color: appTextColor }}>Dark Mode</span>
                        <button 
                          onClick={() => setThemeConfig({ ...themeConfig, isDark: !themeConfig.isDark })}
                          className={`w-9 h-5 rounded-full transition-all relative shrink-0 ${themeConfig.isDark ? 'bg-blue-600' : 'bg-slate-400 dark:bg-slate-600'}`}
                        >
                          <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-all ${themeConfig.isDark ? 'translate-x-4' : ''}`}></span>
                        </button>
                      </div>
                    </div>

                    {/* Live Preview mockup task details inside styling options */}
                    <div className="space-y-2 p-3 rounded-2xl border" style={{ backgroundColor: `${appSurfaceColor}50`, borderColor: appBorderColor }}>
                      <h4 className="text-[10px] font-bold uppercase tracking-wider" style={{ color: appTextMutedColor }}>Live Mockup Preview</h4>
                      
                      <div 
                        className="rounded-xl p-3 border transition-all"
                        style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor, color: appTextColor }}
                      >
                        <h5 className="font-bold text-xs">Complete quarterly report</h5>
                        <div className="flex items-center gap-2 mt-2">
                          <span className="text-[9px] px-2 py-0.5 rounded-full font-bold bg-blue-50/10" style={{ color: appPrimaryColor }}>Work</span>
                          <span className="text-[9px] font-bold opacity-60">2/5 Done</span>
                        </div>
                      </div>
                    </div>

                  </div>
                </div>
              )}



              {/* TASK DETAIL BOTTOM DRAWER PANEL */}
              {activeDetailTaskId && (() => {
                const task = tasks.find(t => t.id === activeDetailTaskId);
                if (!task) return null;

                const totalSubtasks = task.subtasks?.length || 0;
                const completedSubtasks = task.subtasks?.filter(s => s.isDone).length || 0;
                const progressPct = totalSubtasks > 0 ? Math.round((completedSubtasks / totalSubtasks) * 100) : 0;

                return (
                  <div className="absolute inset-0 bg-black/60 z-50 flex flex-col justify-end">
                    <div className="absolute inset-0 -z-10" onClick={() => setActiveDetailTaskId(null)} />
                    
                    <div 
                      className="rounded-t-[32px] border-t max-h-[85%] flex flex-col shadow-2xl relative animate-in slide-in-from-bottom duration-300 overflow-hidden"
                      style={{ backgroundColor: appSurfaceColor, borderColor: appBorderColor, color: appTextColor }}
                    >
                      <div className="w-12 h-1 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto my-3 shrink-0" />
                      
                      <div className="px-5 pb-2 flex justify-between items-start shrink-0">
                        <div className="flex-grow pr-4">
                          <input 
                            type="text" 
                            className="font-bold text-base bg-transparent border-b border-transparent hover:border-slate-300 focus:border-blue-500 focus:outline-none w-full py-0.5"
                            value={task.title}
                            onChange={(e) => {
                              const val = e.target.value;
                              setTasks(tasks.map(t => t.id === task.id ? { ...t, title: val, updatedAt: new Date().toISOString() } : t));
                            }}
                          />
                          <p className="text-[10px] opacity-50 mt-0.5 uppercase tracking-wider font-semibold">Interactive Task Control</p>
                        </div>
                        <button 
                          onClick={() => setActiveDetailTaskId(null)}
                          className="w-7 h-7 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500 hover:text-slate-800 dark:hover:text-slate-200 transition shrink-0"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </div>

                      <div className="flex-grow overflow-y-auto px-5 pb-6 space-y-4 no-scrollbar text-[11px]">
                        
                        <div className="space-y-1">
                          <span className="text-[9px] uppercase font-bold tracking-wider opacity-60">Notes / Instructions</span>
                          <textarea
                            placeholder="Add tasks instructions, contexts..."
                            value={task.notes || ''}
                            onChange={(e) => {
                              const val = e.target.value;
                              setTasks(tasks.map(t => t.id === task.id ? { ...t, notes: val || undefined, updatedAt: new Date().toISOString() } : t));
                            }}
                            className="w-full h-14 rounded-xl border p-2 focus:outline-none focus:ring-1 focus:ring-blue-500 leading-relaxed text-[11px]"
                            style={{ backgroundColor: appBgColor, borderColor: appBorderColor }}
                          />
                        </div>

                        <div className="grid grid-cols-2 gap-3">
                          <div className="space-y-1">
                            <span className="text-[9px] uppercase font-bold tracking-wider opacity-60">Priority Level</span>
                            <select
                              value={task.priority}
                              onChange={(e) => {
                                const level = Number(e.target.value) as PriorityLevel;
                                setTasks(tasks.map(t => t.id === task.id ? { ...t, priority: level, updatedAt: new Date().toISOString() } : t));
                              }}
                              className="w-full border rounded-xl py-1.5 px-2 bg-transparent font-semibold focus:outline-none cursor-pointer text-[11px]"
                              style={{ borderColor: appBorderColor }}
                            >
                              <option value="3" className="text-black">🔴 Critical</option>
                              <option value="2" className="text-black">🟠 High</option>
                              <option value="1" className="text-black">🔵 Medium</option>
                              <option value="0" className="text-black">⚪ Low</option>
                            </select>
                          </div>

                          <div className="space-y-1">
                            <span className="text-[9px] uppercase font-bold tracking-wider opacity-60">Due Date Time</span>
                            <input
                              type="text"
                              value={task.dueDate || ''}
                              onChange={(e) => {
                                const val = e.target.value;
                                setTasks(tasks.map(t => t.id === task.id ? { ...t, dueDate: val || undefined, updatedAt: new Date().toISOString() } : t));
                              }}
                              placeholder="e.g. Today, 5:00 PM"
                              className="w-full border rounded-xl py-1.5 px-2 bg-transparent font-semibold focus:outline-none text-[11px]"
                              style={{ borderColor: appBorderColor }}
                            />
                          </div>
                        </div>

                        <div className="space-y-1">
                          <span className="text-[9px] uppercase font-bold tracking-wider opacity-60 font-sans">Category Groups</span>
                          <div className="flex gap-1 flex-wrap">
                            {categories.map(cat => {
                              const isAttached = task.categoryIds.includes(cat.id);
                              return (
                                <button
                                  key={cat.id}
                                  onClick={() => {
                                    const nextCatIds = isAttached 
                                      ? task.categoryIds.filter(id => id !== cat.id)
                                      : [...task.categoryIds, cat.id];
                                    setTasks(tasks.map(t => t.id === task.id ? { ...t, categoryIds: nextCatIds, updatedAt: new Date().toISOString() } : t));
                                  }}
                                  className="text-[9px] font-bold px-2 py-0.5 rounded-full border transition-all"
                                  style={{
                                    backgroundColor: isAttached ? appPrimaryColor : 'transparent',
                                    borderColor: isAttached ? appPrimaryColor : appBorderColor,
                                    color: isAttached ? '#ffffff' : appTextColor
                                  }}
                                >
                                  {cat.name}
                                </button>
                              );
                            })}
                          </div>
                        </div>

                        <div className="space-y-2 border-t pt-2.5" style={{ borderColor: appBorderColor }}>
                          <div className="flex justify-between items-center">
                            <div className="flex items-center gap-1.5">
                              <span className="text-[9px] uppercase font-bold tracking-wider opacity-60">Action Subtasks Checklist</span>
                              {totalSubtasks > 0 && (
                                <span className="text-[8px] font-bold px-1.5 py-0.5 rounded-full bg-blue-100 dark:bg-blue-950 text-blue-600 dark:text-blue-300">
                                  {completedSubtasks}/{totalSubtasks}
                                </span>
                              )}
                            </div>
                          </div>

                          {totalSubtasks > 0 && (
                            <div className="w-full h-1 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                              <div 
                                className="h-full bg-emerald-500 transition-all duration-300"
                                style={{ width: `${progressPct}%` }}
                              />
                            </div>
                          )}

                          <div className="space-y-1.5 max-h-[110px] overflow-y-auto no-scrollbar pr-1">
                            {(task.subtasks || []).map(sub => (
                              <div 
                                key={sub.id} 
                                className="flex items-center justify-between p-1.5 rounded-lg border"
                                style={{ backgroundColor: appBgColor, borderColor: appBorderColor }}
                              >
                                <div className="flex items-center gap-2">
                                  <button
                                    onClick={() => toggleSubtaskDone(task.id, sub.id)}
                                    className="w-3.5 h-3.5 rounded border flex items-center justify-center shrink-0 transition"
                                    style={{
                                      borderColor: sub.isDone ? 'transparent' : appBorderColor,
                                      backgroundColor: sub.isDone ? appPrimaryColor : 'transparent'
                                    }}
                                  >
                                    {sub.isDone && <Check className="w-2.5 h-2.5 text-white stroke-[3px]" />}
                                  </button>
                                  <span className={`text-[10px] font-medium ${sub.isDone ? 'line-through opacity-40' : ''}`}>
                                    {sub.title}
                                  </span>
                                </div>
                                <button
                                  onClick={() => {
                                    setTasks(tasks.map(t => t.id === task.id ? {
                                      ...t,
                                      subtasks: t.subtasks.filter(s => s.id !== sub.id),
                                      updatedAt: new Date().toISOString()
                                    } : t));
                                  }}
                                  className="text-slate-400 hover:text-red-500 p-0.5 shrink-0"
                                >
                                  <Trash2 className="w-3 h-3" />
                                </button>
                              </div>
                            ))}

                            {totalSubtasks === 0 && (
                              <div className="text-center py-3 text-[9px] text-slate-400">
                                No subtasks yet.
                              </div>
                            )}
                          </div>

                          <div className="flex gap-1.5 mt-1.5">
                            <input
                              type="text"
                              placeholder="Manually add item..."
                              value={newSubtaskText}
                              onChange={(e) => setNewSubtaskText(e.target.value)}
                              onKeyDown={(e) => {
                                if (e.key === 'Enter' && newSubtaskText.trim()) {
                                  const text = newSubtaskText.trim();
                                  setNewSubtaskText('');
                                  const newSub = {
                                    id: `${Date.now()}-${Math.random()}`,
                                    title: text,
                                    isDone: false
                                  };
                                  setTasks(tasks.map(t => t.id === task.id ? {
                                    ...t,
                                    subtasks: [...(t.subtasks || []), newSub],
                                    updatedAt: new Date().toISOString()
                                  } : t));
                                }
                              }}
                              className="flex-grow text-[10px] rounded-lg px-2 py-1 border focus:outline-none"
                              style={{ backgroundColor: appBgColor, borderColor: appBorderColor }}
                            />
                            <button
                              onClick={() => {
                                if (!newSubtaskText.trim()) return;
                                const text = newSubtaskText.trim();
                                setNewSubtaskText('');
                                const newSub = {
                                  id: `${Date.now()}-${Math.random()}`,
                                  title: text,
                                  isDone: false
                                };
                                setTasks(tasks.map(t => t.id === task.id ? {
                                  ...t,
                                  subtasks: [...(t.subtasks || []), newSub],
                                  updatedAt: new Date().toISOString()
                                } : t));
                              }}
                              className="px-2.5 rounded-lg text-white font-bold text-[10px] hover:opacity-90 transition shrink-0"
                              style={{ backgroundColor: appPrimaryColor }}
                            >
                              Add
                            </button>
                          </div>
                        </div>

                        <div className="space-y-1.5 border-t pt-2.5" style={{ borderColor: appBorderColor }}>
                          <span className="text-[9px] uppercase font-bold tracking-wider opacity-60 font-sans">Sound Alert</span>
                          <div className="flex gap-1.5 items-center">
                            <select
                              value={task.soundPath || ''}
                              onChange={(e) => {
                                const val = e.target.value || undefined;
                                setTasks(tasks.map(t => t.id === task.id ? { ...t, soundPath: val, updatedAt: new Date().toISOString() } : t));
                                if (val) playSound(val);
                              }}
                              className="flex-grow border rounded-xl py-1.5 px-2 bg-transparent font-semibold focus:outline-none cursor-pointer text-[11px]"
                              style={{ borderColor: appBorderColor }}
                            >
                              <option value="" className="text-black">🔇 No Sound</option>
                              <option value="bell" className="text-black">🔔 Retro Bell</option>
                              <option value="digital" className="text-black">💻 Digital Blip</option>
                              <option value="marimba" className="text-black">🎹 Marimba Echo</option>
                            </select>
                            {task.soundPath && (
                              <button
                                onClick={() => playSound(task.soundPath!)}
                                className="w-7 h-7 rounded-lg bg-blue-500/10 text-blue-500 flex items-center justify-center hover:bg-blue-500/20 active:scale-90 transition shrink-0"
                              >
                                <Play className="w-3.5 h-3.5 fill-current" />
                              </button>
                            )}
                          </div>
                        </div>

                        <div className="pt-1.5 flex gap-2">
                          <button
                            onClick={() => {
                              setTasks(tasks.filter(t => t.id !== task.id));
                              setActiveDetailTaskId(null);
                            }}
                            className="flex-1 py-2 rounded-xl border border-red-200 dark:border-red-950 hover:bg-red-50/50 dark:hover:bg-red-950/20 text-red-600 dark:text-red-400 font-bold transition flex items-center justify-center gap-1"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                            Delete
                          </button>
                          
                          <button
                            onClick={() => {
                              setTasks(tasks.map(t => t.id === task.id ? { ...t, isCompleted: !t.isCompleted, updatedAt: new Date().toISOString() } : t));
                              setActiveDetailTaskId(null);
                            }}
                            className="flex-grow py-2 rounded-xl text-white font-bold transition flex items-center justify-center gap-1 active:scale-95"
                            style={{ backgroundColor: appPrimaryColor }}
                          >
                            <Check className="w-3.5 h-3.5 stroke-[3px]" />
                            Mark Done
                          </button>
                        </div>

                      </div>
                    </div>
                  </div>
                );
              })()}

              {/* Bottom Tab Navigation Bar inside the Phone Screen */}
              {selectedView !== 'new_task' && (
                <div className="h-16 border-t shrink-0 flex items-center justify-around px-2 pb-1.5 bg-white/95 dark:bg-slate-900/95 backdrop-blur z-20" style={{ borderColor: appBorderColor, backgroundColor: appSurfaceColor }}>
                  {[
                    { id: 'list', label: 'Tasks', icon: CheckSquare },
                    { id: 'kanban', label: 'Kanban', icon: LayoutGrid },
                    { id: 'calendar', label: 'Calendar', icon: Calendar },
                    { id: 'settings', label: 'Settings', icon: Settings },
                  ].map((tab) => {
                    const isActive = selectedView === tab.id || (tab.id === 'settings' && selectedView === 'appearance');
                    const Icon = tab.icon;
                    return (
                      <button
                        key={tab.id}
                        onClick={() => setSelectedView(tab.id as any)}
                        className="flex flex-col items-center justify-center flex-1 py-1 transition-all relative"
                        style={{ color: isActive ? appPrimaryColor : appTextMutedColor }}
                      >
                        <Icon className={`w-5 h-5 transition-transform ${isActive ? 'scale-110 stroke-[2.5px]' : 'stroke-[2px]'}`} />
                        <span className="text-[10px] font-bold mt-1 tracking-tight">{tab.label}</span>
                        {isActive && (
                          <span className="absolute bottom-0 w-1 h-1 rounded-full" style={{ backgroundColor: appPrimaryColor }}></span>
                        )}
                      </button>
                    );
                  })}
                </div>
              )}

              {/* Import confirmation overlay modal */}
              {pendingImport && (
                <div className="absolute inset-0 bg-black/70 flex items-center justify-center p-4 z-[999] backdrop-blur-[1px]">
                  <div className="bg-slate-900 rounded-3xl border border-slate-800 p-5 text-center max-w-[280px] space-y-4 shadow-2xl animate-in fade-in zoom-in duration-200">
                    <div className="w-12 h-12 rounded-full bg-blue-500/10 text-blue-500 flex items-center justify-center mx-auto">
                      <CheckCircle2 className="w-6 h-6" />
                    </div>
                    <div className="space-y-1">
                      <h3 className="text-sm font-bold text-white">Import Backup Data</h3>
                      <p className="text-[10px] text-slate-400">Validate schema: SUCCESS! Overwriting the local state will update all existing tasks, styles and settings presets.</p>
                    </div>
                    
                    <div className="bg-slate-950/50 rounded-xl p-2.5 text-left text-[10px] border border-slate-800 space-y-1">
                      <div className="flex justify-between"><span className="text-slate-500">Tasks Count:</span><span className="font-bold text-slate-300">{pendingImport.tasks.length}</span></div>
                      <div className="flex justify-between"><span className="text-slate-500">Categories Count:</span><span className="font-bold text-slate-300">{pendingImport.categories.length}</span></div>
                      <div className="flex justify-between"><span className="text-slate-500">Theme preset:</span><span className="font-bold text-slate-300">{pendingImport.themeConfig.name}</span></div>
                    </div>
                    
                    <div className="flex gap-2 pt-1">
                      <button 
                        onClick={() => setPendingImport(null)}
                        className="flex-1 py-1.5 rounded-lg border border-slate-800 hover:bg-slate-800 text-xs font-bold transition text-slate-400"
                      >
                        Cancel
                      </button>
                      <button 
                        onClick={handleCommitImport}
                        className="flex-1 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-xs font-bold transition text-white"
                      >
                        Overwrite
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Import Error overlay modal */}
              {importError && (
                <div className="absolute inset-0 bg-black/70 flex items-center justify-center p-4 z-[999] backdrop-blur-[1px]">
                  <div className="bg-slate-900 rounded-3xl border border-slate-800 p-5 text-center max-w-[280px] space-y-4 shadow-2xl animate-in fade-in zoom-in duration-200">
                    <div className="w-12 h-12 rounded-full bg-red-500/10 text-red-500 flex items-center justify-center mx-auto">
                      <X className="w-6 h-6" />
                    </div>
                    <div className="space-y-1">
                      <h3 className="text-sm font-bold text-white">Import Failed</h3>
                      <p className="text-[10px] text-slate-400">{importError}</p>
                    </div>
                    <button 
                      onClick={() => setImportError(null)}
                      className="w-full py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-bold transition text-slate-300"
                    >
                      OK
                    </button>
                  </div>
                </div>
              )}

            </div>

            {/* Phone Home indicator line */}
            <div className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-32 h-1.5 bg-slate-800 rounded-full"></div>
          </div>
        </section>

        {/* Right Column: Code & Specs Workspace (Span 7) */}
        <section className="lg:col-span-7 flex flex-col gap-4">
          
          {/* Design Specs Overview capsule */}
          <div className="bg-slate-950/40 border border-slate-800 rounded-2xl p-5 shadow-lg">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-display font-bold text-md text-white flex items-center gap-2">
                <Bookmark className="w-5 h-5 text-blue-500" />
                Stitch Extract Design Specs
              </h3>
              <span className="text-xs font-mono text-slate-400">Flow Standard Theme</span>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
              <div className="space-y-2.5">
                <div className="flex justify-between items-center bg-slate-900/50 p-2.5 rounded-xl border border-slate-800/60">
                  <span className="text-slate-400">Primary Color Accent:</span>
                  <span className="font-mono text-blue-400 font-bold">#0058BE</span>
                </div>
                <div className="flex justify-between items-center bg-slate-900/50 p-2.5 rounded-xl border border-slate-800/60">
                  <span className="text-slate-400">Paper Base Background:</span>
                  <span className="font-mono text-slate-300 font-bold">#F8F9FA</span>
                </div>
                <div className="flex justify-between items-center bg-slate-900/50 p-2.5 rounded-xl border border-slate-800/60">
                  <span className="text-slate-400">Active Text Color:</span>
                  <span className="font-mono text-slate-300 font-bold">#191C1D</span>
                </div>
              </div>
              <div className="space-y-2.5">
                <div className="flex justify-between items-center bg-slate-900/50 p-2.5 rounded-xl border border-slate-800/60">
                  <span className="text-slate-400">Typography Family:</span>
                  <span className="font-semibold text-slate-300 font-bold">Inter (Google Font)</span>
                </div>
                <div className="flex justify-between items-center bg-slate-900/50 p-2.5 rounded-xl border border-slate-800/60">
                  <span className="text-slate-400">Border Radius Spec:</span>
                  <span className="font-mono text-slate-300 font-bold">16px (rounded-2xl)</span>
                </div>
                <div className="flex justify-between items-center bg-slate-900/50 p-2.5 rounded-xl border border-slate-800/60">
                  <span className="text-slate-400">Ambient shadow spec:</span>
                  <span className="font-mono text-slate-300 font-bold">Diffused (4% alpha)</span>
                </div>
              </div>
            </div>
          </div>

          {/* Tabbed Code Explorer panel */}
          <div className="bg-slate-950 border border-slate-800 rounded-2xl flex flex-col h-[560px] shadow-2xl">
            
            {/* Header with folder name and copying actions */}
            <div className="bg-slate-950 border-b border-slate-800/80 px-4 py-3 flex items-center justify-between shrink-0">
              <div className="flex items-center gap-2">
                <Folder className="w-5 h-5 text-amber-500 fill-amber-500/10" />
                <span className="font-mono text-xs text-slate-400">{getCodePath()}</span>
              </div>
              <button
                onClick={() => handleCopyCode(getCodeContent(), activeCodeTab)}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-900 hover:bg-slate-800 border border-slate-800 text-slate-300 text-xs transition"
              >
                {copiedText === activeCodeTab ? (
                  <>
                    <Check className="w-3.5 h-3.5 text-emerald-400" />
                    <span className="text-emerald-400 font-medium">Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3.5 h-3.5 text-slate-400" />
                    <span>Copy Code</span>
                  </>
                )}
              </button>
            </div>

            {/* Folder Layout structure panel alongside Code Pre content */}
            <div className="flex-grow flex overflow-hidden">
              
              {/* Vertical Side Tabs (Directory Explorer layout) */}
              <div className="w-44 border-r border-slate-800/80 bg-slate-950 overflow-y-auto py-3 space-y-3 shrink-0 flex flex-col justify-between">
                <div>
                  <div className="px-3 mb-2 text-[10px] uppercase font-bold tracking-wider text-slate-500">Root</div>
                  <button 
                    onClick={() => setActiveCodeTab('pubspec')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'pubspec' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>pubspec.yaml</span>
                  </button>

                  <div className="px-3 mt-4 mb-2 text-[10px] uppercase font-bold tracking-wider text-slate-500">Lib</div>
                  <button 
                    onClick={() => setActiveCodeTab('main')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'main' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>main.dart</span>
                  </button>
                  <button 
                    onClick={() => setActiveCodeTab('app')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'app' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>app.dart</span>
                  </button>

                  <div className="px-3 mt-4 mb-2 text-[10px] uppercase font-bold tracking-wider text-slate-500">Lib/Core</div>
                  <button 
                    onClick={() => setActiveCodeTab('theme')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'theme' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>theme_config.dart</span>
                  </button>
                  <button 
                    onClick={() => setActiveCodeTab('db')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'db' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>app_database.dart</span>
                  </button>

                  <div className="px-3 mt-4 mb-2 text-[10px] uppercase font-bold tracking-wider text-slate-500">Lib/Features</div>
                  <button 
                    onClick={() => setActiveCodeTab('task')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'task' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>task.dart</span>
                  </button>
                  <button 
                    onClick={() => setActiveCodeTab('subtask')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'subtask' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>subtask.dart</span>
                  </button>
                  <button 
                    onClick={() => setActiveCodeTab('recurrence')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'recurrence' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>recurrence_rule.dart</span>
                  </button>
                  <button 
                    onClick={() => setActiveCodeTab('category')}
                    className={`w-full flex items-center gap-1.5 px-3 py-1.5 text-left text-xs font-mono transition ${activeCodeTab === 'category' ? 'text-blue-400 bg-slate-900/50 border-l-2 border-blue-500' : 'text-slate-400 hover:text-slate-200'}`}
                  >
                    <FileCode className="w-3.5 h-3.5 shrink-0" />
                    <span>category.dart</span>
                  </button>
                </div>

                {/* Micro instructions detail */}
                <div className="px-3 py-2 text-[10px] text-slate-500 border-t border-slate-900 leading-tight">
                  All models utilize <code className="text-slate-400">freezed</code> annotations paired with robust <code className="text-slate-400">Isar</code> collections schemas.
                </div>
              </div>

              {/* High-Fidelity Code Pre block viewer */}
              <div className="flex-1 bg-slate-950 p-4 overflow-auto font-mono text-xs leading-relaxed text-slate-300 no-scrollbar select-text">
                <pre className="whitespace-pre">{getCodeContent()}</pre>
              </div>

            </div>
          </div>
          
        </section>

      </main>

      {/* Footer System Info */}
      <footer className="mt-12 border-t border-slate-800 bg-slate-950 py-6 text-center text-slate-500 text-xs shrink-0">
        <p className="max-w-xl mx-auto px-4 leading-normal">
          Flow Task Optimizer • Built with Google AI Studio • Adhering to the <strong>Modern Minimalist</strong> specification pixel-for-pixel where feasible. All generated dart models exist on disk ready for copy or extraction.
        </p>
      </footer>

    </div>
  );
}
