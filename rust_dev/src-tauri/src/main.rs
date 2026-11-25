// 发布模式下隐藏 Windows 控制台窗口，请勿删除
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    moemoment_lib::run();
}
