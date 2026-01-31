#!/bin/bash

# 1. 窗口布局管理 (完全保留原版酷炫效果)
current_window_id=$(osascript -e 'tell app "Terminal" to id of front window')
osascript <<EOF
tell application "Terminal"
    activate
    set windowList to every window
    repeat with theWindow in windowList
        if id of theWindow is not ${current_window_id} then
            try
                close theWindow saving no
            end try
        end if
    end repeat
end tell
EOF
sleep 1

# 获取屏幕尺寸布局
if command -v system_profiler >/dev/null 2>&1; then
    screen_info=$(system_profiler SPDisplaysDataType | grep Resolution | head -1 | awk '{print $2, $4}' | tr 'x' ' ')
    read -r width height <<< "$screen_info"
else
    width=1920; height=1080
fi

# 布局参数
spacing=20
x1=0; y1=0
upper_height=$((height/2-2*spacing))
upper_item_width=$(( (width-spacing)/2 ))
lower_height=$((height/2-2*spacing))
lower_y=$((y1+upper_height+2*spacing))
lower_item_width=$(( (width-spacing)/2 ))
wai_width=$((upper_item_width/2))
wai_height=$upper_height
nexus_ritual_height=$((lower_height-30))
nexus_ritual_y=$((lower_y+5))

function arrange_window {
    local title=$1
    local x=$2
    local y=$3
    local w=$4
    local h=$5
    local right_x=$((x + w))
    local bottom_y=$((y + h))
    osascript -e "tell application \"Terminal\" to set bounds of first window whose name contains \"$title\" to {$x, $y, $right_x, $bottom_y}" 2>/dev/null
}

echo "✅ 正在启动所有节点..."

# 2. 依次启动各项目 (调用生成的桌面快捷方式)
DESKTOP_DIR="$HOME/Desktop"

# 2.1 Tashi
if [ -f "$DESKTOP_DIR/My_Tashi.command" ]; then
    open "$DESKTOP_DIR/My_Tashi.command"
    sleep 2
    arrange_window "My_Tashi" $((x1+30)) $y1 $upper_item_width $upper_height
else
    echo "⚠️ 未找到 My_Tashi.command，请先运行/安装 Tashi"
fi

# 2.2 Dria (取代原版位置)
if [ -f "$DESKTOP_DIR/My_Dria.command" ]; then
    open "$DESKTOP_DIR/My_Dria.command"
    sleep 2
    arrange_window "My_Dria" $((x1+upper_item_width+spacing+upper_item_width/2)) $y1 $wai_width $wai_height
else
     echo "⚠️ 未找到 My_Dria.command，请先运行/安装 Dria"
fi

# 2.3 Nexus
if [ -f "$DESKTOP_DIR/My_Nexus.command" ]; then
    open "$DESKTOP_DIR/My_Nexus.command"
    sleep 2
    arrange_window "My_Nexus" $x1 $nexus_ritual_y $lower_item_width $nexus_ritual_height
else
     echo "⚠️ 未找到 My_Nexus.command，请先运行/安装 Nexus"
fi

# 2.4 OptimAI
if [ -f "$DESKTOP_DIR/My_Optimal.command" ]; then
    open "$DESKTOP_DIR/My_Optimal.command"
    # OptimAI 放在右下角
    arrange_window "My_Optimal" $((x1+lower_item_width+spacing)) $nexus_ritual_y $lower_item_width $nexus_ritual_height
else
     echo "⚠️ 未找到 My_Optimal.command，请先运行/安装 Optimal"
fi

echo "✅ 所有任务已执行。"
