'use client'

import { useState, useEffect, useRef, useMemo } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import {
  Users, Plus, Flame, Send, Lock, Search, Copy, Share2,
} from 'lucide-react'
import { useAuthStore } from '@/lib/auth-store'
import { toPersianDigits } from '@/lib/jalali'
import { toast } from 'sonner'

interface StudyRoom {
  id: string
  roomCode: string // کد ۶ رقمی انگلیسی
  name: string
  hostId: string
  hostName: string
  hostAvatar: string
  members: { userId: string; username: string; displayName: string; avatar: string; focusMinutes: number; isFocusing: boolean }[]
  challengeMinutes: number
  createdAt: string
}

interface StudyMessage {
  id: string
  roomId: string
  userId: string
  username: string
  displayName: string
  avatar: string
  text: string
  createdAt: string
}

function generateRoomCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)]
  }
  return code
}

export function StudyRoomPage() {
  const { currentUser } = useAuthStore()
  const [rooms, setRooms] = useState<StudyRoom[]>([])
  const [activeRoom, setActiveRoom] = useState<StudyRoom | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [showJoin, setShowJoin] = useState(false)
  const [messages, setMessages] = useState<StudyMessage[]>([])
  const [msgText, setMsgText] = useState('')
  const [isFocusing, setIsFocusing] = useState(false)
  const [focusSeconds, setFocusSeconds] = useState(0)
  const timerRef = useRef<number | null>(null)
  const [loaded, setLoaded] = useState(false)

  // بارگذاری اتاق‌ها
  useEffect(() => {
    if (loaded) return
    const data = localStorage.getItem('study-rooms')
    if (data) {
      try {
        const parsed = JSON.parse(data)
        setTimeout(() => setRooms(parsed), 0)
      } catch {}
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoaded(true)
  }, [loaded])

  if (!currentUser) {
    return (
      <div className="px-4 py-12 text-center">
        <Lock className="h-16 w-16 mx-auto mb-3 text-muted-foreground opacity-30" />
        <p className="text-sm text-muted-foreground">برای استفاده از اتاق مطالعه، وارد حساب خود شوید</p>
      </div>
    )
  }

  const saveRooms = (newRooms: StudyRoom[]) => {
    setRooms(newRooms)
    localStorage.setItem('study-rooms', JSON.stringify(newRooms))
  }

  const joinRoom = (room: StudyRoom) => {
    if (!room.members.find((m) => m.userId === currentUser.id)) {
      const updated = {
        ...room,
        members: [...room.members, {
          userId: currentUser.id,
          username: currentUser.username,
          displayName: currentUser.displayName,
          avatar: currentUser.avatar,
          focusMinutes: 0,
          isFocusing: false,
        }],
      }
      const newRooms = rooms.map((r) => r.id === room.id ? updated : r)
      saveRooms(newRooms)
      setActiveRoom(updated)
    } else {
      setActiveRoom(room)
    }
    const msgData = localStorage.getItem(`study-messages-${room.id}`)
    if (msgData) { try { setMessages(JSON.parse(msgData)) } catch {} }
  }

  // جستجوی اتاق با کد
  const joinByCode = (code: string) => {
    const allRooms = JSON.parse(localStorage.getItem('study-rooms') || '[]')
    const room = allRooms.find((r: StudyRoom) => r.roomCode === code.toUpperCase())
    if (!room) {
      toast.error('اتاقی با این کد پیدا نشد')
      return
    }
    joinRoom(room)
    setShowJoin(false)
    toast.success(`وارد اتاق "${room.name}" شدید`)
  }

  const toggleFocus = () => {
    if (isFocusing) {
      if (timerRef.current) clearInterval(timerRef.current)
      const minutes = Math.floor(focusSeconds / 60)
      if (activeRoom && minutes > 0) {
        const updated = {
          ...activeRoom,
          members: activeRoom.members.map((m) =>
            m.userId === currentUser.id
              ? { ...m, focusMinutes: m.focusMinutes + minutes, isFocusing: false }
              : m
          ),
        }
        const newRooms = rooms.map((r) => r.id === activeRoom.id ? updated : r)
        saveRooms(newRooms)
        setActiveRoom(updated)
        toast.success(`${toPersianDigits(minutes)} دقیقه تمرکز!`)
      }
      setIsFocusing(false)
      setFocusSeconds(0)
    } else {
      setIsFocusing(true)
      timerRef.current = window.setInterval(() => setFocusSeconds((s) => s + 1), 1000)
      toast.info('تمرکز شروع شد! 🧠')
    }
  }

  const sendMessage = () => {
    if (!msgText.trim() || !activeRoom) return
    const msg: StudyMessage = {
      id: `msg_${Date.now()}`,
      roomId: activeRoom.id,
      userId: currentUser.id,
      username: currentUser.username,
      displayName: currentUser.displayName,
      avatar: currentUser.avatar,
      text: msgText.trim(),
      createdAt: new Date().toISOString(),
    }
    const newMsgs = [...messages, msg]
    setMessages(newMsgs)
    localStorage.setItem(`study-messages-${activeRoom.id}`, JSON.stringify(newMsgs))
    setMsgText('')
  }

  const copyRoomCode = () => {
    if (activeRoom) {
      navigator.clipboard.writeText(activeRoom.roomCode)
      toast.success(`کد اتاق کپی شد: ${activeRoom.roomCode}`)
    }
  }

  const shareRoom = async () => {
    if (activeRoom) {
      const text = `بیا با هم درس بخونیم! 📚\nاتاق مطالعه: ${activeRoom.name}\nکد ورود: ${activeRoom.roomCode}`
      if (navigator.share) {
        try { await navigator.share({ title: 'اتاق مطالعه', text }) } catch {}
      } else {
        navigator.clipboard.writeText(text)
        toast.success('اطلاعات اتاق کپی شد')
      }
    }
  }

  // صفحه فعال (داخل اتاق)
  if (activeRoom) {
    const totalFocus = activeRoom.members.reduce((sum, m) => sum + m.focusMinutes, 0)
    const focusingCount = activeRoom.members.filter((m) => m.isFocusing).length

    return (
      <div className="fixed inset-0 z-[60] bg-background flex flex-col">
        <div className="flex items-center gap-3 p-3 border-b safe-top">
          <Button variant="ghost" size="icon" className="h-9 w-9" onClick={() => { setActiveRoom(null); setIsFocusing(false); if (timerRef.current) clearInterval(timerRef.current) }}>
            ←
          </Button>
          <div className="flex-1">
            <p className="font-medium text-sm">{activeRoom.name}</p>
            <p className="text-xs text-muted-foreground">{toPersianDigits(activeRoom.members.length)} نفر · {toPersianDigits(focusingCount)} در حال تمرکز</p>
          </div>
          <Button variant="ghost" size="icon" className="h-9 w-9" onClick={copyRoomCode} title="کپی کد اتاق">
            <Copy className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="icon" className="h-9 w-9" onClick={shareRoom} title="اشتراک‌گذاری">
            <Share2 className="h-4 w-4" />
          </Button>
        </div>

        {/* کد اتاق */}
        <div className="px-3 py-2 bg-primary/5 border-b text-center">
          <p className="text-xs text-muted-foreground">کد دعوت اتاق:</p>
          <p className="text-xl font-mono font-bold tracking-widest text-primary" dir="ltr">{activeRoom.roomCode}</p>
        </div>

        {/* کارت تمرکز مشترک */}
        <Card className="m-3 p-4 bg-primary/5 border-primary/20">
          <div className="text-center">
            <p className="text-xs text-muted-foreground mb-1">چالش گروهی ({toPersianDigits(activeRoom.challengeMinutes)} دقیقه)</p>
            <p className="text-3xl font-mono font-bold">
              {toPersianDigits(Math.floor(focusSeconds / 60).toString().padStart(2, '0'))}:{toPersianDigits((focusSeconds % 60).toString().padStart(2, '0'))}
            </p>
            <p className="text-xs text-muted-foreground mt-1">مجموع گروه: {toPersianDigits(totalFocus)} دقیقه</p>
          </div>
          <Button
            className={`w-full mt-3 h-12 ${isFocusing ? 'bg-destructive' : 'bg-primary'}`}
            onClick={toggleFocus}
          >
            {isFocusing ? '⏸ توقف تمرکز' : '🔥 شروع تمرکز'}
          </Button>
        </Card>

        {/* اعضا */}
        <div className="px-3 pb-2">
          <p className="text-xs font-semibold text-muted-foreground mb-2">اعضای اتاق</p>
          <div className="flex gap-2 overflow-x-auto no-scrollbar">
            {activeRoom.members.map((m) => (
              <div key={m.userId} className="flex flex-col items-center gap-1 shrink-0">
                <div className="relative">
                  <Avatar className="h-10 w-10">
                    <AvatarFallback className="bg-primary/10">{m.avatar}</AvatarFallback>
                  </Avatar>
                  {m.isFocusing && (
                    <span className="absolute -bottom-1 -left-1 text-xs">🔥</span>
                  )}
                </div>
                <span className="text-[10px] truncate max-w-[50px]">{m.displayName.split(' ')[0]}</span>
                {m.focusMinutes > 0 && (
                  <span className="text-[8px] text-muted-foreground">{toPersianDigits(m.focusMinutes)}د</span>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* چت محدود */}
        <div className="flex-1 overflow-y-auto px-3 space-y-2" style={{ WebkitOverflowScrolling: 'touch' }}>
          {messages.length === 0 ? (
            <p className="text-center text-xs text-muted-foreground py-4">چت محدود - فقط پیام‌های کوتاه (۱۰۰ کاراکتر)</p>
          ) : (
            messages.map((m) => (
              <div key={m.id} className={`flex ${m.userId === currentUser.id ? 'justify-start' : 'justify-end'}`}>
                <div className={`max-w-[75%] rounded-2xl px-3 py-1.5 ${m.userId === currentUser.id ? 'bg-primary text-primary-foreground' : 'bg-muted'}`}>
                  <p className="text-xs font-semibold mb-0.5 opacity-70">{m.displayName}</p>
                  <p className="text-sm">{m.text}</p>
                </div>
              </div>
            ))
          )}
        </div>

        {/* ورودی چت */}
        <div className="p-3 border-t safe-bottom">
          <div className="flex gap-2">
            <Input
              value={msgText}
              onChange={(e) => setMsgText(e.target.value.slice(0, 100))}
              placeholder="پیام کوتاه..."
              onKeyDown={(e) => { if (e.key === 'Enter') sendMessage() }}
              maxLength={100}
            />
            <Button size="icon" onClick={sendMessage} disabled={!msgText.trim()}>
              <Send className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </div>
    )
  }

  // لیست اتاق‌ها
  return (
    <div className="px-4 py-4 space-y-4">
      <div className="grid grid-cols-2 gap-2">
        <Button onClick={() => setShowCreate(true)} className="h-12">
          <Plus className="h-5 w-5 ml-2" />
          اتاق جدید
        </Button>
        <Button variant="outline" onClick={() => setShowJoin(true)} className="h-12">
          <Search className="h-5 w-5 ml-2" />
          ورود با کد
        </Button>
      </div>

      {/* توضیح */}
      <Card className="p-3 bg-green-50 dark:bg-green-950/20 border-green-200 dark:border-green-900">
        <p className="text-xs text-green-700 dark:text-green-400 leading-relaxed">
          👯 <strong>اتاق مطالعه چیست؟</strong> یه فضای گروهی که تا ۳۰ نفر می‌تونن وارد بشن و با هم تمرکز کنن.
          کد ۶ رقمی اتاق رو به دوستات بده تا وارد بشن. همه تایمر مشترک می‌بینن و می‌تونن چت کوتاه کنن.
        </p>
      </Card>

      {rooms.length === 0 ? (
        <div className="text-center py-12 text-muted-foreground">
          <Users className="h-12 w-12 mx-auto mb-3 opacity-30" />
          <p className="text-sm">هنوز اتاقی ساخته نشده</p>
          <p className="text-xs mt-1">یه اتاق بساز یا با کد وارد اتاق بقیه بشو</p>
        </div>
      ) : (
        <div className="space-y-2">
          <p className="text-xs font-semibold text-muted-foreground px-1">اتاق‌های شما:</p>
          {rooms.map((r) => (
            <Card key={r.id} className="p-4 cursor-pointer hover:shadow-md transition-shadow" onClick={() => joinRoom(r)}>
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-full bg-primary/15 flex items-center justify-center shrink-0">
                  <Users className="h-5 w-5 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm truncate">{r.name}</p>
                  <div className="flex items-center gap-2 mt-0.5">
                    <Badge variant="outline" className="text-xs h-5">{toPersianDigits(r.members.length)} نفر</Badge>
                    <Badge variant="outline" className="text-xs h-5 font-mono" dir="ltr">{r.roomCode}</Badge>
                    <span className="text-xs text-muted-foreground">میزبان: {r.hostName}</span>
                  </div>
                </div>
                {r.members.filter((m) => m.isFocusing).length > 0 && (
                  <Badge className="bg-orange-500/15 text-orange-500 gap-1">
                    <Flame className="h-3 w-3" />
                    {toPersianDigits(r.members.filter((m) => m.isFocusing).length)}
                  </Badge>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      <CreateRoomDialog
        key={showCreate ? 'open' : 'closed'}
        open={showCreate}
        onOpenChange={setShowCreate}
        user={currentUser}
        onCreate={(name, challenge) => {
          const room: StudyRoom = {
            id: `room_${Date.now()}`,
            roomCode: generateRoomCode(),
            name,
            hostId: currentUser.id,
            hostName: currentUser.displayName,
            hostAvatar: currentUser.avatar,
            members: [{
              userId: currentUser.id,
              username: currentUser.username,
              displayName: currentUser.displayName,
              avatar: currentUser.avatar,
              focusMinutes: 0,
              isFocusing: false,
            }],
            challengeMinutes: challenge,
            createdAt: new Date().toISOString(),
          }
          const newRooms = [room, ...rooms]
          saveRooms(newRooms)
          setShowCreate(false)
          joinRoom(room)
          toast.success(`اتاق ساخته شد! کد: ${room.roomCode}`)
        }}
      />

      <JoinRoomDialog
        key={showJoin ? 'open' : 'closed'}
        open={showJoin}
        onOpenChange={setShowJoin}
        onJoin={joinByCode}
      />
    </div>
  )
}

function CreateRoomDialog({ open, onOpenChange, user, onCreate }: any) {
  const [name, setName] = useState('')
  const [challenge, setChallenge] = useState(50)

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="text-right">اتاق مطالعه جدید</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 pt-2">
          <div className="space-y-2">
            <label className="text-sm font-medium">نام اتاق</label>
            <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="مثلا: کنکوری‌های عربی" />
          </div>
          <div className="space-y-2">
            <div className="flex justify-between">
              <label className="text-sm font-medium">چالش گروهی (دقیقه)</label>
              <span className="font-bold">{toPersianDigits(challenge)}</span>
            </div>
            <Input type="range" min="25" max="120" step="5" value={challenge} onChange={(e) => setChallenge(parseInt(e.target.value))} />
          </div>
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)}>انصراف</Button>
            <Button className="flex-1" disabled={!name.trim()} onClick={() => onCreate(name.trim(), challenge)}>ساخت اتاق</Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function JoinRoomDialog({ open, onOpenChange, onJoin }: any) {
  const [code, setCode] = useState('')

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="text-right">ورود به اتاق با کد</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 pt-2">
          <div className="space-y-2">
            <label className="text-sm font-medium">کد اتاق (۶ حرف)</label>
            <Input
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 6))}
              placeholder="مثلا: ABC123"
              dir="ltr"
              className="text-center text-2xl font-mono tracking-widest"
              autoFocus
            />
          </div>
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)}>انصراف</Button>
            <Button className="flex-1" disabled={code.length !== 6} onClick={() => onJoin(code)}>ورود</Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
