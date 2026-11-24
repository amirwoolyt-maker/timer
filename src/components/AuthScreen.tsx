'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card } from '@/components/ui/card'
import { useAuthStore } from '@/lib/auth-store'
import { Gender, StudyField, Grade, FIELD_LABELS, FIELD_EMOJIS } from '@/lib/auth-types'
import { toPersianDigits } from '@/lib/jalali'
import { toast } from 'sonner'
import { User, LogIn, Eye, EyeOff, UserCircle } from 'lucide-react'

const AVATAR_OPTIONS_MALE = ['👨', '🧑', '👦', '👴', '🧔', '👨‍💼', '👨‍💻', '👨‍🔬', '🦸‍♂️', '🦹‍♂️']
const AVATAR_OPTIONS_FEMALE = ['👩', '👧', '👵', '👩‍💼', '👩‍💻', '👩‍🔬', '🦸‍♀️', '🦹‍♀️', '👸', '🧙‍♀️']
const AVATAR_OPTIONS_OTHER = ['👤', '🧙', '🧛', '🧜', '🧝', '🧞', '🧟', '🤖', '👽', '🦄']

export function AuthScreen() {
  const { register, login } = useAuthStore()
  const [mode, setMode] = useState<'login' | 'register'>('register')
  const [loading, setLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  
  const [username, setUsername] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [gender, setGender] = useState<Gender | ''>('')
  const [studyField, setStudyField] = useState<StudyField | ''>('')
  const [grade, setGrade] = useState<Grade | 0>(0)
  const [password, setPassword] = useState('')
  const [avatar, setAvatar] = useState('👤')
  
  const handleSubmit = async () => {
    setLoading(true)
    
    try {
      if (mode === 'register') {
        if (!gender) {
          toast.error('جنسیت را انتخاب کنید')
          setLoading(false)
          return
        }
        if (!studyField) {
          toast.error('رشته تحصیلی را انتخاب کنید')
          setLoading(false)
          return
        }
        if (!grade) {
          toast.error('پایه تحصیلی را انتخاب کنید')
          setLoading(false)
          return
        }
        const result = await register({
          username: username.trim(),
          displayName: displayName.trim(),
          gender: gender as Gender,
          studyField: studyField as StudyField,
          grade: grade as Grade,
          password,
          avatar,
        })
        
        if (!result.success) {
          toast.error(result.error || 'خطا در ثبت‌نام')
        } else {
          toast.success('ثبت‌نام موفق! خوش آمدید 🎉')
        }
      } else {
        const result = await login({
          username: username.trim(),
          password,
        })
        
        if (!result.success) {
          toast.error(result.error || 'خطا در ورود')
        } else {
          toast.success('خوش آمدید! 👋')
        }
      }
    } catch (err) {
      toast.error('خطای غیرمنتظره')
    } finally {
      setLoading(false)
    }
  }
  
  const avatarOptions = gender === 'female' 
    ? AVATAR_OPTIONS_FEMALE 
    : gender === 'male' 
    ? AVATAR_OPTIONS_MALE 
    : AVATAR_OPTIONS_OTHER
  
  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center p-4 safe-top safe-bottom">
      <div className="w-full max-w-sm">
        {/* لوگو */}
        <div className="text-center mb-6">
          <div className="text-6xl mb-2">🐉</div>
          <h1 className="text-2xl font-bold">یادآور تسک‌ها</h1>
          <p className="text-sm text-muted-foreground mt-1">
            {mode === 'register' ? 'ثبت‌نام کنید تا پیشرفتتون ذخیره بشه' : 'وارد اکانتتون بشید'}
          </p>
        </div>
        
        <Card className="p-5">
          {/* تب‌ها */}
          <div className="flex gap-1 mb-4 bg-muted p-1 rounded-lg">
            <button
              onClick={() => setMode('register')}
              className={`flex-1 py-2 rounded-md text-sm font-medium transition-all ${
                mode === 'register' ? 'bg-background text-primary shadow-sm' : 'text-muted-foreground'
              }`}
            >
              <User className="h-4 w-4 ml-1 inline" />
              ثبت‌نام
            </button>
            <button
              onClick={() => setMode('login')}
              className={`flex-1 py-2 rounded-md text-sm font-medium transition-all ${
                mode === 'login' ? 'bg-background text-primary shadow-sm' : 'text-muted-foreground'
              }`}
            >
              <LogIn className="h-4 w-4 ml-1 inline" />
              ورود
            </button>
          </div>
          
          <div className="space-y-3">
            {/* ID انگلیسی */}
            <div className="space-y-1.5">
              <Label htmlFor="username">ID (انگلیسی)</Label>
              <Input
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value.replace(/[^a-zA-Z0-9_]/g, ''))}
                placeholder="مثلا: ahmad_123"
                autoComplete="username"
                dir="ltr"
                className="text-left"
              />
              <p className="text-xs text-muted-foreground">
                فقط حروف انگلیسی، عدد و _
              </p>
            </div>
            
            {/* نام نمایشی */}
            {mode === 'register' && (
              <div className="space-y-1.5">
                <Label htmlFor="displayName">نام</Label>
                <Input
                  id="displayName"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="مثلا: احمد محمدی"
                />
              </div>
            )}
            
            {/* جنسیت (فقط ثبت‌نام) */}
            {mode === 'register' && (
              <div className="space-y-1.5">
                <Label>جنسیت *</Label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => { setGender('male'); setAvatar('👨') }}
                    className={`flex flex-col items-center gap-1 py-3 rounded-lg border-2 transition-all ${
                      gender === 'male' ? 'border-primary bg-primary/10 text-primary' : 'border-transparent bg-muted text-muted-foreground'
                    }`}
                  >
                    <span className="text-2xl">👨</span>
                    <span className="text-xs">پسر</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => { setGender('female'); setAvatar('👩') }}
                    className={`flex flex-col items-center gap-1 py-3 rounded-lg border-2 transition-all ${
                      gender === 'female' ? 'border-primary bg-primary/10 text-primary' : 'border-transparent bg-muted text-muted-foreground'
                    }`}
                  >
                    <span className="text-2xl">👩</span>
                    <span className="text-xs">دختر</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => { setGender('other'); setAvatar('👤') }}
                    className={`flex flex-col items-center gap-1 py-3 rounded-lg border-2 transition-all ${
                      gender === 'other' ? 'border-primary bg-primary/10 text-primary' : 'border-transparent bg-muted text-muted-foreground'
                    }`}
                  >
                    <span className="text-2xl">👤</span>
                    <span className="text-xs">سایر</span>
                  </button>
                </div>
              </div>
            )}
            
            {/* رشته تحصیلی (فقط ثبت‌نام) */}
            {mode === 'register' && (
              <div className="space-y-1.5">
                <Label>رشته تحصیلی *</Label>
                <div className="grid grid-cols-3 gap-2">
                  {(['math', 'science', 'humanities'] as StudyField[]).map((field) => (
                    <button
                      key={field}
                      type="button"
                      onClick={() => setStudyField(field)}
                      className={`flex flex-col items-center gap-1 py-2 rounded-lg border-2 transition-all ${
                        studyField === field ? 'border-primary bg-primary/10 text-primary' : 'border-transparent bg-muted text-muted-foreground'
                      }`}
                    >
                      <span className="text-xl">{FIELD_EMOJIS[field]}</span>
                      <span className="text-xs">{FIELD_LABELS[field]}</span>
                    </button>
                  ))}
                </div>
              </div>
            )}
            
            {/* پایه تحصیلی (فقط ثبت‌نام) */}
            {mode === 'register' && (
              <div className="space-y-1.5">
                <Label>پایه تحصیلی *</Label>
                <div className="grid grid-cols-3 gap-2">
                  {([10, 11, 12] as Grade[]).map((g) => (
                    <button
                      key={g}
                      type="button"
                      onClick={() => setGrade(g)}
                      className={`py-2 rounded-lg border-2 text-sm font-medium transition-all ${
                        grade === g ? 'border-primary bg-primary/10 text-primary' : 'border-transparent bg-muted text-muted-foreground'
                      }`}
                    >
                      پایه {toPersianDigits(g)}
                    </button>
                  ))}
                </div>
              </div>
            )}
            
            {/* رمز */}
            <div className="space-y-1.5">
              <Label htmlFor="password">رمز</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="حداقل ۶ کاراکتر"
                  autoComplete={mode === 'register' ? 'new-password' : 'current-password'}
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>
            
            {/* آواتار (فقط ثبت‌نام) */}
            {mode === 'register' && gender && (
              <div className="space-y-1.5">
                <Label>آواتار</Label>
                <div className="grid grid-cols-10 gap-1">
                  {avatarOptions.map((a) => (
                    <button
                      key={a}
                      type="button"
                      onClick={() => setAvatar(a)}
                      className={`aspect-square text-xl rounded-md border-2 transition-all flex items-center justify-center ${
                        avatar === a ? 'border-primary bg-primary/10' : 'border-transparent bg-muted'
                      }`}
                    >
                      {a}
                    </button>
                  ))}
                </div>
              </div>
            )}
            
            {/* دکمه */}
            <Button
              onClick={handleSubmit}
              disabled={loading || !username || !password || (mode === 'register' && (!displayName || !gender || !studyField || !grade))}
              className="w-full h-12"
            >
              {loading ? 'صبر کنید...' : mode === 'register' ? 'ثبت‌نام' : 'ورود'}
            </Button>
          </div>
        </Card>
        
        <p className="text-xs text-center text-muted-foreground mt-4">
          {mode === 'register' 
            ? 'با ثبت‌نام، موافقت می‌کنید داده‌هایتون ذخیره بشه'
            : 'اگه اکانت ندارید، ثبت‌نام کنید'
          }
        </p>
      </div>
    </div>
  )
}
