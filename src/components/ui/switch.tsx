"use client"

import * as React from "react"

interface SwitchProps {
  checked?: boolean
  onCheckedChange?: (checked: boolean) => void
  disabled?: boolean
  id?: string
  className?: string
}

function Switch({ checked = false, onCheckedChange, disabled, id, className }: SwitchProps) {
  const handleToggle = () => {
    if (!disabled && onCheckedChange) {
      onCheckedChange(!checked)
    }
  }

  return (
    <button
      type="button"
      role="switch"
      id={id}
      aria-checked={checked}
      disabled={disabled}
      onClick={handleToggle}
      style={{
        position: 'relative',
        display: 'inline-flex',
        height: '24px',
        width: '44px',
        flexShrink: 0,
        alignItems: 'center',
        borderRadius: '9999px',
        border: '2px solid transparent',
        transition: 'background-color 0.2s',
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.5 : 1,
        backgroundColor: checked ? 'var(--primary)' : 'var(--input)',
        ...(className ? {} : {}),
      }}
      className={className}
    >
      <span
        style={{
          position: 'absolute',
          display: 'block',
          height: '20px',
          width: '20px',
          borderRadius: '9999px',
          backgroundColor: 'white',
          boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
          transition: 'transform 0.2s',
          transform: checked ? 'translateX(20px)' : 'translateX(2px)',
        }}
      />
    </button>
  )
}

export { Switch }
