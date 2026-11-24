'use client'

import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Trash2, RotateCcw, AlertCircle, FileText, Plus, Clock } from 'lucide-react'
import { useProStore } from '@/lib/pro-store'
import { useTaskStore } from '@/lib/store'
import { toPersianDigits, formatJalaliDate } from '@/lib/jalali'
import { toast } from 'sonner'
import { useEffect, useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

const TYPE_LABELS: Record<string, { label: string; emoji: string; color: string }> = {
  task: { label: 'تسک', emoji: '📋', color: '#3b82f6' },
  project: { label: 'پروژه', emoji: '📁', color: '#a855f7' },
  template: { label: 'الگو', emoji: '📋', color: '#f59e0b' },
}

export function TrashPage() {
  const { trash, restoreFromTrash, deleteFromTrash, clearExpiredTrash } = useProStore()
  const { addTask } = useTaskStore()
  const { addProject, addTemplate } = useProStore()

  useEffect(() => { clearExpiredTrash() }, [clearExpiredTrash])

  const handleRestore = (id: string) => {
    const item = restoreFromTrash(id)
    if (!item) return

    if (item.type === 'task') {
      const { id: _, createdAt, updatedAt, completed, completedAt, ...rest } = item.data
      addTask({ ...rest, completed: false, active: true })
      toast.success('تسک بازیابی شد')
    } else if (item.type === 'project') {
      const { id: _, createdAt, updatedAt, ...rest } = item.data
      addProject(rest)
      toast.success('پروژه بازیابی شد')
    } else if (item.type === 'template') {
      const { id: _, createdAt, ...rest } = item.data
      addTemplate(rest)
      toast.success('الگو بازیابی شد')
    }
  }

  return (
    <div className="px-4 py-4 space-y-4">
      <Card className="p-4 bg-amber-50 dark:bg-amber-950/20 border-amber-200 dark:border-amber-900">
        <div className="flex items-start gap-2">
          <AlertCircle className="h-5 w-5 text-amber-500 shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-medium text-amber-700 dark:text-amber-400">سطل زباله</p>
            <p className="text-xs text-amber-600 dark:text-amber-500 mt-1">
              تسک‌ها، پروژه‌ها و الگوهای حذف‌شده تا ۳۰ روز قابل بازیابی هستند.
            </p>
          </div>
        </div>
      </Card>

      {trash.length === 0 ? (
        <div className="text-center py-12 text-muted-foreground">
          <Trash2 className="h-12 w-12 mx-auto mb-3 opacity-30" />
          <p className="text-sm">سطل زباله خالی است</p>
        </div>
      ) : (
        <div className="space-y-2">
          <p className="text-xs text-muted-foreground px-1">
            {toPersianDigits(trash.length)} آیتم حذف‌شده
          </p>
          {trash.map((item) => {
            const typeInfo = TYPE_LABELS[item.type] || TYPE_LABELS.task
            const daysLeft = Math.ceil((new Date(item.expiresAt).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
            return (
              <Card key={item.id} className="p-3 opacity-75">
                <div className="flex items-center gap-3">
                  <span className="text-xl">{typeInfo.emoji}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate line-through">{item.title}</p>
                    <div className="flex items-center gap-2 mt-0.5">
                      <Badge variant="outline" className="text-xs h-5" style={{ color: typeInfo.color, borderColor: typeInfo.color + '40' }}>
                        {typeInfo.label}
                      </Badge>
                      <Badge variant="outline" className="text-xs h-5">
                        {toPersianDigits(daysLeft)} روز
                      </Badge>
                      <span className="text-xs text-muted-foreground">
                        {formatJalaliDate(new Date(item.deletedAt), false)}
                      </span>
                    </div>
                  </div>
                  <Button variant="ghost" size="icon" className="h-8 w-8 text-primary" onClick={() => handleRestore(item.id)}>
                    <RotateCcw className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => { deleteFromTrash(item.id); toast.success('برای همیشه حذف شد') }}>
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </Card>
            )
          })}
        </div>
      )}
    </div>
  )
}

// ============ الگوها (Templates) ============
// الگو = مجموعه‌ای از تسک‌های آماده که با یک کلیک همه با هم ساخته می‌شوند
// مثلاً "برنامه روز مدرسه" شامل ۸ تسک با زمان‌های مشخص

export function TemplatesPage() {
  const { templates, addTemplate, deleteTemplate, moveToTrash } = useProStore()
  const { addTask, categories } = useTaskStore()
  const [showNew, setShowNew] = useState(false)

  const applyTemplate = (template: any) => {
    const now = new Date()
    template.tasks.forEach((t: any) => {
      const dueDate = new Date(now)
      if (t.time) {
        const [h, m] = t.time.split(':').map(Number)
        dueDate.setHours(h, m, 0, 0)
      }
      addTask({
        title: t.title,
        description: t.description || '',
        categoryId: t.categoryId,
        dueDate: dueDate.toISOString(),
        hasTime: !!t.time,
        completed: false,
        active: true,
        notificationText: '',
        notificationType: 'default',
        notificationSound: 'chime',
        notificationVolume: 70,
        notificationVibrate: true,
        recurringEnabled: false,
        repeatType: 'none',
        repeatIntervalDays: 1,
        priority: t.priority,
        tags: [],
      })
    })
    toast.success(`${toPersianDigits(template.tasks.length)} تسک از الگو ساخته شد`)
  }

  return (
    <div className="px-4 py-4 space-y-4">
      {/* توضیح تفاوت الگو و پروژه */}
      <Card className="p-3 bg-blue-50 dark:bg-blue-950/20 border-blue-200 dark:border-blue-900">
        <p className="text-xs text-blue-700 dark:text-blue-400 leading-relaxed">
          📋 <strong>الگو چیست؟</strong> الگو مجموعه‌ای از تسک‌های آماده‌ست که با یک کلیک همه با هم ساخته می‌شوند.
          مثلاً "برنامه روز مدرسه" شامل ۸ تسک با زمان‌های مشخص. فرق با پروژه: پروژه یه پوشه‌ست که تسک‌ها رو دسته‌بندی می‌کنه، ولی الگو یه قالب آماده‌ست که سریع تسک‌ها رو می‌سازه.
        </p>
      </Card>

      <Button onClick={() => setShowNew(true)} className="w-full h-12">
        <Plus className="h-5 w-5 ml-2" />
        الگوی جدید
      </Button>

      {/* الگوهای پیش‌فرض */}
      {templates.length === 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold text-muted-foreground px-1">الگوهای پیشنهادی:</p>
          {DEFAULT_TEMPLATES.map((t, i) => (
            <Card key={i} className="p-3">
              <div className="flex items-center gap-3">
                <span className="text-2xl">{t.emoji}</span>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm">{t.name}</h3>
                  <p className="text-xs text-muted-foreground">{toPersianDigits(t.tasks.length)} تسک آماده</p>
                </div>
                <Button variant="outline" size="sm" onClick={() => {
                  addTemplate(t as any)
                  toast.success('الگو اضافه شد')
                }}>
                  <Plus className="h-4 w-4 ml-1" />
                  اضافه
                </Button>
                <Button variant="default" size="sm" onClick={() => applyTemplate(t)}>
                  اعمال
                </Button>
              </div>
            </Card>
          ))}
        </div>
      )}

      {templates.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold text-muted-foreground px-1">الگوهای شما:</p>
          {templates.map((t) => (
            <Card key={t.id} className="p-3">
              <div className="flex items-center gap-3">
                <span className="text-2xl">{t.emoji}</span>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm truncate">{t.name}</h3>
                  <p className="text-xs text-muted-foreground">{toPersianDigits(t.tasks.length)} تسک</p>
                </div>
                <Button variant="outline" size="sm" onClick={() => applyTemplate(t)}>
                  <Plus className="h-4 w-4 ml-1" />
                  اعمال
                </Button>
                <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => {
                  moveToTrash({ id: t.id, type: 'template', title: t.name, emoji: t.emoji, data: t })
                  deleteTemplate(t.id)
                  toast.success('الگو به سطل زباله منتقل شد')
                }}>
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </Card>
          ))}
        </div>
      )}

      <TemplateDialog
        key={showNew ? 'open' : 'closed'}
        open={showNew}
        onOpenChange={setShowNew}
        categories={categories}
        onSave={(data) => { addTemplate(data); toast.success('الگو ساخته شد'); setShowNew(false) }}
      />
    </div>
  )
}

