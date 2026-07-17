-- main.lua
require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.content.*"
import "android.net.*"
import "android.provider.Settings"
import "android.content.pm.PackageManager"
import "android.Manifest"
import "android.os.PowerManager"

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
local function getSharedData(key, defaultValue)
  local sp = activity.getSharedPreferences("SUMusic", Context.MODE_PRIVATE)
  return sp.getString(key, defaultValue)
end

local function setSharedData(key, value)
  local sp = activity.getSharedPreferences("SUMusic", Context.MODE_PRIVATE)
  local editor = sp.edit()
  editor.putString(key, value)
  editor.commit()
end

-- ==================== 权限检测 ====================
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

function 检查媒体权限()
  if Build.VERSION.SDK_INT >= 33 then
    local audio = activity.checkSelfPermission(Manifest.permission.READ_MEDIA_AUDIO) == PackageManager.PERMISSION_GRANTED
    local images = activity.checkSelfPermission(Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED
    return audio and images
  end
  return true
end

function 检查悬浮窗权限()
  if Build.VERSION.SDK_INT >= 23 then
    return Settings.canDrawOverlays(activity)
  end
  return true
end

function 检查电池优化权限()
  if Build.VERSION.SDK_INT >= 23 then
    local pm = activity.getSystemService(Context.POWER_SERVICE)
    return pm.isIgnoringBatteryOptimizations(activity.getPackageName())
  end
  return true
end

function 请求电池优化权限()
  if Build.VERSION.SDK_INT >= 23 then
    if not 检查电池优化权限() then
      local intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
      intent.setData(Uri.parse("package:" .. activity.getPackageName()))
      activity.startActivity(intent)
    end
  end
end

function 必需权限已全部授权()
  if Build.VERSION.SDK_INT >= 33 then
    if not 检查通知权限() then return false end
    if not 检查媒体权限() then return false end
   else
    if not 检查存储权限() then return false end
  end
  return true
end

function 请求所有权限()
  if Build.VERSION.SDK_INT >= 33 then
    local perms = {}
    if not 检查通知权限() then
      table.insert(perms, Manifest.permission.POST_NOTIFICATIONS)
    end
    if not 检查媒体权限() then
      table.insert(perms, Manifest.permission.READ_MEDIA_AUDIO)
      table.insert(perms, Manifest.permission.READ_MEDIA_IMAGES)
    end
    if #perms > 0 then
      activity.requestPermissions(perms, 100)
    end
   else
    if not 检查存储权限() then
      activity.requestPermissions({Manifest.permission.WRITE_EXTERNAL_STORAGE}, 100)
    end
  end
  -- 请求电池优化（不阻塞）
  请求电池优化权限()
end

-- ==================== 服务条款 ====================
local termsContent = [[
SU音乐 - 开源许可协议
最后更新日期：2026年5月

本项目采用部分开源模式。

一、开源声明
1.1 本项目的用户界面、基础框架、下载管理等模块采用 [MIT License] 开源许可证，任何人都可以自由使用、修改和分发这些部分的代码。
1.2 本项目核心模块（包括但不限于酷我音乐平台会员接口、API请求逻辑、会员验证机制等）为闭源模块，不包含在开源许可范围内，禁止对其进行任何形式的破解、逆向工程、提取或二次利用。
1.3 本项目的数据来源原理是从酷我音乐平台的公开服务器中拉取数据，经过对数据简单地筛选与合并后进行展示，因此本项目不对数据的合法性、准确性负责。

二、闭源模块保护
2.1 酷我音乐平台会员接口及相关API模块为本项目的核心技术，旨在防止滥用，不对外开放源代码。
2.2 禁止对闭源模块进行以下任何操作：
（1）破解：包括但不限于绕过功能限制、模拟会员请求、修改验证逻辑等。
（2）逆向工程：包括但不限于反编译、反汇编、提取闭源代码、分析API通信协议、抓取或模拟API请求接口等。
（3）篡改：包括但不限于修改闭源模块代码、资源文件、配置文件等。
（4）滥用：包括但不限于高频请求、批量下载、商业使用等可能影响酷我音乐平台正常服务的行为。

2.3 关于二次修改与分发
本项目允许非商业性质的二次修改与分发，但严禁以下行为：
（1）植入恶意代码：禁止在修改后的版本中植入任何形式的病毒、木马、广告插件、弹窗广告、信息窃取模块、挖矿脚本等恶意代码。
（2）捆绑垃圾插件：禁止捆绑与音乐播放无关的任何第三方插件、推广软件、流氓组件。
（3）以营利为目的的盗版：禁止将本软件重新打包后以任何形式收费、植入广告获利、或通过引流手段谋取商业利益。
（4）冒名分发：禁止将修改后的版本冒充原版进行分发，误导用户。

违反上述条款的恶意修改与分发行为，均构成侵权，本项目保留追究法律责任的权利。

三、版权数据
3.1 使用本项目的过程中可能会产生版权数据（包括但不限于图像、音频、名字等）。对于这些版权数据，本项目不拥有它们的所有权。为了避免侵权，使用者务必在24小时内清除使用本项目的过程中所产生的版权数据。
3.2 本项目本身没有获取某个音频数据的能力，本项目使用的在线音频数据来源来自酷我音乐平台返回的在线链接。

四、免责声明
4.1 本软件按"原样"提供，不提供任何形式的明示或暗示担保。
4.2 在任何情况下，作者或版权持有人均不对因使用本软件而产生的任何索赔、损害或其他责任负责。

五、使用限制
5.1 本项目完全免费，仅供个人对技术的学习交流使用。
5.2 禁止在违反当地法律法规的情况下使用本项目，由此造成的任何后果由使用者承担。

六、禁止滥用
6.1 为了维护酷我音乐平台的正常服务，禁止利用本项目进行：
（1）高频或批量下载音乐文件
（2）将会员接口用于其他项目或服务
（3）任何形式的商业使用
（4）对酷我音乐平台服务器造成过大压力的行为
6.2 如发现滥用行为，本项目保留采取措施的权利。

七、音乐平台声明
7.1 本项目音源来自酷我音乐平台，版权归酷我音乐及相关权利人所有。
7.2 音乐平台不易，请尊重版权，支持正版。如需长期使用音乐，请在官方平台购买会员。

八、侵权处理
8.1 我们尊重知识产权。如您是相关版权方或酷我音乐平台的授权代表，认为本项目侵害了您的合法权益，请通过以下方式联系我们，我们将在收到通知后以最快速度进行整改或下架处理。

九、接受协议
9.1 若你使用了本项目，即代表你接受本协议。

十、联系方式
项目相关事宜，请联系：2831466885@qq.com
]]

-- ==================== 显示服务条款 ====================
function showTermsDialog()
  AlertDialog.Builder(activity)
  .setTitle("服务条款")
  .setMessage(termsContent)
  .setPositiveButton("同意并继续", { onClick = function()
      setSharedData("terms_accepted", "true")
      请求所有权限()
      if 必需权限已全部授权() then
        activity.newActivity("main3")
       else
        activity.newActivity("main2")
      end
      activity.finish()
    end })
  .setNegativeButton("不同意", { onClick = function()
      Toast.makeText(activity, "您必须同意服务条款才能使用本应用", Toast.LENGTH_LONG):show()
      activity.finish()
    end })
  .setCancelable(false)
  .show()
end

-- ==================== 启动 ====================
local hasAgreed = getSharedData("terms_accepted", "false")
if hasAgreed == "true" then
  请求所有权限()
  if 必需权限已全部授权() then
    activity.newActivity("main3")
   else
    activity.newActivity("main2")
  end
  activity.finish()
 else
  showTermsDialog()
end