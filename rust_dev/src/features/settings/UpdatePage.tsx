import { useEffect, useState } from 'react'
import { listen } from '@tauri-apps/api/event'
import { CheckCircle2, Download, RefreshCw, ShieldAlert } from 'lucide-react'
import { Page } from '@/components/Page'
import { Button } from '@/components/arc/button/button'
import { Progress } from '@/components/arc/progress/progress'
import SegmentedControl from '@/components/arc/segmented-control/segmented-control'
import { Switch } from '@/components/arc/switch/switch'
import { useNav } from '@/app/navigation'
import { api } from '@/lib/api'
import { formatBytes, formatDateTime } from '@/lib/format'
import type { AppSettings, DownloadResult, UpdateInfo } from '@/lib/types'

/** 从 SHA256SUMS 文本里找出与文件名对应的哈希；找不到时退回唯一一条 64 位十六进制。 */
function findChecksum(text: string, fileName: string): string | null {
  const lines = text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
  for (const line of lines) {
    const match = line.match(/^([a-fA-F0-9]{64})\s+\*?(.+)$/)
    if (match && match[2].trim() === fileName) return match[1].toLowerCase()
  }
  const hashes = lines
    .map((line) => line.match(/^([a-fA-F0-9]{64})/)?.[1])
    .filter((value): value is string => Boolean(value))
  return hashes.length === 1 ? hashes[0].toLowerCase() : null
}