// الگوهای پیش‌فرض
const DEFAULT_TEMPLATES = [
  {
    name: 'برنامه روز مدرسه',
    emoji: '🏫',
    tasks: [
      { title: 'بیدار شدن و صبحانه', categoryId: 'personal', priority: 'medium', time: '06:30' },
      { title: 'مرور درس ریاضی', categoryId: 'study', priority: 'high', time: '07:00' },
      { title: 'رفتن به مدرسه', categoryId: 'personal', priority: 'high', time: '07:30' },
      { title: 'ناهار', categoryId: 'personal', priority: 'low', time: '12:00' },
      { title: 'استراحت', categoryId: 'personal', priority: 'low', time: '13:00' },
      { title: 'تکالیف', categoryId: 'study', priority: 'high', time: '16:00' },
      { title: 'ورزش', categoryId: 'health', priority: 'medium', time: '17:30' },
      { title: 'شام و مطالعه', categoryId: 'study', priority: 'medium', time: '20:00' },
    ],
  },
  {
    name: 'روز امتحان',
    emoji: '📝',
    tasks: [
      { title: 'بیدار شدن زود', categoryId: 'personal', priority: 'high', time: '05:00' },
      { title: 'مرور سریع نکات', categoryId: 'study', priority: 'high', time: '05:30' },
      { title: 'صبحانه سبک', categoryId: 'health', priority: 'medium', time: '06:30' },
      { title: 'آمادگی و رفتن', categoryId: 'personal', priority: 'high', time: '07:00' },
      { title: 'استراحت بعد از امتحان', categoryId: 'personal', priority: 'low', time: '14:00' },
    ],
  },
  {
    name: 'روز کنکور',
    emoji: '🎯',
    tasks: [
      { title: 'بیدار شدن', categoryId: 'personal', priority: 'high', time: '05:00' },
      { title: 'مرور نکات مهم', categoryId: 'study', priority: 'high', time: '05:30' },
      { title: 'صبحانه', categoryId: 'health', priority: 'high', time: '06:30' },
      { title: 'رفتن به جلسه', categoryId: 'personal', priority: 'high', time: '07:00' },
      { title: 'استراحت', categoryId: 'personal', priority: 'low', time: '15:00' },
    ],
  },
]

