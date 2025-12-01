# Run P2 Ablation Study - Complete Pipeline
# This script runs all experiments, generates figures, and prepares dashboard

Write-Host ""
Write-Host "=== P2 Ablation Study - Complete Pipeline ===" -ForegroundColor Cyan
Write-Host "This will take approximately 10-15 minutes"
Write-Host ""

# Step 1: Ask if user wants to clear old data
$clearData = Read-Host "Clear old experiment data? (y/N)"
if ($clearData -eq 'y' -or $clearData -eq 'Y') {
    Write-Host ""
    Write-Host "[1/4] Clearing old data..." -ForegroundColor Yellow
    Remove-Item data\latency_results.csv -ErrorAction SilentlyContinue
    Remove-Item data\power_logs.csv -ErrorAction SilentlyContinue
    Write-Host "Done: Old data cleared" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[1/4] Keeping existing data (will append new runs)" -ForegroundColor Yellow
}

# Step 2: Run experiments
Write-Host ""
Write-Host "[2/4] Running P2 ablation experiments..." -ForegroundColor Yellow
Write-Host "  - CPU Thread Scaling (t1, t4, t8)"
Write-Host "  - GPU Layer Offloading (l0, l11, l22)"
Write-Host "  - Batch Size Scaling (b128, b512, b1024)"
Write-Host ""

uv run python src\run_session.py --config config\p2_ablation.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Experiments failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done: Experiments complete!" -ForegroundColor Green
Write-Host ""

# Step 3: Generate figures
Write-Host "[3/4] Generating analysis figures..." -ForegroundColor Yellow
uv run python src\analysis\generate_report.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Figure generation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Done: Figures saved to figures\" -ForegroundColor Green
Write-Host ""

# Step 4: Instructions for dashboard
Write-Host "[4/4] Dashboard Setup" -ForegroundColor Yellow
Write-Host ""
Write-Host "To view results in GameMaker dashboard:"
Write-Host ""
Write-Host "  1. Start server (in new terminal):"
Write-Host "     > uv run python src\demo_server.py"
Write-Host ""
Write-Host "  2. Restart GameMaker project"
Write-Host ""
Write-Host "  3. Explore tabs:"
Write-Host "     - Live Trace - Real-time power visualization"
Write-Host "     - Energy vs Latency - Scatter plot of all runs"
Write-Host "     - Metrics Comparison - CPU vs GPU comparison"
Write-Host ""

Write-Host "=== Pipeline Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Data:    data\latency_results.csv, data\power_logs.csv"
Write-Host "  Figures: figures\*.png"
Write-Host ""
Write-Host "Check experiment_guide.md for detailed documentation."
Write-Host ""
