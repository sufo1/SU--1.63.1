-- main3.lua (主逻辑页)
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.webkit.*"
import "android.content.*"
import "android.net.*"
import "android.net.ConnectivityManager"
import "java.net.NetworkInterface"
import "android.animation.*"
import "android.graphics.*"
import "android.graphics.drawable.*"
import "android.view.animation.*"
import "android.widget.FrameLayout"
import "android.view.Gravity"
import "android.provider.Settings"
import "android.graphics.drawable.GradientDrawable"
import "android.webkit.DownloadListener"
import "android.widget.CheckBox"

-- ==================== 版本配置 ====================
本地版本 = "1.63.1"

-- ==================== 全屏+状态栏统一配置 ====================
pcall(function() activity.ActionBar.hide() end)
activity.setTheme(android.R.style.Theme_DeviceDefault_Light)
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
activity.getWindow().setStatusBarColor(0xFFFFFFFF)
activity.getWindow().setNavigationBarColor(0xFFF5F5F5)
activity.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR)

function 全屏()
  local window = activity.getWindow()
  window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)
  window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
  xpcall(function()
    local lp = window.getAttributes()
    lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
    window.setAttributes(lp)
  end, function(e) end)
end
全屏()

-- ==================== SharedPreferences ====================
function getSharedData(key, defaultValue)
  local sp = activity.getSharedPreferences("SUMusic", Context.MODE_PRIVATE)
  return sp.getString(key, defaultValue)
end

function setSharedData(key, value)
  local sp = activity.getSharedPreferences("SUMusic", Context.MODE_PRIVATE)
  local editor = sp.edit()
  editor.putString(key, value)
  editor.commit()
end

-- ==================== 本地路径 ====================
LOCAL_HTML_PATH = activity.getLuaDir() .. "/index.html"

-- ==================== 网络检测 ====================
function isNetworkAvailable()
  local cm = activity.getSystemService(Context.CONNECTIVITY_SERVICE)
  local activeNetwork = cm.getActiveNetworkInfo()
  return activeNetwork ~= nil and activeNetwork.isConnected()
end

-- ==================== 快速请求 ====================
function 快速请求(url, callback, retryCount, timeout)
  retryCount = retryCount or 2
  timeout = timeout or 3000
  local attempt = 0
  local completed = false

  local function doRequest()
    attempt = attempt + 1
    local timer = Ticker()
    timer.Period = timeout
    timer.onTick = function()
      if not completed then
        timer.stop()
        if attempt < retryCount then
          doRequest()
         else
          completed = true
          if callback then callback(nil, "超时") end
        end
      end
    end
    timer.start()

    Http.get(url, nil, "utf-8", nil, function(code, content)
      if not completed then
        completed = true
        timer.stop()
        if callback then callback(code, content) end
      end
    end)
  end
  doRequest()
end

-- ==================== DNS 优化 ====================
import "java.net.InetAddress"
function 优化DNS()
  xpcall(function()
    local props = luajava.bindClass("java.lang.System")
    if props then
      props.setProperty("sun.net.spi.nameservice.nameservers", "223.5.5.5,223.6.6.6,119.29.29.29,114.114.114.114")
      props.setProperty("sun.net.spi.nameservice.provider.1", "dns,sun")
    end
  end, function(e) end)

  local domains = {
    "223.5.5.5", "223.6.6.6", "119.29.29.29", "114.114.114.114",
    "xn--69w.top", "api.kuwo.cn", "wapi.kuwo.cn", "search.kuwo.cn"
  }
  for _, domain in ipairs(domains) do
    xpcall(function()
      InetAddress.getAllByName(domain)
    end, function(e) end)
  end
end

-- ==================== 版本更新检测 ====================
function checkUpdate(callback)
  local url = "http://xn--69w.top/%E5%85%AC%E5%91%8A/SU%E9%9F%B3%E4%B9%90.txt"
  local completed = false

  快速请求(url, function(code, content)
    if completed then return end
    completed = true

    if code == 200 and content then
      local 远程版本 = content:match("版本【(.-)】")
      local 强制更新列表 = content:match("强制更新x【(.-)】")
      local 更新内容 = content:match("更新内容【(.-)】")
      local 群号 = content:match("按钮代码【(.-)】") or "1079722856"
      local 更新链接 = content:match("链接【(.-)】")

      if 远程版本 then
        远程版本 = 远程版本:gsub("^%s*(.-)%s*$", "%1")
      end

      local 是否强制更新 = false
      if 强制更新列表 and 强制更新列表 ~= "" then
        local versions = {}
        for v in 强制更新列表:gmatch("[^,]+") do
          table.insert(versions, v:gsub("^%s*(.-)%s*$", "%1"))
        end
        for _, v in ipairs(versions) do
          if v == 本地版本 then
            是否强制更新 = true
            break
          end
        end
      end

      if 远程版本 and 远程版本 ~= 本地版本 then
        local jumpUrl = "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=" .. 群号 .. "&card_type=group&source=qrcode"
        if 更新链接 and 更新链接 ~= "" then
          jumpUrl = 更新链接
        end
        local 提示消息 = 更新内容 or "发现新版本：" .. 远程版本

        if 是否强制更新 then
          AlertDialog.Builder(activity)
          .setTitle("强制更新")
          .setMessage(提示消息)
          .setCancelable(false)
          .setPositiveButton("立即更新", { onClick = function()
              if 更新链接 and 更新链接 ~= "" then
                local viewIntent = Intent("android.intent.action.VIEW", Uri.parse(更新链接))
                activity.startActivity(viewIntent)
               else
                local viewIntent = Intent("android.intent.action.VIEW", Uri.parse(jumpUrl))
                activity.startActivity(viewIntent)
              end
              activity.finish()
            end })
          .show()
          if callback then callback(true) end
         else
          AlertDialog.Builder(activity)
          .setTitle("发现新版本")
          .setMessage(提示消息)
          .setPositiveButton("立即更新", { onClick = function()
              if 更新链接 and 更新链接 ~= "" then
                local viewIntent = Intent("android.intent.action.VIEW", Uri.parse(更新链接))
                activity.startActivity(viewIntent)
               else
                local viewIntent = Intent("android.intent.action.VIEW", Uri.parse(jumpUrl))
                activity.startActivity(viewIntent)
              end
            end })
          .setNegativeButton("稍后再说", nil)
          .show()
          if callback then callback(false) end
        end
       else
        if callback then callback(false) end
      end
     else
      if callback then callback(false) end
    end
  end)

  task(3000, function()
    if not completed then
      completed = true
      if callback then callback(false) end
    end
  end)
