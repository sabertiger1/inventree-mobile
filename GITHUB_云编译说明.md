# 上传到 GitHub 并启用云编译

按以下步骤可将本项目推送到您自己的 GitHub 仓库，并利用 GitHub Actions 自动/手动编译 Android APK，无需在本地安装 Flutter 环境。

---

## 一、在 GitHub 上创建新仓库

1. 登录 [GitHub](https://github.com)，点击右上角 **+** → **New repository**。
2. 填写：
   - **Repository name**：例如 `inventree-app` 或任意名称。
   - **Visibility**：选 **Public** 或 **Private**。
   - **不要**勾选 “Add a README file” / “Add .gitignore” / “Choose a license”（保持空仓库）。
3. 点击 **Create repository**。
4. 记下仓库地址，形如：`https://github.com/你的用户名/仓库名.git`。

---

## 二、在本地添加您的远程仓库并推送

在项目根目录 `e:\InvenTree\inventree-app` 下打开终端（PowerShell 或 CMD），依次执行：

### 1. 配置 Git 用户（若尚未配置过）

```bash
git config --global user.email "你的邮箱@example.com"
git config --global user.name "你的名字或 GitHub 用户名"
```

### 2. 添加您的 GitHub 仓库为远程

将下面的 `你的用户名` 和 `仓库名` 换成你在第一步里创建的仓库信息：

```bash
git remote add mygithub https://github.com/你的用户名/仓库名.git
```

例如：`git remote add mygithub https://github.com/zhangsan/inventree-app.git`

### 3. 推送代码并触发云编译

- 若你的 GitHub 默认分支是 **main**：

  ```bash
  git push -u mygithub master:main
  ```

  之后可改为在 main 上开发，再推送：

  ```bash
  git push mygithub main
  ```

- 若你希望仓库默认分支叫 **master**（与当前本地一致）：

  ```bash
  git push -u mygithub master
  ```

推送成功后，GitHub Actions 会自动开始运行 **Android** 和 **iOS** 的云编译（若仓库为 Public，Actions 免费可用）。

---

## 三、查看云编译与下载 APK

1. 打开你的仓库页面：`https://github.com/你的用户名/仓库名`。
2. 点击顶部 **Actions** 标签。
3. 左侧选择 **Android** workflow，右侧会看到每次 push 或手动触发的运行记录。
4. 点进某次 **Run**（例如 “汉化与云编译…” 对应的那次）。
5. 等 **Build for Android** 和 **Upload APK** 都打勾完成后，页面底部 **Artifacts** 区域会出现 **inventree-android-apk**，点击即可下载 `app-release.apk` 安装包。

---

## 四、手动触发编译（不推代码也可编译）

1. 在仓库页打开 **Actions**。
2. 左侧选 **Android**（或 **iOS**）。
3. 右侧点击 **Run workflow**，选择分支后运行即可。

---

## 五、当前已做的改动说明

- **汉化**：增加简体中文支持，设置里语言显示为「简体中文」/「繁體中文」。
- **Android workflow**：支持 `main` / `master` 分支，支持 `workflow_dispatch` 手动运行；构建 **release** APK 并上传为 Artifact，便于直接下载安装。
- **iOS workflow**：同样支持 `main` / `master` 与手动触发。

云编译使用仓库中的 **.github/workflows/android.yaml** 和 **ios.yaml**，无需在本地安装 Flutter、Android SDK 或 Xcode。
