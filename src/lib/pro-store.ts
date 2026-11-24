// Store برای قابلیت‌های حرفه‌ای: پروژه، گیمیفیکیشن، سطل زباله، الگو

'use client'

import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import {
  Project, GamificationStats, TrashedItem, TaskTemplate, TrashItemType,
  XP_REWARDS, getLevelFromXP, Achievement, ALL_ACHIEVEMENTS,
} from './pro-features-types'
import { useAuthStore } from './auth-store'

interface ProStore {
  // پروژه‌ها
  projects: Project[]
  addProject: (data: Omit<Project, 'id' | 'createdAt' | 'updatedAt'>) => void
  updateProject: (id: string, updates: Partial<Project>) => void
  deleteProject: (id: string) => void

  // گیمیفیکیشن
  gamification: GamificationStats
  addXP: (amount: number, reason?: string) => void
  checkStreak: () => void
  unlockAchievement: (id: string) => void
  resetGamification: () => void

  // سطل زباله (پشتیبانی از تسک، پروژه، الگو)
  trash: TrashedItem[]
  moveToTrash: (item: { id: string; type: TrashItemType; title: string; emoji: string; data: any }) => void
  restoreFromTrash: (id: string) => TrashedItem | null
  deleteFromTrash: (id: string) => void
  clearExpiredTrash: () => void

  // الگوها
  templates: TaskTemplate[]
  addTemplate: (data: Omit<TaskTemplate, 'id' | 'createdAt'>) => void
  deleteTemplate: (id: string) => void

  // تنظیمات
  morningBriefingShown: boolean
  dailyReviewShown: boolean
  setMorningBriefingShown: (v: boolean) => void
  setDailyReviewShown: (v: boolean) => void
}

