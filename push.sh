#!/bin/bash
set -euo pipefail

# 自动提交仓库脚本，bash push.sh 运行
# ==================== 自动清理子目录 .git + 清理 git 缓存 ====================
auto_clean_git() {
  echo -e "\n========================================"
  echo "🔍 第一步：自动扫描并清理子目录 .git"
  echo "========================================\n"

  local CURRENT_GIT=$(realpath ".git")

  # 查找所有子目录 .git
  found_any=0
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    local full=$(realpath "$dir")
    if [ "$full" != "$CURRENT_GIT" ]; then
      found_any=1
      echo "发现嵌套Git: $dir"
      rm -rf "$dir"
      local subdir=$(dirname "$dir")
      git rm --cached "$subdir" >/dev/null 2>&1 || true
    fi
  done < <(find . -type d -name ".git" 2>/dev/null)

  if [ $found_any -eq 0 ]; then
    echo "✅ 没有需要清理的 .git 目录"
  else
    echo -e "\n✅ 子目录 .git 清理完成（GitHub/Gitee 箭头已消失）！"
  fi
}

# ==================== 提交 + 数字选择远程 + 选择分支 ====================
auto_git_push() {
  echo -e "\n========================================"
  echo "🚀 第二步：提交代码"
  echo "========================================"

  # 检查是否是 git 仓库
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo -e "\n❌ 错误：当前不是 Git 仓库！"
    exit 1
  }

  # 提交信息
  read -p "请输入提交描述: " msg
  [ -z "$msg" ] && msg="update: $(date '+%Y-%m-%d %H:%M:%S')"

  git add .
  git commit -m "$msg"
  echo -e "\n✅ 本地提交成功！"

  # ==================== 选择远程仓库（数字选择 + 显示地址） ====================
  echo -e "\n========================================"
  echo "📡 第三步：选择远程仓库"
  echo "========================================"

  # 读取远程
  i=1
  options=""
  while read -r line; do
    url=$(git remote get-url "$line")
    echo "$i) $line -> $url"
    eval "opt$i=$line"
    options="$options $i"
    i=$((i + 1))
  done < <(git remote)

  total=$((i - 1))
  read -p "请选择 [1-$total]: " sel

  # 选择远程
  remote=$(eval "echo \$opt$sel")
  [ -z "$remote" ] && {
    echo "❌ 选择无效"
    exit 1
  }

  # ==================== 选择分支 ====================
  echo -e "\n========================================"
  echo "🌿 第四步：选择分支"
  echo "========================================"

  current_branch=$(git rev-parse --abbrev-ref HEAD)
  read -p "分支名称 [默认 $current_branch]: " branch
  [ -z "$branch" ] && branch="$current_branch"

  # ==================== 确认推送（回车=YES） ====================
  echo -e "\n========================================"
  echo "⚠️  确认推送"
  echo "远程: $remote"
  echo "分支: $branch"
  echo "========================================"

  read -p "确定推送？(回车=yes, n取消): " confirm
  [ "$confirm" = "n" ] && {
    echo "🚫 已取消"
    exit 0
  }

  # ==================== 推送 ====================
  echo -e "\n📤 开始推送..."
  if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    git push "$remote" "$branch"
  else
    git push -u "$remote" "$branch"
  fi

  echo -e "\n🎉 推送成功！"
}

# ==================== 主流程 ====================
auto_clean_git
auto_git_push
