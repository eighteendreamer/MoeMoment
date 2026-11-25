import { Dialog, DialogClose, DialogContent } from '@/components/arc/dialog/dialog'
import { Button } from '@/components/arc/button/button'

interface ConfirmDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description: string
  confirmText?: string
  cancelText?: string
  danger?: boolean
  busy?: boolean
  onConfirm: () => void
}

/** 统一的二次确认弹层：删除、丢弃、清除等不可逆操作必须走这里。 */
export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmText = '确认',
  cancelText = '取消',
  danger = false,
  busy = false,
  onConfirm,
}: ConfirmDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent title={title} description={description}>
        <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
          <DialogClose asChild>
            <Button variant="secondary" disabled={busy} style={{ flex: 1 }}>
              {cancelText}
            </Button>
          </DialogClose>
          <Button
            variant={danger ? 'danger' : 'primary'}
            loading={busy}
            style={{ flex: 1 }}
            onClick={onConfirm}
          >
            {confirmText}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
