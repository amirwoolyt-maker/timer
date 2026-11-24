'use client'

import { useState, useMemo } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import { Slider } from '@/components/ui/slider'
import { Textarea } from '@/components/ui/textarea'
import {
  Plus, Trash2, Heart, Droplet, Calendar, TrendingUp, Flower2,
  Moon, Sun, Zap, Brain, Coffee, AlertCircle,
} from 'lucide-react'
import { useAuthStore } from '@/lib/auth-store'
import { toPersianDigits, formatJalaliDate, gregorianToJalali, PERSIAN_MONTHS } from '@/lib/jalali'
import { toast } from 'sonner'
import { useEffect } from 'react'

interface PeriodCycle {
  id: string
  startDate: string
  cycleLength: number
  periodLength: number
  symptoms: string[]
  notes: string
}

const SYMPTOMS = [
  'درد شکم', 'سردرد', 'خستگی', 'تغییرات خلقی', 'نفخ',
  'حساسیت سینه', 'جوش', 'اشتهای زیاد', 'بی‌خوابی', 'گرفتگی'
]

const PHASE_INFO = [
  {
    name: 'فاز قاعدگی',
    days: 'روز ۱ تا ۵',
    emoji: '🩸',
    color: '#ef4444',
    desc: 'دوره پریود - خونریزی رخ می‌دهد',
    tips: 'استراحت کنید، آبرسانی کنید، غذاهای آهن‌دار بخورید',
    hormones: 'استروژن و پروژسترون پایین',
  },
  {
    name: 'فاز فولیکولر',
    days: 'روز ۶ تا ۱۳',
    emoji: '🌱',
    color: '#10b981',
    desc: 'تخمدان‌ها آماده می‌شوند برای تخمک‌گذاری',
    tips: 'انرژی بالا، بهترین زمان برای ورزش و یادگیری',
    hormones: 'استروژن در حال افزایش',
  },
  {
    name: 'فاز تخمک‌گذاری',
    days: 'روز ۱۴',
    emoji: '✨',
    color: '#f59e0b',
    desc: 'تخمک از تخمدان آزاد می‌شود',
    tips: 'بیشترین انرژی، بهترین زمان برای کارهای مهم',
    hormones: 'LH و استروژن اوج',
  },
  {
    name: 'فاز لوتئال',
    days: 'روز ۱۵ تا ۲۸',
    emoji: '🌙',
    color: '#8b5cf6',
    desc: 'بدن آماده بارداری یا شروع دوره بعدی می‌شود',
    tips: 'ممکن است خلق پایین بیاید، استراحت و خودمراقبتی مهم است',
    hormones: 'پروژسترون بالا، سپس افت',
  },
]

