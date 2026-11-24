// انواع داده‌های کاربر و احراز هویت

export type Gender = 'male' | 'female' | 'other'

export type StudyField = 'math' | 'science' | 'humanities' // ریاضی / تجربی / انسانی

export type Grade = 10 | 11 | 12

export const FIELD_LABELS: Record<StudyField, string> = {
  math: 'ریاضی',
  science: 'تجربی',
  humanities: 'انسانی',
}

export const FIELD_EMOJIS: Record<StudyField, string> = {
  math: '🔢',
  science: '🧬',
  humanities: '📚',
}

// دروس هر رشته و پایه
export const SUBJECTS_BY_FIELD_GRADE: Record<StudyField, Record<Grade, string[]>> = {
  math: {
    10: ['ریاضی', 'فیزیک', 'شیمی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'اجتماعی', 'زیست', 'زمین'],
    11: ['ریاضی', 'فیزیک', 'شیمی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'هندسه', 'حسابان', 'زیست'],
    12: ['ریاضی', 'فیزیک', 'شیمی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'هندسه', 'حسابان', 'تفاضلی'],
  },
  science: {
    10: ['ریاضی', 'فیزیک', 'شیمی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'زیست', 'زمین', 'اجتماعی'],
    11: ['ریاضی', 'فیزیک', 'شیمی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'زیست', 'زمین', 'اخترشناسی'],
    12: ['ریاضی', 'فیزیک', 'شیمی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'زیست', 'زمین', 'ژئولوژی'],
  },
  humanities: {
    10: ['ریاضی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'تاریخ', 'جغرافیا', 'اجتماعی', 'فلسفه', 'منطق'],
    11: ['ریاضی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'تاریخ', 'جغرافیا', 'جامعه‌شناسی', 'فلسفه', 'منطق'],
    12: ['ریاضی', 'ادبیات فارسی', 'عربی', 'دینی', 'زبان', 'تاریخ', 'جغرافیا', 'حقوق', 'فلسفه', 'منطق'],
  },
}

export interface User {
  id: string
  username: string
  displayName: string
  gender: Gender
  studyField: StudyField
  grade: Grade
  email?: string
  avatar: string
  avatarType: 'emoji' | 'image'
  bio: string
  createdAt: string
  followersCount: number
  followingCount: number
}

export interface AuthSession {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

export interface RegisterData {
  username: string
  displayName: string
  gender: Gender
  studyField: StudyField
  grade: Grade
  password: string
  avatar?: string
}

export interface LoginData {
  username: string
  password: string
}

// پست سوشال
export interface SocialPost {
  id: string
  userId: string
  username: string
  displayName: string
  avatar: string
  text: string
  image?: string
  wordCount: number
  type: 'general' | 'task_share' | 'timer_share'
  sharedTaskTitle?: string
  sharedTimerName?: string
  sharedTimerSeconds?: number
  originalDeleted?: boolean
  likes: string[]
  comments: SocialComment[]
  shares: number
  savedBy: string[]
  createdAt: string
  updatedAt: string
}

export interface SocialComment {
  id: string
  userId: string
  username: string
  displayName: string
  avatar: string
  text: string
  createdAt: string
}

// چت
export interface ChatMessage {
  id: string
  chatId: string
  senderId: string
  senderUsername: string
  senderDisplayName: string
  senderAvatar: string
  text: string
  createdAt: string
  read: boolean
}

export interface Chat {
  id: string
  type: 'private' | 'group'
  name?: string  // برای گروه
  avatar?: string  // برای گروه
  participants: string[]  // userId ها
  participantsInfo: {
    userId: string
    username: string
    displayName: string
    avatar: string
  }[]
  lastMessage?: ChatMessage
  createdAt: string
  updatedAt: string
}

// چرخه پریود
export interface PeriodCycle {
  id: string
  userId: string
  startDate: string  // ISO
  cycleLength: number  // معمولا 28 روز
  periodLength: number  // معمولا 5 روز
  symptoms: string[]
  notes: string
  createdAt: string
}

export const MAX_POST_WORDS = 200
export const MAX_COMMENT_WORDS = 50
export const MAX_GROUP_MEMBERS = 30
