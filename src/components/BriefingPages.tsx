'use client'

import { useMemo } from 'react'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { useTaskStore } from '@/lib/store'
import { useExtendedStore } from '@/lib/extended-store'
import { useProStore } from '@/lib/pro-store'
import { getLevelFromXP, getLevelTitle } from '@/lib/pro-features-types'
import { toPersianDigits, formatJalaliDate, PERSIAN_WEEKDAYS } from '@/lib/jalali'
import { formatDurationHuman } from '@/lib/time-format'
import {
  Sun, Moon, Target, Clock, AlertCircle, CheckCircle2,
  Flame, TrendingUp, ArrowLeft,
} from 'lucide-react'

// ============ Morning Briefing ============
export function MorningBriefing({ onClose, onNavigate }: { onClose: () => void; onNavigate?: (page: string) => void }) {
  const { tasks } = useTaskStore()
  const { timerSessions } = useExtendedStore()
  const { gamification } = useProStore()

  const today = new Date()
  const todayStr = today.toDateString()

  const todayTasks = tasks.filter((t) => {
    const d = new Date(t.dueDate)
    return d.toDateString() === todayStr && !t.completed && t.active
  })

  const importantTask = todayTasks.find((t) => t.priority === 'high') || todayTasks[0]
  const hasAppointment = todayTasks.find((t) => t.hasTime)

  const levelInfo = getLevelFromXP(gamification.xp)
  const levelTitle = getLevelTitle(levelInfo.level)

  const greeting = today.getHours() < 6 ? 'سحر بخیر' : today.getHours() < 12 ? 'صبح بخیر' : today.getHours() < 17 ? 'ظهر بخیر' : today.getHours() < 20 ? 'عصر بخیر' : 'شب بخیر'

  return (
    <div className="fixed inset-0 z-[80] bg-background flex flex-col safe-top safe-bottom">
      <div className="flex-1 overflow-y-auto px-4 py-6">
        {/* سلام */}
        <div className="text-center mb-6">
          <div className="text-6xl mb-2">☀️</div>
          <h1 className="text-2xl font-bold">{greeting} 👋</h1>
          <p className="text-sm text-muted-foreground mt-1">
            {PERSIAN_WEEKDAYS[today.getDay()]} · {formatJalaliDate(today, false)}
          </p>
        </div>

        {/* Level */}
        <Card className="p-4 mb-4 bg-gradient-to-br from-primary/10 to-transparent border-primary/20">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-3xl">{levelTitle.emoji}</span>
              <div>
                <p className="font-bold">Level {toPersianDigits(levelInfo.level)}</p>
                <p className="text-xs text-muted-foreground">{levelTitle.title}</p>
              </div>
            </div>
            {gamification.streak > 0 && (
              <div className="flex items-center gap-1">
                <Flame className="h-5 w-5 text-orange-500" />
                <span className="font-bold text-orange-500">{toPersianDigits(gamification.streak)}</span>
              </div>
            )}
          </div>
        </Card>

        {/* تسک‌های امروز */}
        <Card className="p-4 mb-4">
          <div className="flex items-center gap-2 mb-3">
            <Target className="h-5 w-5 text-primary" />
            <h3 className="font-semibold">امروز {toPersianDigits(todayTasks.length)} تسک داری</h3>
          </div>
          {todayTasks.length === 0 ? (
            <p className="text-sm text-muted-foreground">تسکی برای امروز نیست. روز خوبی داشته باشی! 🌟</p>
          ) : (
            <div className="space-y-2">
              {todayTasks.slice(0, 5).map((t) => (
                <div key={t.id} className="flex items-center gap-2 text-sm">
                  <div className={`h-2 w-2 rounded-full ${t.priority === 'high' ? 'bg-red-500' : t.priority === 'medium' ? 'bg-amber-500' : 'bg-green-500'}`} />
                  <span className="flex-1 truncate">{t.title}</span>
                  {t.hasTime && (
                    <span className="text-xs text-muted-foreground">
                      {toPersianDigits(new Date(t.dueDate).getHours().toString().padStart(2, '0'))}:{toPersianDigits(new Date(t.dueDate).getMinutes().toString().padStart(2, '0'))}
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* مهم‌ترین تسک */}
        {importantTask && (
          <Card className="p-4 mb-4 bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-900">
            <div className="flex items-center gap-2 mb-2">
              <AlertCircle className="h-5 w-5 text-amber-500" />
              <h3 className="font-semibold text-amber-700 dark:text-amber-400">مهم‌ترین تسک امروز</h3>
            </div>
            <p className="font-bold">{importantTask.title}</p>
            {importantTask.hasTime && (
              <p className="text-xs text-muted-foreground mt-1">
                ساعت {toPersianDigits(new Date(importantTask.dueDate).getHours().toString().padStart(2, '0'))}:{toPersianDigits(new Date(importantTask.dueDate).getMinutes().toString().padStart(2, '0'))}
              </p>
            )}
          </Card>
        )}

        {/* قرارهای زمانی */}
        {hasAppointment && (
          <Card className="p-4 mb-4">
            <div className="flex items-center gap-2 mb-2">
              <Clock className="h-5 w-5 text-blue-500" />
              <h3 className="font-semibold">قرارهای امروز</h3>
            </div>
            <div className="space-y-1">
              {todayTasks.filter((t) => t.hasTime).slice(0, 3).map((t) => (
                <div key={t.id} className="flex items-center gap-2 text-sm">
                  <Badge variant="outline" className="text-xs">
                    {toPersianDigits(new Date(t.dueDate).getHours().toString().padStart(2, '0'))}:{toPersianDigits(new Date(t.dueDate).getMinutes().toString().padStart(2, '0'))}
                  </Badge>
                  <span className="truncate">{t.title}</span>
                </div>
              ))}
            </div>
          </Card>
        )}

        {/* نقل قول انگیزشی */}
        <Card className="p-4 bg-primary/5">
          <p className="text-sm text-center italic">
            «بهترین زمان برای شروع کردن، همین حالاست.»
          </p>
        </Card>
      </div>

      <div className="p-4 border-t safe-bottom">
        <Button className="w-full h-12" onClick={onClose}>
          شروع روز 👊
        </Button>
      </div>
    </div>
  )
}

// ============ Daily Review ============
export function DailyReview({ onClose }: { onClose: () => void }) {
  const { tasks } = useTaskStore()
  const { timerSessions } = useExtendedStore()
  const { gamification } = useProStore()

  const today = new Date()
  const todayStr = today.toDateString()

  const stats = useMemo(() => {
    const todayTasks = tasks.filter((t) => {
      const d = new Date(t.dueDate)
      return d.toDateString() === todayStr
    })
    const completed = todayTasks.filter((t) => t.completed)
    const completionRate = todayTasks.length > 0 ? Math.round((completed.length / todayTasks.length) * 100) : 0

    const todayTimers = timerSessions.filter((t) =>
      t.status === 'completed' && new Date(t.startedAt).toDateString() === todayStr
    )
    const todayFocus = 0
    const totalMinutes = todayTimers.reduce((sum, t) => sum + Math.floor(t.elapsedSeconds / 60), 0) + todayFocus

    // مقایسه با بهترین روز هفته
    const weekAgo = new Date(today)
    weekAgo.setDate(weekAgo.getDate() - 7)
    const weekTasks = tasks.filter((t) =>
      t.completedAt && new Date(t.completedAt) >= weekAgo
    )
    const dayCounts: Record<string, number> = {}
    weekTasks.forEach((t) => {
      if (t.completedAt) {
        const d = new Date(t.completedAt).toDateString()
        dayCounts[d] = (dayCounts[d] || 0) + 1
      }
    })
    const maxDay = Math.max(...Object.values(dayCounts), 0)
    const isBestDay = completed.length >= maxDay && completed.length > 0

    return {
      total: todayTasks.length,
      completed: completed.length,
      completionRate,
      totalMinutes,
      isBestDay,
    }
  }, [tasks, timerSessions])

  const levelInfo = getLevelFromXP(gamification.xp)
  const mood = stats.completionRate >= 80 ? { emoji: '🎉', text: 'عالی بود!' } :
    stats.completionRate >= 50 ? { emoji: '👍', text: 'خوب بود' } :
    stats.completionRate > 0 ? { emoji: '💪', text: 'تلاش بیشتر' } :
    { emoji: '😴', text: 'استراحت کردی' }

  return (
    <div className="fixed inset-0 z-[80] bg-background flex flex-col safe-top safe-bottom">
      <div className="flex-1 overflow-y-auto px-4 py-6">
        <div className="text-center mb-6">
          <div className="text-6xl mb-2">🌙</div>
          <h1 className="text-2xl font-bold">مرور روز</h1>
          <p className="text-sm text-muted-foreground mt-1">
            {PERSIAN_WEEKDAYS[today.getDay()]} · {formatJalaliDate(today, false)}
          </p>
        </div>

        {/* خلاصه */}
        <Card className="p-5 mb-4 text-center bg-gradient-to-br from-primary/10 to-transparent border-primary/20">
          <div className="text-5xl mb-2">{mood.emoji}</div>
          <p className="text-lg font-bold">{mood.text}</p>
        </Card>

        {/* آمار */}
        <div className="grid grid-cols-2 gap-3 mb-4">
          <Card className="p-4">
            <CheckCircle2 className="h-6 w-6 text-green-500 mb-2" />
            <p className="text-2xl font-bold">{toPersianDigits(stats.completionRate)}%</p>
            <p className="text-xs text-muted-foreground">انجام تسک‌ها</p>
            <p className="text-xs mt-1">{toPersianDigits(stats.completed)} از {toPersianDigits(stats.total)}</p>
          </Card>
          <Card className="p-4">
            <Clock className="h-6 w-6 text-blue-500 mb-2" />
            <p className="text-lg font-bold">{stats.totalMinutes > 0 ? formatDurationHuman(stats.totalMinutes * 60) : '۰'}</p>
            <p className="text-xs text-muted-foreground">زمان کار و تمرکز</p>
          </Card>
        </div>

        {/* بهترین عملکرد */}
        {stats.isBestDay && (
          <Card className="p-4 mb-4 bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-900">
            <div className="flex items-center gap-2">
              <TrendingUp className="h-6 w-6 text-amber-500" />
              <div>
                <p className="font-bold text-amber-700 dark:text-amber-400">بهترین عملکرد این هفته! 🔥</p>
                <p className="text-xs text-amber-600 dark:text-amber-500">آفرین! ادامه بده</p>
              </div>
            </div>
          </Card>
        )}

        {/* Streak */}
        {gamification.streak > 1 && (
          <Card className="p-4 mb-4 bg-orange-50 dark:bg-orange-950/20 border-orange-200 dark:border-orange-900">
            <div className="flex items-center gap-2">
              <Flame className="h-6 w-6 text-orange-500" />
              <div>
                <p className="font-bold text-orange-600 dark:text-orange-400">
                  {toPersianDigits(gamification.streak)} روز متوالی! 🔥
                </p>
                <p className="text-xs text-orange-500">فردا هم ادامه بده!</p>
              </div>
            </div>
          </Card>
        )}

        {/* Level */}
        <Card className="p-4 mb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-2xl">{getLevelTitle(levelInfo.level).emoji}</span>
              <div>
                <p className="font-bold">Level {toPersianDigits(levelInfo.level)}</p>
                <p className="text-xs text-muted-foreground">{getLevelTitle(levelInfo.level).title}</p>
              </div>
            </div>
            <div className="text-left">
              <p className="font-bold">{toPersianDigits(gamification.xp)} XP</p>
              <p className="text-xs text-muted-foreground">امروز</p>
            </div>
          </div>
        </Card>
      </div>

      <div className="p-4 border-t safe-bottom">
        <Button className="w-full h-12" onClick={onClose}>
          شب بخیر 🌙
        </Button>
      </div>
    </div>
  )
}