end

-- ==================== 悬浮窗变量 ====================
local wm, layout, tvLyric, params
local lastX, lastY, isDragging = 0, 0, false
local initX, initY = 0, 0
local isBgVisible = true
local autoPlayEnabled = false
local clickCount = 0
local clickTimer = nil

local colorList = {
  0xFFFFFFFF, 0xFF4FC3F7, 0xFFFFB74D, 0xFFFFD54F,
  0xFF81C784, 0xFFCE93D8, 0xFFEF5350, 0xFF80DEEA, 0xFFFF8A65
}
local currentColorIndex = 1

local function getMaxLyricWidth()
  return math.floor(activity.getWidth() * 0.7)
end

function 检查悬浮窗权限()
  if Build.VERSION.SDK_INT >= 23 then
    return Settings.canDrawOverlays(activity)
  end
  return true
end

function 更新悬浮窗背景()
  if tvLyric then
    local bg = GradientDrawable()
    bg.setCornerRadius(30)
    if isBgVisible then
      bg.setColor(0xCC675D5D)
     else
      bg.setColor(0x00000000)
    end
    tvLyric.setBackgroundDrawable(bg)
  end
end

function 切换背景()
  isBgVisible = not isBgVisible
  更新悬浮窗背景()
  Toast.makeText(activity, isBgVisible and "歌词背景已显示" or "歌词背景已隐藏", Toast.LENGTH_SHORT).show()
end

function 切换颜色()
  currentColorIndex = currentColorIndex + 1
  if currentColorIndex > #colorList then currentColorIndex = 1 end
  if tvLyric then tvLyric.setTextColor(colorList[currentColorIndex]) end
  local colorNames = {"白色", "亮蓝", "橙色", "黄色", "绿色", "紫色", "红色", "青色", "珊瑚"}
  Toast.makeText(activity, "颜色: " .. colorNames[currentColorIndex], Toast.LENGTH_SHORT).show()
end

function createFloatWindow()
  if layout ~= nil then return true end
  if not 检查悬浮窗权限() then return false end

  wm = activity.getSystemService("window")
  params = WindowManager.LayoutParams()

  if Build.VERSION.SDK_INT >= 26 then
    params.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
   else
    params.type = WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
  end

  params.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE + WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
  params.format = PixelFormat.TRANSLUCENT
  params.gravity = Gravity.TOP + Gravity.CENTER_HORIZONTAL
  params.y = 25
  params.width = getMaxLyricWidth()
  params.height = WindowManager.LayoutParams.WRAP_CONTENT

  initX = params.x
  initY = params.y

  layout = FrameLayout(activity)
  layout.setBackgroundColor(0x00000000)

  tvLyric = TextView(activity)
  tvLyric.setTextSize(14)
  tvLyric.setTextColor(colorList[currentColorIndex])
  tvLyric.setGravity(Gravity.CENTER)
  tvLyric.setTypeface(Typeface.DEFAULT_BOLD)
  tvLyric.setPadding(30, 12, 30, 12)
  tvLyric.setText("SU音乐-点击还原,长按切换,双击变色")
  tvLyric.setMaxLines(10)
  tvLyric.setEllipsize(nil)

  local bg = GradientDrawable()
  bg.setCornerRadius(30)
  bg.setColor(0xCC675D5D)
  tvLyric.setBackgroundDrawable(bg)

  local longPressTimer = nil
  local isLongPressTriggered = false

  tvLyric.setOnTouchListener({
    onTouch = function(v, event)
      local action = event.getAction()
      if action == MotionEvent.ACTION_DOWN then
        lastX = event.getRawX()
        lastY = event.getRawY()
        isDragging = false
        isLongPressTriggered = false

        longPressTimer = Ticker()
        longPressTimer.Period = 500
        longPressTimer.onTick = function()
          longPressTimer.stop()
          if not isDragging and not isLongPressTriggered then
            isLongPressTriggered = true
            切换背景()
          end
        end
        longPressTimer.start()
        return true

       elseif action == MotionEvent.ACTION_MOVE then
        local deltaX = event.getRawX() - lastX
        local deltaY = event.getRawY() - lastY
        if math.abs(deltaX) > 10 or math.abs(deltaY) > 10 then
          isDragging = true
          if longPressTimer then longPressTimer.stop() end
          if layout ~= nil and params ~= nil then
            params.x = params.x + deltaX
            params.y = params.y + deltaY
            wm.updateViewLayout(layout, params)
          end
          lastX = event.getRawX()
          lastY = event.getRawY()
        end
        return true

       elseif action == MotionEvent.ACTION_UP then
        if longPressTimer then longPressTimer.stop() end

        if not isDragging and not isLongPressTriggered then
          clickCount = clickCount + 1
          if clickTimer then clickTimer.stop(); clickTimer = nil end

          if clickCount == 2 then
            clickCount = 0
            切换颜色()
            if layout ~= nil and params ~= nil then
              params.x = initX; params.y = initY
              wm.updateViewLayout(layout, params)
            end
           else
            if layout ~= nil and params ~= nil then
              params.x = initX; params.y = initY
              wm.updateViewLayout(layout, params)
            end
            clickTimer = Ticker()
            clickTimer.Period = 600
            clickTimer.onTick = function()
              clickTimer.stop(); clickTimer = nil; clickCount = 0
            end
            clickTimer.start()
          end
        end
        return true
      end
      return false
    end
  })

  layout.addView(tvLyric)
  wm.addView(layout, params)
  return true
