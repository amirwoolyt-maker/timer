'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import { Plus, Trash2, Pencil, FolderKanban, Clock, Target } from 'lucide-react'
import { useProStore } from '@/lib/pro-store'
import { useTaskStore } from '@/lib/store'
import { toPersianDigits, formatJalaliDate } from '@/lib/jalali'
import { toast } from 'sonner'

const PROJECT_COLORS = ['#10b981', '#3b82f6', '#a855f7', '#f97316', '#ec4899', '#14b8a6', '#ef4444', '#f59e0b']
const PROJECT_EMOJIS = ['📁', '📚', '🎯', '🚀', '💡', '🎨', '🔬', '🏆', '⭐', '🔥']

export function ProjectsPage() {
  const { projects, addProject, updateProject, deleteProject, moveToTrash } = useProStore()
  const { tasks } = useTaskStore()
  const [showNew, setShowNew] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)

  // محاسبه پیشرفت هر پروژه
  const getProjectStats = (projectId: string) => {
    const projectTasks = tasks.filter((t) => (t as any).projectId === projectId)
    const completed = projectTasks.filter((t) => t.completed).length
    const total = projectTasks.length
    const progress = total > 0 ? Math.round((completed / total) * 100) : 0
    return { completed, total, progress }
  }

  return (
    <div className="px-4 py-4 space-y-4">
      {/* توضیح تفاوت پروژه و الگو */}
      <Card className="p-3 bg-purple-50 dark:bg-purple-950/20 border-purple-200 dark:border-purple-900">
        <p className="text-xs text-purple-700 dark:text-purple-400 leading-relaxed">
          📁 <strong>پروژه چیست؟</strong> پروژه یه پوشه‌ست که تسک‌های مرتبط رو دسته‌بندی می‌کنه.
          مثلاً "کنکور ۱۴۰۶" شامل تسک‌های تاریخ، عربی، فلسفه. هر پروژه مهلت (Deadline) و درصد پیشرفت داره.
          فرق با الگو: الگو یه قالب آماده‌ست که سریع تسک می‌سازه، ولی پروژه یه فضای سازماندهی تسک‌هاست.
        </p>
      </Card>

      <Button onClick={() => setShowNew(true)} className="w-full h-12">
        <Plus className="h-5 w-5 ml-2" />
        پروژه جدید
      </Button>

      {projects.length === 0 ? (
        <div className="text-center py-12 text-muted-foreground">
          <FolderKanban className="h-12 w-12 mx-auto mb-3 opacity-30" />
          <p className="text-sm">هنوز پروژه‌ای نساختی</p>
          <p className="text-xs mt-1">پروژه مثل "کنکور ۱۴۰۶" بساز و تسک‌ها رو دسته‌بندی کن</p>
        </div>
      ) : (
        <div className="space-y-3">
          {projects.map((p) => {
            const stats = getProjectStats(p.id)
            return (
              <Card key={p.id} className="p-4" style={{ borderRight: `4px solid ${p.color}` }}>
                <div className="flex items-start justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-2xl">{p.emoji}</span>
                    <div>
                      <h3 className="font-bold">{p.name}</h3>
                      {p.description && (
                        <p className="text-xs text-muted-foreground mt-0.5">{p.description}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex gap-1">
                    <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => setEditingId(p.id)}>
                      <Pencil className="h-3.5 w-3.5" />
                    </Button>
                    <Button
                      variant="ghost" size="icon" className="h-7 w-7 text-destructive"
                      onClick={() => {
                      if (confirm('پروژه حذف شود؟ قابل بازیابی در سطل زباله.')) {
                        moveToTrash({ id: p.id, type: 'project', title: p.name, emoji: p.emoji, data: p })
                        deleteProject(p.id)
                        toast.success('پروژه به سطل زباله منتقل شد')
                      }
                    }}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>

                {/* پیشرفت */}
                <div className="space-y-1 mb-2">
                  <div className="flex justify-between text-xs">
                    <span className="text-muted-foreground">
                      {toPersianDigits(stats.completed)}/{toPersianDigits(stats.total)} تسک
                    </span>
                    <span className="font-medium">{toPersianDigits(stats.progress)}%</span>
                  </div>
                  <Progress value={stats.progress} className="h-2" />
                </div>

                {/* Deadline */}
                {p.deadline && (
                  <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <Clock className="h-3 w-3" />
                    <span>مهلت: {formatJalaliDate(new Date(p.deadline), false)}</span>
                  </div>
                )}
              </Card>
            )
          })}
        </div>
      )}

      <ProjectDialog
        key={showNew ? 'new' : editingId || 'closed'}
        open={showNew || !!editingId}
        onOpenChange={(v) => { if (!v) { setShowNew(false); setEditingId(null) } }}
        project={editingId ? projects.find((p) => p.id === editingId) : null}
        onSave={(data) => {
          if (editingId) {
            updateProject(editingId, data)
            toast.success('پروژه ویرایش شد')
          } else {
            addProject(data)
            toast.success('پروژه ساخته شد')
          }
          setShowNew(false)
          setEditingId(null)
        }}
      />
    </div>
  )
}

function ProjectDialog({ open, onOpenChange, project, onSave }: {
  open: boolean
  onOpenChange: (v: boolean) => void
  project: any
  onSave: (data: any) => void
}) {
  const [name, setName] = useState(project?.name || '')
  const [emoji, setEmoji] = useState(project?.emoji || '📁')
  const [color, setColor] = useState(project?.color || PROJECT_COLORS[0])
  const [description, setDescription] = useState(project?.description || '')
  const [deadline, setDeadline] = useState(project?.deadline ? project.deadline.split('T')[0] : '')

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="text-right">{project ? 'ویرایش پروژه' : 'پروژه جدید'}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 pt-2">
          <div className="space-y-2">
            <Label>نام پروژه</Label>
            <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="مثلا: کنکور ۱۴۰۶" />
          </div>
          <div className="space-y-2">
            <Label>ایموجی</Label>
            <div className="grid grid-cols-10 gap-1">
              {PROJECT_EMOJIS.map((e) => (
                <button key={e} type="button" onClick={() => setEmoji(e)}
                  className={`aspect-square text-xl rounded-md border-2 flex items-center justify-center ${emoji === e ? 'border-primary bg-primary/10' : 'border-transparent bg-muted'}`}>
                  {e}
                </button>
              ))}
            </div>
          </div>
          <div className="space-y-2">
            <Label>رنگ</Label>
            <div className="flex gap-2 flex-wrap">
              {PROJECT_COLORS.map((c) => (
                <button key={c} type="button" onClick={() => setColor(c)}
                  className={`h-8 w-8 rounded-full border-2 ${color === c ? 'border-foreground scale-110' : 'border-transparent'}`}
                  style={{ backgroundColor: c }} />
              ))}
            </div>
          </div>
          <div className="space-y-2">
            <Label>توضیحات (اختیاری)</Label>
            <Textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="توضیحات پروژه..." rows={2} />
          </div>
          <div className="space-y-2">
            <Label>مهلت (اختیاری)</Label>
            <Input type="date" value={deadline} onChange={(e) => setDeadline(e.target.value)} />
          </div>
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)}>انصراف</Button>
            <Button className="flex-1" disabled={!name.trim()} onClick={() => onSave({
              name: name.trim(), emoji, color, description: description.trim(),
              deadline: deadline ? new Date(deadline).toISOString() : undefined,
            })}>ذخیره</Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
