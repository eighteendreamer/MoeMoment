/**
 * 与 Rust 侧 DTO 对应的类型定义（serde camelCase）。
 * 修改这里时必须同步 src-tauri/src/dto.rs。
 */

export type LensState = 'unopened' | 'in_use' | 'expired' | 'discarded'
export type CycleUnit = 'day' | 'week' | 'month' | 'year'
export type ExpirySource = 'none' | 'package' | 'usage' | 'earlier_of_both'

/** 六个镜片参数，键名与数据库 JSON 保持一致，全部可选 */
export interface LensSpecs {
  Lens_diameter?: number
  Colored_diameter?: number
  Moisture_content?: number
  Base_arc?: number
  Left_eye_prescription?: number
  right_eye_prescription?: number
}

export interface LensImage {
  id: number
  path: string
  sortOrder: number
}

export interface Lens {
  id: number
  brand: string
  name: string
  cycleId: number
  cycleName: string
  cycleUnit: CycleUnit
  cycleValue: number
  colorScheme: string | null
  lensSpecs: LensSpecs
  status: string
  state: LensState
  expiryDate: string | null
  expirySource: ExpirySource
  daysRemaining: number | null
  isExpiringSoon: boolean
  openedAt: string | null
  packageExpiryDate: string | null
  discardedAt: string | null
  note: string | null
  images: LensImage[]
  createdAt: string
  updatedAt: string
}

export interface HomeStats {
  inUse: number
  unopened: number
  expired: number
  total: number
  discarded: number
}

export interface HomeOverview {
  expiring: Lens[]
  expired: Lens[]
  recent: Lens[]
  stats: HomeStats
  advanceDays: number
  lensReminderEnabled: boolean
}

export interface LensFilter {
  keyword?: string
  cycleId?: number
  state?: LensState | 'all'
  colorScheme?: string
}

export interface LensUpsert {
  brand: string
  name: string
  cycleId: number
  colorScheme?: string | null
  lensSpecs?: LensSpecs
  packageExpiryDate?: string | null
  note?: string | null
  images: string[]
}

export interface Cycle {
  id: number
  cycleName: string
  cycleUnit: CycleUnit
  cycleValue: number
  isBuiltin: boolean
  sortOrder: number
  lensCount: number
}

export interface CycleUpsert {
  cycleName: string
  cycleUnit: CycleUnit
  cycleValue: number
  sortOrder?: number
}

export interface LensReminderSetting {
  isActive: boolean
  advanceDays: number
  reminderTime: string
}

export interface CareChangeLog {
  id: number
  changedAt: string
  note: string | null
}

export interface CareChangeReminder {
  isActive: boolean
  frequency: string
  intervalDays: number
  reminderTime: string
  lastChangedDate: string | null
  nextChangedDate: string | null
  daysUntilNext: number | null
  history: CareChangeLog[]
}

export interface CareExpiryReminder {
  isActive: boolean
  advanceDays: number
  reminderTime: string
}

export interface CareBottle {
  id: number
  brand: string
  name: string
  openedAt: string | null
  packageExpiryDate: string | null
  afterOpenValidDays: number | null
  isCurrent: boolean
  note: string | null
  expiryDate: string | null
  daysRemaining: number | null
  expired: boolean
}

export interface CareState {
  change: CareChangeReminder
  expiry: CareExpiryReminder
  bottle: CareBottle | null
}

export interface CareBottleInput {
  id?: number | null
  brand: string
  name: string
  openedAt?: string | null
  packageExpiryDate?: string | null
  afterOpenValidDays?: number | null
  isCurrent: boolean
  note?: string | null
}

export interface NotificationLog {
  id: number
  notificationKey: string
  targetType: string
  targetId: number | null
  scheduledDate: string
  sentAt: string | null
  status: 'scheduled' | 'sent' | 'failed' | 'cancelled'
  title: string
  body: string
}

export interface NotificationPermission {
  granted: boolean
  canRequest: boolean
  platformNote: string
}

export interface AppSettings {
  systemNotificationsEnabled: boolean
  autoUpdateEnabled: boolean
  githubMirrorMode: 'official' | 'mirror' | 'auto'
  updateChannel: 'stable' | 'beta'
  lastUpdateCheckAt: string | null
}

export interface AppInfo {
  version: string
  identifier: string
  platform: string
  arch: string
  databasePath: string
}

export interface UpdateAsset {
  name: string
  url: string
  size: number
  contentType: string | null
}

export interface UpdateInfo {
  currentVersion: string
  latestVersion: string | null
  hasUpdate: boolean
  notes: string | null
  publishedAt: string | null
  releaseUrl: string | null
  asset: UpdateAsset | null
  checksum: UpdateAsset | null
  installHint: string
  source: string | null
  error: string | null
}

export interface DownloadResult {
  path: string
  bytes: number
  sha256: string
  verified: boolean
}