end

function setLyric(text)
  if tvLyric then tvLyric.setText(text or "") end
end

function hideFloatWindow()
  if layout then
    wm.removeView(layout)
    layout = nil; tvLyric = nil; params = nil
  end
end

function showFloatWindow()
  if layout == nil then createFloatWindow() end
end

-- ==================== URL 解码 ====================
function urlDecode(str)
  if not str then return "" end
  str = str:gsub("+", " ")
  str = str:gsub("%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end)
  return str
end

-- ==================== 下载队列管理 ====================
local musicDownloadQueue = {}
local isMusicDialogShowing = false
local currentMusicDialog = nil
local musicNoPrompt = false
local isBatchMode = false
local batchDownloadCount = 0
local batchCompletedCount = 0
local batchFilePaths = {}

-- ==================== 显示音乐批量下载弹窗 ====================
function showMusicBatchDialog()
  if #musicDownloadQueue == 0 then
    isMusicDialogShowing = false
    return
  end

  if currentMusicDialog then
    pcall(function() currentMusicDialog.dismiss() end)
    currentMusicDialog = nil
  end

  local isSingle = (#musicDownloadQueue == 1)

  local layout = LinearLayout(activity)
  layout.setOrientation(LinearLayout.VERTICAL)
  layout.setPadding(40, 20, 40, 20)

  local titleView = TextView(activity)
  if isSingle then
    titleView.setText("下载确认")
   else
    titleView.setText("批量下载音乐（共 " .. #musicDownloadQueue .. " 首）")
  end
  titleView.setTextSize(18)
  titleView.setTextColor(0xFF222222)
  titleView.setGravity(Gravity.CENTER)
  titleView.setTypeface(Typeface.DEFAULT_BOLD)
  titleView.setPadding(0, 0, 0, 15)
  layout.addView(titleView)

  if isSingle then
    local fileView = TextView(activity)
    fileView.setText("文件名: " .. musicDownloadQueue[1].filename)
    fileView.setTextSize(14)
    fileView.setTextColor(0xFF666666)
    fileView.setPadding(0, 0, 0, 10)
    layout.addView(fileView)

    local pathView = TextView(activity)
    pathView.setText("保存路径: Music/SU音乐")
    pathView.setTextSize(12)
    pathView.setTextColor(0xFF999999)
    pathView.setPadding(0, 0, 0, 15)
    layout.addView(pathView)
   else
    local scrollView = ScrollView(activity)
    scrollView.setLayoutParams(LinearLayout.LayoutParams(-1, 300))

    local listLayout = LinearLayout(activity)
    listLayout.setOrientation(LinearLayout.VERTICAL)

    for i, item in ipairs(musicDownloadQueue) do
      local fileView = TextView(activity)
      fileView.setText(i .. ". " .. item.filename)
      fileView.setTextSize(13)
      fileView.setTextColor(0xFF333333)
      fileView.setPadding(0, 4, 0, 4)
      listLayout.addView(fileView)
    end

    scrollView.addView(listLayout)
    layout.addView(scrollView)
  end

  local cbNoPrompt = CheckBox(activity)
  cbNoPrompt.setText("此次不再提示（重启软件重置）")
  cbNoPrompt.setTextSize(13)
  cbNoPrompt.setPadding(0, 15, 0, 0)
  layout.addView(cbNoPrompt)

  local dialog = AlertDialog.Builder(activity)
  dialog.setView(layout)

  if isSingle then
    dialog.setPositiveButton("下载", { onClick = function()
        if cbNoPrompt.isChecked() then
          musicNoPrompt = true
        end
        local item = musicDownloadQueue[1]
        musicDownloadQueue = {}
        isMusicDialogShowing = false
        currentMusicDialog = nil
        startSystemDownload(item.url, item.filename, false)
      end })
   else
    dialog.setPositiveButton("全部下载", { onClick = function()
        if cbNoPrompt.isChecked() then
          musicNoPrompt = true
        end
        isBatchMode = true
        batchDownloadCount = #musicDownloadQueue
        batchCompletedCount = 0
        batchFilePaths = {}

        Toast.makeText(activity, "开始批量下载 " .. batchDownloadCount .. " 首音乐", Toast.LENGTH_SHORT).show()

        for i, item in ipairs(musicDownloadQueue) do
          task((i - 1) * 500, function()
            startSystemDownload(item.url, item.filename, false)
          end)
        end

        musicDownloadQueue = {}
        isMusicDialogShowing = false
        currentMusicDialog = nil
      end })
  end

  dialog.setNegativeButton("取消", { onClick = function()
      musicDownloadQueue = {}
      isMusicDialogShowing = false
      currentMusicDialog = nil
    end })

  currentMusicDialog = dialog.show()
  isMusicDialogShowing = true
end

-- ==================== 添加到音乐下载队列 ====================
function addMusicToQueue(url, filename)
  if musicNoPrompt then
    startSystemDownload(url, filename, false)
    return
  end

  table.insert(musicDownloadQueue, {
    url = url,
    filename = filename
  })

  showMusicBatchDialog()
end

-- ==================== 单个下载完成弹窗 ====================
function showSingleDownloadCompleteDialog(filename, filePath)
  AlertDialog.Builder(activity)
  .setTitle("下载完成")
  .setMessage("文件已下载完成：\n\n" .. filename .. "\n\n保存路径：" .. filePath)
  .setPositiveButton("打开文件夹", { onClick = function()
      local intent = Intent(Intent.ACTION_VIEW)
      if Build.VERSION.SDK_INT >= 30 then
        if filePath:find("Movies") then
          local uri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3AMovies%2FSU%E9%9F%B3%E4%B9%90")
          intent.setData(uri)
         else
          local uri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3AMusic%2FSU%E9%9F%B3%E4%B9%90")
          intent.setData(uri)
        end
       else
        local folderPath = filePath:match("(.+)/[^/]+$") or "/storage/emulated/0/Movies/SU音乐/"
        intent.setDataAndType(Uri.parse("file://" .. folderPath), "*/*")
      end
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      intent.addCategory(Intent.CATEGORY_DEFAULT)
      activity.startActivity(intent)
    end })
  .setNegativeButton("确定", nil)
  .show()
end

-- ==================== 批量下载完成弹窗 ====================
function showBatchDownloadCompleteDialog()
  local count = batchCompletedCount
  local msg = "批量下载完成！\n\n共下载 " .. count .. " 首音乐：\n"
  for i, path in ipairs(batchFilePaths) do
    local name = path:match("([^/]+)$") or path
    msg = msg .. "\n" .. i .. ". " .. name
  end
  msg = msg .. "\n\n保存路径：/storage/emulated/0/Music/SU音乐/"

  AlertDialog.Builder(activity)
  .setTitle("批量下载完成")
  .setMessage(msg)
  .setPositiveButton("打开文件夹", { onClick = function()
      local intent = Intent(Intent.ACTION_VIEW)
      if Build.VERSION.SDK_INT >= 30 then
        local uri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3AMusic%2FSU%E9%9F%B3%E4%B9%90")
        intent.setData(uri)
       else
        intent.setDataAndType(Uri.parse("file:///storage/emulated/0/Music/SU音乐/"), "*/*")
      end
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      intent.addCategory(Intent.CATEGORY_DEFAULT)
      activity.startActivity(intent)
    end })
  .setNegativeButton("确定", nil)
  .show()
end

-- ==================== 系统下载管理器 ====================
function startSystemDownload(url, filename, isVideo)
  local fullPath
  if isVideo then
    fullPath = "/storage/emulated/0/Movies/SU音乐/" .. filename
   else
    fullPath = "/storage/emulated/0/Music/SU音乐/" .. filename
  end

  local dirPath = fullPath:match("(.+)/[^/]+$") or ""
  local dir = luajava.newInstance("java.io.File", dirPath)
  if not dir.exists() then dir.mkdirs() end

  local file = luajava.newInstance("java.io.File", fullPath)
  if file.exists() then
    AlertDialog.Builder(activity)
    .setTitle("文件已存在")
    .setMessage("文件已存在：\n\n" .. filename .. "\n\n是否重新下载覆盖？")
    .setPositiveButton("覆盖", { onClick = function()
        file.delete()
        doSystemDownload(url, fullPath, filename)
      end })
    .setNegativeButton("取消", nil)
    .show()
    return
  end

  doSystemDownload(url, fullPath, filename)
end

-- ========== 执行系统下载 ==========
function doSystemDownload(url, fullPath, filename)
  local downloadManager = activity.getSystemService(Context.DOWNLOAD_SERVICE)
  local uri = Uri.parse(url)
  local request = DownloadManager.Request(uri)
  request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_MOBILE | DownloadManager.Request.NETWORK_WIFI)

  local file = luajava.newInstance("java.io.File", fullPath)
  request.setDestinationUri(Uri.fromFile(file))

  request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
  request.setTitle("SU音乐下载")
  request.setDescription(filename)

  local downloadId = downloadManager.enqueue(request)

  if downloadId >= 0 then
    Toast.makeText(activity, "开始下载: " .. filename, Toast.LENGTH_SHORT).show()
    monitorDownload(downloadId, filename)
   else
    Toast.makeText(activity, "下载启动失败", Toast.LENGTH_SHORT).show()
  end
end

-- ========== 监控下载完成 ==========
function monitorDownload(downloadId, filename)
  local checkTimer = Ticker()
  checkTimer.Period = 2000

  checkTimer.onTick = function()
    local downloadManager = activity.getSystemService(Context.DOWNLOAD_SERVICE)
    local query = DownloadManager.Query()
    query.setFilterById(long{downloadId})

    local cursor = downloadManager.query(query)
    if cursor and cursor.moveToFirst() then
      local status = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS))

      if status == DownloadManager.STATUS_SUCCESSFUL then
        checkTimer.stop()
        cursor.close()

        local filePath = ""
        if filename:match("%.mp4$") or filename:match("%.mkv$") then
          filePath = "/storage/emulated/0/Movies/SU音乐/" .. filename
         else
          filePath = "/storage/emulated/0/Music/SU音乐/" .. filename
        end

        if isBatchMode then
          batchCompletedCount = batchCompletedCount + 1
          table.insert(batchFilePaths, filePath)

          if batchCompletedCount >= batchDownloadCount then
            isBatchMode = false
            showBatchDownloadCompleteDialog()
          end
         else
          showSingleDownloadCompleteDialog(filename, filePath)
        end
        return
       elseif status == DownloadManager.STATUS_FAILED then
        checkTimer.stop()
        cursor.close()
        Toast.makeText(activity, "下载失败: " .. filename, Toast.LENGTH_SHORT).show()
        return
      end
    end
    if cursor then cursor.close() end
  end
  checkTimer.start()
