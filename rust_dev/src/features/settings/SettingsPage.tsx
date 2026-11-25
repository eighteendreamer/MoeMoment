import { useEffect, useState } from 'react'
import {
  Bell,
  ChevronRight,
  CloudDownload,
  Droplets,
  GitBranch,
  Info,
  Repeat2,
  Timer,
} from 'lucide-react'
import { Page } from '@/components/Page'
import { Dialog, DialogContent } from '@/components/arc/dialog/dialog'
import { Button } from '@/components/arc/button/button'
import SegmentedControl from '@/components/arc/segmented-control/segmented-control'
import { useNav } from '@/app/navigation'
import { api } from '@/lib/api'
import type { AppInfo, AppSettings, NotificationPermission } from '@/lib/types'

const MIRROR_LABEL: Record<string, string> = {
  official: '官方源',
  mirror: '镜像源',
  auto: '自动（镜像优先）',
}

export function SettingsPage() {
  const { push, version, refresh } = useNav()
  const [info, setInfo] = useState<AppInfo | null>(null)
  const [settings, setSettings] = useState<AppSettings | null>(null)
  const [permission, setPermission] = useState<NotificationPermission | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [mirrorOpen, setMirrorOpen] = useState(false)
  const [mirrorValue, setMirrorValue] = useState('auto')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    let cancelled = false
    Promise.all([api.appInfo(), api.getAppSettings(), api.notificationPermission()])
      .then(([nextInfo, nextSettings, nextPermission]) => {
        if (cancelled) return
        setInfo(nextInfo)
        setSettings(nextSettings)
        setMirrorValue(nextSettings.githubMirrorMode)
        setPermission(nextPermission)
        setError(null)
      })
      .catch((err: Error) => !cancelled && setError(err.message))
    return () => {
      cancelled = true
    }
  }, [version])

  const saveMirror = async () => {
    setSaving(true)
    try {
      const updated = await api.setAppSetting('github_mirror_mode', mirrorValue)
      setSettings(updated)
      setMirrorOpen(false)
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <Page hero tabBar title="我的">
      {error ? (
        <div className="error-box" style={{ marginBottom: 14 }}>
          {error}
        </div>
      ) : null}

      <div className="settings-group">
        <h3>通知与提醒</h3>
        <div className="settings-card">
          <button className="settings-row" onClick={() => push({ name: 'notifications' })}>
            <span className="lead">
              <Bell size={16} strokeWidth={1.8} />
            </span>
            <span>系统通知</span>
            <span className="value">
              {permission ? (permission.granted ? '已授权' : '未授权') : '检查中'}
              <ChevronRight size={15} />
            </span>
          </button>
          <button className="settings-row" onClick={() => push({ name: 'reminders' })}>
            <span className="lead">
              <Timer size={16} strokeWidth={1.8} />
            </span>
            <span>提醒设置</span>
            <span className="value">
              <ChevronRight size={15} />
            </span>
          </button>
          <button className="settings-row" onClick={() => push({ name: 'care' })}>
            <span className="lead">
              <Droplets size={16} strokeWidth={1.8} />
            </span>
            <span>护理液信息</span>
            <span className="value">
              <ChevronRight size={15} />
            </span>
          </button>
        </div>
      </div>

      <div className="settings-group">
        <h3>管理</h3>
        <div className="settings-card">
          <button className="settings-row" onClick={() => push({ name: 'cycles' })}>
            <span className="lead">
              <Repeat2 size={16} strokeWidth={1.8} />
            </span>
            <span>周期管理</span>
            <span className="value">
              <ChevronRight size={15} />
            </span>
          </button>
          <button className="settings-row" onClick={() => push({ name: 'update' })}>
            <span className="lead">
              <CloudDownload size={16} strokeWidth={1.8} />
            </span>
            <span>自动更新</span>
            <span className="value">
              {settings?.autoUpdateEnabled ? '已开启' : '已关闭'}
              <ChevronRight size={15} />
            </span>
          </button>
          <button className="settings-row" onClick={() => setMirrorOpen(true)}>
            <span className="lead">
              <GitBranch size={16} strokeWidth={1.8} />
            </span>
            <span>GitHub 镜像加速</span>
            <span className="value">
              {MIRROR_LABEL[settings?.githubMirrorMode ?? 'auto']}
              <ChevronRight size={15} />
            </span>
          </button>
        </div>
      </div>

      <div className="settings-group">
        <h3>关于</h3>
        <div className="settings-card">
          <div className="settings-row" style={{ cursor: 'default' }}>
            <span className="lead">
              <Info size={16} strokeWidth={1.8} />
            </span>
            <span>版本</span>
            <span className="value">
              {info ? `${info.version} · ${info.platform}` : '—'}
            </span>
          </div>
        </div>
      </div>

      <Dialog open={mirrorOpen} onOpenChange={setMirrorOpen}>
        <DialogContent
          title="GitHub 镜像加速"
          description="只影响更新包的下载地址，不改变版本校验逻辑。镜像地址需要可信配置，未配置时仅能使用官方源。"
        >
          <div style={{ marginTop: 14 }}>
            <SegmentedControl
              label="下载源"
              fullWidth
              value={mirrorValue}
              onValueChange={setMirrorValue}
              options={[
                { value: 'official', label: '官方源' },
                { value: 'mirror', label: '镜像源' },
                { value: 'auto', label: '自动' },
              ]}
            />
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
            <Button variant="secondary" style={{ flex: 1 }} onClick={() => setMirrorOpen(false)}>
              取消
            </Button>
            <Button style={{ flex: 1 }} loading={saving} onClick={saveMirror}>
              保存
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </Page>
  )
}
