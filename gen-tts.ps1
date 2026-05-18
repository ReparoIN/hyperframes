#!/usr/bin/env pwsh
# gen-tts.ps1 — Regenerate all 30 voiceovers with Python313 in PATH
# Run from repo root. Cleans timestamp headers from scripts before TTS.

$env:PATH = "C:\Users\Harish-Ops\AppData\Local\Programs\Python\Python313;C:\Users\Harish-Ops\AppData\Local\Programs\Python\Python313\Scripts;" + $env:PATH

$ads = Get-ChildItem callcards-*\ad-* -Directory | Sort-Object FullName
$total = $ads.Count
$done = 0
$failed = @()

foreach ($ad in $ads) {
    $done++
    $script = Join-Path $ad.FullName "voiceover-script.txt"
    $out    = Join-Path $ad.FullName "assets\voiceover.mp3"

    if (-not (Test-Path $script)) {
        Write-Host "[$done/$total] SKIP (no script): $($ad.Name)"
        continue
    }
    if (Test-Path $out) {
        Write-Host "[$done/$total] skip (exists): $($ad.FullName -replace '.*hyperframes\\','')"
        continue
    }

    # Strip headers and timestamp prefixes → clean text
    $lines = Get-Content $script
    $cleanLines = $lines |
        Where-Object { $_ -match '^\[\d+:\d+-\d+:\d+\]' } |
        ForEach-Object { $_ -replace '^\[\d+:\d+-\d+:\d+\]\s*', '' }
    $cleanText = ($cleanLines | Where-Object { $_.Trim() -ne '' }) -join ' '

    $tmp = [System.IO.Path]::GetTempFileName() + ".txt"
    [System.IO.File]::WriteAllText($tmp, $cleanText, [System.Text.Encoding]::UTF8)

    Write-Host "[$done/$total] TTS: $($ad.FullName -replace '.*hyperframes\\','')"
    npx hyperframes tts $tmp --output $out

    Remove-Item $tmp -ErrorAction SilentlyContinue

    if (-not (Test-Path $out)) {
        Write-Host "  FAILED: $out"
        $failed += $ad.FullName
    } else {
        $size = (Get-Item $out).Length
        Write-Host "  OK ($([math]::Round($size/1024))KB)"
    }
}

Write-Host ""
Write-Host "Done. $done ads processed."
if ($failed.Count -gt 0) {
    Write-Host "FAILED ($($failed.Count)):"
    $failed | ForEach-Object { Write-Host "  $_" }
}