end

-- ==================== 获取文件名 ====================
function getFilename(url, disposition)
  local filename = nil
  if disposition then
    filename = disposition:match('filename="(.+)"') or disposition:match("filename=(.+)")
    if filename then filename = filename:gsub('["\']', '') end
  end
  if not filename or filename == "" then
    filename = url:match("[^/]+$")
  end
  if filename then filename = filename:match("([^?]+)") end
  return filename
end

-- ==================== 判断是否为视频文件 ====================
function isVideoFile(url)
  if not url then return false end
  local videoExtensions = {".mp4", ".mkv", ".avi", ".flv", ".mov", ".wmv", ".webm", ".3gp"}
  for _, ext in ipairs(videoExtensions) do
    if url:find(ext, 1, true) then return true end
  end
  if url:find("video", 1, true) then return true end
  return false
end

-- ==================== 处理MP4下载请求 ====================
function handleMP4DownloadRequest(url)
  if not url then return false end

  print("=== handleMP4DownloadRequest ===")
  print("原始URL: " .. url)

  if url:find("su%.su%.su") and (url:find("mp4=mp4") or url:find("mp4=")) then
    local encodedUrl = url:match("url=([^&]+)")
    local songTitleEncoded = url:match("%%E6%%AD%%8C%%E6%%9B%%B2%%E5%%90%%8D=([^&]+)")
    local artistEncoded = url:match("%%E6%%AD%%8C%%E6%%89%%8B=([^&]+)")

    print("songTitleEncoded: " .. (songTitleEncoded or "nil"))
    print("artistEncoded: " .. (artistEncoded or "nil"))

    if encodedUrl then
      local downloadUrl = urlDecode(encodedUrl)
      print("解码后URL: " .. downloadUrl)

      local title = "未知视频"
      if songTitleEncoded then
        title = urlDecode(songTitleEncoded)
        print("解码后歌曲名: [" .. title .. "]")
      end

      local singer = ""
      if artistEncoded then
        singer = urlDecode(artistEncoded)
        print("解码后歌手: [" .. singer .. "]")
      end

      local fileName = ""
      if singer ~= "" and singer ~= "null" and singer ~= "undefined" then
        fileName = title .. " - " .. singer .. ".mp4"
       else
        fileName = title .. ".mp4"
      end
      fileName = fileName:gsub("[\\/:*?\"<>|]", "_")
      fileName = fileName:gsub("_+", "_")

      if fileName == "" or fileName == ".mp4" then
        fileName = "video_" .. os.time() .. ".mp4"
      end

      print("最终文件名: " .. fileName)
      print("===============================")

      startSystemDownload(downloadUrl, fileName, true)
      return true
    end
  end
  return false
