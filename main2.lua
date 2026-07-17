-- main2.lua (权限申请页)
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.view.animation.*"
import "android.animation.*"
import "android.content.Intent"
import "android.net.Uri"
import "android.provider.Settings"
import "android.content.Context"
import "android.content.pm.PackageManager"
import "android.Manifest"

-- ==================== 隐藏标题栏 ====================
pcall(function() activity.ActionBar.hide() end)

-- ==================== 权限检测函数 ====================
function 检查存储权限()
  if Build.VERSION.SDK_INT >= 23 then
    return activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
  end
  return true
end

function 检查通知权限()
  if Build.VERSION.SDK_INT >= 33 then
    return activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
  end
  return true
end

function 检查悬浮窗权限()
  if Build.VERSION.SDK_INT >= 23 then
    return Settings.canDrawOverlays(activity)
  end
  return true
end

function 检查电池优化()
  if Build.VERSION.SDK_INT >= 23 then
    local powerManager = activity.getSystemService(Context.POWER_SERVICE)
    return powerManager.isIgnoringBatteryOptimizations(activity.getPackageName())
  end
  return true
end

-- ==================== 必需权限是否全部授权 ====================
function 必需权限已全部授权()
  if not 检查存储权限() then
    return false
  end
  if Build.VERSION.SDK_INT >= 33 and not 检查通知权限() then
    return false
  end
  return true
end

-- ==================== 跳转函数 ====================
function 请求存储权限()
  if Build.VERSION.SDK_INT >= 23 then
    activity.requestPermissions({Manifest.permission.WRITE_EXTERNAL_STORAGE}, 100)
  end
end

function 跳转悬浮窗设置()
  if Build.VERSION.SDK_INT >= 23 then
    local intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
    Uri.parse("package:" .. activity.getPackageName()))
    activity.startActivityForResult(intent, 101)
  end
end

function 跳转应用信息()
  local intent = Intent()
  intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
  intent.setData(Uri.parse("package:" .. activity.getPackageName()))
  intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  activity.startActivity(intent)
end

-- ==================== 更新UI状态 ====================
function 更新按钮状态()
  -- 存储权限
  if 检查存储权限() then
    storageStatus.setText("✅ 已授权")
    storageStatus.setTextColor(0xFF4CAF50)
    storageBtn.setVisibility(View.GONE)
    storageIcon.setColorFilter(0xFF4CAF50)
   else
    storageStatus.setText("❌ 未授权")
    storageStatus.setTextColor(0xFFF44336)
    storageBtn.setVisibility(View.VISIBLE)
    storageIcon.setColorFilter(0xFFF44336)
  end

  -- 通知权限
  if Build.VERSION.SDK_INT >= 33 then
    if 检查通知权限() then
      notificationStatus.setText("✅ 已授权")
      notificationStatus.setTextColor(0xFF4CAF50)
      notificationBtn.setVisibility(View.GONE)
      notificationIcon.setColorFilter(0xFF4CAF50)
     else
      notificationStatus.setText("❌ 未授权")
      notificationStatus.setTextColor(0xFFF44336)
      notificationBtn.setVisibility(View.VISIBLE)
      notificationIcon.setColorFilter(0xFFF44336)
    end
   else
    notificationStatus.setText("✅ 已授权")
    notificationStatus.setTextColor(0xFF4CAF50)
    notificationBtn.setVisibility(View.GONE)
    notificationIcon.setColorFilter(0xFF4CAF50)
  end

  -- 悬浮窗权限
  if 检查悬浮窗权限() then
    floatStatus.setText("✅ 已授权")
    floatStatus.setTextColor(0xFF4CAF50)
    floatBtn.setVisibility(View.GONE)
    floatIcon.setColorFilter(0xFF4CAF50)
   else
    floatStatus.setText("⚪ 未授权")
    floatStatus.setTextColor(0xFF999999)
    floatBtn.setVisibility(View.VISIBLE)
    floatIcon.setColorFilter(0xFF999999)
  end

  -- 电池优化（纯自动检测）
  if 检查电池优化() then
    batteryStatus.setText("✅ 已授权")
    batteryStatus.setTextColor(0xFF4CAF50)
    batteryBtn.setVisibility(View.GONE)
    batteryIcon.setColorFilter(0xFF4CAF50)
   else
    batteryStatus.setText("⚪ 未授权")
    batteryStatus.setTextColor(0xFF999999)
    batteryBtn.setVisibility(View.VISIBLE)
    batteryIcon.setColorFilter(0xFF999999)
  end

  -- 进入按钮
  if 必需权限已全部授权() then
    enterBtn.setEnabled(true)
    enterBtn.setAlpha(1.0)
    enterBtn.setText("🎵 进入 SU音乐")
    enterBtn.setBackgroundDrawable(进入按钮样式(true))
   else
    enterBtn.setEnabled(false)
    enterBtn.setAlpha(0.6)
    enterBtn.setText("⚠️ 请先授权必需权限")
    enterBtn.setBackgroundDrawable(进入按钮样式(false))
  end
