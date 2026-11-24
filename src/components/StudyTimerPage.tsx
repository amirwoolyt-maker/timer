'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { useAuthStore } from '@/lib/auth-store'
import { useExtendedStore } from '@/lib/extended-store'
import { useProStore } from '@/lib/pro-store'
import { SUBJECTS_BY_FIELD_GRADE, FIELD_LABELS, FIELD_EMOJIS } from '@/lib/auth-types'
import { toPersianDigits } from '@/lib/jalali'
import { formatSeconds } from '@/lib/time-format'
import { toast } from 'sonner'
import { Play, Pause, Square, BookOpen, Trophy, Flame, Clock } from 'lucide-react'

interface StudySession {
  id: string
  subject: string
  seconds: number
  date: string
}

const SUBJECT_EMOJIS: Record<string, string> = {
  'ریاضی': '🔢', 'فیزیک': '⚛️', 'شیمی': '🧪', 'ادبیات فارسی': '📖',
  'عربی': '🕌', 'دینی': '☪️', 'زبان': '🌐', 'اجتماعی': '👥',
  'زیست': '🧬', 'زمین': '🌍', 'هندسه': '📐', 'حسابان': '➗',
  'تفاضلی': '📊', 'تاریخ': '📜', 'جغرافیا': '🗺️', 'فلسفه': '💭',
  'منطق': '🧠', 'حقوق': '⚖️', 'جامعه‌شناسی': '👤', 'اخترشناسی': '🌟',
  'ژئولوژی': '⛏️',
}