end

-- ==================== 处理通用下载链接 ====================
function handleGenericDownload(url)
  if not url then return false end

  if url:find("su%.su%.su") and (url:find("mp4=") or url:find(".mp4")) then
    local encodedUrl = url:match("url=([^&]+)")
    local songTitleEncoded = url:match("%%E6%%AD%%8C%%E6%%9B%%B2%%E5%%90%%8D=([^&]+)")
    local artistEncoded = url:match("%%E6%%AD%%8C%%E6%%89%%8B=([^&]+)")

    if encodedUrl then
      local downloadUrl = urlDecode(encodedUrl)
      local title = "未知视频"
      local singer = ""
      if songTitleEncoded then title = urlDecode(songTitleEncoded) end
      if artistEncoded then singer = urlDecode(artistEncoded) end

      local fileName = (singer ~= "" and singer ~= "null") and (title .. " - " .. singer .. ".mp4") or (title .. ".mp4")
      fileName = fileName:gsub("[\\/:*?\"<>|]", "_")
      fileName = fileName:gsub("_+", "_")

      startSystemDownload(downloadUrl, fileName, true)
      return true
    end
    return false
  end

  if url:find("%.mp4$") or url:find("%.mkv$") or url:find("%.avi$") or url:find("%.flv$") or url:find("%.mov$") or url:find("%.webm$") then
    local fileName = getFilename(url, nil) or "video_" .. os.time() .. ".mp4"
    startSystemDownload(url, fileName, true)
    return true
  end

  if url:find("%.mp3$") or url:find("%.m4a$") or url:find("%.flac$") or url:find("%.wav$") or url:find("%.aac$") then
    local fileName = getFilename(url, nil) or "audio_" .. os.time() .. ".mp3"
    addMusicToQueue(url, fileName)
    return true
  end

  if url:find("video", 1, true) then
    local fileName = getFilename(url, nil) or "video_" .. os.time() .. ".mp4"
    startSystemDownload(url, fileName, true)
    return true
  end

  return false
end

-- ==================== 封面图片管理 ====================
local 封面保存路径 = activity.getLuaDir() .. "/current_cover.jpg"
local 应用图标Bitmap = nil

function 获取应用图标()
  if 应用图标Bitmap == nil then
    local iconId = activity.getResources().getIdentifier("icon", "drawable", activity.getPackageName())
    if iconId ~= 0 then
      应用图标Bitmap = BitmapFactory.decodeResource(activity.getResources(), iconId)
    end
  end
  return 应用图标Bitmap
end

