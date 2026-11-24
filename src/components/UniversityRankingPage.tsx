'use client'

import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Trophy, ArrowLeft, ExternalLink, MapPin, Star } from 'lucide-react'
import { UNIVERSITY_RANKINGS } from '@/lib/resources'
import { toPersianDigits } from '@/lib/jalali'
import { useState } from 'react'

export function UniversityRankingPage() {
  const [selected, setSelected] = useState<typeof UNIVERSITY_RANKINGS[0] | null>(null)
  
  // رنگ بر اساس رتبه
  const getRankColor = (rank: number) => {
    if (rank === 1) return { bg: '#fbbf24', text: '#78350f', emoji: '🥇' }  // طلایی
    if (rank === 2) return { bg: '#cbd5e1', text: '#1e293b', emoji: '🥈' }  // نقره‌ای
    if (rank === 3) return { bg: '#d97706', text: '#fff', emoji: '🥉' }    // برنزی
    return { bg: '#3b82f6', text: '#fff', emoji: '🏅' }
  }
  
  // رنگ نوار نمودار بر اساس امتیاز
  const getBarColor = (score: number) => {
    if (score >= 90) return '#10b981'  // سبز - عالی
    if (score >= 80) return '#3b82f6'  // آبی - خیلی خوب
    if (score >= 75) return '#f59e0b'  // نارنجی - خوب
    return '#6b7280'  // خاکستری - متوسط
  }
  
  return (
    <div className="px-4 py-4">
      {/* هدر */}
      <Card className="p-4 mb-4 bg-gradient-to-l from-primary/10 to-transparent">
        <div className="flex items-center gap-3">
          <Trophy className="h-8 w-8 text-primary" />
          <div>
            <h2 className="font-bold">رتبه‌بندی دانشگاه‌های ایران</h2>
            <p className="text-xs text-muted-foreground">
              بر اساس معروفیت، کیفیت و مقبولیت مدرک
            </p>
          </div>
        </div>
      </Card>
      
      {/* توضیح */}
      <Card className="p-3 mb-4 bg-muted/50">
        <p className="text-xs text-muted-foreground leading-relaxed">
          📊 این رتبه‌بندی بر اساس کیفیت آموزش، معروفیت، مقبولیت مدرک در بازار کار و رتبه‌بندی‌های ملی تهیه شده است. امتیاز هر دانشگاه از ۰ تا ۱۰۰ است.
        </p>
      </Card>
      
      {/* نمودار ستونی */}
      <div className="space-y-3">
        {UNIVERSITY_RANKINGS.map((uni) => {
          const rankColor = getRankColor(uni.rank)
          const barColor = getBarColor(uni.score)
          
          return (
            <Card
              key={uni.rank}
              className="p-3 cursor-pointer hover:shadow-md transition-shadow"
              onClick={() => setSelected(uni)}
            >
              {/* ردیف اول: رتبه + نام */}
              <div className="flex items-center gap-3 mb-2">
                {/* رتبه */}
                <div
                  className="h-10 w-10 rounded-full flex items-center justify-center text-lg font-bold shrink-0"
                  style={{ backgroundColor: rankColor.bg, color: rankColor.text }}
                >
                  {rankColor.emoji}
                </div>
                
                {/* نام و ایموجی */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{uni.emoji}</span>
                    <h3 className="font-semibold text-sm truncate">{uni.name}</h3>
                  </div>
                  <div className="flex items-center gap-2 mt-0.5">
                    <Badge variant="outline" className="text-xs h-5 gap-0.5">
                      <MapPin className="h-2.5 w-2.5" />
                      {uni.city}
                    </Badge>
                    <span className="text-xs text-muted-foreground">{uni.specialties}</span>
                  </div>
                </div>
                
                {/* امتیاز */}
                <div className="text-left shrink-0">
                  <div className="flex items-center gap-0.5">
                    <Star className="h-3.5 w-3.5 text-amber-500 fill-amber-500" />
                    <span className="font-bold text-lg" style={{ color: barColor }}>
                      {toPersianDigits(uni.score)}
                    </span>
                  </div>
                  <p className="text-xs text-muted-foreground">از ۱۰۰</p>
                </div>
              </div>
              
              {/* نوار نمودار */}
              <div className="relative h-6 bg-muted rounded-full overflow-hidden">
                <div
                  className="absolute top-0 right-0 h-full rounded-full transition-all duration-500 flex items-center justify-start pl-2"
                  style={{
                    width: `${uni.score}%`,
                    backgroundColor: barColor,
                  }}
                >
                  <span className="text-xs font-bold text-white">
                    {toPersianDigits(uni.score)}٪
                  </span>
                </div>
              </div>
            </Card>
          )
        })}
      </div>
      
      {/* راهنما */}
      <Card className="p-3 mt-4">
        <p className="text-xs font-semibold mb-2">🎨 راهنمای رنگ‌ها:</p>
        <div className="grid grid-cols-2 gap-2 text-xs">
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full" style={{ backgroundColor: '#10b981' }} />
            <span>عالی (۹۰+)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full" style={{ backgroundColor: '#3b82f6' }} />
            <span>خیلی خوب (۸۰-۸۹)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full" style={{ backgroundColor: '#f59e0b' }} />
            <span>خوب (۷۵-۷۹)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="h-3 w-3 rounded-full" style={{ backgroundColor: '#6b7280' }} />
            <span>متوسط (زیر ۷۵)</span>
          </div>
        </div>
      </Card>
      
      {/* جزئیات دانشگاه انتخاب شده */}
      {selected && (
        <div
          className="fixed inset-0 z-[60] bg-background/80 backdrop-blur flex items-end sm:items-center justify-center p-4"
          onClick={() => setSelected(null)}
        >
          <Card
            className="w-full max-w-md p-5 animate-scale-in"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-3">
                <span className="text-4xl">{selected.emoji}</span>
                <div>
                  <h3 className="font-bold text-lg">{selected.name}</h3>
                  <div className="flex items-center gap-2 mt-1">
                    <Badge variant="outline" className="text-xs gap-0.5">
                      <MapPin className="h-2.5 w-2.5" />
                      {selected.city}
                    </Badge>
                    <span className="text-xs">رتبه {toPersianDigits(selected.rank)}</span>
                  </div>
                </div>
              </div>
              <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => setSelected(null)}>
                <ArrowLeft className="h-4 w-4" />
              </Button>
            </div>
            
            <p className="text-sm text-muted-foreground mb-3 leading-relaxed">
              {selected.description}
            </p>
            
            <div className="space-y-2 mb-4">
              <div className="flex justify-between text-sm">
                <span>تخصص:</span>
                <span className="font-medium">{selected.specialties}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span>امتیاز کل:</span>
                <span className="font-bold" style={{ color: getBarColor(selected.score) }}>
                  {toPersianDigits(selected.score)} از ۱۰۰
                </span>
              </div>
            </div>
            
            <div className="relative h-8 bg-muted rounded-full overflow-hidden mb-4">
              <div
                className="absolute top-0 right-0 h-full rounded-full flex items-center justify-start pl-3"
                style={{
                  width: `${selected.score}%`,
                  backgroundColor: getBarColor(selected.score),
                }}
              >
                <span className="text-xs font-bold text-white">
                  {toPersianDigits(selected.score)}٪
                </span>
              </div>
            </div>
            
            <Button
              variant="outline"
              className="w-full"
              onClick={() => {
                // پیدا کردن سایت دانشگاه
                const site = RESOURCE_SITES_FOR_UNI.find(s => s.name === selected.name)
                if (site) {
                  window.open(site.url, '_blank')
                }
              }}
            >
              <ExternalLink className="h-4 w-4 ml-2" />
              بازدید از سایت دانشگاه
            </Button>
          </Card>
        </div>
      )}
    </div>
  )
}

