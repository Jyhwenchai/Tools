#!/bin/bash

# 权限优化版本构建脚本
# 构建发布版本并进行权限验证

echo "===== 权限优化版本构建脚本 ====="
echo "开始时间: $(date)"
echo ""

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 创建构建目录
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/Tools.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"

mkdir -p $BUILD_DIR
mkdir -p $EXPORT_PATH

# 1. 清理项目
echo -e "${BLUE}===== 1. 清理项目 =====${NC}"
xcodebuild clean -project Tools/Tools.xcodeproj -scheme Tools -configuration Release

# 2. 运行SwiftLint
echo -e "${BLUE}===== 2. 运行SwiftLint =====${NC}"
if command -v swiftlint &> /dev/null; then
  echo "运行SwiftLint代码检查..."
  swiftlint --strict
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SwiftLint检查通过${NC}"
  else
    echo -e "${RED}✗ SwiftLint检查失败，请修复代码规范问题${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️ SwiftLint未安装，跳过代码规范检查${NC}"
fi

# 3. 运行SwiftFormat
echo -e "${BLUE}===== 3. 运行SwiftFormat =====${NC}"
if command -v swiftformat &> /dev/null; then
  echo "运行SwiftFormat代码格式化..."
  swiftformat Tools/
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SwiftFormat格式化完成${NC}"
  else
    echo -e "${RED}✗ SwiftFormat格式化失败${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}⚠️ SwiftFormat未安装，跳过代码格式化${NC}"
fi

# 4. 运行单元测试
echo -e "${BLUE}===== 4. 运行单元测试 =====${NC}"
xcodebuild test -project Tools/Tools.xcodeproj -scheme Tools -destination 'platform=macOS'

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ 单元测试通过${NC}"
else
  echo -e "${RED}✗ 单元测试失败，请修复测试问题${NC}"
  exit 1
fi

# 5. 验证Info.plist权限配置
echo -e "${BLUE}===== 5. 验证Info.plist权限配置 =====${NC}"
echo "检查Info.plist中的权限声明..."

# 检查Info.plist中是否只包含必要的权限
PLIST_PATH="Tools/Tools/Info.plist"
PERMISSION_COUNT=$(grep -c "NSPasteboardUsageDescription\|NSFileProviderDomainUsageDescription\|NSAppleEventsUsageDescription" "$PLIST_PATH")

if [ $PERMISSION_COUNT -le 1 ]; then
  echo -e "${GREEN}✓ Info.plist权限配置正确${NC}"
else
  echo -e "${RED}✗ Info.plist包含多余的权限声明，请检查并移除${NC}"
  exit 1
fi

# 6. 验证Entitlements配置
echo -e "${BLUE}===== 6. 验证Entitlements配置 =====${NC}"
echo "检查Entitlements文件..."

ENTITLEMENTS_PATH="Tools/Tools/Tools.entitlements"
ENTITLEMENTS_COUNT=$(grep -c "com.apple.security.app-sandbox\|com.apple.security.files" "$ENTITLEMENTS_PATH")

if [ $ENTITLEMENTS_COUNT -le 1 ]; then
  echo -e "${GREEN}✓ Entitlements配置正确${NC}"
else
  echo -e "${RED}✗ Entitlements包含多余的权限，请检查并移除${NC}"
  exit 1
fi

# 7. 构建发布版本
echo -e "${BLUE}===== 7. 构建发布版本 =====${NC}"
echo "构建Release版本..."

xcodebuild archive -project Tools/Tools.xcodeproj -scheme Tools -configuration Release -archivePath "$ARCHIVE_PATH"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ 构建成功${NC}"
else
  echo -e "${RED}✗ 构建失败${NC}"
  exit 1
fi

# 8. 导出应用
echo -e "${BLUE}===== 8. 导出应用 =====${NC}"
echo "导出应用..."

# 创建导出选项plist
cat > "$BUILD_DIR/exportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "$EXPORT_PATH" -exportOptionsPlist "$BUILD_DIR/exportOptions.plist"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ 导出成功${NC}"
  echo "应用已导出到: $EXPORT_PATH"
else
  echo -e "${RED}✗ 导出失败${NC}"
  exit 1
fi

# 9. 验证应用签名
echo -e "${BLUE}===== 9. 验证应用签名 =====${NC}"
echo "验证应用签名..."

APP_PATH=$(find "$EXPORT_PATH" -name "*.app" -type d)
codesign -vvv --deep --strict "$APP_PATH"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ 应用签名有效${NC}"
else
  echo -e "${RED}✗ 应用签名无效${NC}"
  exit 1
fi

# 10. 总结
echo -e "${BLUE}===== 10. 构建总结 =====${NC}"
echo -e "${GREEN}✅ 权限优化版本构建完成!${NC}"
echo "应用路径: $APP_PATH"
echo ""
echo "下一步:"
echo "1. 运行权限验证测试: ./Tools/ToolsTests/run_permission_verification_tests.sh"
echo "2. 进行手动权限验证: 参考 Tools/ToolsTests/PERMISSION_POPUP_ELIMINATION_VERIFICATION.md"
echo "3. 准备发布说明: 更新 PERMISSION_OPTIMIZATION_RELEASE_NOTES.md"
echo ""
echo "结束时间: $(date)"