export type PriorityLevel = 0 | 1 | 2 | 3; // 0: Low, 1: Medium, 2: High, 3: Critical

export interface Subtask {
  id: string;
  title: string;
  isDone: boolean;
}

export interface RecurrenceRule {
  frequency: 'none' | 'daily' | 'weekly' | 'monthly';
  interval: number;
}

export interface Task {
  id: string;
  title: string;
  notes?: string;
  dueDate?: string; // ISO string or human-readable
  reminderAt?: string;
  priority: PriorityLevel;
  isCompleted: boolean;
  categoryIds: string[];
  subtasks: Subtask[];
  recurrence?: RecurrenceRule;
  createdAt: string;
  updatedAt: string;
  customFields?: Record<string, any>;
  kanbanStatus: 'todo' | 'in_progress' | 'done';
  wallpaperPath?: string;
  soundPath?: string;
  wallpaperOffsetY?: number;
}

export interface Category {
  id: string;
  name: string;
  colorValue: string; // e.g., "#0058be"
  iconName?: string;
}

export interface ThemeConfig {
  id: string;
  name: string;
  primaryColor: string;
  backgroundColor: string;
  fontFamily: string;
  densityScale: number; // 1: Compact, 2: Comfortable, 3: Relaxed
  isDark: boolean;
  appWallpaperPath?: string;
}

export interface SettingsState {
  showPriorityIndicator: boolean;
  showNotesPreview: boolean;
  showDueTime: boolean;
  showSubtaskProgress: boolean;
  swipeRight: 'Complete' | 'Delete' | 'None';
  swipeLeft: 'Complete' | 'Delete' | 'None';
  dailyReminders: boolean;
  smartSuggestions: boolean;
  notificationsEnabled?: boolean;
  defaultSortOrder?: 'dueDate' | 'priority' | 'alphabetical' | 'createdDate';
  themeMode?: 'light' | 'dark' | 'system';
}
