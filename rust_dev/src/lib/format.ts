/** 日期与文案格式化：业务日期统一使用本地 YYYY-MM-DD 字符串。 */

export function todayISO(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = `${now.getMonth() + 1}`.padStart(2, '0')
  const day = `${now.getDate()}`.padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function isoToDate(iso: string | null | undefined): Date | undefined {
  if (!iso) return undefined
  const [year, month, day] = iso.split('-').map(Number)
  if (!year || !month || !day) return undefined
  return new Date(year, month - 1, day)
}

export function dateToISO(date: Date | undefined): string | null {
  if (!date) return null
  const year = date.getFullYear()
  const month = `${date.getMonth() + 1}`.padStart(2, '0')
  const day = `${date.getDate()}`.padStart(2, '0')
  return `${year}-${month}-${day}`
}

/** 2026-04-01 → 2026年4月1日；同一年时简写为 4月1日 */
export function formatDate(iso: string | null | undefined, short = false): string {
  const date = isoToDate(iso)
  if (!date) return '未填写'
  const current = new Date()
  const sameYear = date.getFullYear() === current.getFullYear()
  if (short && sameYear) return `${date.getMonth() + 1}月${date.getDate()}日`
  return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`
}

/** 剩余天数文案：今天到期 / 还剩 N 天 / 已过期 N 天 */
export function remainingText(days: number | null): string {
  if (days === null) return '无到期日'
  if (days === 0) return '今天到期'
  if (days > 0) return `还剩 ${days} 天`
  return `已过期 ${Math.abs(days)} 天`
}

export function remainingTone(days: number | null): 'danger' | 'warning' | 'calm' {
  if (days === null) return 'calm'
  if (days <= 0) return 'danger'
  if (days <= 3) return 'warning'
  return 'calm'
}

/** 数据库持久化状态的中文名称 */
export const STORAGE_STATE_LABEL: Record<string, string> = {
  unopened: '未开封',
  opened: '已开封',
  discarded: '已丢弃',
}

export const STATE_LABEL: Record<string, string> = {
  in_use: '使用中',
  unopened: '未开封',
  expired: '已过期',
  discarded: '已丢弃',
}

export const CYCLE_UNIT_LABEL: Record<string, string> = {
  day: '天',
  week: '周',
  month: '个月',
  year: '年',
}

/** 周期的人类可读表达：2 个月 / 10 天 */
export function cycleText(unit: string, value: number): string {
  if (unit === 'week') return `${value} 周`
  if (unit === 'month') return `${value} 个月`
  if (unit === 'year') return `${value} 年`
  return `${value} 天`
}

export function formatBytes(bytes: number): string {
  if (!bytes) return '未知大小'
  const units = ['B', 'KB', 'MB', 'GB']
  let value = bytes
  let index = 0
  while (value >= 1024 && index < units.length - 1) {
    value /= 1024
    index += 1
  }
  return `${value.toFixed(index === 0 ? 0 : 1)} ${units[index]}`
}

export function formatDateTime(value: string | null | undefined): string {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  const pad = (n: number) => `${n}`.padStart(2, '0')
  return `${date.getMonth() + 1}月${date.getDate()}日 ${pad(date.getHours())}:${pad(date.getMinutes())}`
}
