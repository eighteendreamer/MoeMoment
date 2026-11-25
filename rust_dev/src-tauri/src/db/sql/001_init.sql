-- 初始化结构（schemaVersion 1）
-- 约定：业务日期为本地日历日期字符串（YYYY-MM-DD），时间戳为 RFC3339 字符串。

CREATE TABLE IF NOT EXISTS lens_cycles (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  cycle_name    TEXT    NOT NULL,
  cycle_unit    TEXT    NOT NULL CHECK (cycle_unit IN ('day', 'week', 'month', 'year')),
  cycle_value   INTEGER NOT NULL CHECK (cycle_value > 0),
  is_builtin    INTEGER NOT NULL DEFAULT 0,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT    NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_lens_cycles_natural
  ON lens_cycles (cycle_name, cycle_unit, cycle_value);

CREATE TABLE IF NOT EXISTS lenses (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT,
  brand                TEXT    NOT NULL DEFAULT '',
  name                 TEXT    NOT NULL DEFAULT '',
  cycle_id             INTEGER NOT NULL REFERENCES lens_cycles (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  color_scheme         TEXT,
  lens_specs           TEXT,
  status               TEXT    NOT NULL DEFAULT 'unopened'
                        CHECK (status IN ('unopened', 'opened', 'discarded')),
  opened_at            TEXT,
  package_expiry_date  TEXT,
  discarded_at         TEXT,
  note                 TEXT,
  created_at           TEXT    NOT NULL,
  updated_at           TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lenses_cycle_id ON lenses (cycle_id);
CREATE INDEX IF NOT EXISTS idx_lenses_status ON lenses (status);
CREATE INDEX IF NOT EXISTS idx_lenses_package_expiry ON lenses (package_expiry_date);
CREATE INDEX IF NOT EXISTS idx_lenses_opened_at ON lenses (opened_at);
CREATE INDEX IF NOT EXISTS idx_lenses_updated_at ON lenses (updated_at);

CREATE TABLE IF NOT EXISTS lens_images (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  lens_id     INTEGER NOT NULL REFERENCES lenses (id) ON DELETE CASCADE,
  image_path  TEXT    NOT NULL,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lens_images_lens ON lens_images (lens_id, sort_order);

CREATE TABLE IF NOT EXISTS lens_expiry_reminder_settings (
  id            INTEGER PRIMARY KEY,
  is_active     INTEGER NOT NULL DEFAULT 1,
  advance_days  INTEGER NOT NULL DEFAULT 3,
  reminder_time TEXT    NOT NULL DEFAULT '09:00',
  updated_at    TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS care_solution_change_reminders (
  id                INTEGER PRIMARY KEY,
  is_active         INTEGER NOT NULL DEFAULT 1,
  frequency         TEXT    NOT NULL DEFAULT 'every_3_days',
  interval_days     INTEGER NOT NULL DEFAULT 3 CHECK (interval_days > 0),
  reminder_time     TEXT    NOT NULL DEFAULT '09:00',
  last_changed_date TEXT,
  next_changed_date TEXT,
  updated_at        TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS care_solution_change_logs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  reminder_id INTEGER NOT NULL REFERENCES care_solution_change_reminders (id) ON DELETE CASCADE,
  changed_at  TEXT    NOT NULL,
  note        TEXT,
  created_at  TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_care_change_logs_changed_at ON care_solution_change_logs (changed_at);

CREATE TABLE IF NOT EXISTS care_solution_bottles (
  id                     INTEGER PRIMARY KEY AUTOINCREMENT,
  brand                  TEXT    NOT NULL DEFAULT '',
  name                   TEXT    NOT NULL DEFAULT '',
  opened_at              TEXT,
  package_expiry_date    TEXT,
  after_open_valid_days  INTEGER CHECK (after_open_valid_days IS NULL OR after_open_valid_days > 0),
  is_current             INTEGER NOT NULL DEFAULT 1,
  note                   TEXT,
  created_at             TEXT    NOT NULL,
  updated_at             TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_care_bottles_is_current ON care_solution_bottles (is_current);

CREATE TABLE IF NOT EXISTS care_solution_expiry_settings (
  id            INTEGER PRIMARY KEY,
  is_active     INTEGER NOT NULL DEFAULT 1,
  advance_days  INTEGER NOT NULL DEFAULT 3,
  reminder_time TEXT    NOT NULL DEFAULT '09:00',
  updated_at    TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS app_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS notification_logs (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  notification_key TEXT    NOT NULL UNIQUE,
  target_type      TEXT    NOT NULL,
  target_id        INTEGER,
  scheduled_date   TEXT    NOT NULL,
  sent_at          TEXT,
  status           TEXT    NOT NULL DEFAULT 'scheduled'
                    CHECK (status IN ('scheduled', 'sent', 'failed', 'cancelled')),
  title            TEXT    NOT NULL,
  body             TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notification_logs_schedule
  ON notification_logs (scheduled_date, status);
CREATE INDEX IF NOT EXISTS idx_notification_logs_target
  ON notification_logs (target_type, target_id);