function generateId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 9)}`
}

function makeStorage() {
  if (typeof window === 'undefined') {
    return { getItem: () => null, setItem: () => {}, removeItem: () => {} }
  }
  return window.localStorage
}

const DEFAULT_GAMIFICATION: GamificationStats = {
  xp: 0,
  level: 1,
  streak: 0,
  lastActiveDate: '',
  totalTasksCompleted: 0,
  totalFocusMinutes: 0,
  achievements: [],
}

export const useProStore = create<ProStore>()(
  persist(
    (set, get) => ({
      // ============ پروژه‌ها ============
      projects: [],

      addProject: (data) => {
        const now = new Date().toISOString()
        const project: Project = { ...data, id: generateId(), createdAt: now, updatedAt: now }
        set((state) => ({ projects: [...state.projects, project] }))
      },

      updateProject: (id, updates) => {
        set((state) => ({
          projects: state.projects.map((p) =>
            p.id === id ? { ...p, ...updates, updatedAt: new Date().toISOString() } : p
          ),
        }))
      },

      deleteProject: (id) => {
        set((state) => ({ projects: state.projects.filter((p) => p.id !== id) }))
      },

      // ============ گیمیفیکیشن ============
      gamification: DEFAULT_GAMIFICATION,

      addXP: (amount, reason) => {
        set((state) => {
          const newXP = state.gamification.xp + amount
          const levelInfo = getLevelFromXP(newXP)
          const newStats: GamificationStats = {
            ...state.gamification,
            xp: newXP,
            level: levelInfo.level,
          }

          // چک دستاوردها
          const achievements = [...newStats.achievements]
          const unlockIfNotExists = (id: string) => {
            if (!achievements.find((a) => a.id === id)) {
              const ach = ALL_ACHIEVEMENTS.find((a) => a.id === id)
              if (ach) {
                achievements.push({ ...ach, unlockedAt: new Date().toISOString() })
              }
            }
          }

          if (newStats.totalTasksCompleted + 1 >= 1) unlockIfNotExists('first_task')
          if (newStats.totalTasksCompleted + 1 >= 10) unlockIfNotExists('ten_tasks')
          if (newStats.totalTasksCompleted + 1 >= 50) unlockIfNotExists('fifty_tasks')
          if (newStats.totalTasksCompleted + 1 >= 100) unlockIfNotExists('hundred_tasks')
          if (newStats.totalFocusMinutes >= 60) unlockIfNotExists('focus_1h')
          if (newStats.totalFocusMinutes >= 600) unlockIfNotExists('focus_10h')

          newStats.achievements = achievements
          return { gamification: newStats }
        })
      },

      checkStreak: () => {
        set((state) => {
          const today = new Date().toDateString()
          const lastActive = state.gamification.lastActiveDate
          const achievements = [...state.gamification.achievements]

          if (lastActive === today) return state // امروز قبلاً فعال بوده

          const yesterday = new Date()
          yesterday.setDate(yesterday.getDate() - 1)
          const yesterdayStr = yesterday.toDateString()

          let newStreak = 1
          if (lastActive === yesterdayStr) {
            newStreak = state.gamification.streak + 1
          }

          // چک دستاوردهای streak
          const unlockIfNotExists = (id: string) => {
            if (!achievements.find((a) => a.id === id)) {
              const ach = ALL_ACHIEVEMENTS.find((a) => a.id === id)
              if (ach) achievements.push({ ...ach, unlockedAt: new Date().toISOString() })
            }
          }
          if (newStreak >= 3) unlockIfNotExists('streak_3')
          if (newStreak >= 7) unlockIfNotExists('streak_7')
          if (newStreak >= 30) unlockIfNotExists('streak_30')

          return {
            gamification: {
              ...state.gamification,
              streak: newStreak,
              lastActiveDate: today,
              achievements,
            },
          }
        })
      },

      unlockAchievement: (id) => {
        set((state) => {
          const achievements = [...state.gamification.achievements]
          if (!achievements.find((a) => a.id === id)) {
            const ach = ALL_ACHIEVEMENTS.find((a) => a.id === id)
            if (ach) achievements.push({ ...ach, unlockedAt: new Date().toISOString() })
          }
          return { gamification: { ...state.gamification, achievements } }
        })
      },

      resetGamification: () => {
        set({ gamification: { ...DEFAULT_GAMIFICATION } })
      },

      // ============ سطل زباله ============
      trash: [],

      moveToTrash: (item) => {
        const now = new Date()
        const expires = new Date(now)
        expires.setDate(expires.getDate() + 30)

        const trashed: TrashedItem = {
          id: item.id,
          type: item.type,
          title: item.title,
          emoji: item.emoji,
          data: item.data,
          deletedAt: now.toISOString(),
          expiresAt: expires.toISOString(),
        }
        set((state) => ({ trash: [trashed, ...state.trash] }))
      },

      restoreFromTrash: (id) => {
        const item = get().trash.find((t) => t.id === id)
        if (!item) return null
        set((state) => ({ trash: state.trash.filter((t) => t.id !== id) }))
        return item
      },

      deleteFromTrash: (id) => {
        set((state) => ({ trash: state.trash.filter((t) => t.id !== id) }))
      },

      clearExpiredTrash: () => {
        const now = new Date()
        set((state) => ({
          trash: state.trash.filter((t) => new Date(t.expiresAt) > now),
        }))
      },

      // ============ الگوها ============
      templates: [],

      addTemplate: (data) => {
        const template: TaskTemplate = {
          ...data,
          id: generateId(),
          createdAt: new Date().toISOString(),
        }
        set((state) => ({ templates: [...state.templates, template] }))
      },

      deleteTemplate: (id) => {
        set((state) => ({ templates: state.templates.filter((t) => t.id !== id) }))
      },

      // ============ تنظیمات ============
      morningBriefingShown: false,
      dailyReviewShown: false,
      setMorningBriefingShown: (v) => set({ morningBriefingShown: v }),
      setDailyReviewShown: (v) => set({ dailyReviewShown: v }),
    }),
    {
      name: 'task-reminder-pro-storage',
      storage: createJSONStorage(makeStorage),
      version: 1,
    }
  )
)