function 删除旧封面()
  local file = luajava.newInstance("java.io.File", 封面保存路径)
  if file.exists() then file.delete() end
end

function 下载封面图片(coverUrl)
  if not coverUrl or coverUrl == "" then return end
  local oldFile = luajava.newInstance("java.io.File", 封面保存路径)
  if oldFile.exists() then oldFile.delete() end
  Http.download(coverUrl, 封面保存路径, function(code)
    if code == 200 then 显示音乐通知栏() end
  end)
end

function 获取封面Bitmap()
  local file = luajava.newInstance("java.io.File", 封面保存路径)
  if file.exists() then
    return BitmapFactory.decodeFile(封面保存路径)
  end
  return nil
end

-- ==================== 检测播放状态 ====================
function 检测播放状态(callback)
  webView.evaluateJavascript([[
        (function() {
            var audio = document.getElementById('audioElement') || document.querySelector('audio');
            if (audio) {
                return audio.paused ? 'paused' : 'playing';
            }
            return 'unknown';
        })();
    ]], {
    onReceiveValue = function(value)
      if value then
        local state = value:gsub('"', '')
        if state == 'playing' then
          if callback then callback(true) end
         elseif state == 'paused' then
          if callback then callback(false) end
        end
      end
    end
  })
end

-- ==================== 通知栏音乐控制器 ====================
local NOTIFICATION_ID = 10086
local CHANNEL_ID = "SUMusicChannel"
local 渠道已创建 = false
local currentSongInfo = { title = "SU音乐", artist = "等待播放", isPlaying = false }

function 获取小图标()
  local iconId = activity.getResources().getIdentifier("icon", "drawable", activity.getPackageName())
  if iconId == 0 then iconId = android.R.drawable.ic_media_play end
  return iconId
end

function 创建通知渠道()
  if 渠道已创建 then return end
  xpcall(function()
    local nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
    local channel = NotificationChannel(CHANNEL_ID, "SU音乐播放器", NotificationManager.IMPORTANCE_LOW)
    channel.setDescription("音乐播放控制")
    channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC)
    nm.createNotificationChannel(channel)
    渠道已创建 = true
  end, function(e) end)
end

function 显示音乐通知栏()
  xpcall(function()
    创建通知渠道()
    检测播放状态(function(isPlaying)
      currentSongInfo.isPlaying = isPlaying
      local nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
      local builder = Notification.Builder(activity, CHANNEL_ID)
      builder.setSmallIcon(获取小图标())
      builder.setContentTitle(currentSongInfo.title)
      builder.setContentText(currentSongInfo.artist)
      builder.setVisibility(Notification.VISIBILITY_PUBLIC)
      builder.setPriority(Notification.PRIORITY_LOW)
      builder.setOngoing(false)

      local coverBmp = 获取封面Bitmap()
      if coverBmp then
        builder.setLargeIcon(coverBmp)
       else
        local iconBmp = 获取应用图标()
        if iconBmp then builder.setLargeIcon(iconBmp) end
      end

      local prevIntent = Intent("SU_MUSIC_PREV")
      local prevPendingIntent = PendingIntent.getBroadcast(activity, 4, prevIntent, PendingIntent.FLAG_UPDATE_CURRENT)
      builder.addAction(android.R.drawable.ic_media_previous, "上一首", prevPendingIntent)

      local playIcon = currentSongInfo.isPlaying and android.R.drawable.ic_media_pause or android.R.drawable.ic_media_play
      local playIntent = Intent("SU_MUSIC_PLAY_PAUSE")
      local playPendingIntent = PendingIntent.getBroadcast(activity, 3, playIntent, PendingIntent.FLAG_UPDATE_CURRENT)
      builder.addAction(playIcon, "播放/暂停", playPendingIntent)

      local nextIntent = Intent("SU_MUSIC_NEXT")
      local nextPendingIntent = PendingIntent.getBroadcast(activity, 5, nextIntent, PendingIntent.FLAG_UPDATE_CURRENT)
      builder.addAction(android.R.drawable.ic_media_next, "下一首", nextPendingIntent)

      local mediaStyle = Notification.MediaStyle()
      mediaStyle.setShowActionsInCompactView(int{0, 1, 2})
      builder.setStyle(mediaStyle)

      nm.notify(NOTIFICATION_ID, builder.build())
    end)
  end, function(e) end)
end

function 设置缓冲中()
  currentSongInfo.title = "缓冲中..."
  currentSongInfo.artist = ""
  currentSongInfo.isPlaying = false
  删除旧封面()
  显示音乐通知栏()
end

function 更新歌曲信息(title, artist, coverUrl)
  currentSongInfo.title = title
  currentSongInfo.artist = artist
  显示音乐通知栏()
  if coverUrl and coverUrl ~= "" then 下载封面图片(coverUrl) end
end

function 删除通知()
  xpcall(function()
    local nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
    nm.cancel(NOTIFICATION_ID)
  end, function(e) end)
end

-- ==================== 广播接收器 ====================
local broadcastReceiver = BroadcastReceiver({
  onReceive = function(context, intent)
    local action = intent.getAction()
    if action == "SU_MUSIC_PLAY_PAUSE" then
      检测播放状态(function(isPlaying)
        if isPlaying then
          webView.loadUrl("javascript:audio.pause();")
         else
          webView.loadUrl("javascript:audio.play();")
        end
        显示音乐通知栏()
      end)
     elseif action == "SU_MUSIC_PREV" then
      设置缓冲中()
      webView.loadUrl("javascript:playPrev();")
     elseif action == "SU_MUSIC_NEXT" then
      设置缓冲中()
      webView.loadUrl("javascript:playNext();")
    end
  end
})

