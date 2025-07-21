#!/bin/bash

# 权限优化最终测试脚本
# 运行所有相关测试并生成报告

echo "===== 权限优化最终测试与验证 ====="
echo "开始时间: $(date)"
echo ""

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 创建结果目录
RESULTS_DIR="TestResults"
mkdir -p $RESULTS_DIR

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 运行指定测试并记录结果
run_test() {
  TEST_NAME=$1
  echo -e "${YELLOW}运行测试: $TEST_NAME${NC}"
  
  # 增加总测试计数
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  # 运行测试
  xcrun swift test --filter "$TEST_NAME" > "$RESULTS_DIR/$TEST_NAME.log" 2>&1
  
  # 检查测试结果
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 测试通过: $TEST_NAME${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ 测试失败: $TEST_NAME${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "查看日志: $RESULTS_DIR/$TEST_NAME.log"
  fi
  echo ""
}

# 1. 文件访问权限移除测试
echo "===== 1. 文件访问权限移除测试 ====="
run_test "FileAccessPermissionRemovalTests"

# 2. 性能监控权限移除测试
echo "===== 2. 性能监控权限移除测试 ====="
run_test "PerformanceUIRemovalTests"

# 3. 核心功能完整性测试
echo "===== 3. 核心功能完整性测试 ====="
run_test "CoreFunctionalityIntegrityTests"

# 4. 粘贴板权限优化测试
echo "===== 4. 粘贴板权限优化测试 ====="
run_test "ClipboardServiceTests"

# 5. 应用稳定性测试
echo "===== 5. 应用稳定性测试 ====="
run_test "ApplicationStabilityTests"

# 6. 启动性能测试
echo "===== 6. 启动性能测试 ====="
run_test "StartupPerformanceTests"

# 7. 设置界面简化测试
echo "===== 7. 设置界面简化测试 ====="
run_test "SimplifiedSettingsTests"

# 8. 长时间运行稳定性测试 (可选，时间较长)
if [ "$1" == "--full" ]; then
  echo "===== 8. 长时间运行稳定性测试 ====="
  run_test "LongRunningStabilityTests"
fi

# 9. 权限弹窗消除验证
echo "===== 9. 权限弹窗消除验证 ====="
run_test "FileAccessPermissionRemovalTests/testEntitlementsFileAccessRemoved"

# 10. 构建发布版本测试
echo "===== 10. 构建发布版本测试 ====="
echo -e "${YELLOW}构建发布版本...${NC}"
xcodebuild -project Tools/Tools.xcodeproj -scheme Tools -configuration Release build > "$RESULTS_DIR/build_release.log" 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ 发布版本构建成功${NC}"
else
  echo -e "${RED}✗ 发布版本构建失败${NC}"
  echo "查看日志: $RESULTS_DIR/build_release.log"
fi

# 打印测试结果摘要
echo ""
echo "===== 测试结果摘要 ====="
echo -e "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "${RED}失败: $FAILED_TESTS${NC}"
echo ""

# 检查是否所有测试都通过
if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}✅ 所有测试通过! 权限优化验证成功!${NC}"
  echo "详细报告请查看: Tools/ToolsTests/PERMISSION_OPTIMIZATION_VERIFICATION.md"
else
  echo -e "${RED}❌ 有测试失败! 请查看日志并修复问题.${NC}"
fi

echo ""
echo "结束时间: $(date)"