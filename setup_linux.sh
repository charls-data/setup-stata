#!/bin/bash
# For use in GitHub Actions workflows to automate Stata setup on Linux
set -euo pipefail

# =============================================================================
#  0. ENV
# =============================================================================
DBW="\033[48;2;0;0;139m\033[38;2;255;255;255m"
DRW="\033[48;2;139;0;0m\033[38;2;255;255;255m"
NC="\033[0m"
w_dir=$(pwd)

echo -e "${DBW}========== Stata Automated Installation Script Starting ==========${NC}"
echo " "

# =============================================================================
#  1. Download Stata installer
# =============================================================================
echo -e "${DBW}1 of 6: Download Stata Installer${NC}"
STATA_INSTALLER="/tmp/stata_linux.tar.gz"
curl -L -o $STATA_INSTALLER $STATA_URL
echo "Download complete, preparing for installation..."
echo " "

# =============================================================================
#  2. Install Stata
# =============================================================================
echo -e "${DBW}2 of 6: Install Stata${NC}"

# untar the installer
mkdir -p /tmp/stata_install
tar -xzf $STATA_INSTALLER -C /tmp/stata_install

# Change to the installation directory
mkdir -p /opt/stata${STATA_VERSION}
cd /opt/stata${STATA_VERSION}

# Install Stata
(
  set +e
  yes 2>/dev/null | /tmp/stata_install/install
  rc=${PIPESTATUS[1]}
  exit "$rc"
)
echo "Installation command executed, verifying installation..."

# Verify successful installation
STATA_EXE="/opt/stata${STATA_VERSION}/stata-${STATA_EDITION}"
if [ ! -f "$STATA_EXE" ]; then
  echo -e "$DRW}Stata installation failed, executable not found: $STATA_EXE${NC}"
  exit 1  # Installation failed
fi
echo "Stata installed successfully."
echo " "

# =============================================================================
#  3. Stata License
# =============================================================================
# Create license file
echo -e "${DBW}3 of 6: Setup Stata License${NC}"
LICENSE_FILE="/opt/stata${STATA_VERSION}/stata.lic"

# Write license content to license file
printf '%s' "$STATA_LICENSE" > $LICENSE_FILE

# Check if the license file was created successfully
if [ ! -f "$LICENSE_FILE" ]; then
  echo -e "${DRW}Failed to create license file at: ${LICENSE_FILE}${NC}"
  exit 2  # License file creation failed
fi

echo "License file created successfully at: $LICENSE_FILE"
echo " "

# =============================================================================
#  4 Fix Library Dependencies
# =============================================================================
echo -e "${DBW}4 of 6: Fixing Library Dependencies${NC}"
for LIB in ncurses tinfo; do
  target=$(ldconfig -p | awk "/lib${LIB}\.so\.6/ {print \$NF; exit}")
  [[ -n $target ]] || { echo "lib${LIB}.so.6 not found"; exit 1; }
  sudo ln -sf "$target" "$(dirname "$target")/lib${LIB}.so.5"
done
sudo ldconfig
echo "Library dependencies fixed successfully."
echo " "

# =============================================================================
#  4. Test Stata Functionality
# =============================================================================
echo -e "${DBW}5 of 6: Test Stata Functionality${NC}"

# Stata batch log file
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
EXPECTED_LOG_FILE="$SCRIPT_DIR/stata.log"

# remove any previous log file
if [ -f "$EXPECTED_LOG_FILE" ]; then
  echo "Removing previous test log file: $EXPECTED_LOG_FILE"
  rm -f "$EXPECTED_LOG_FILE"
fi

# run Stata in batch mode to test functionality
cd "$SCRIPT_DIR"
"$STATA_EXE" -b "di 3241"
STATA_EXIT_CODE=$?
cd $w_dir

# Check Stata execution result
if [ $STATA_EXIT_CODE -ne 0 ]; then
  echo -e "${DRW}Stata test failed, exit code: $STATA_EXIT_CODE${NC}"
  exit 3  # Stata execution failed
fi
echo "Stata test run passed!"

# Check for log file
if [ ! -f "$EXPECTED_LOG_FILE" ]; then
  echo -e "${DRW}Expected log file not found: $EXPECTED_LOG_FILE${NC}"
  exit 4  # Log file not created
fi

# check end of log file
LAST_LINE=$(tail -n 1 "$EXPECTED_LOG_FILE")
if [[ "$LAST_LINE" != "3241" ]]; then
  echo -e "${DRW}Stata test did not complete successfully,${NC}"
  echo -e "${DRW}last line of the log file is: $LAST_LINE${NC}"
  exit 5  # Log format unexpected
fi
echo "Log file confirms successful execution."
echo " "

# =============================================================================
#  6. Export Stata Executable to ENV
# =============================================================================
echo -e "${DBW}6 of 6: Export Stata Executable to Environment Variable${NC}"

# 设置环境变量，使其在后续步骤中可用
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "STATA_EXE=$STATA_EXE" >> $GITHUB_ENV
  echo "Setting environment variable 'STATA_EXE' to: $STATA_EXE"
else
  echo -e "${DRW}Warning: GITHUB_ENV not found. Cannot export STATA_EXE.${NC}"
  exit 6  # Environment variable export failed
fi

# Clean up
echo "Cleaning up: Removing files..."
rm -f "$EXPECTED_LOG_FILE"
rm -f "$STATA_INSTALLER"
rm -rf /tmp/stata_install

echo " "
echo -e "${DBW}========== Stata Installation and Configuration Successful ==========${NC}" 
echo " "
