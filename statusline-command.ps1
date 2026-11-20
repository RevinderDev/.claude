$data = [Console]::In.ReadToEnd() | ConvertFrom-Json
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$model = $data.model.display_name
$dir = Split-Path -Leaf $data.workspace.current_dir
$cost = [double]($data.cost.total_cost_usd ?? 0)
$pct = [int][Math]::Floor([double]($data.context_window.used_percentage ?? 0))
$durationMs = [long]($data.cost.total_duration_ms ?? 0)
# Subscription rate limits (absent for API users / before the first response)
$sessionPct = $data.rate_limits.five_hour.used_percentage
$weekPct = $data.rate_limits.seven_day.used_percentage

# Gruvbox dark palette (24-bit)
$AQUA = "`e[38;2;142;192;124m"; $GREEN = "`e[38;2;184;187;38m"; $YELLOW = "`e[38;2;250;189;47m"
$RED = "`e[38;2;251;73;52m"; $DARK_YELLOW = "`e[38;2;215;153;33m"; $BLUE = "`e[38;2;131;165;152m"
$PURPLE = "`e[38;2;211;134;155m"; $GRAY = "`e[38;2;146;131;116m"; $RESET = "`e[0m"
$SEP = "$GRAY | $RESET"

# Colored 10-segment bar + percentage (0-100)
function Bar([int]$p) {
    $color = if ($p -ge 90) { $RED } elseif ($p -ge 70) { $YELLOW } else { $GREEN }
    $filled = [Math]::Min([Math]::Floor($p / 10), 10)
    "$color$('█' * $filled)$('░' * (10 - $filled)) $p%$RESET"
}

$mins = [Math]::Floor($durationMs / 60000); $secs = [Math]::Floor(($durationMs % 60000) / 1000)

$branch = ''
git --no-optional-locks rev-parse --git-dir *> $null
if ($LASTEXITCODE -eq 0) {
    $branch = "$SEP🌿 $PURPLE$(git --no-optional-locks branch --show-current 2>$null)$RESET"
}

$limits = ''
if ($null -ne $sessionPct) { $limits = "$SEP⚡ $(Bar ([Math]::Floor($sessionPct)))" }
if ($null -ne $weekPct) { $limits += "$SEP📅 $([Math]::Floor($weekPct))%" }

$costFmt = '$' + $cost.ToString('F2', [Globalization.CultureInfo]::InvariantCulture)
"$AQUA[$model]$RESET 📁 $BLUE$dir$RESET$branch$SEP$(Bar $pct)$SEP$DARK_YELLOW$costFmt$RESET$limits$SEP⏱️ ${mins}m ${secs}s"