export function StudyTimerPage() {
  const { currentUser } = useAuthStore()
  const { startTimer, pauseTimer, resumeTimer, stopTimer } = useExtendedStore()
  const { addXP, gamification } = useProStore()
  const { activeTimer } = useExtendedStore()
  
  const [selectedSubject, setSelectedSubject] = useState<string>('')
  const [sessions, setSessions] = useState<StudySession[]>([])
  const [elapsedSeconds, setElapsedSeconds] = useState(0)
  const timerRef = useRef<number | null>(null)
  const [loaded, setLoaded] = useState(false)

  // بارگذاری جلسات
  useEffect(() => {
    if (!currentUser || loaded) return
    const data = localStorage.getItem(`study-sessions-${currentUser.id}`)
    if (data) {
      try {
        const parsed = JSON.parse(data)
        setTimeout(() => setSessions(parsed), 0)
      } catch {}
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoaded(true)
  }, [currentUser, loaded])

  // تایمر
  useEffect(() => {
    if (!activeTimer || activeTimer.status !== 'running') {
      if (timerRef.current) clearInterval(timerRef.current)
      return
    }
    timerRef.current = window.setInterval(() => {
      if (activeTimer.startedAt) {
        const start = new Date(activeTimer.startedAt).getTime()
        const elapsed = Math.floor((Date.now() - start) / 1000)
        setElapsedSeconds(elapsed)
      }
    }, 1000)
    return () => { if (timerRef.current) clearInterval(timerRef.current) }
  }, [activeTimer])

  if (!currentUser) {
    return (
      <div className="px-4 py-12 text-center text-muted-foreground">
        <BookOpen className="h-12 w-12 mx-auto mb-3 opacity-30" />
        <p className="text-sm">برای استفاده از تایمر درس، وارد حساب خود شوید</p>
      </div>
    )
  }

  const subjects = SUBJECTS_BY_FIELD_GRADE[currentUser.studyField][currentUser.grade]

  const saveSession = (newSessions: StudySession[]) => {
    setSessions(newSessions)
    localStorage.setItem(`study-sessions-${currentUser.id}`, JSON.stringify(newSessions))
  }

  const handleStart = () => {
    if (!selectedSubject) {
      toast.error('یک درس انتخاب کنید')
      return
    }
    startTimer({
      name: selectedSubject,
      emoji: SUBJECT_EMOJIS[selectedSubject] || '📚',
      description: `درس ${selectedSubject} - ${FIELD_LABELS[currentUser.studyField]} پایه ${currentUser.grade}`,
      categoryId: 'study',
      notificationEnabled: false,
    })
    setElapsedSeconds(0)
    toast.success(`شروع مطالعه: ${selectedSubject} 📚`)
  }

  const handleStop = () => {
    if (!activeTimer) return
    const minutes = Math.floor(elapsedSeconds / 60)
    stopTimer(activeTimer.id)
    
    // ذخیره جلسه
    const newSession: StudySession = {
      id: `study_${Date.now()}`,
      subject: selectedSubject,
      seconds: elapsedSeconds,
      date: new Date().toISOString(),
    }
    saveSession([newSession, ...sessions])
    
    // XP
    if (minutes > 0) {
      const xp = Math.floor(minutes / 60 * 50) + minutes
      addXP(xp, `درس ${selectedSubject}`)
      toast.success(`${toPersianDigits(minutes)} دقیقه مطالعه ${selectedSubject}! +${toPersianDigits(xp)} XP`)
    }
    
    setElapsedSeconds(0)
  }

  // محاسبه آمار
  const todayStr = new Date().toDateString()
  const todaySessions = sessions.filter(s => new Date(s.date).toDateString() === todayStr)
  const todayTotal = todaySessions.reduce((sum, s) => sum + s.seconds, 0)
  const totalAll = sessions.reduce((sum, s) => sum + s.seconds, 0)

  // آمار هر درس
  const subjectStats = subjects.map(subj => {
    const subjSessions = sessions.filter(s => s.subject === subj)
    const total = subjSessions.reduce((sum, s) => sum + s.seconds, 0)
    return { subject: subj, total, count: subjSessions.length }
  }).sort((a, b) => b.total - a.total)

  const maxSubjectTime = Math.max(...subjectStats.map(s => s.total), 1)

  return (
    <div className="px-4 py-4 space-y-4">
      {/* اطلاعات کاربر */}
      <Card className="p-3 bg-primary/5 border-primary/20">
        <div className="flex items-center gap-2">
          <span className="text-2xl">{FIELD_EMOJIS[currentUser.studyField]}</span>
          <div>
            <p className="text-sm font-medium">
              {FIELD_LABELS[currentUser.studyField]} · پایه {toPersianDigits(currentUser.grade)}
            </p>
            <p className="text-xs text-muted-foreground">{toPersianDigits(subjects.length)} درس</p>
          </div>
        </div>
      </Card>

      {/* تایمر فعال */}
      {activeTimer && activeTimer.status !== 'completed' ? (
        <Card className="p-6 border-2 border-primary/30 bg-primary/5">
          <div className="text-center mb-4">
            <Badge className="bg-primary/15 text-primary gap-1 mb-2">
              {activeTimer.status === 'running' ? <Flame className="h-3 w-3" /> : <Pause className="h-3 w-3" />}
              {activeTimer.status === 'running' ? 'در حال مطالعه' : 'متوقف موقت'}
            </Badge>
            <div className="text-4xl font-mono font-bold tabular-nums">
              {formatSeconds(elapsedSeconds)}
            </div>
            <p className="text-sm text-muted-foreground mt-2">
              {SUBJECT_EMOJIS[selectedSubject] || '📚'} {selectedSubject}
            </p>
          </div>
          <div className="flex gap-2">
            {activeTimer.status === 'running' ? (
              <Button onClick={() => pauseTimer(activeTimer.id)} variant="outline" className="flex-1 h-12">
                <Pause className="h-5 w-5 ml-2" /> توقف
              </Button>
            ) : (
              <Button onClick={() => resumeTimer(activeTimer.id)} className="flex-1 h-12">
                <Play className="h-5 w-5 ml-2" /> ادامه
              </Button>
            )}
            <Button onClick={handleStop} variant="destructive" className="flex-1 h-12">
              <Square className="h-5 w-5 ml-2" /> پایان
            </Button>
          </div>
        </Card>
      ) : (
        <>
          {/* انتخاب درس */}
          <div className="space-y-2">
            <Label className="text-sm font-semibold">درس را انتخاب کنید</Label>
            <div className="grid grid-cols-3 gap-2">
              {subjects.map((subj) => (
                <button
                  key={subj}
                  onClick={() => setSelectedSubject(subj)}
                  className={`flex flex-col items-center gap-1 py-3 rounded-lg border-2 transition-all ${
                    selectedSubject === subj ? 'border-primary bg-primary/10 text-primary' : 'border-transparent bg-muted text-muted-foreground'
                  }`}
                >
                  <span className="text-2xl">{SUBJECT_EMOJIS[subj] || '📚'}</span>
                  <span className="text-xs font-medium text-center">{subj}</span>
                </button>
              ))}
            </div>
          </div>

          {/* دکمه شروع */}
          <Button
            onClick={handleStart}
            disabled={!selectedSubject}
            className="w-full h-14 text-base"
          >
            <Play className="h-6 w-6 ml-2" />
            شروع مطالعه {selectedSubject}
          </Button>
        </>
      )}

      {/* آمار امروز */}
      <div className="grid grid-cols-2 gap-3">
        <Card className="p-4">
          <Clock className="h-5 w-5 text-blue-500 mb-2" />
          <p className="text-lg font-bold">{formatSeconds(todayTotal)}</p>
          <p className="text-xs text-muted-foreground">مطالعه امروز</p>
        </Card>
        <Card className="p-4">
          <Trophy className="h-5 w-5 text-amber-500 mb-2" />
          <p className="text-lg font-bold">{formatSeconds(totalAll)}</p>
          <p className="text-xs text-muted-foreground">کل مطالعه</p>
        </Card>
      </div>

      {/* نمودار درس‌ها */}
      {sessions.length > 0 && (
        <Card className="p-4">
          <h3 className="font-semibold mb-3 flex items-center gap-2">
            <BookOpen className="h-4 w-4" />
            رتبه‌بندی درس‌ها
          </h3>
          <div className="space-y-2">
            {subjectStats.filter(s => s.total > 0).map((s, i) => (
              <div key={s.subject} className="flex items-center gap-2">
                <span className="text-xs font-bold w-6">{toPersianDigits(i + 1)}</span>
                <span className="text-lg">{SUBJECT_EMOJIS[s.subject] || '📚'}</span>
                <span className="text-sm flex-1 truncate">{s.subject}</span>
                <div className="flex-1 max-w-[100px] h-4 bg-muted rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full bg-primary"
                    style={{ width: `${(s.total / maxSubjectTime) * 100}%` }}
                  />
                </div>
                <span className="text-xs font-mono w-12 text-left">{formatSeconds(s.total)}</span>
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* جلسات اخیر */}
      {todaySessions.length > 0 && (
        <div>
          <h3 className="text-sm font-semibold text-muted-foreground mb-2 px-1">
            جلسات امروز ({toPersianDigits(todaySessions.length)})
          </h3>
          <div className="space-y-1">
            {todaySessions.slice(0, 5).map((s) => (
              <Card key={s.id} className="p-2">
                <div className="flex items-center gap-2">
                  <span className="text-lg">{SUBJECT_EMOJIS[s.subject] || '📚'}</span>
                  <span className="text-sm flex-1">{s.subject}</span>
                  <span className="text-xs font-mono text-primary">{formatSeconds(s.seconds)}</span>
                </div>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* دکمه لیگ */}
      <Button variant="outline" className="w-full h-12" onClick={() => {
        toast.info('لیگ رقابت از منوی بیشتر قابل دسترس است')
      }}>
        <Trophy className="h-5 w-5 ml-2" />
        مشاهده لیگ رقابت
      </Button>
    </div>
  )
}

import { Label } from '@/components/ui/label'