export function PeriodCyclePage() {
  const { currentUser } = useAuthStore()
  const [cycles, setCycles] = useState<PeriodCycle[]>([])
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [loaded, setLoaded] = useState(false)
  
  // بارگذاری داده‌ها از localStorage (یه بار)
  useEffect(() => {
    if (!currentUser || loaded) return
    const data = localStorage.getItem(`period-cycles-${currentUser.id}`)
    if (data) {
      try {
        const parsed = JSON.parse(data)
        // استفاده از setTimeout برای جلوگیری از setState در effect
        setTimeout(() => setCycles(parsed), 0)
      } catch {}
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoaded(true)
  }, [currentUser, loaded])
  
  // ذخیره داده‌ها
  const saveCycles = (newCycles: PeriodCycle[]) => {
    setCycles(newCycles)
    if (currentUser) {
      localStorage.setItem(`period-cycles-${currentUser.id}`, JSON.stringify(newCycles))
    }
  }
  
  // محاسبه فاز فعلی
  const currentPhase = useMemo(() => {
    if (cycles.length === 0) return null
    
    const lastCycle = cycles[0]
    const startDate = new Date(lastCycle.startDate)
    const today = new Date()
    const diffDays = Math.floor((today.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24))
    
    if (diffDays < 0) return null
    
    // محاسبه روز در چرخه فعلی
    const dayInCycle = diffDays % lastCycle.cycleLength
    
    if (dayInCycle < lastCycle.periodLength) {
      return { ...PHASE_INFO[0], dayInCycle: dayInCycle + 1 }
    } else if (dayInCycle < 13) {
      return { ...PHASE_INFO[1], dayInCycle: dayInCycle + 1 }
    } else if (dayInCycle < 15) {
      return { ...PHASE_INFO[2], dayInCycle: dayInCycle + 1 }
    } else {
      return { ...PHASE_INFO[3], dayInCycle: dayInCycle + 1 }
    }
  }, [cycles])
  
  // پیش‌بینی پریود بعدی
  const nextPeriodDate = useMemo(() => {
    if (cycles.length === 0) return null
    const lastCycle = cycles[0]
    const startDate = new Date(lastCycle.startDate)
    const nextDate = new Date(startDate)
    nextDate.setDate(nextDate.getDate() + lastCycle.cycleLength)
    return nextDate
  }, [cycles])
  
  const handleAddCycle = (data: Omit<PeriodCycle, 'id'>) => {
    const newCycle: PeriodCycle = {
      ...data,
      id: `cycle_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
    }
    saveCycles([newCycle, ...cycles])
    toast.success('چرخه ثبت شد')
    setShowAddDialog(false)
  }
  
  const handleDelete = (id: string) => {
    if (confirm('حذف شود؟')) {
      saveCycles(cycles.filter(c => c.id !== id))
      toast.success('حذف شد')
    }
  }
  
  // اگه کاربر وارد نشده
  if (!currentUser) {
    return (
      <div className="px-4 py-12 text-center">
        <Flower2 className="h-16 w-16 mx-auto mb-3 text-muted-foreground opacity-30" />
        <p className="text-sm text-muted-foreground">
          برای استفاده از این بخش، وارد حساب خود شوید
        </p>
      </div>
    )
  }
  
  return (
    <div className="px-4 py-4 space-y-4">
      {/* فاز فعلی */}
      {currentPhase ? (
        <Card 
          className="p-5 border-2"
          style={{ borderColor: currentPhase.color + '40', backgroundColor: currentPhase.color + '08' }}
        >
          <div className="flex items-center gap-3 mb-3">
            <span className="text-4xl">{currentPhase.emoji}</span>
            <div>
              <h3 className="font-bold text-lg" style={{ color: currentPhase.color }}>
                {currentPhase.name}
              </h3>
              <p className="text-xs text-muted-foreground">
                روز {toPersianDigits(currentPhase.dayInCycle)} چرخه
              </p>
            </div>
          </div>
          <p className="text-sm mb-3">{currentPhase.desc}</p>
          <div className="space-y-2">
            <div className="flex items-start gap-2">
              <Brain className="h-4 w-4 text-primary shrink-0 mt-0.5" />
              <p className="text-xs">{currentPhase.hormones}</p>
            </div>
            <div className="flex items-start gap-2">
              <Zap className="h-4 w-4 text-amber-500 shrink-0 mt-0.5" />
              <p className="text-xs">{currentPhase.tips}</p>
            </div>
          </div>
        </Card>
      ) : (
        <Card className="p-5 bg-muted/50">
          <p className="text-sm text-center text-muted-foreground">
            چرخه‌ای ثبت نشده. اولین چرخه خود را اضافه کنید.
          </p>
        </Card>
      )}
      
      {/* پیش‌بینی پریود بعدی */}
      {nextPeriodDate && (
        <Card className="p-4">
          <div className="flex items-center gap-3">
            <Calendar className="h-8 w-8 text-primary shrink-0" />
            <div>
              <p className="text-xs text-muted-foreground">پریود بعدی تقریبی</p>
              <p className="font-bold">{formatJalaliDate(nextPeriodDate, true)}</p>
            </div>
          </div>
        </Card>
      )}
      
      {/* دکمه افزودن */}
      <Button onClick={() => setShowAddDialog(true)} className="w-full h-12">
        <Plus className="h-5 w-5 ml-2" />
        ثبت چرخه جدید
      </Button>
      
      {/* راهنمای فازها */}
      <Card className="p-4">
        <h3 className="font-semibold mb-3 flex items-center gap-2">
          <Flower2 className="h-4 w-4 text-primary" />
          مراحل چرخه
        </h3>
        <div className="space-y-2">
          {PHASE_INFO.map((phase, i) => (
            <div key={i} className="flex items-start gap-2">
              <span className="text-xl shrink-0">{phase.emoji}</span>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium" style={{ color: phase.color }}>
                    {phase.name}
                  </p>
                  <Badge variant="outline" className="text-xs">{phase.days}</Badge>
                </div>
                <p className="text-xs text-muted-foreground mt-0.5">{phase.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </Card>
      
      {/* توصیه‌های سلامتی */}
      <Card className="p-4 bg-pink-50 dark:bg-pink-950/20 border-pink-200 dark:border-pink-900">
        <h3 className="font-semibold mb-3 flex items-center gap-2 text-pink-700 dark:text-pink-400">
          <Heart className="h-4 w-4" />
          توصیه‌های سلامتی
        </h3>
        <ul className="space-y-2 text-xs">
          <li className="flex items-start gap-2">
            <Droplet className="h-3.5 w-3.5 text-pink-500 shrink-0 mt-0.5" />
            <span>آب فراوان بنوشید (حداقل ۸ لیوان روزانه)</span>
          </li>
          <li className="flex items-start gap-2">
            <Coffee className="h-3.5 w-3.5 text-amber-600 shrink-0 mt-0.5" />
            <span>کافئین و نمک را کم کنید</span>
          </li>
          <li className="flex items-start gap-2">
            <Sun className="h-3.5 w-3.5 text-orange-500 shrink-0 mt-0.5" />
            <span>ورزش سبک (پیاده‌روی، یوگا) مفید است</span>
          </li>
          <li className="flex items-start gap-2">
            <Moon className="h-3.5 w-3.5 text-indigo-500 shrink-0 mt-0.5" />
            <span>خواب کافی (۷-۹ ساعت) داشته باشید</span>
          </li>
          <li className="flex items-start gap-2">
            <TrendingUp className="h-3.5 w-3.5 text-green-500 shrink-0 mt-0.5" />
            <span>مصرف آهن و ویتامین C افزایش دهید</span>
          </li>
        </ul>
      </Card>
      
      {/* تاریخچه */}
      {cycles.length > 0 && (
        <div>
          <h2 className="text-sm font-semibold text-muted-foreground mb-2 px-1">
            تاریخچه ({toPersianDigits(cycles.length)})
          </h2>
          <div className="space-y-2">
            {cycles.map((c) => (
              <Card key={c.id} className="p-3">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium">
                      {formatJalaliDate(new Date(c.startDate), false)}
                    </p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      چرخه {toPersianDigits(c.cycleLength)} روزه · پریود {toPersianDigits(c.periodLength)} روزه
                    </p>
                    {c.symptoms.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-1">
                        {c.symptoms.slice(0, 3).map(s => (
                          <Badge key={s} variant="outline" className="text-xs h-5">{s}</Badge>
                        ))}
                      </div>
                    )}
                  </div>
                  <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => handleDelete(c.id)}>
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        </div>
      )}
      
      <NewCycleDialog
        key={showAddDialog ? 'open' : 'closed'}
        open={showAddDialog}
        onOpenChange={setShowAddDialog}
        onAdd={handleAddCycle}
      />
    </div>
  )
}

function NewCycleDialog({ open, onOpenChange, onAdd }: {
  open: boolean
  onOpenChange: (v: boolean) => void
  onAdd: (data: Omit<PeriodCycle, 'id'>) => void
}) {
  const [startDate, setStartDate] = useState(new Date().toISOString().split('T')[0])
  const [cycleLength, setCycleLength] = useState(28)
  const [periodLength, setPeriodLength] = useState(5)
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>([])
  const [notes, setNotes] = useState('')
  
  const toggleSymptom = (s: string) => {
    setSelectedSymptoms(prev => prev.includes(s) ? prev.filter(x => x !== s) : [...prev, s])
  }
  
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto hide-scrollbar" dir="rtl" style={{ WebkitOverflowScrolling: 'touch' }}>
        <DialogHeader>
          <DialogTitle className="text-right">ثبت چرخه جدید</DialogTitle>
          <DialogDescription className="text-right">
            اطلاعات چرخه قاعدگی خود را وارد کنید
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4 pt-2">
          {/* تاریخ شروع */}
          <div className="space-y-2">
            <Label>تاریخ شروع آخرین پریود</Label>
            <Input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="text-base"
            />
            {startDate && (
              <p className="text-xs text-muted-foreground">
                {(() => {
                  const [y, m, d] = startDate.split('-').map(Number)
                  const [jy, jm, jd] = gregorianToJalali(y, m, d)
                  return `معادل: ${toPersianDigits(jd)} ${PERSIAN_MONTHS[jm - 1]} ${toPersianDigits(jy)}`
                })()}
              </p>
            )}
          </div>
          
          {/* طول چرخه */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>طول چرخه (روز)</Label>
              <span className="text-lg font-bold">{toPersianDigits(cycleLength)}</span>
            </div>
            <Slider value={[cycleLength]} onValueChange={(v) => setCycleLength(v[0])} min={21} max={35} step={1} />
            <div className="flex justify-between text-xs text-muted-foreground">
              <span>۲۱</span>
              <span>طبیعی: ۲۸</span>
              <span>۳۵</span>
            </div>
          </div>
          
          {/* طول پریود */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>طول پریود (روز)</Label>
              <span className="text-lg font-bold">{toPersianDigits(periodLength)}</span>
            </div>
            <Slider value={[periodLength]} onValueChange={(v) => setPeriodLength(v[0])} min={2} max={10} step={1} />
          </div>
          
          {/* علائم */}
          <div className="space-y-2">
            <Label>علائم (اختیاری)</Label>
            <div className="flex flex-wrap gap-1.5">
              {SYMPTOMS.map(s => (
                <button
                  key={s}
                  type="button"
                  onClick={() => toggleSymptom(s)}
                  className={`px-2.5 py-1 rounded-full text-xs border-2 transition-all ${
                    selectedSymptoms.includes(s)
                      ? 'border-primary bg-primary/10 text-primary'
                      : 'border-transparent bg-muted text-muted-foreground'
                  }`}
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
          
          {/* یادداشت */}
          <div className="space-y-2">
            <Label>یادداشت (اختیاری)</Label>
            <Textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="توضیحات اضافی..."
              rows={2}
            />
          </div>
          
          <div className="flex gap-2 pt-2">
            <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)}>انصراف</Button>
            <Button className="flex-1" onClick={() => onAdd({
              startDate,
              cycleLength,
              periodLength,
              symptoms: selectedSymptoms,
              notes: notes.trim(),
            })}>
              ذخیره
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
