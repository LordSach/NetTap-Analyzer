#!/usr/bin/env bash
set -e

echo "----------------------------------------"
echo " NetTap Analyzer — Grouped Git Commits"
echo "----------------------------------------"

# Ensure this is a git repo
if [ ! -d ".git" ]; then
    echo "❌ ERROR: This directory is not a git repository."
    echo "Run 'git init' first."
    exit 1
fi

echo "✔ Git repository detected."

confirm() {
    read -p "Proceed with this commit? (y/n): " yn
    case $yn in
        [Yy]* ) ;;
        * ) echo "Skipping."; return 1 ;;
    esac
}

# -------------------------
# 1) Commit – Project Scaffolding
# -------------------------
echo ""
echo "----------------------------------------"
echo " Commit Group 1: Project scaffolding"
echo "----------------------------------------"
echo "Includes:"
echo "  • README.md"
echo "  • LICENSE"
echo "  • .gitignore"
echo "  • scripts/, examples/, tools/ (empty scaffolding)"
echo "  • docs/ folder + initial markdowns (not technical content)"
echo ""

if confirm; then
    git add README.md LICENSE .gitignore
    git add scripts examples tools docs
    git commit -m "Initial scaffolding: repo structure, docs, tools, examples, ignore rules"
    echo "✔ Commit 1 completed."
fi


# -------------------------
# 2) Commit – RTL Baseline (Empty Shells)
# -------------------------
echo ""
echo "----------------------------------------"
echo " Commit Group 2: RTL baseline"
echo "----------------------------------------"
echo "Includes:"
echo "  • rtl/common/*"
echo "  • rtl/axi/*"
echo "  • rtl/dma_core/*"
echo "  • rtl/mac/*"
echo ""

if confirm; then
    git add rtl
    git commit -m "Add RTL baseline module structure (dma_core, axi, mac, common)"
    echo "✔ Commit 2 completed."
fi


# -------------------------
# 3) Commit – Simulation Baseline
# -------------------------
echo ""
echo "----------------------------------------"
echo " Commit Group 3: Simulation baseline"
echo "----------------------------------------"
echo "Includes:"
echo "  • SV TB structure"
echo "  • cocotb test directory"
echo "  • models folder"
echo ""

if confirm; then
    git add sim
    git commit -m "Add simulation environment: SV testbenches, cocotb tests, models"
    echo "✔ Commit 3 completed."
fi


# -------------------------
# 4) Commit – Software Baseline
# -------------------------
echo ""
echo "----------------------------------------"
echo " Commit Group 4: Software baseline"
echo "----------------------------------------"
echo "Includes:"
echo "  • PS apps (kernel module, user-space, baremetal)"
echo "  • utils"
echo ""

if confirm; then
    git add sw
    git commit -m "Add software baseline: PS applications, kernel module, utilities"
    echo "✔ Commit 4 completed."
fi


# -------------------------
# 5) Commit – FPGA Project Roots
# -------------------------
echo ""
echo "----------------------------------------"
echo " Commit Group 5: FPGA project baseline"
echo "----------------------------------------"
echo "Includes:"
echo "  • Vivado TCL"
echo "  • Constraints"
echo "  • Bitstream directory"
echo ""

if confirm; then
    git add fpga
    git commit -m "Add FPGA project structure: Vivado TCL, constraints, bitstream storage"
    echo "✔ Commit 5 completed."
fi


# -------------------------
# 6) Final Cleanup Commit
# -------------------------
echo ""
echo "----------------------------------------"
echo " Commit Group 6: Cleanup"
echo "----------------------------------------"
echo "Includes:"
echo "  • Any uncommitted new files"
echo ""

if confirm; then
    git add .
    git commit -m "Cleanup: add any remaining untracked files"
    echo "✔ Commit 6 completed."
fi

echo ""
echo "----------------------------------------"
echo "🎉 All commit groups processed!"
echo "----------------------------------------"
