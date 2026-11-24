'use client'

import { useState, useEffect, useMemo } from 'react'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { useAuthStore } from '@/lib/auth-store'
import { FIELD_LABELS, FIELD_EMOJIS, StudyField, SUBJECTS_BY_FIELD_GRADE } from '@/lib/auth-types'
import { toPersianDigits, formatJalaliDate } from '@/lib/jalali'
import { formatSeconds } from '@/lib/time-format'
import { Trophy, Crown, Medal, Flame, ChevronLeft } from 'lucide-react'

interface LeaderboardUser {
  userId: string
  username: string
  displayName: string
  avatar: string
  studyField: StudyField
  grade: number
  totalSeconds: number
  subjectBreakdown: Record<string, number>
}

export function LeaguePage() {
  const { currentUser, getUserByUsername, searchUsers } = useAuthStore()
  const [activeTab, setActiveTab] = useState<'field' | 'subject' | 'all'>('all')
  const [selectedSubject, setSelectedSubject] = useState<string>('')
  const [leaderboard, setLeaderboard] = useState<LeaderboardUser[]>([])
  const [selectedUserProfile, setSelectedUserProfile] = useState<any>(null)
  const [loaded, setLoaded] = useState(false)

  // بارگذاری داده‌های لیگ
  useEffect(() => {
    if (loaded) return
    // جمع‌آوری تمام داده‌های مطالعه از localStorage کاربران
    const users = JSON.parse(localStorage.getItem('task-reminder-users-db') || '[]')
    const lbData: LeaderboardUser[] = []

    users.forEach((u: any) => {
      const sessions = JSON.parse(localStorage.getItem(`study-sessions-${u.id}`) || '[]')
      const totalSeconds = sessions.reduce((sum: number, s: any) => sum + s.seconds, 0)
      
      const subjectBreakdown: Record<string, number> = {}
      sessions.forEach((s: any) => {
        subjectBreakdown[s.subject] = (subjectBreakdown[s.subject] || 0) + s.seconds
      })

      if (totalSeconds > 0) {
        lbData.push({
          userId: u.id,
          username: u.username,
          displayName: u.displayName,
          avatar: u.avatar,
          studyField: u.studyField,
          grade: u.grade,
          totalSeconds,
          subjectBreakdown,
        })
      }
    })

    // اضافه کردن کاربران دمو اگه لیست خالی باشه
    if (lbData.length === 0) {
      const demoUsers = [
        { username: 'sara_math', displayName: 'سارا محمدی', avatar: '👩', studyField: 'math' as StudyField, grade: 12, totalSeconds: 14400, subjectBreakdown: { 'ریاضی': 7200, 'فیزیک': 3600, 'شیمی': 3600 } },
        { username: 'ali_study', displayName: 'علی رضایی', avatar: '🧑', studyField: 'science' as StudyField, grade: 11, totalSeconds: 10800, subjectBreakdown: { 'زیست': 5400, 'شیمی': 3600, 'ریاضی': 1800 } },
        { username: 'maryam_k', displayName: 'مریم حسینی', avatar: '👧', studyField: 'humanities' as StudyField, grade: 12, totalSeconds: 7200, subjectBreakdown: { 'ادبیات فارسی': 3600, 'تاریخ': 1800, 'جغرافیا': 1800 } },
        { username: 'reza_ph', displayName: 'رضا کریمی', avatar: '👦', studyField: 'math' as StudyField, grade: 11, totalSeconds: 5400, subjectBreakdown: { 'ریاضی': 3600, 'فیزیک': 1800 } },
        { username: 'negar_s', displayName: 'نگار سلیمانی', avatar: '👩', studyField: 'science' as StudyField, grade: 10, totalSeconds: 3600, subjectBreakdown: { 'زیست': 1800, 'ریاضی': 1800 } },
      ]
      demoUsers.forEach(d => lbData.push({ userId: d.username, ...d } as any))
    }

    setTimeout(() => setLeaderboard(lbData), 0)
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoaded(true)
  }, [loaded])

  // فیلتر لیست
  const filteredLeaderboard = useMemo(() => {
    let result = [...leaderboard]

    if (activeTab === 'field' && currentUser) {
      result = result.filter(u => u.studyField === currentUser.studyField)
    } else if (activeTab === 'subject' && selectedSubject) {
      result = result.filter(u => u.subjectBreakdown[selectedSubject] > 0)
      result = result.sort((a, b) => (b.subjectBreakdown[selectedSubject] || 0) - (a.subjectBreakdown[selectedSubject] || 0))
    } else {
      result = result.sort((a, b) => b.totalSeconds - a.totalSeconds)
    }

    return result.slice(0, 50) // فقط ۵۰ نفر برتر
  }, [leaderboard, activeTab, selectedSubject, currentUser])

  // لیست درس‌ها برای تب درس
  const allSubjects = useMemo(() => {
    const subjects = new Set<string>()
    leaderboard.forEach(u => Object.keys(u.subjectBreakdown).forEach(s => subjects.add(s)))
    return Array.from(subjects).sort()
  }, [leaderboard])

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Crown className="h-5 w-5 text-amber-500" />
    if (rank === 2) return <Medal className="h-5 w-5 text-gray-400" />
    if (rank === 3) return <Medal className="h-5 w-5 text-orange-700" />
    return <span className="text-sm font-bold text-muted-foreground">{toPersianDigits(rank)}</span>
  }

  const handleUserClick = (user: LeaderboardUser) => {
    setSelectedUserProfile(user)
  }

  return (
    <div className="px-4 py-4 space-y-4">
      {/* هدر */}
      <Card className="p-4 bg-gradient-to-br from-amber-500/10 to-transparent border-amber-500/20">
        <div className="flex items-center gap-3">
          <Trophy className="h-8 w-8 text-amber-500" />
          <div>
            <h2 className="font-bold">لیگ رقابت</h2>
            <p className="text-xs text-muted-foreground">۵۰ نفر برتر بر اساس زمان مطالعه</p>
          </div>
        </div>
      </Card>

      {/* تب‌ها */}
      <div className="flex gap-1 bg-muted p-1 rounded-lg">
        {[
          { id: 'all', label: 'همه' },
          { id: 'field', label: currentUser ? FIELD_LABELS[currentUser.studyField] : 'رشته من' },
          { id: 'subject', label: 'درس' },
        ].map((t) => (
          <button
            key={t.id}
            onClick={() => setActiveTab(t.id as any)}
            className={`flex-1 py-2 rounded-md text-xs font-medium transition-all ${
              activeTab === t.id ? 'bg-background text-primary shadow-sm' : 'text-muted-foreground'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* انتخاب درس (فقط تب درس) */}
      {activeTab === 'subject' && (
        <div className="flex flex-wrap gap-1.5">
          {allSubjects.map((subj) => (
            <button
              key={subj}
              onClick={() => setSelectedSubject(subj)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                selectedSubject === subj ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground'
              }`}
            >
              {subj}
            </button>
          ))}
        </div>
      )}

      {/* لیست برترین‌ها */}
      {filteredLeaderboard.length === 0 ? (
        <div className="text-center py-12 text-muted-foreground">
          <Trophy className="h-12 w-12 mx-auto mb-3 opacity-30" />
          <p className="text-sm">هنوز کسی مطالعه نکرده</p>
          {activeTab === 'subject' && !selectedSubject && (
            <p className="text-xs mt-1">یک درس را انتخاب کنید</p>
          )}
        </div>
      ) : (
        <div className="space-y-2">
          {/* ۳ نفر اول با کارت خاص */}
          {filteredLeaderboard.slice(0, 3).map((user, i) => (
            <Card
              key={user.userId}
              className={`p-3 cursor-pointer hover:shadow-md transition-shadow ${
                i === 0 ? 'bg-amber-50 dark:bg-amber-950/20 border-amber-300 dark:border-amber-900' :
                i === 1 ? 'bg-gray-50 dark:bg-gray-950/20 border-gray-300 dark:border-gray-800' :
                'bg-orange-50 dark:bg-orange-950/20 border-orange-300 dark:border-orange-900'
              }`}
              onClick={() => handleUserClick(user)}
            >
              <div className="flex items-center gap-3">
                <div className="shrink-0 w-8 flex justify-center">
                  {getRankIcon(i + 1)}
                </div>
                <Avatar className="h-10 w-10 shrink-0">
                  <AvatarFallback className="bg-primary/10 text-lg">{user.avatar}</AvatarFallback>
                </Avatar>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-sm truncate">{user.displayName}</p>
                  <div className="flex items-center gap-1.5">
                    <span className="text-xs text-muted-foreground" dir="ltr">@{user.username}</span>
                    <Badge variant="outline" className="text-xs h-4 gap-0.5">
                      {FIELD_EMOJIS[user.studyField]}
                      <span className="text-[10px]">{FIELD_LABELS[user.studyField]}</span>
                    </Badge>
                    <Badge variant="outline" className="text-xs h-4">پایه {toPersianDigits(user.grade)}</Badge>
                  </div>
                </div>
                <div className="text-left shrink-0">
                  <p className="font-bold text-sm">
                    {activeTab === 'subject' && selectedSubject
                      ? formatSeconds(user.subjectBreakdown[selectedSubject] || 0)
                      : formatSeconds(user.totalSeconds)}
                  </p>
                  <p className="text-xs text-muted-foreground">زمان</p>
                </div>
              </div>
            </Card>
          ))}

          {/* بقیه */}
          {filteredLeaderboard.slice(3).map((user, i) => (
            <Card
              key={user.userId}
              className="p-3 cursor-pointer hover:bg-muted/50 transition-colors"
              onClick={() => handleUserClick(user)}
            >
              <div className="flex items-center gap-3">
                <div className="shrink-0 w-8 flex justify-center">
                  {getRankIcon(i + 4)}
                </div>
                <Avatar className="h-8 w-8 shrink-0">
                  <AvatarFallback className="bg-primary/10 text-sm">{user.avatar}</AvatarFallback>
                </Avatar>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm truncate">{user.displayName}</p>
                  <span className="text-xs text-muted-foreground" dir="ltr">@{user.username}</span>
                </div>
                <div className="text-left shrink-0">
                  <p className="font-mono text-sm text-primary">
                    {activeTab === 'subject' && selectedSubject
                      ? formatSeconds(user.subjectBreakdown[selectedSubject] || 0)
                      : formatSeconds(user.totalSeconds)}
                  </p>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* پروفایل کاربر انتخاب شده */}
      {selectedUserProfile && (
        <div
          className="fixed inset-0 z-[60] bg-background/80 backdrop-blur flex items-end sm:items-center justify-center p-4"
          onClick={() => setSelectedUserProfile(null)}
        >
          <Card className="w-full max-w-md p-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <Avatar className="h-16 w-16">
                  <AvatarFallback className="bg-primary/10 text-3xl">{selectedUserProfile.avatar}</AvatarFallback>
                </Avatar>
                <div>
                  <h3 className="font-bold text-lg">{selectedUserProfile.displayName}</h3>
                  <p className="text-sm text-muted-foreground" dir="ltr">@{selectedUserProfile.username}</p>
                </div>
              </div>
              <button onClick={() => setSelectedUserProfile(null)} className="text-muted-foreground">
                <ChevronLeft className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex justify-between text-sm">
                <span>رشته:</span>
                <span className="font-medium">
                  {FIELD_EMOJIS[selectedUserProfile.studyField]} {FIELD_LABELS[selectedUserProfile.studyField]}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span>پایه:</span>
                <span className="font-medium">{toPersianDigits(selectedUserProfile.grade)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span>کل زمان مطالعه:</span>
                <span className="font-bold text-primary">{formatSeconds(selectedUserProfile.totalSeconds)}</span>
              </div>
            </div>

            {/* تفکیک درس‌ها */}
            {selectedUserProfile.subjectBreakdown && Object.keys(selectedUserProfile.subjectBreakdown).length > 0 && (
              <div>
                <p className="text-xs font-semibold text-muted-foreground mb-2">زمان هر درس:</p>
                <div className="space-y-1">
                  {Object.entries(selectedUserProfile.subjectBreakdown)
                    .sort((a: any, b: any) => b[1] - a[1])
                    .map(([subj, secs]: any) => (
                      <div key={subj} className="flex items-center justify-between text-xs">
                        <span>{subj}</span>
                        <span className="font-mono text-primary">{formatSeconds(secs)}</span>
                      </div>
                    ))}
                </div>
              </div>
            )}
          </Card>
        </div>
      )}
    </div>
  )
}