local filter = IntentFilter()
filter.addAction("SU_MUSIC_PLAY_PAUSE")
filter.addAction("SU_MUSIC_PREV")
filter.addAction("SU_MUSIC_NEXT")
activity.registerReceiver(broadcastReceiver, filter)

-- ==================== 创建保存目录 ====================
local musicDir = "/storage/emulated/0/Music/SU音乐/"
local musicDirObj = luajava.newInstance("java.io.File", musicDir)
if not musicDirObj.exists() then musicDirObj.mkdirs() end

local videoDir = "/storage/emulated/0/Movies/SU音乐/"
local videoDirObj = luajava.newInstance("java.io.File", videoDir)
if not videoDirObj.exists() then videoDirObj.mkdirs() end

-- ==================== 主布局 ====================
local root = FrameLayout(activity)
root.setBackgroundColor(0xFF1a0533)

webView = LuaWebView(activity)
webView.getSettings().setAllowUniversalAccessFromFileURLs(true)
webView.getSettings().setJavaScriptEnabled(true)
webView.setVisibility(View.VISIBLE)
root.addView(webView, FrameLayout.LayoutParams(-1, -1))

activity.setContentView(root)

-- ==================== 下载监听器 ====================
webView.setDownloadListener({
  onDownloadStart = function(url, userAgent, contentDisposition, mimetype, contentLength)
    print("=== 浏览器下载拦截 ===")
    print("URL: " .. url)

    local isVideo = false
    if mimetype and mimetype:find("video", 1, true) then
      isVideo = true
     elseif url:find("%.mp4$") or url:find("%.mkv$") or url:find("%.avi$") or
      url:find("%.flv$") or url:find("%.mov$") or url:find("%.webm$") or
      url:find("%.3gp$") then
      isVideo = true
    end

    local filename = getFilename(url, contentDisposition)
    if not filename or filename == "" then
      local timestamp = os.time()
      filename = isVideo and ("video_" .. timestamp .. ".mp4") or ("file_" .. timestamp .. ".mp3")
    end

    if url:find("su%.su%.su") and (url:find("mp4=mp4") or url:find("mp4=")) then
      local songTitleEncoded = url:match("%%E6%%AD%%8C%%E6%%9B%%B2%%E5%%90%%8D=([^&]+)")
      local artistEncoded = url:match("%%E6%%AD%%8C%%E6%%89%%8B=([^&]+)")
      if songTitleEncoded then
        local title = urlDecode(songTitleEncoded)
        local singer = ""
        if artistEncoded then
          singer = urlDecode(artistEncoded)
        end
        filename = (singer ~= "" and singer ~= "null") and (title .. " - " .. singer .. ".mp4") or (title .. ".mp4")
        filename = filename:gsub("[\\/:*?\"<>|]", "_")
        isVideo = true
      end
    end

    print("文件名: " .. filename)
    print("=====================")

    if isVideo then
      startSystemDownload(url, filename, true)
     else
      addMusicToQueue(url, filename)
    end
  end
})

