// انواع داده‌های قابلیت‌های جدید - پروژه، گیمیفیکیشن، داشبورد، الگو

// ============ پروژه‌ها ============
export interface Project {
  id: string
  name: string
  emoji: string
  color: string
  description?: string
  deadline?: string // ISO
  createdAt: string
  updatedAt: string
}

// ============ گیمیفیکیشن ============
export interface GamificationStats {
  xp: number
  level: number
  streak: number
  lastActiveDate: string // ISO
  totalTasksCompleted: number
  totalFocusMinutes: number
  achievements: Achievement[]
}

export interface Achievement {
  id: string
  name: string
  description: string
  emoji: string
  unlockedAt?: string
}

export const XP_REWARDS = {
  taskEasy: 10,
  taskMedium: 20,
  taskHard: 30,
  focusHour: 50,
  allTasksDay: 100,
  streak7: 200,
  streak30: 500,
}

export const LEVEL_TITLES: { level: number; title: string; emoji: string }[] = [
  { level: 1, title: 'تازه‌کار', emoji: '🌱' },
  { level: 3, title: 'در حال رشد', emoji: '🌿' },
  { level: 5, title: 'پویا', emoji: '⚡' },
  { level: 8, title: 'متمرکز', emoji: '🎯' },
  { level: 10, title: 'حرفه‌ای', emoji: '💪' },
  { level: 15, title: 'استاد بهره‌وری', emoji: '😎' },
  { level: 20, title: 'افسانه‌ای', emoji: '🏆' },
  { level: 30, title: 'اسطوره', emoji: '👑' },
]

export function getLevelTitle(level: number): { title: string; emoji: string } {
  let result = LEVEL_TITLES[0]
  for (const lt of LEVEL_TITLES) {
    if (level >= lt.level) result = lt
  }
  return result
}

export function xpForLevel(level: number): number {
  return level * 100 // هر level نیاز به level*100 XP دارد
}

export function getLevelFromXP(xp: number): { level: number; currentXP: number; neededXP: number; progress: number } {
  let level = 1
  let remaining = xp
  let needed = 100
  
  while (remaining >= needed) {
    remaining -= needed
    level++
    needed = level * 100
  }
  
  return {
    level,
    currentXP: remaining,
    neededXP: needed,
    progress: (remaining / needed) * 100,
  }
}

// ============ سطل زباله ============
export type TrashItemType = 'task' | 'project' | 'template'

export interface TrashedItem {
  id: string
  type: TrashItemType
  title: string
  emoji: string
  data: any // داده‌های کامل آیتم
  deletedAt: string // ISO
  expiresAt: string // ISO + 30 روز
}

// ============ الگوها (Templates) ============
export interface TaskTemplate {
  id: string
  name: string
  emoji: string
  tasks: {
    title: string
    description?: string
    categoryId: string
    priority: 'low' | 'medium' | 'high'
    durationMinutes?: number // برای زمان‌بندی
    time?: string // "HH:MM" برای زمان روز
  }[]
  createdAt: string
}

// ============ آمار ============
export interface DayStats {
  date: string // ISO
  tasksCompleted: number
  tasksTotal: number
  focusMinutes: number
  xpEarned: number
}

export interface WeekStats {
  dayName: string
  tasksCompleted: number
  focusMinutes: number
}

// دستاوردها
export const ALL_ACHIEVEMENTS: Achievement[] = [
  { id: 'first_task', name: 'اولین قدم', description: 'اولین تسک خود را انجام دهید', emoji: '🎯' },
  { id: 'ten_tasks', name: 'ده‌تا ده‌تا', description: '۱۰ تسک انجام دهید', emoji: '🔟' },
  { id: 'fifty_tasks', name: 'نیمه راه', description: '۵۰ تسک انجام دهید', emoji: '🎖️' },
  { id: 'hundred_tasks', name: 'صدتا!', description: '۱۰۰ تسک انجام دهید', emoji: '💯' },
  { id: 'streak_3', name: 'سه روز!', description: '۳ روز متوالی فعالیت کنید', emoji: '🔥' },
  { id: 'streak_7', name: 'یک هفته!', description: '۷ روز متوالی فعالیت کنید', emoji: '⚡' },
  { id: 'streak_30', name: 'یک ماه!', description: '۳۰ روز متوالی فعالیت کنید', emoji: '👑' },
  { id: 'focus_1h', name: 'یک ساعت تمرکز', description: 'یک ساعت تمرکز کامل', emoji: '🧠' },
  { id: 'focus_10h', name: 'ده ساعت', description: 'مجموعاً ۱۰ ساعت تمرکز', emoji: '💎' },
  { id: 'all_day', name: 'روز بی‌نقص', description: 'تمام تسک‌های روز را انجام دهید', emoji: '✨' },
  { id: 'early_bird', name: 'سحرگاه', description: 'قبل از ساعت ۶ صبح تسک انجام دهید', emoji: '🌅' },
  { id: 'night_owl', name: 'جغد شب', description: 'بعد از ساعت ۱۲ شب تسک انجام دهید', emoji: '🦉' },
]
