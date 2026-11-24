'use client'

import { useMemo } from 'react'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { useTaskStore } from '@/lib/store'
import { useExtendedStore } from '@/lib/extended-store'
import { useProStore } from '@/lib/pro-store'
import { getLevelFromXP, getLevelTitle, ALL_ACHIEVEMENTS } from '@/lib/pro-features-types'
import { toPersianDigits, formatJalaliDate, PERSIAN_WEEKDAYS } from '@/lib/jalali'
import { formatDurationHuman } from '@/lib/time-format'
import {
  TrendingUp, Target, Flame, Clock, Trophy, CheckCircle2,
  AlertCircle, Award, Calendar, Zap,
} from 'lucide-react'

export function DashboardPage() {
  const { tasks } = useTaskStore()
  const { timerSessions } = useExtendedStore()
  const { gamification } = useProStore()

  // محاسبه آمار
  const stats = useMemo(() => {
    const now = new Date()
    const today = now.toDateString()
    const weekAgo = new Date(now)
    weekAgo.setDate(weekAgo.getDate() - 7)

    const completedTasks = tasks.filter((t) => t.completed)
    const todayTasks = tasks.filter((t) => new Date(t.dueDate).toDateString() === today)
    const todayCompleted = todayTasks.filter((t) => t.completed)
    const overdueTasks = tasks.filter((t) => {
      const d = new Date(t.dueDate)
      return d < now && !t.completed && t.active
    })

    const completionRate = todayTasks.length > 0
      ? Math.round((todayCompleted.length / todayTasks.length) * 100)
      : 0

    // بهترین روز هفته
    const dayCounts: Record<number, number> = {}
    completedTasks.forEach((t) => {
      if (t.completedAt) {
        const d = new Date(t.completedAt)
        if (d >= weekAgo) {
          dayCounts[d.getDay()] = (dayCounts[d.getDay()] || 0) + 1
        }
      }
    })
    let bestDay = 0
    let bestDayCount = 0
    for (let i = 0; i < 7; i++) {
      if ((dayCounts[i] || 0) > bestDayCount) {
        bestDayCount = dayCounts[i] || 0
        bestDay = i
      }
    }

    // ساعت‌های بیشترین فعالیت
    const hourCounts: Record<number, number> = {}
    completedTasks.forEach((t) => {
      if (t.completedAt) {
        const h = new Date(t.completedAt).getHours()
        hourCounts[h] = (hourCounts[h] || 0) + 1
      }
    })
    const topHours = Object.entries(hourCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([h, c]) => ({ hour: parseInt(h), count: c }))

    // تایمر امروز
    const todayTimers = timerSessions.filter((t) => 
      t.status === 'completed' && new Date(t.startedAt).toDateString() === today
    )
    const todayFocusMinutes = 0
    const totalTodayMinutes = todayTimers.reduce((sum, t) => sum + Math.floor(t.elapsedSeconds / 60), 0) + todayFocusMinutes

    // نمودار هفته
    const weekStats: { day: string; short: string; count: number; isToday: boolean }[] = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now)
      d.setDate(d.getDate() - i)
      const dayStr = d.toDateString()
      const dayTasks = completedTasks.filter((t) => 
        t.completedAt && new Date(t.completedAt).toDateString() === dayStr
      )
      weekStats.push({
        day: PERSIAN_WEEKDAYS[d.getDay()],
        short: PERSIAN_WEEKDAYS[d.getDay()].slice(0, 1),
        count: dayTasks.length,
        isToday: dayStr === today,
      })
    }

    return {
      completionRate,
      todayTasksTotal: todayTasks.length,
      todayCompleted: todayCompleted.length,
      overdueCount: overdueTasks.length,
      totalCompleted: completedTasks.length,
      bestDay,
      bestDayCount,
      topHours,
      totalTodayMinutes,
      weekStats,
    }
  }, [tasks, timerSessions])

  const levelInfo = getLevelFromXP(gamification.xp)
  const levelTitle = getLevelTitle(levelInfo.level)
  const maxWeekCount = Math.max(...stats.weekStats.map((w) => w.count), 1)

  return (
    <div className="px-4 py-4 space-y-4">
      {/* کارت Level و Streak */}
      <Card className="p-4 bg-gradient-to-br from-primary/10 to-transparent border-primary/20">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <span className="text-3xl">{levelTitle.emoji}</span>
            <div>
              <p className="font-bold text-lg">Level {toPersianDigits(levelInfo.level)}</p>
              <p className="text-xs text-muted-foreground">{levelTitle.title}</p>
            </div>
          </div>
          {gamification.streak > 0 && (
            <div className="flex items-center gap-1">
              <Flame className="h-5 w-5 text-orange-500" />
              <span className="font-bold text-lg text-orange-500">
                {toPersianDigits(gamification.streak)}
              </span>
            </div>
          )}
        </div>
        {/* نوار XP */}
        <div className="space-y-1">
          <div className="flex justify-between text-xs">
            <span>XP: {toPersianDigits(gamification.xp)}</span>
            <span>{toPersianDigits(levelInfo.currentXP)}/{toPersianDigits(levelInfo.neededXP)}</span>
          </div>
          <Progress value={levelInfo.progress} className="h-2" />
        </div>
      </Card>

      {/* کارت‌های آمار اصلی */}
      <div className="grid grid-cols-2 gap-3">
        {/* درصد انجام امروز */}
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <Target className="h-5 w-5 text-primary" />
            <span className="text-xs text-muted-foreground">انجام امروز</span>
          </div>
          <p className="text-2xl font-bold">{toPersianDigits(stats.completionRate)}%</p>
          <p className="text-xs text-muted-foreground mt-1">
            {toPersianDigits(stats.todayCompleted)} از {toPersianDigits(stats.todayTasksTotal)} تسک
          </p>
        </Card>

        {/* تسک‌های عقب‌افتاده */}
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <AlertCircle className="h-5 w-5 text-destructive" />
            <span className="text-xs text-muted-foreground">عقب‌افتاده</span>
          </div>
          <p className="text-2xl font-bold text-destructive">
            {toPersianDigits(stats.overdueCount)}
          </p>
          <p className="text-xs text-muted-foreground mt-1">تسک نیاز به توجه</p>
        </Card>

        {/* زمان امروز */}
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <Clock className="h-5 w-5 text-blue-500" />
            <span className="text-xs text-muted-foreground">زمان امروز</span>
          </div>
          <p className="text-lg font-bold">
            {stats.totalTodayMinutes > 0 ? formatDurationHuman(stats.totalTodayMinutes * 60) : '۰'}
          </p>
          <p className="text-xs text-muted-foreground mt-1">مجموع کار و تمرکز</p>
        </Card>

        {/* کل تسک‌های انجام شده */}
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <CheckCircle2 className="h-5 w-5 text-green-500" />
            <span className="text-xs text-muted-foreground">کل انجام شده</span>
          </div>
          <p className="text-2xl font-bold">{toPersianDigits(stats.totalCompleted)}</p>
          <p className="text-xs text-muted-foreground mt-1">تسک از همیشه</p>
        </Card>
      </div>

      {/* نمودار هفته */}
      <Card className="p-4">
        <h3 className="font-semibold mb-3 flex items-center gap-2">
          <TrendingUp className="h-4 w-4" />
          فعالیت هفته
        </h3>
        <div className="flex items-end justify-between gap-2 h-32">
          {stats.weekStats.map((day, i) => (
            <div key={i} className="flex-1 flex flex-col items-center gap-1">
              <div className="text-xs font-medium" style={{ opacity: day.count > 0 ? 1 : 0.3 }}>
                {toPersianDigits(day.count)}
              </div>
              <div
                className="w-full rounded-t-md transition-all"
                style={{
                  height: `${(day.count / maxWeekCount) * 80 + 4}px`,
                  backgroundColor: day.isToday ? 'var(--primary)' : 'var(--muted-foreground)',
                  opacity: day.isToday ? 1 : 0.5,
                }}
              />
              <span className={`text-xs ${day.isToday ? 'font-bold text-primary' : 'text-muted-foreground'}`}>
                {day.short}
              </span>
            </div>
          ))}
        </div>
      </Card>

      {/* بهترین روز هفته */}
      {stats.bestDayCount > 0 && (
        <Card className="p-4 bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-900">
          <div className="flex items-center gap-3">
            <Trophy className="h-8 w-8 text-amber-500 shrink-0" />
            <div>
              <p className="text-sm font-medium">بهترین روز هفته</p>
              <p className="text-lg font-bold text-amber-600 dark:text-amber-400">
                {PERSIAN_WEEKDAYS[stats.bestDay]}
              </p>
              <p className="text-xs text-muted-foreground">
                {toPersianDigits(stats.bestDayCount)} تسک انجام دادی
              </p>
            </div>
          </div>
        </Card>
      )}

      {/* ساعت‌های پر فعالیت */}
      {stats.topHours.length > 0 && (
        <Card className="p-4">
          <h3 className="font-semibold mb-3 flex items-center gap-2">
            <Zap className="h-4 w-4" />
            ساعات پر فعالیت
          </h3>
          <div className="space-y-2">
            {stats.topHours.map((h, i) => (
              <div key={i} className="flex items-center gap-3">
                <Badge variant={i === 0 ? 'default' : 'secondary'} className="w-8 justify-center">
                  {toPersianDigits(i + 1)}
                </Badge>
                <span className="text-sm font-medium">
                  ساعت {toPersianDigits(h.hour)} تا {toPersianDigits(h.hour + 1)}
                </span>
                <span className="text-xs text-muted-foreground mr-auto">
                  {toPersianDigits(h.count)} تسک
                </span>
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* دستاوردها */}
      <Card className="p-4">
        <h3 className="font-semibold mb-3 flex items-center gap-2">
          <Award className="h-4 w-4" />
          دستاوردها ({toPersianDigits(gamification.achievements.length)}/{toPersianDigits(ALL_ACHIEVEMENTS.length)})
        </h3>
        <div className="grid grid-cols-4 gap-2">
          {ALL_ACHIEVEMENTS.map((ach) => {
            const unlocked = gamification.achievements.find((a) => a.id === ach.id)
            return (
              <div
                key={ach.id}
                className={`flex flex-col items-center gap-1 p-2 rounded-lg text-center ${
                  unlocked ? 'bg-primary/10' : 'bg-muted/50 opacity-40'
                }`}
              >
                <span className="text-2xl">{unlocked ? ach.emoji : '🔒'}</span>
                <span className="text-[10px] font-medium leading-tight">{ach.name}</span>
              </div>
            )
          })}
        </div>
      </Card>
    </div>
  )
}