-- ==================== WebViewClient ====================
function 显示本地网页()
  local file = luajava.newInstance("java.io.File", LOCAL_HTML_PATH)
  if not file.exists() then
    Toast.makeText(activity, "HTML文件不存在: " .. LOCAL_HTML_PATH, Toast.LENGTH_LONG).show()
    return false
  end

  webView.loadUrl("file://" .. LOCAL_HTML_PATH)

  webView.setWebViewClient({
    shouldOverrideUrlLoading = function(view, url)
      print("=== WebView拦截 ===")
      print("URL: " .. (url or "空"))

      if url and url:find("su%.su%.su") then
        if url:find("mp4=mp4") or url:find("mp4=") or url:find("&mp4") then
          print("检测到MP4下载请求")
          if handleMP4DownloadRequest(url) then
            return true
          end
        end

        if url:find("url=") and not url:find("auto_play=") and not url:find("bfwc=") and not url:find("float_lyric=") then
          local encodedUrl = url:match("url=([^&]+)")
          if encodedUrl then
            local downloadUrl = urlDecode(encodedUrl)
            if downloadUrl:find("%.mp4", 1, true) or downloadUrl:find("video", 1, true) then
              local songTitleEncoded = url:match("%%E6%%AD%%8C%%E6%%9B%%B2%%E5%%90%%8D=([^&]+)")
              local artistEncoded = url:match("%%E6%%AD%%8C%%E6%%89%%8B=([^&]+)")
              local fileName = "video_" .. os.time() .. ".mp4"

              if songTitleEncoded then
                local title = urlDecode(songTitleEncoded)
                local singer = ""
                if artistEncoded then
                  singer = urlDecode(artistEncoded)
                end
                fileName = (singer ~= "" and singer ~= "null") and (title .. " - " .. singer .. ".mp4") or (title .. ".mp4")
                fileName = fileName:gsub("[\\/:*?\"<>|]", "_")
              end

              print("通用下载 - 文件名: " .. fileName)
              startSystemDownload(downloadUrl, fileName, true)
              return true
            end
          end
        end

        if url:find("auto_play=") then
          local state = url:match("auto_play=([^&]+)")
          if state == "yes" then
            autoPlayEnabled = true
            setSharedData("auto_play_enabled", "yes")
            webView.loadUrl("javascript:playNext();")
           elseif state == "no" then
            autoPlayEnabled = false
            setSharedData("auto_play_enabled", "no")
          end
          return true
        end

        if url:find("bfwc=") then
          local state = url:match("bfwc=([^&]+)")
          if state == "yes" and autoPlayEnabled then
            webView.loadUrl("javascript:audio.play();")
          end
          return true
        end

        if url:find("float_lyric=") then
          local state = url:match("float_lyric=([^&]+)")
          if state == "on" then
            if 检查悬浮窗权限() then
              createFloatWindow()
              setSharedData("float_lyric_enabled", "on")
            end
           elseif state == "off" then
            hideFloatWindow()
            setSharedData("float_lyric_enabled", "off")
          end
          return true
        end

        if url:find("/lyric") then
          local text = url:match("text=([^&]+)")
          local trans = url:match("trans=([^&]+)")
          if text then
            local lyricText = urlDecode(text)
            local lyricTrans = trans and urlDecode(trans) or ""
            if lyricTrans ~= "" then
              setLyric(lyricText .. "\n" .. lyricTrans)
             else
              setLyric(lyricText)
            end
          end
          return true
        end

        if url:find("bfzt=") then
          local state = url:match("bfzt=([^&]+)")
          if state == "yes" then
            currentSongInfo.isPlaying = true
           elseif state == "no" then
            currentSongInfo.isPlaying = false
          end
          显示音乐通知栏()
          return true
        end

        if url:find("gq=") then
          local gq = url:match("gq=([^&]+)")
          local gs = url:match("gs=([^&]+)")
          local gqurl = url:match("gqurl=([^&]+)")
          if gq then
            local songTitle = urlDecode(gq)
            local songArtist = gs and urlDecode(gs) or ""
            local songCover = gqurl and urlDecode(gqurl) or ""
            更新歌曲信息(songTitle, songArtist, songCover)
          end
          return true
        end

        local playUrl = url:match("url=([^&]+)")
        if playUrl then
          playUrl = urlDecode(playUrl)
          local musicNameEncoded = url:match("%%E6%%AD%%8C%%E6%%9B%%B2%%E5%%90%%8D=([^&]+)")
          local musicName = musicNameEncoded and urlDecode(musicNameEncoded) or "未知歌曲"
          local singerEncoded = url:match("%%E6%%AD%%8C%%E6%%89%%8B=([^&]+)")
          local singer = singerEncoded and urlDecode(singerEncoded):gsub("%%2C", ","):gsub(",", "、") or ""

          local mp3Encoded = url:match("mp3=([^&]+)")
          local mp4Encoded = url:match("mp4=([^&]+)")

          local fileExtension = ".mp3"
          local isVideo = false

          if mp4Encoded then
            fileExtension = (mp4Encoded:match("^%.") and mp4Encoded or "." .. mp4Encoded)
            isVideo = true
           elseif mp3Encoded then
            fileExtension = (mp3Encoded:match("^%.") and mp3Encoded or "." .. mp3Encoded)
          end

          if playUrl:find("%.mp4", 1, true) then
            fileExtension = ".mp4"
            isVideo = true
          end

          local fileName = (singer ~= "") and (musicName .. " - " .. singer .. fileExtension) or (musicName .. fileExtension)
          fileName = fileName:gsub("[\\/:*?\"<>|]", "_")
          fileName = fileName:gsub("_+", "_")

          print("下载 - 文件名: " .. fileName)
          if isVideo then
            startSystemDownload(playUrl, fileName, true)
           else
            addMusicToQueue(playUrl, fileName)
          end
          return true
        end

        return false
      end

      if url and (url:find("%.mp4") or url:find("%.mp3") or url:find("%.mkv") or url:find("%.m4a") or url:find("%.flac")) then
        if handleGenericDownload(url) then
          return true
        end
      end

      return false
    end
  })

  return true
end

-- ==================== 启动 ====================
task(500, function()
  优化DNS()

  if isNetworkAvailable() then
    checkUpdate(function(hasUpdate) end)
  end

  local savedAutoPlay = getSharedData("auto_play_enabled", "no")
  autoPlayEnabled = (savedAutoPlay == "yes")

  删除通知()
  删除旧封面()
  currentSongInfo.title = "SU音乐"
  currentSongInfo.artist = "等待播放"
  显示音乐通知栏()

  local floatLyricEnabled = getSharedData("float_lyric_enabled", "off")
  if floatLyricEnabled == "on" and 检查悬浮窗权限() then
    createFloatWindow()
  end

  显示本地网页()
end)

-- ==================== 网络监听 ====================
local networkMonitor = Ticker()
networkMonitor.Period = 5000
local wasOffline = false
networkMonitor.onTick = function()
  if isNetworkAvailable() then
    if wasOffline then
      wasOffline = false
      Toast.makeText(activity, "网络已连接", Toast.LENGTH_SHORT).show()
    end
   else
    wasOffline = true
  end
end
networkMonitor.start()

-- ==================== 返回键退出 ====================
local exitParam = 0
function onKeyDown(code, event)
  if string.find(tostring(event), "KEYCODE_BACK") ~= nil then
    if webView.getVisibility() == View.VISIBLE and webView.canGoBack() then
      webView.goBack()
     elseif exitParam + 2 > tonumber(os.time()) then
      if networkMonitor then networkMonitor.stop() end
      if broadcastReceiver then
        pcall(function() activity.unregisterReceiver(broadcastReceiver) end)
      end
      删除通知()
      hideFloatWindow()
      activity.finish()
      os.exit()
     else
      Toast.makeText(activity, "再按一次返回键退出", Toast.LENGTH_SHORT).show()
      exitParam = tonumber(os.time())
    end
    return true
  end
  return false
end

-- ==================== 应用销毁 ====================
function onDestroy()
  if networkMonitor then networkMonitor.stop() end
  if broadcastReceiver then
    pcall(function() activity.unregisterReceiver(broadcastReceiver) end)
  end
  删除通知()
  hideFloatWindow()
end