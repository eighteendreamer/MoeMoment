/**
 * Tauri 命令封装。所有数据库读写都必须经过这里，页面不直接 invoke 字符串。
 * 错误统一是后端返回的中文字符串，转成 Error 抛出。
 */
import { convertFileSrc, invoke } from '@tauri-apps/api/core'
import type {
  AppInfo,
  AppSettings,
  CareBottleInput,
  CareState,
  Cycle,
  CycleUpsert,
  DownloadResult,
  HomeOverview,
  Lens,
  LensFilter,
  LensReminderSetting,
  LensUpsert,
  NotificationLog,
  NotificationPermission,
  UpdateInfo,
} from './types'

async function call<T>(command: string, args?: Record<string, unknown>): Promise<T> {
  try {
    return await invoke<T>(command, args)
  } catch (error) {
    const message =
      typeof error === 'string'
        ? error
        : error instanceof Error
          ? error.message
          : '操作失败，请重试'
    throw new Error(message)
  }
}

export const api = {
  // 美瞳
  listLenses: (filter: LensFilter = {}) => call<Lens[]>('list_lenses', { filter }),
  getLens: (id: number) => call<Lens>('get_lens', { id }),
  createLens: (payload: LensUpsert) => call<Lens>('create_lens', { payload }),
  updateLens: (id: number, payload: LensUpsert) => call<Lens>('update_lens', { id, payload }),
  deleteLens: (id: number) => call<void>('delete_lens', { id }),
  openLens: (lensId: number, openedAt?: string | null) =>
    call<Lens>('open_lens', { request: { lensId, openedAt: openedAt ?? null } }),
  discardLens: (id: number) => call<Lens>('discard_lens', { id }),
  restoreLens: (id: number) => call<Lens>('restore_lens', { id }),
  homeOverview: () => call<HomeOverview>('home_overview'),
  expiringLenses: () => call<Lens[]>('expiring_lenses'),
  lensColors: () => call<string[]>('lens_colors'),

  // 周期
  listCycles: () => call<Cycle[]>('list_cycles'),
  createCycle: (payload: CycleUpsert) => call<Cycle>('create_cycle', { payload }),
  updateCycle: (id: number, payload: CycleUpsert) => call<Cycle>('update_cycle', { id, payload }),
  deleteCycle: (id: number) => call<void>('delete_cycle', { id }),

  // 护理液
  careState: () => call<CareState>('care_state'),
  saveCareBottle: (payload: CareBottleInput) => call<CareState>('save_care_bottle', { payload }),
  updateCareChangeReminder: (payload: {
    isActive: boolean
    frequency: string
    intervalDays: number
    reminderTime: string
  }) => call<CareState>('update_care_change_reminder', { payload }),
  updateCareExpiryReminder: (payload: {
    isActive: boolean
    advanceDays: number
    reminderTime: string
  }) => call<CareState>('update_care_expiry_reminder', { payload }),
  markCareChanged: (changedAt?: string | null, note?: string | null) =>
    call<CareState>('mark_care_changed', { changedAt: changedAt ?? null, note: note ?? null }),

  // 设置与通知
  appInfo: () => call<AppInfo>('app_info'),
  getAppSettings: () => call<AppSettings>('get_app_settings'),
  setAppSetting: (key: string, value: string) => call<AppSettings>('set_app_setting', { key, value }),
  lensReminderSetting: () => call<LensReminderSetting>('lens_reminder_setting'),
  updateLensReminder: (payload: LensReminderSetting) =>
    call<LensReminderSetting>('update_lens_reminder', { payload }),
  notificationPermission: () => call<NotificationPermission>('notification_permission'),
  requestNotificationPermission: () =>
    call<NotificationPermission>('request_notification_permission'),
  notificationLogs: (limit = 30) => call<NotificationLog[]>('notification_logs', { limit }),
  rescheduleNotifications: () => call<number>('reschedule_notifications'),

  // 更新
  checkUpdate: () => call<UpdateInfo>('check_update'),
  fetchUpdateChecksum: (url: string) => call<string>('fetch_update_checksum', { url }),
  installApk: (path: string) => call<void>('install_apk', { path }),
  exportBackup: () => call<string>('export_backup'),
  importBackup: (dataBase64: string) =>
    call<{ lenses: number; images: number; cycles: number; careBottles: number; autoBackup: string | null }>(
      'import_backup',
      { dataBase64 },
    ),
  shareFile: (path: string, mime?: string) => call<void>('share_file', { path, mime }),
  downloadUpdate: (url: string, fileName: string, expectedSha256?: string | null) =>
    call<DownloadResult>('download_update', {
      url,
      fileName,
      expectedSha256: expectedSha256 ?? null,
    }),

  // 图片
  saveLensImage: (data: string, mime?: string) =>
    call<string>('save_lens_image', { data, mime: mime ?? null }),
  deleteLensImage: (path: string) => call<void>('delete_lens_image', { path }),
}

/** 把本地绝对路径转成 WebView 可加载的 asset URL */
export function imageUrl(path: string | null | undefined): string | null {
  if (!path) return null
  try {
    return convertFileSrc(path)
  } catch {
    return null
  }
}
