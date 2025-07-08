# Build Release APK Script
Write-Host "🚀 Starting Release APK Build..." -ForegroundColor Green

# Clean project
Write-Host "🧹 Cleaning Project..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📦 Getting Dependencies..." -ForegroundColor Yellow
flutter pub get

# Build APK
Write-Host "🔨 Building Release APK..." -ForegroundColor Yellow
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Check build success
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ APK Built Successfully!" -ForegroundColor Green
    Write-Host "📍 File Location: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
    
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $fileInfo = Get-Item $apkPath
        Write-Host "📊 File Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
        Write-Host "🕒 Created: $($fileInfo.LastWriteTime)" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ APK Build Failed" -ForegroundColor Red
    Write-Host "💡 Check errors above and try again" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Important Notes:" -ForegroundColor Magenta
Write-Host "• Make sure Google Maps API key is correct" -ForegroundColor White
Write-Host "• Ensure the key is enabled for Production" -ForegroundColor White
Write-Host "• Test the app on a real device" -ForegroundColor White 