function TemplateDialog({ open, onOpenChange, categories, onSave }: any) {
  const [name, setName] = useState('')
  const [emoji, setEmoji] = useState('📋')
  const [tasks, setTasks] = useState<any[]>([{ title: '', categoryId: categories[0]?.id || 'study', priority: 'medium', time: '' }])

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto hide-scrollbar" dir="rtl" style={{ WebkitOverflowScrolling: 'touch' }}>
        <DialogHeader>
          <DialogTitle className="text-right">الگوی جدید</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 pt-2">
          <div className="flex gap-2">
            <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="نام الگو..." className="flex-1" />
            <Input value={emoji} onChange={(e) => setEmoji(e.target.value)} className="w-16 text-center text-xl" />
          </div>
          <div className="space-y-2">
            {tasks.map((t, i) => (
              <div key={i} className="flex gap-1.5">
                <Input
                  value={t.title}
                  onChange={(e) => { const n = [...tasks]; n[i] = { ...t, title: e.target.value }; setTasks(n) }}
                  placeholder="عنوان تسک..."
                  className="flex-1 text-sm"
                />
                <select
                  value={t.priority}
                  onChange={(e) => { const n = [...tasks]; n[i] = { ...t, priority: e.target.value }; setTasks(n) }}
                  className="text-xs rounded-md border px-1 bg-background"
                >
                  <option value="low">کم</option>
                  <option value="medium">متوسط</option>
                  <option value="high">زیاد</option>
                </select>
                <Input
                  type="time"
                  value={t.time}
                  onChange={(e) => { const n = [...tasks]; n[i] = { ...t, time: e.target.value }; setTasks(n) }}
                  className="w-24 text-xs"
                />
                {tasks.length > 1 && (
                  <Button variant="ghost" size="icon" className="h-8 w-8 shrink-0 text-destructive" onClick={() => setTasks(tasks.filter((_, idx) => idx !== i))}>
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                )}
              </div>
            ))}
            <Button variant="outline" size="sm" className="w-full" onClick={() => setTasks([...tasks, { title: '', categoryId: categories[0]?.id || 'study', priority: 'medium', time: '' }])}>
              <Plus className="h-4 w-4 ml-1" /> تسک بیشتر
            </Button>
          </div>
          <div className="flex gap-2 sticky bottom-0 bg-background py-2">
            <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)}>انصراف</Button>
            <Button className="flex-1" disabled={!name.trim() || tasks.every((t) => !t.title.trim())} onClick={() => onSave({
              name: name.trim(), emoji,
              tasks: tasks.filter((t) => t.title.trim()),
            })}>ذخیره</Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
