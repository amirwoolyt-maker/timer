'use client'

import { useState, useMemo } from 'react'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { useTaskStore } from '@/lib/store'
import { gregorianToJalali, toPersianDigits, PERSIAN_MONTHS, PERSIAN_WEEKDAYS, PERSIAN_WEEKDAYS_SHORT } from '@/lib/jalali'
import { ChevronRight, ChevronLeft, Calendar } from 'lucide-react'

export function CalendarPage() {
  const { tasks, getCategory } = useTaskStore()
  const [view, setView] = useState<'month' | 'week' | 'day'>('month')
  const [currentDate, setCurrentDate] = useState(new Date())

  // محاسبه روزهای ماه جلالی
  const monthData = useMemo(() => {
    const [jy, jm, jd] = gregorianToJalali(
      currentDate.getFullYear(),
      currentDate.getMonth() + 1,
      currentDate.getDate()
    )
    
    // پیدا کردن اولین روز ماه جلالی
    const firstOfMonth = new Date(currentDate)
    // محاسبه تقریبی
    const jalaliFirstDay = jd - 1
    firstOfMonth.setDate(firstOfMonth.getDate() - jalaliFirstDay)
    
    const days: { date: Date; isCurrentMonth: boolean; isToday: boolean }[] = []
    
    // روزهای قبل از شروع ماه جلالی (روزهای آخر ماه قبل)
    const firstJalaliDOW = firstOfMonth.getDay() // 0=یکشنبه
    
    for (let i = firstJalaliDOW - 1; i >= 0; i--) {
      const d = new Date(firstOfMonth)
      d.setDate(d.getDate() - i - 1)
      days.push({ date: d, isCurrentMonth: false, isToday: false })
    }
    
    // روزهای ماه جلالی (۳۱ یا ۳۰ روز)
    for (let i = 0; i < 31; i++) {
      const d = new Date(firstOfMonth)
      d.setDate(d.getDate() + i)
      const today = new Date()
      const isToday = d.toDateString() === today.toDateString()
      
      // چک کن که هنوز تو همین ماه جلالی هستیم
      const [cy, cm, cd] = gregorianToJalali(d.getFullYear(), d.getMonth() + 1, d.getDate())
      days.push({ 
        date: d, 
        isCurrentMonth: cm === jm, 
        isToday 
      })
    }
    
    return { jy, jm, jd, days }
  }, [currentDate])

  // تسک‌های هر روز
  const getTasksForDate = (date: Date) => {
    return tasks.filter((t) => {
      const taskDate = new Date(t.dueDate)
      return taskDate.toDateString() === date.toDateString()
    })
  }

  // ناوبری
  const prevMonth = () => {
    const d = new Date(currentDate)
    d.setMonth(d.getMonth() - 1)
    setCurrentDate(d)
  }
  const nextMonth = () => {
    const d = new Date(currentDate)
    d.setMonth(d.getMonth() + 1)
    setCurrentDate(d)
  }
  const goToday = () => setCurrentDate(new Date())

  const todayTasks = getTasksForDate(new Date())

  return (
    <div className="px-4 py-4 space-y-4">
      {/* هدر تقویم */}
      <Card className="p-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-bold text-lg">
            {PERSIAN_MONTHS[monthData.jm - 1]} {toPersianDigits(monthData.jy)}
          </h2>
          <div className="flex gap-1">
            <Button variant="ghost" size="icon" className="h-8 w-8" onClick={prevMonth}>
              <ChevronRight className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="sm" className="h-8" onClick={goToday}>
              امروز
            </Button>
            <Button variant="ghost" size="icon" className="h-8 w-8" onClick={nextMonth}>
              <ChevronLeft className="h-4 w-4" />
            </Button>
          </div>
        </div>

        {/* تب‌ها */}
        <div className="flex gap-1 bg-muted p-1 rounded-lg">
          {[
            { id: 'month', label: 'ماهانه' },
            { id: 'week', label: 'هفتگی' },
            { id: 'day', label: 'روزانه' },
          ].map((t) => (
            <button
              key={t.id}
              onClick={() => setView(t.id as any)}
              className={`flex-1 py-1.5 rounded-md text-xs font-medium transition-all ${
                view === t.id ? 'bg-background text-primary shadow-sm' : 'text-muted-foreground'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
      </Card>

      {/* تقویم ماهانه */}
      {view === 'month' && (
        <Card className="p-3">
          {/* روزهای هفته */}
          <div className="grid grid-cols-7 gap-1 mb-2">
            {PERSIAN_WEEKDAYS_SHORT.map((day) => (
              <div key={day} className="text-center text-xs font-semibold text-muted-foreground py-1">
                {day}
              </div>
            ))}
          </div>
          {/* روزهای ماه */}
          <div className="grid grid-cols-7 gap-1">
            {monthData.days.map((day, i) => {
              const dayTasks = getTasksForDate(day.date)
              const [jy, jm, jd] = gregorianToJalali(
                day.date.getFullYear(), day.date.getMonth() + 1, day.date.getDate()
              )
              const hasOverdue = dayTasks.some((t) => !t.completed && day.date < new Date())
              const allDone = dayTasks.length > 0 && dayTasks.every((t) => t.completed)
              
              return (
                <div
                  key={i}
                  className={`aspect-square rounded-lg p-1 flex flex-col items-center justify-center relative cursor-pointer transition-all ${
                    !day.isCurrentMonth ? 'opacity-30' : ''
                  } ${
                    day.isToday ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'
                  } ${hasOverdue && !day.isToday ? 'bg-destructive/10' : ''} ${
                    allDone && !day.isToday ? 'bg-primary/10' : ''
                  }`}
                >
                  <span className={`text-sm font-medium ${day.isToday ? '' : ''}`}>
                    {toPersianDigits(jd)}
                  </span>
                  {dayTasks.length > 0 && (
                    <div className="flex gap-0.5 mt-0.5 flex-wrap justify-center">
                      {dayTasks.slice(0, 3).map((t) => {
                        const cat = getCategory(t.categoryId)
                        return (
                          <div
                            key={t.id}
                            className="h-1.5 w-1.5 rounded-full"
                            style={{ backgroundColor: cat?.color || '#6b7280' }}
                          />
                        )
                      })}
                      {dayTasks.length > 3 && (
                        <span className="text-[8px]">+{toPersianDigits(dayTasks.length - 3)}</span>
                      )}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        </Card>
      )}

      {/* تقویم هفتگی */}
      {view === 'week' && (
        <Card className="p-3">
          <div className="space-y-2">
            {PERSIAN_WEEKDAYS_SHORT.map((dayName, dayIdx) => {
              const d = new Date(currentDate)
              const diff = (dayIdx - currentDate.getDay() + 7) % 7
              d.setDate(d.getDate() + diff)
              const dayTasks = getTasksForDate(d)
              const isToday = d.toDateString() === new Date().toDateString()
              
              return (
                <div key={dayIdx} className={`p-2 rounded-lg ${isToday ? 'bg-primary/10' : 'bg-muted/50'}`}>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-medium">{dayName}</span>
                    {dayTasks.length > 0 && (
                      <Badge variant="secondary" className="text-xs">{toPersianDigits(dayTasks.length)}</Badge>
                    )}
                  </div>
                  {dayTasks.length > 0 && (
                    <div className="space-y-1">
                      {dayTasks.map((t) => {
                        const cat = getCategory(t.categoryId)
                        return (
                          <div key={t.id} className="flex items-center gap-1.5 text-xs">
                            <div className="h-2 w-2 rounded-full" style={{ backgroundColor: cat?.color }} />
                            <span className={`truncate ${t.completed ? 'line-through opacity-50' : ''}`}>
                              {t.title}
                            </span>
                          </div>
                        )
                      })}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        </Card>
      )}

      {/* تقویم روزانه */}
      {view === 'day' && (
        <Card className="p-3">
          <div className="text-center mb-3">
            <p className="text-xs text-muted-foreground">
              {PERSIAN_WEEKDAYS[currentDate.getDay()]}
            </p>
            <p className="text-2xl font-bold">
              {(() => {
                const [jy, jm, jd] = gregorianToJalali(
                  currentDate.getFullYear(), currentDate.getMonth() + 1, currentDate.getDate()
                )
                return `${toPersianDigits(jd)} ${PERSIAN_MONTHS[jm - 1]} ${toPersianDigits(jy)}`
              })()}
            </p>
          </div>
          {todayTasks.length === 0 ? (
            <p className="text-center text-sm text-muted-foreground py-8">تسکی برای این روز نیست</p>
          ) : (
            <div className="space-y-2">
              {todayTasks.map((t) => {
                const cat = getCategory(t.categoryId)
                return (
                  <div
                    key={t.id}
                    className={`flex items-center gap-2 p-2 rounded-lg ${
                      t.completed ? 'bg-muted/30 opacity-60' : 'bg-muted/50'
                    }`}
                    style={{ borderRight: `3px solid ${cat?.color || '#6b7280'}` }}
                  >
                    <span className={`text-sm flex-1 ${t.completed ? 'line-through' : ''}`}>
                      {t.title}
                    </span>
                    {t.completed && (
                      <Badge variant="secondary" className="text-xs bg-primary/15 text-primary">
                        ✓
                      </Badge>
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </Card>
      )}

      {/* راهنما */}
      <Card className="p-3 bg-muted/50">
        <div className="flex items-center gap-2 mb-2">
          <Calendar className="h-4 w-4 text-muted-foreground" />
          <p className="text-xs font-medium text-muted-foreground">راهنما</p>
        </div>
        <div className="space-y-1 text-xs text-muted-foreground">
          <div className="flex items-center gap-2">
            <div className="h-2 w-2 rounded-full bg-primary" />
            <span>نقطه = تسک در آن روز</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded bg-destructive/10" />
            <span>پس‌زمینه قرمز = تسک عقب‌افتاده</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded bg-primary/10" />
            <span>پس‌زمینه سبز = همه تسک‌ها انجام شده</span>
          </div>
        </div>
      </Card>
    </div>
  )
}
