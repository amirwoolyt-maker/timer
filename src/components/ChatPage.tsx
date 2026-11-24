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
  Send, Search, MessageCircle, Users, Plus, ArrowRight, Lock, Trash2,
} from 'lucide-react'
import { useAuthStore } from '@/lib/auth-store'
import { Chat, ChatMessage } from '@/lib/auth-types'
import { toPersianDigits, relativeTime } from '@/lib/jalali'
import { toast } from 'sonner'

export function ChatPage() {
  const { currentUser, searchUsers } = useAuthStore()
  const [chats, setChats] = useState<Chat[]>([])
  const [activeChat, setActiveChat] = useState<Chat | null>(null)
  const [showSearch, setShowSearch] = useState(false)
  const [showNewGroup, setShowNewGroup] = useState(false)
  const [loaded, setLoaded] = useState(false)
  
  // بارگذاری چت‌ها
  useEffect(() => {
    if (!currentUser || loaded) return
    const data = localStorage.getItem(`chats-${currentUser.id}`)
    if (data) {
      try {
        const parsed = JSON.parse(data)
        setTimeout(() => setChats(parsed), 0)
      } catch {}
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoaded(true)
  }, [currentUser, loaded])
  
  const saveChats = (newChats: Chat[]) => {
    setChats(newChats)
    if (currentUser) {
      localStorage.setItem(`chats-${currentUser.id}`, JSON.stringify(newChats))
    }
  }
  
  // اگه کاربر وارد نشده
  if (!currentUser) {
    return (
      <div className="px-4 py-12 text-center">
        <Lock className="h-16 w-16 mx-auto mb-3 text-muted-foreground opacity-30" />
        <p className="text-sm text-muted-foreground mb-3">
          برای استفاده از چت، باید وارد حساب خود شوید
        </p>
        <Badge variant="secondary" className="gap-1">
          <Lock className="h-3 w-3" />
          قفل شده
        </Badge>
      </div>
    )
  }
  
  return (
    <div className="flex flex-col" style={{ height: 'calc(100vh - 140px)' }}>
      {/* هدر */}
      <div className="px-4 py-3 border-b">
        <div className="flex items-center justify-between mb-2">
          <h2 className="font-bold">چت با کنکوری‌ها</h2>
          <div className="flex gap-1">
            <Button variant="ghost" size="icon" className="h-9 w-9" onClick={() => setShowSearch(true)}>
              <Search className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" className="h-9 w-9" onClick={() => setShowNewGroup(true)}>
              <Users className="h-4 w-4" />
            </Button>
          </div>
        </div>
        <p className="text-xs text-muted-foreground">
          {toPersianDigits(chats.length)} چت · {toPersianDigits(chats.filter(c => c.type === 'group').length)} گروه
        </p>
      </div>
      
      {/* لیست چت‌ها */}
      <div className="flex-1 overflow-y-auto">
        {chats.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground">
            <MessageCircle className="h-12 w-12 mx-auto mb-3 opacity-30" />
            <p className="text-sm">هنوز چتی ندارید</p>
            <p className="text-xs mt-1">با جستجوی کاربران، چت جدید بسازید</p>
          </div>
        ) : (
          <div className="divide-y">
            {chats.map((chat) => (
              <ChatListItem
                key={chat.id}
                chat={chat}
                currentUserId={currentUser.id}
                onClick={() => setActiveChat(chat)}
              />
            ))}
          </div>
        )}
      </div>
      
      {/* دیالوگ جستجوی کاربر */}
      <SearchUserDialog
        key={showSearch ? 'open' : 'closed'}
        open={showSearch}
        onOpenChange={setShowSearch}
        onSelectUser={(user) => {
          // ایجاد یا باز کردن چت خصوصی
          const existing = chats.find(c => 
            c.type === 'private' && 
            c.participants.includes(user.id)
          )
          if (existing) {
            setActiveChat(existing)
          } else {
            const newChat: Chat = {
              id: `chat_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
              type: 'private',
              participants: [currentUser.id, user.id],
              participantsInfo: [
                { userId: currentUser.id, username: currentUser.username, displayName: currentUser.displayName, avatar: currentUser.avatar },
                { userId: user.id, username: user.username, displayName: user.displayName, avatar: user.avatar },
              ],
              createdAt: new Date().toISOString(),
              updatedAt: new Date().toISOString(),
            }
            saveChats([newChat, ...chats])
            setActiveChat(newChat)
          }
          setShowSearch(false)
          toast.success(`چت با ${user.displayName} شروع شد`)
        }}
      />
      
      {/* دیالوگ ساخت گروه */}
      <NewGroupDialog
        key={showNewGroup ? 'open' : 'closed'}
        open={showNewGroup}
        onOpenChange={setShowNewGroup}
        onCreate={(name, members) => {
          const newChat: Chat = {
            id: `group_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
            type: 'group',
            name,
            avatar: '👥',
            participants: [currentUser.id, ...members.map(m => m.id)],
            participantsInfo: [
              { userId: currentUser.id, username: currentUser.username, displayName: currentUser.displayName, avatar: currentUser.avatar },
              ...members.map(m => ({ userId: m.id, username: m.username, displayName: m.displayName, avatar: m.avatar })),
            ],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          }
          saveChats([newChat, ...chats])
          setActiveChat(newChat)
          setShowNewGroup(false)
          toast.success(`گروه "${name}" ساخته شد`)
        }}
      />
      
      {/* پنجره چت */}
      {activeChat && (
        <ChatWindow
          chat={activeChat}
          currentUserId={currentUser.id}
          onBack={() => setActiveChat(null)}
          onSendMessage={(text) => {
            const msg: ChatMessage = {
              id: `msg_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
              chatId: activeChat.id,
              senderId: currentUser.id,
              senderUsername: currentUser.username,
              senderDisplayName: currentUser.displayName,
              senderAvatar: currentUser.avatar,
              text,
              createdAt: new Date().toISOString(),
              read: false,
            }
            const updatedChats = chats.map(c => 
              c.id === activeChat.id 
                ? { ...c, lastMessage: msg, updatedAt: msg.createdAt }
                : c
            )
            saveChats(updatedChats)
            setActiveChat({ ...activeChat, lastMessage: msg })
          }}
        />
      )}
    </div>
  )
}

function ChatListItem({ chat, currentUserId, onClick }: {
  chat: Chat
  currentUserId: string
  onClick: () => void
}) {
  const otherUser = chat.type === 'private' 
    ? chat.participantsInfo.find(p => p.userId !== currentUserId)
    : null
  
  const name = chat.type === 'group' ? chat.name : otherUser?.displayName
  const avatar = chat.type === 'group' ? chat.avatar : otherUser?.avatar
  
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center gap-3 p-3 hover:bg-muted transition-colors text-right"
    >
      <Avatar className="h-12 w-12 shrink-0">
        <AvatarFallback className="bg-primary/10 text-xl">{avatar}</AvatarFallback>
      </Avatar>
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between">
          <p className="font-medium text-sm truncate">{name}</p>
          {chat.lastMessage && (
            <span className="text-xs text-muted-foreground shrink-0">
              {relativeTime(new Date(chat.lastMessage.createdAt))}
            </span>
          )}
        </div>
        <p className="text-xs text-muted-foreground truncate">
          {chat.lastMessage 
            ? `${chat.lastMessage.senderId === currentUserId ? 'شما: ' : ''}${chat.lastMessage.text}`
            : chat.type === 'group'
            ? `${toPersianDigits(chat.participants.length)} عضو`
            : 'چت جدید'
          }
        </p>
      </div>
      {chat.type === 'group' && (
        <Badge variant="secondary" className="text-xs shrink-0">
          {toPersianDigits(chat.participants.length)}
        </Badge>
      )}
    </button>
  )
}

function ChatWindow({ chat, currentUserId, onBack, onSendMessage }: {
  chat: Chat
  currentUserId: string
  onBack: () => void
  onSendMessage: (text: string) => void
}) {
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [text, setText] = useState('')
  const scrollRef = useRef<HTMLDivElement>(null)
  const [loaded, setLoaded] = useState(false)
  
  // بارگذاری پیام‌ها
  useEffect(() => {
    if (loaded) return
    const data = localStorage.getItem(`messages-${chat.id}`)
    if (data) {
      try {
        const parsed = JSON.parse(data)
        setTimeout(() => setMessages(parsed), 0)
      } catch {}
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoaded(true)
  }, [chat.id, loaded])
  
  // اسکرول به پایین
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages])
  
  const handleSend = () => {
    if (!text.trim()) return
    onSendMessage(text.trim())
    
    // اضافه کردن به پیام‌های محلی
    const msg: ChatMessage = {
      id: `msg_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`,
      chatId: chat.id,
      senderId: currentUserId,
      senderUsername: '',
      senderDisplayName: 'شما',
      senderAvatar: '',
      text: text.trim(),
      createdAt: new Date().toISOString(),
      read: false,
    }
    const newMessages = [...messages, msg]
    setMessages(newMessages)
    localStorage.setItem(`messages-${chat.id}`, JSON.stringify(newMessages))
    setText('')
  }
  
  const otherUser = chat.type === 'private' 
    ? chat.participantsInfo.find(p => p.userId !== currentUserId)
    : null
  
  const title = chat.type === 'group' ? chat.name : otherUser?.displayName
  const avatar = chat.type === 'group' ? chat.avatar : otherUser?.avatar
  
  return (
    <div className="fixed inset-0 z-[60] bg-background flex flex-col">
      {/* هدر */}
      <div className="flex items-center gap-3 p-3 border-b safe-top">
        <Button variant="ghost" size="icon" className="h-9 w-9" onClick={onBack}>
          <ArrowRight className="h-5 w-5" />
        </Button>
        <Avatar className="h-10 w-10">
          <AvatarFallback className="bg-primary/10 text-lg">{avatar}</AvatarFallback>
        </Avatar>
        <div className="flex-1 min-w-0">
          <p className="font-medium text-sm truncate">{title}</p>
          {chat.type === 'group' && (
            <p className="text-xs text-muted-foreground">
              {toPersianDigits(chat.participants.length)} عضو
            </p>
          )}
        </div>
      </div>
      
      {/* پیام‌ها */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-3" style={{ WebkitOverflowScrolling: 'touch' }}>
        {messages.length === 0 ? (
          <div className="text-center py-12 text-muted-foreground">
            <MessageCircle className="h-12 w-12 mx-auto mb-3 opacity-30" />
            <p className="text-sm">پیامی وجود ندارد</p>
            <p className="text-xs mt-1">اولین پیام را بفرستید</p>
          </div>
        ) : (
          messages.map((msg) => {
            const isMine = msg.senderId === currentUserId || msg.senderDisplayName === 'شما'
            return (
              <div key={msg.id} className={`flex ${isMine ? 'justify-start' : 'justify-end'}`}>
                <div className={`max-w-[75%] rounded-2xl px-3 py-2 ${
                  isMine 
                    ? 'bg-primary text-primary-foreground rounded-bl-sm' 
                    : 'bg-muted rounded-br-sm'
                }`}>
                  {!isMine && chat.type === 'group' && (
                    <p className="text-xs font-semibold mb-1 opacity-70">
                      {msg.senderDisplayName}
                    </p>
                  )}
                  <p className="text-sm whitespace-pre-wrap">{msg.text}</p>
                  <p className={`text-xs mt-1 ${isMine ? 'text-primary-foreground/70' : 'text-muted-foreground'}`}>
                    {relativeTime(new Date(msg.createdAt))}
                  </p>
                </div>
              </div>
            )
          })
        )}
      </div>
      
      {/* ورودی پیام */}
      <div className="p-3 border-t safe-bottom">
        <div className="flex gap-2">
          <Input
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="پیام بنویس..."
            onKeyDown={(e) => { if (e.key === 'Enter') handleSend() }}
            className="flex-1"
          />
          <Button size="icon" onClick={handleSend} disabled={!text.trim()} className="h-10 w-10">
            <Send className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}

function SearchUserDialog({ open, onOpenChange, onSelectUser }: {
  open: boolean
  onOpenChange: (v: boolean) => void
  onSelectUser: (user: any) => void
}) {
  const { currentUser, searchUsers } = useAuthStore()
  const [query, setQuery] = useState('')
  const results = useMemo(() => {
    if (!query.trim()) return []
    return searchUsers(query).filter(u => u.id !== currentUser?.id)
  }, [query, currentUser, searchUsers])
  
  useEffect(() => {
    // برای جستجوی زنده، نتایج از useMemo میاد
  }, [query])
  
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md" dir="rtl">
        <DialogHeader>
          <DialogTitle className="text-right">جستجوی کاربر</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 pt-2">
          <div className="relative">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="ID یا نام کاربر..."
              className="pr-10"
              dir="ltr"
              autoFocus
            />
          </div>
          
          <div className="max-h-80 overflow-y-auto space-y-1">
            {results.length === 0 ? (
              <p className="text-center text-sm text-muted-foreground py-8">
                {query.trim() ? 'کاربری یافت نشد' : 'برای جستجو تایپ کنید'}
              </p>
            ) : (
              results.map(user => (
                <button
                  key={user.id}
                  onClick={() => onSelectUser(user)}
                  className="w-full flex items-center gap-3 p-2 rounded-lg hover:bg-muted transition-colors text-right"
                >
                  <Avatar className="h-10 w-10 shrink-0">
                    <AvatarFallback className="bg-primary/10 text-lg">{user.avatar}</AvatarFallback>
                  </Avatar>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{user.displayName}</p>
                    <p className="text-xs text-muted-foreground" dir="ltr">@{user.username}</p>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function NewGroupDialog({ open, onOpenChange, onCreate }: {
  open: boolean
  onOpenChange: (v: boolean) => void
  onCreate: (name: string, members: any[]) => void
}) {
  const { searchUsers, currentUser } = useAuthStore()
  const [name, setName] = useState('')
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState<any[]>([])
  
  const results = useMemo(() => {
    if (!query.trim()) return []
    return searchUsers(query).filter(u => 
      u.id !== currentUser?.id && 
      !selected.find(s => s.id === u.id)
    )
  }, [query, selected, currentUser, searchUsers])
  
  useEffect(() => {
    // نتایج از useMemo میاد
  }, [query, selected])
  
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto hide-scrollbar" dir="rtl">
        <DialogHeader>
          <DialogTitle className="text-right">ساخت گروه جدید</DialogTitle>
        </DialogHeader>
        <div className="space-y-3 pt-2">
          <div className="space-y-1.5">
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="نام گروه..."
            />
          </div>
          
          {selected.length > 0 && (
            <div>
              <p className="text-xs text-muted-foreground mb-1">
                اعضا: {toPersianDigits(selected.length + 1)}/{toPersianDigits(30)}
              </p>
              <div className="flex flex-wrap gap-1">
                {selected.map(m => (
                  <Badge key={m.id} variant="secondary" className="gap-1">
                    {m.displayName}
                    <button onClick={() => setSelected(selected.filter(s => s.id !== m.id))}>×</button>
                  </Badge>
                ))}
              </div>
            </div>
          )}
          
          <div className="relative">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="جستجوی کاربر برای اضافه کردن..."
              className="pr-10"
              dir="ltr"
            />
          </div>
          
          <div className="max-h-60 overflow-y-auto space-y-1">
            {results.map(user => (
              <button
                key={user.id}
                onClick={() => {
                  if (selected.length < 29) {
                    setSelected([...selected, user])
                    setQuery('')
                  } else {
                    toast.error('حداکثر ۳۰ نفر')
                  }
                }}
                className="w-full flex items-center gap-3 p-2 rounded-lg hover:bg-muted transition-colors text-right"
              >
                <Avatar className="h-8 w-8 shrink-0">
                  <AvatarFallback className="bg-primary/10 text-sm">{user.avatar}</AvatarFallback>
                </Avatar>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">{user.displayName}</p>
                  <p className="text-xs text-muted-foreground" dir="ltr">@{user.username}</p>
                </div>
                <Plus className="h-4 w-4 text-primary" />
              </button>
            ))}
          </div>
          
          <div className="flex gap-2 pt-2 sticky bottom-0 bg-background py-3">
            <Button variant="outline" className="flex-1" onClick={() => onOpenChange(false)}>انصراف</Button>
            <Button
              className="flex-1"
              disabled={!name.trim() || selected.length === 0}
              onClick={() => {
                onCreate(name.trim(), selected)
                setName('')
                setSelected([])
                setQuery('')
              }}
            >
              ساخت گروه
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