export function UpdatePage() {
  const { refresh } = useNav()
  const [settings, setSettings] = useState<AppSettings | null>(null)
  const [info, setInfo] = useState<UpdateInfo | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [checking, setChecking] = useState(false)
  const [downloading, setDownloading] = useState(false)
  const [progress, setProgress] = useState<{ downloaded: number; total: number } | null>(null)
  const [result, setResult] = useState<DownloadResult | null>(null)

  useEffect(() => {
    api
      .getAppSettings()
      .then(setSettings)
      .catch((err: Error) => setError(err.message))
  }, [])

  useEffect(() => {
    const unlisten = listen<{ downloaded: number; total: number }>('update://progress', (event) => {
      setProgress(event.payload)
    })
    return () => {
      unlisten.then((fn) => fn()).catch(() => undefined)
    }
  }, [])

  const check = async () => {
    setChecking(true)
    setError(null)
    setResult(null)
    try {
      const next = await api.checkUpdate()
      setInfo(next)
      // 配置缺失等情况在卡片内用提示文案展示，不当作红色错误
      setError(null)
      const nextSettings = await api.getAppSettings()
      setSettings(nextSettings)
      refresh()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setChecking(false)
    }
  }

  const toggleAutoUpdate = async (checked: boolean) => {
    try {
      const updated = await api.setAppSetting('auto_update_enabled', String(checked))
      setSettings(updated)
    } catch (err) {
      setError((err as Error).message)
    }
  }

  const setChannel = async (value: string) => {
    try {
      const updated = await api.setAppSetting('update_channel', value)
      setSettings(updated)
    } catch (err) {
      setError((err as Error).message)
    }
  }

  const download = async () => {
    if (!info?.asset) return
    setDownloading(true)
    setError(null)
    setProgress({ downloaded: 0, total: info.asset.size })

    try {
      let expected: string | null = null
      if (info.checksum) {
        const text = await api.fetchUpdateChecksum(info.checksum.url)
        expected = findChecksum(text, info.asset.name)
      }
      const downloaded = await api.downloadUpdate(info.asset.url, info.asset.name, expected)
      setResult(downloaded)

      // Android：下载并校验完成后直接拉起系统安装器
      if (downloaded.verified || expected === null) {
        try {
          await api.installApk(downloaded.path)
        } catch {
          setError('无法自动打开安装包，请到系统通知或文件中手动安装')
        }
      }
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setDownloading(false)
    }
  }

  const percent =
    progress && progress.total > 0
      ? Math.min(100, Math.round((progress.downloaded / progress.total) * 100))
      : null

  return (
    <Page title="自动更新">
      {error ? (
        <div className="error-box" style={{ marginBottom: 12 }}>
          {error}
        </div>
      ) : null}

      <div className="card card-pad" style={{ marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 12.5, color: 'var(--mm-ink-3)' }}>当前版本</div>
            <div style={{ fontSize: 22, fontWeight: 700, marginTop: 2 }}>
              v{info?.currentVersion ?? '—'}
            </div>
          </div>
          <Button variant="secondary" loading={checking} onClick={check}>
            <RefreshCw size={15} style={{ marginRight: 6 }} />
            检查更新
          </Button>
        </div>

        {info ? (
          <div style={{ marginTop: 12 }}>
            {info.error ? (
              <div className="notice">{info.error}</div>
            ) : info.hasUpdate ? (
              <div className="notice-soft">
                发现新版本 <strong>v{info.latestVersion}</strong>
                {info.publishedAt ? ` · ${formatDateTime(info.publishedAt)}` : ''}
                {info.source ? ` · 来源 ${info.source}` : ''}
              </div>
            ) : (
              <div className="notice-soft">
                已是最新版本{settings?.lastUpdateCheckAt ? `（${formatDateTime(settings.lastUpdateCheckAt)} 检查）` : ''}
              </div>
            )}
          </div>
        ) : (
          <p className="muted" style={{ marginBottom: 0, marginTop: 10 }}>
            {settings?.lastUpdateCheckAt
              ? `上次检查：${formatDateTime(settings.lastUpdateCheckAt)}`
              : '尚未检查过更新'}
          </p>
        )}
      </div>

      <div className="settings-group">
        <h3>更新设置</h3>
        <div className="settings-card">
          <div className="settings-row" style={{ cursor: 'default' }}>
            <span style={{ flex: 1 }}>
              <span style={{ display: 'block' }}>自动检查更新</span>
              <span style={{ fontSize: 12, color: 'var(--mm-ink-3)' }}>
                仅在你打开应用时检查，不会后台静默安装
              </span>
            </span>
            <Switch
              checked={settings?.autoUpdateEnabled ?? true}
              onCheckedChange={toggleAutoUpdate}
              disabled={!settings}
              aria-label="自动检查更新"
            />
          </div>
          <div className="card-pad" style={{ paddingTop: 12 }}>
            <SegmentedControl
              label="更新渠道"
              fullWidth
              value={settings?.updateChannel ?? 'stable'}
              onValueChange={setChannel}
              options={[
                { value: 'stable', label: '正式版' },
                { value: 'beta', label: '预览版' },
              ]}
            />
          </div>
        </div>
      </div>

      {info?.hasUpdate && info.asset ? (
        <div className="card card-pad" style={{ marginBottom: 14 }}>
          <div style={{ fontWeight: 620 }}>{info.asset.name}</div>
          <div className="muted" style={{ marginTop: 2 }}>
            {formatBytes(info.asset.size)}
            {info.checksum ? ` · 附带校验文件 ${info.checksum.name}` : ' · 发布未附带校验文件'}
          </div>

          {downloading ? (
            <div style={{ marginTop: 14 }}>
              <Progress value={percent ?? 0} label="下载中" showValue />
              <div className="progress-meta">
                <span>{formatBytes(progress?.downloaded ?? 0)}</span>
                <span>{percent === null ? '总大小未知' : `${percent}%`}</span>
              </div>
            </div>
          ) : null}

          <Button
            style={{ width: '100%', marginTop: 14 }}
            loading={downloading}
            onClick={download}
          >
            <Download size={16} style={{ marginRight: 6 }} />
            下载安装包
          </Button>

          <div className="notice" style={{ marginTop: 12 }}>
            {info.installHint}
          </div>
        </div>
      ) : null}

      {info?.notes ? (
        <section className="section">
          <div className="section-head">
            <h2>更新说明</h2>
          </div>
          <div className="card card-pad">
            <pre
              style={{
                margin: 0,
                whiteSpace: 'pre-wrap',
                fontFamily: 'inherit',
                fontSize: 13,
                lineHeight: 1.7,
                color: 'var(--mm-ink-2)',
              }}
            >
              {info.notes}
            </pre>
          </div>
        </section>
      ) : null}

      {result ? (
        <div className="card card-pad" style={{ marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontWeight: 620 }}>
            {result.verified ? (
              <CheckCircle2 size={17} color="var(--mm-success)" />
            ) : (
              <ShieldAlert size={17} color="var(--mm-warning)" />
            )}
            {result.verified ? 'SHA-256 校验通过' : '已下载，但发布未提供可比对哈希'}
          </div>
          <div className="muted" style={{ marginTop: 6, wordBreak: 'break-all' }}>
            文件：{result.path}
          </div>
          <div className="muted" style={{ marginTop: 4, wordBreak: 'break-all' }}>
            SHA-256：{result.sha256}
          </div>
          <div className="muted" style={{ marginTop: 4 }}>
            大小：{formatBytes(result.bytes)}
          </div>
          <div className="notice" style={{ marginTop: 10 }}>
            {info?.installHint ?? '请手动打开安装包完成更新。'}
          </div>
        </div>
      ) : null}
    </Page>
  )
}