end

-- ==================== 按钮样式 ====================
function 进入按钮样式(启用)
  local bg = GradientDrawable()
  bg.setShape(GradientDrawable.RECTANGLE)
  bg.setCornerRadius(25)
  if 启用 then
    bg.setColor(0xFF6C63FF)
   else
    bg.setColor(0xFFBDBDBD)
  end
  return bg
end

function 权限按钮样式(颜色)
  local bg = GradientDrawable()
  bg.setShape(GradientDrawable.RECTANGLE)
  bg.setCornerRadius(16)
  bg.setColor(颜色)
  return bg
end

-- ==================== 布局 ====================
local layout = {
  LinearLayout,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  background = "#FFF5F7FA",
  {
    ScrollView,
    layout_width = "fill",
    layout_height = "fill",
    overScrollMode = 2,
    {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      padding = "24dp",
      paddingTop = "40dp",
      {
        -- ========== 头部图标 + 标题 ==========
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        gravity = "center",
        layout_marginBottom = "28dp",
        {
          ImageView,
          layout_width = "80dp",
          layout_height = "80dp",
          src = "icon.png",
        },
        {
          TextView,
          layout_width = "wrap",
          layout_height = "wrap",
          layout_marginTop = "12dp",
          text = "SU音乐",
          textSize = "26sp",
          textColor = "#2C2C2C",
          typeface = Typeface.DEFAULT_BOLD,
        },
        {
          TextView,
          layout_width = "wrap",
          layout_height = "wrap",
          layout_marginTop = "4dp",
          text = "授权以下权限以获得完整体验",
          textSize = "13sp",
          textColor = "#999999",
        },
      },
      -- ========== 存储权限 ==========
      {
        CardView,
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginBottom = "12dp",
        radius = "16dp",
        elevation = "2dp",
        cardBackgroundColor = "#FFFFFF",
        {
          LinearLayout,
          orientation = "horizontal",
          layout_width = "fill",
          layout_height = "wrap",
          padding = "16dp",
          gravity = "center_vertical",
          {
            ImageView,
            id = "storageIcon",
            layout_width = "28dp",
            layout_height = "28dp",
            src = "drawable/ic_folder.png",
            colorFilter = "#999999",
            layout_marginRight = "14dp",
          },
          {
            LinearLayout,
            orientation = "vertical",
            layout_width = "0dp",
            layout_height = "wrap",
            layout_weight = "1",
            {
              TextView,
              text = "存储权限",
              textSize = "15sp",
              textColor = "#2C2C2C",
              typeface = Typeface.DEFAULT_BOLD,
            },
            {
              TextView,
              text = "下载音乐到本地",
              textSize = "12sp",
              textColor = "#999999",
              layout_marginTop = "2dp",
            },
          },
          {
            TextView,
            id = "storageStatus",
            text = "检测中...",
            textSize = "13sp",
            layout_marginRight = "12dp",
          },
          {
            Button,
            id = "storageBtn",
            text = "去授权",
            textSize = "12sp",
            backgroundColor = "#6C63FF",
            textColor = "#FFFFFF",
            paddingLeft = "18dp",
            paddingRight = "18dp",
            paddingTop = "6dp",
            paddingBottom = "6dp",
            minWidth = "0dp",
            minHeight = "0dp",
            visibility = 8,
            backgroundDrawable = 权限按钮样式(0xFF6C63FF),
            onClick = function()
              请求存储权限()
            end,
          },
        },
      },
      -- ========== 通知权限 ==========
      {
        CardView,
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginBottom = "12dp",
        radius = "16dp",
        elevation = "2dp",
        cardBackgroundColor = "#FFFFFF",
        visibility = Build.VERSION.SDK_INT >= 33 and View.VISIBLE or View.GONE,
        {
          LinearLayout,
          orientation = "horizontal",
          layout_width = "fill",
          layout_height = "wrap",
          padding = "16dp",
          gravity = "center_vertical",
          {
            ImageView,
            id = "notificationIcon",
            layout_width = "28dp",
            layout_height = "28dp",
            src = "drawable/ic_notification.png",
            colorFilter = "#999999",
            layout_marginRight = "14dp",
          },
          {
            LinearLayout,
            orientation = "vertical",
            layout_width = "0dp",
            layout_height = "wrap",
            layout_weight = "1",
            {
              TextView,
              text = "通知权限",
              textSize = "15sp",
              textColor = "#2C2C2C",
              typeface = Typeface.DEFAULT_BOLD,
            },
            {
              TextView,
              text = "通知栏显示和控制音乐",
              textSize = "12sp",
              textColor = "#999999",
              layout_marginTop = "2dp",
            },
          },
          {
            TextView,
            id = "notificationStatus",
            text = "检测中...",
            textSize = "13sp",
            layout_marginRight = "12dp",
          },
          {
            Button,
            id = "notificationBtn",
            text = "去开启",
            textSize = "12sp",
            backgroundColor = "#6C63FF",
            textColor = "#FFFFFF",
            paddingLeft = "18dp",
            paddingRight = "18dp",
            paddingTop = "6dp",
            paddingBottom = "6dp",
            minWidth = "0dp",
            minHeight = "0dp",
            visibility = 8,
            backgroundDrawable = 权限按钮样式(0xFF6C63FF),
            onClick = function()
              AlertDialog.Builder(activity)
              .setTitle("🔔 通知权限")
              .setMessage("请在应用信息中，点击「通知」选项，然后开启「允许通知」开关。")
              .setPositiveButton("去开启", { onClick = function()
                  跳转应用信息()
                end })
              .setNegativeButton("取消", nil)
              .show()
            end,
          },
        },
      },
      -- ========== 悬浮窗权限 ==========
      {
        CardView,
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginBottom = "12dp",
        radius = "16dp",
        elevation = "2dp",
        cardBackgroundColor = "#FFFFFF",
        {
          LinearLayout,
          orientation = "horizontal",
          layout_width = "fill",
          layout_height = "wrap",
          padding = "16dp",
          gravity = "center_vertical",
          {
            ImageView,
            id = "floatIcon",
            layout_width = "28dp",
            layout_height = "28dp",
            src = "drawable/ic_float.png",
            colorFilter = "#999999",
            layout_marginRight = "14dp",
          },
          {
            LinearLayout,
            orientation = "vertical",
            layout_width = "0dp",
            layout_height = "wrap",
            layout_weight = "1",
            {
              LinearLayout,
              orientation = "horizontal",
              layout_width = "wrap",
              layout_height = "wrap",
              {
                TextView,
                text = "悬浮窗权限",
                textSize = "15sp",
                textColor = "#2C2C2C",
                typeface = Typeface.DEFAULT_BOLD,
              },
              {
                TextView,
                text = "  选填",
                textSize = "11sp",
                textColor = "#FF9800",
                layout_marginLeft = "8dp",
              },
            },
            {
              TextView,
              text = "显示桌面歌词",
              textSize = "12sp",
              textColor = "#999999",
              layout_marginTop = "2dp",
            },
          },
          {
            TextView,
            id = "floatStatus",
            text = "检测中...",
            textSize = "13sp",
            layout_marginRight = "12dp",
          },
          {
            Button,
            id = "floatBtn",
            text = "去授权",
            textSize = "12sp",
            backgroundColor = "#9E9E9E",
            textColor = "#FFFFFF",
            paddingLeft = "18dp",
            paddingRight = "18dp",
            paddingTop = "6dp",
            paddingBottom = "6dp",
            minWidth = "0dp",
            minHeight = "0dp",
            visibility = 8,
            backgroundDrawable = 权限按钮样式(0xFF9E9E9E),
            onClick = function()
              跳转悬浮窗设置()
            end,
          },
        },
      },
      -- ========== 电池优化 ==========
      {
        CardView,
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginBottom = "20dp",
        radius = "16dp",
        elevation = "2dp",
        cardBackgroundColor = "#FFFFFF",
        {
          LinearLayout,
          orientation = "horizontal",
          layout_width = "fill",
          layout_height = "wrap",
          padding = "16dp",
          gravity = "center_vertical",
          {
            ImageView,
            id = "batteryIcon",
            layout_width = "28dp",
            layout_height = "28dp",
            src = "drawable/ic_battery.png",
            colorFilter = "#999999",
            layout_marginRight = "14dp",
          },
          {
            LinearLayout,
            orientation = "vertical",
            layout_width = "0dp",
            layout_height = "wrap",
            layout_weight = "1",
            {
              LinearLayout,
              orientation = "horizontal",
              layout_width = "wrap",
              layout_height = "wrap",
              {
                TextView,
                text = "电池优化",
                textSize = "15sp",
                textColor = "#2C2C2C",
                typeface = Typeface.DEFAULT_BOLD,
              },
              {
                TextView,
                text = "  选填",
                textSize = "11sp",
                textColor = "#FF9800",
                layout_marginLeft = "8dp",
              },
            },
            {
              TextView,
              text = "防止后台播放被系统杀死",
              textSize = "12sp",
              textColor = "#999999",
              layout_marginTop = "2dp",
            },
          },
          {
            TextView,
            id = "batteryStatus",
            text = "检测中...",
            textSize = "13sp",
            layout_marginRight = "12dp",
          },
          {
            Button,
            id = "batteryBtn",
            text = "去设置",
            textSize = "12sp",
            backgroundColor = "#9E9E9E",
            textColor = "#FFFFFF",
            paddingLeft = "18dp",
            paddingRight = "18dp",
            paddingTop = "6dp",
            paddingBottom = "6dp",
            minWidth = "0dp",
            minHeight = "0dp",
            visibility = 8,
            backgroundDrawable = 权限按钮样式(0xFF9E9E9E),
            onClick = function()
              if Build.VERSION.SDK_INT >= 23 then
                local intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                activity.startActivity(intent)
              end
            end,
          },
        },
      },
      -- ========== 底部提示 ==========
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        gravity = "center",
        layout_marginBottom = "16dp",
        {
          TextView,
          layout_width = "wrap",
          layout_height = "wrap",
          text = "💡 存储和通知为必需权限，其他可跳过",
          textSize = "11sp",
          textColor = "#BBBBBB",
        },
      },
      -- ========== 进入按钮 ==========
      {
        Button,
        id = "enterBtn",
        layout_width = "fill",
        layout_height = "52dp",
        layout_marginBottom = "16dp",
        text = "⚠️ 请先授权必需权限",
        textSize = "16sp",
        textColor = "#FFFFFF",
        enabled = false,
        alpha = 0.6,
        backgroundDrawable = 进入按钮样式(false),
        onClick = function()
          if 必需权限已全部授权() then
            activity.newActivity("main3")
            activity.finish()
           else
            Toast.makeText(activity, "请先授权必需权限", Toast.LENGTH_SHORT).show()
          end
        end,
      },
    },
  },
}

