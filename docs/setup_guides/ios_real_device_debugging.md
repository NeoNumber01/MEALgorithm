# iOS 真机调试指南

本教程帮助你在 iPhone 真机上运行 MEALgorithm 应用。

---

## 前置条件

- ✅ iPhone 16 (iOS 26)
- ✅ Apple Developer Program 会员（中国区）
- ✅ Mac 上安装了 Xcode
- ✅ USB 数据线（Type-C to Type-C）

---

## 第一步：连接 iPhone 到 Mac

1. 用 **USB 数据线** 连接 iPhone 到 Mac
2. 在 iPhone 上，如果弹出 **"信任此电脑？"**，点击 **信任** 并输入密码
3. 确保 iPhone 已解锁

---

## 第二步：在 Xcode 中配置签名

### 2.1 打开项目设置

1. 在 Xcode 中，点击左侧 Project Navigator 中的 **MEALgorithmiOS** 项目（蓝色图标）
2. 选择 **TARGETS** 下的 **MEALgorithmiOS**
3. 点击 **Signing & Capabilities** 标签页

### 2.2 配置 Team

1. 勾选 **Automatically manage signing**（自动管理签名）
2. 在 **Team** 下拉菜单中，选择你的 **Apple Developer Team**
   - 如果没有显示，点击 **Add an Account...** 登录你的 Apple ID
   - 确保使用的是加入了 Apple Developer Program 的 Apple ID

### 2.3 确认 Bundle Identifier

确保 **Bundle Identifier** 是唯一的，例如：
```
com.yourname.MEALgorithmiOS
```

如果提示"该 Bundle ID 已被使用"，请修改为一个独特的值。

---

## 第三步：选择真机设备

1. 在 Xcode 顶部工具栏，点击设备选择器（目前可能显示 "iPhone 16"）
2. 你应该能看到你的 **iPhone 16** 出现在设备列表中
3. 选择它

> **注意**: 如果看不到你的 iPhone：
> - 确保 iPhone 已解锁并信任此 Mac
> - 尝试拔掉再重新插入数据线
> - 检查 Xcode → Window → Devices and Simulators，确保设备已识别

---

## 第四步：首次运行（信任开发者）

1. 点击 **▶️ Run** 按钮（或按 Cmd+R）
2. Xcode 会编译并将 App 安装到你的 iPhone 上
3. **首次运行会失败**，因为 iPhone 不信任这个开发者

### 在 iPhone 上信任开发者证书

1. 打开 iPhone **设置** App
2. 进入 **通用** → **VPN与设备管理**（或 **描述文件与设备管理**）
3. 在 **开发者 App** 下，找到你的开发者证书/Team 名称
4. 点击它，然后点击 **信任 "你的开发者名称"**
5. 确认信任

---

## 第五步：再次运行

1. 回到 Xcode
2. 再次点击 **▶️ Run** 按钮
3. App 应该会在你的 iPhone 上成功启动！

---

## 常见问题排查

### 问题 1：设备未显示在 Xcode 中

**解决**:
1. 确保 iPhone 已解锁
2. 在 iPhone 上点击"信任此电脑"
3. 尝试使用不同的 USB 端口或数据线
4. 重启 Xcode

### 问题 2：Signing 证书错误

**解决**:
1. 确保你的 Apple Developer Program 订阅没有过期
2. 在 Xcode → Preferences → Accounts 中登录你的 Apple ID
3. 点击 "Download Manual Profiles"

### 问题 3：App 安装失败

**解决**:
1. 检查 iPhone 上是否已有同名 App，如有请删除
2. 确保 iPhone 有足够存储空间
3. 在 Xcode 中：Product → Clean Build Folder
4. 重新运行

### 问题 4：无线调试（可选）

你可以启用无线调试，这样以后不用插线：
1. 连接 USB 状态下
2. Xcode → Window → Devices and Simulators
3. 选择你的 iPhone
4. 勾选 **Connect via network**

---

## 验证网络功能

真机运行后，尝试注册功能。由于真机不受 iOS 模拟器的 QUIC/HTTP3 兼容性问题影响，注册功能应该正常工作。

如果仍有网络问题，请检查：
1. iPhone 是否连接到 WiFi
2. 是否开启了 VPN（如有，尝试关闭）
3. 防火墙设置是否阻止了 Supabase 连接