// نگاشت نام دانشگاه به سایت
const RESOURCE_SITES_FOR_UNI = [
  { name: 'دانشگاه شریف', url: 'https://www.sharif.edu' },
  { name: 'دانشگاه تهران', url: 'https://www.ut.ac.ir' },
  { name: 'دانشگاه امیرکبیر (پلی‌تکنیک)', url: 'https://www.aut.ac.ir' },
  { name: 'دانشگاه علوم پزشکی تهران', url: 'https://www.tums.ac.ir' },
  { name: 'دانشگاه فردوسی مشهد', url: 'https://www.ferdowsi.um.ac.ir' },
  { name: 'دانشگاه شهید بهشتی', url: 'https://www.sbu.ac.ir' },
  { name: 'دانشگاه علم و صنعت', url: 'https://www.iust.ac.ir' },
  { name: 'دانشگاه تبریز', url: 'https://www.tabrizu.ac.ir' },
  { name: 'دانشگاه اصفهان', url: 'https://www.ui.ac.ir' },
  { name: 'دانشگاه صنعتی اصفهان', url: 'https://www.iut.ac.ir' },
  { name: 'دانشگاه علوم پزشکی شهید بهشتی', url: 'https://www.sbmu.ac.ir' },
  { name: 'دانشگاه گیلان', url: 'https://www.guilan.ac.ir' },
  { name: 'دانشگاه مازندران', url: 'https://www.umz.ac.ir' },
  { name: 'دانشگاه خوارزمی', url: 'https://www.khuisf.ac.ir' },
  { name: 'دانشگاه بوعلی سینا', url: 'https://www.basu.ac.ir' },
]
