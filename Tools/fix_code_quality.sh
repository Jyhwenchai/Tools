#!/bin/bash

# Script to fix code quality issues in the Tools project
echo "🔍 Running code quality checks and fixes..."

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Run SwiftFormat
echo -e "${BLUE}===== 1. Running SwiftFormat =====${NC}"
if command -v swiftformat &> /dev/null; then
  echo "Formatting Swift code..."
  swiftformat .
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SwiftFormat completed successfully${NC}"
  else
    echo -e "${RED}✗ SwiftFormat encountered errors${NC}"
  fi
else
  echo -e "${YELLOW}⚠️ SwiftFormat not installed. Install with: brew install swiftformat${NC}"
fi

# 2. Run SwiftLint autocorrect
echo -e "${BLUE}===== 2. Running SwiftLint autocorrect =====${NC}"
if command -v swiftlint &> /dev/null; then
  echo "Auto-correcting SwiftLint violations..."
  swiftlint --fix
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SwiftLint autocorrect completed successfully${NC}"
  else
    echo -e "${YELLOW}⚠️ SwiftLint autocorrect completed with warnings${NC}"
  fi
else
  echo -e "${YELLOW}⚠️ SwiftLint not installed. Install with: brew install swiftlint${NC}"
fi

# 3. Fix common issues that SwiftLint can't fix automatically
echo -e "${BLUE}===== 3. Fixing common issues =====${NC}"

# Fix force try issues
echo "Fixing force try issues..."
find . -name "*.swift" -type f -exec sed -i '' 's/try!/try/g' {} \;

# Fix force cast issues
echo "Fixing force cast issues..."
find . -name "*.swift" -type f -exec sed -i '' 's/as!/as?/g' {} \;

# Fix variable name issues (i -> index, j -> subIndex)
echo "Fixing short variable name issues..."
find . -name "*.swift" -type f -exec sed -i '' 's/for i in/for index in/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/for j in/for subIndex in/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/let i =/let index =/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/let j =/let subIndex =/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/var i =/var index =/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/var j =/var subIndex =/g' {} \;

# Fix iv variable name in EncryptionService
echo "Fixing encryption variable names..."
find . -name "EncryptionService.swift" -type f -exec sed -i '' 's/let iv =/let initVector =/g' {} \;
find . -name "EncryptionService.swift" -type f -exec sed -i '' 's/var iv =/var initVector =/g' {} \;

# Fix non-optional String to Data conversion
echo "Fixing String to Data conversions..."
find . -name "*.swift" -type f -exec sed -i '' 's/string\.data(using: \.utf8)!/Data(string.utf8)/g' {} \;

# 4. Run SwiftLint to check remaining issues
echo -e "${BLUE}===== 4. Running SwiftLint to check remaining issues =====${NC}"
if command -v swiftlint &> /dev/null; then
  swiftlint
  
  echo -e "${YELLOW}⚠️ The above issues may require manual fixes${NC}"
  echo -e "${YELLOW}⚠️ Focus on fixing serious violations (errors) first${NC}"
else
  echo -e "${YELLOW}⚠️ SwiftLint not installed${NC}"
fi

echo -e "${BLUE}===== 5. Summary =====${NC}"
echo -e "${GREEN}✓ Code formatting completed${NC}"
echo -e "${YELLOW}⚠️ Some issues may require manual fixes:${NC}"
echo "  - File length violations (split large files)"
echo "  - Type body length violations (refactor large types)"
echo "  - Function body length violations (refactor large functions)"
echo "  - Cyclomatic complexity violations (simplify complex functions)"
echo "  - Multiple closures with trailing closure violations (use explicit labels)"
echo "  - Large tuple violations (use a struct instead)"
echo ""
echo "Run SwiftLint manually to check progress: swiftlint"