activity.setContentView(loadlayout(layout))

-- ==================== 定时刷新权限状态 ====================
local refreshTimer = Ticker()
refreshTimer.Period = 500
refreshTimer.onTick = function()
  更新按钮状态()
end
refreshTimer.start()

-- ==================== 初始化 ====================
更新按钮状态()

-- ==================== 权限请求回调 ====================
function onRequestPermissionsResult(requestCode, permissions, grantResults)
  if requestCode == 100 then
    if grantResults[0] == PackageManager.PERMISSION_GRANTED then
      Toast.makeText(activity, "存储权限已授权", Toast.LENGTH_SHORT).show()
     else
      Toast.makeText(activity, "存储权限被拒绝，无法下载音乐", Toast.LENGTH_SHORT).show()
    end
    更新按钮状态()
  end
end

function onActivityResult(requestCode, resultCode, data)
  if requestCode == 101 then
    task(300, function()
      更新按钮状态()
      if 检查悬浮窗权限() then
        Toast.makeText(activity, "悬浮窗权限已开启", Toast.LENGTH_SHORT).show()
      end
    end)
  end
end

function onResume()
  更新按钮状态()
end

function onKeyDown(code, event)
  if code == 4 then
    if refreshTimer then refreshTimer.stop() end
    activity.finish()
    return true
  end
  return false
end

function onDestroy()
  if refreshTimer then refreshTimer.stop() end
end