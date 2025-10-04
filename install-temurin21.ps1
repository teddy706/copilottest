# Temurin JDK 21 설치 스크립트 (Windows)
# 사용법:
# 1) 관리자 권한으로 PowerShell을 실행
# 2) 이 스크립트 위치로 이동한 후 아래 명령으로 실행:
#    powershell -NoProfile -ExecutionPolicy Bypass -File .\install-temurin21.ps1

$ErrorActionPreference = 'Stop'
Write-Output "=== Temurin JDK 21 설치 스크립트 ==="

try {
    Write-Output "1) Adoptium API 조회하여 최신 Temurin 21 다운로드 URL 가져오기..."
    $api = 'https://api.adoptium.net/v3/assets/latest/21/hotspot?release_type=ga&architecture=x64&os=windows&image_type=jdk'
    $assets = Invoke-RestMethod -Uri $api -UseBasicParsing
    if (-not $assets -or $assets.Count -eq 0) { throw "Adoptium API에서 자산을 찾을 수 없습니다." }
    $url = $assets[0].binary.package.link
    Write-Output "다운로드 URL: $url"

    Write-Output "2) 설치 패키지 다운로드 (임시 폴더)..."
    $ext = [System.IO.Path]::GetExtension($url).ToLower()
    $outName = if ($ext -eq '.msi') { 'temurin21.msi' } else { 'temurin21' + $ext }
    $out = Join-Path $env:TEMP $outName
    if (Test-Path $out) { Remove-Item -Force $out }
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
    Write-Output "다운로드 완료: $out"

    if ($ext -eq '.msi') {
        Write-Output "3) MSI 설치 시작 (관리자 권한이 필요하며 UAC 프롬프트가 표시될 수 있음)..."
        # 무인 설치. 필요시 /qn 대신 UI 설치로 변경 가능
        $msiArgs = "/i `"$out`" /qn /norestart"
        $p = Start-Process -FilePath msiexec.exe -ArgumentList $msiArgs -Wait -PassThru -Verb RunAs
        if ($p.ExitCode -ne 0) { Write-Warning "msiexec 종료 코드: $($p.ExitCode). 무인 설치가 실패했을 수 있습니다." }
    } elseif ($ext -eq '.zip') {
        Write-Output "3) ZIP 패키지로 감지됨 — 압축 해제 처리(관리자 권한 필요할 수 있음)..."
        $instRoot = 'C:\Program Files\Eclipse Adoptium'
        $extracted = $null
        try {
            # 시도: Program Files로 압축 해제
            if (-not (Test-Path $instRoot)) { New-Item -Path $instRoot -ItemType Directory -Force | Out-Null }
            Expand-Archive -LiteralPath $out -DestinationPath $instRoot -Force
            # 가장 안쪽 jdk 디렉터리를 찾음
            $subdirs = Get-ChildItem -Path $instRoot -Directory | Sort-Object Name -Descending
            if ($subdirs -and $subdirs.Count -gt 0) { $extracted = Join-Path $instRoot $subdirs[0].Name }
        } catch {
            Write-Warning "Program Files에 압축을 풀 수 없음(권한 문제). 사용자 폴더에 설치를 시도합니다."
        }
        if (-not $extracted) {
            $userInst = Join-Path $env:LOCALAPPDATA 'Programs\Temurin'
            if (-not (Test-Path $userInst)) { New-Item -Path $userInst -ItemType Directory -Force | Out-Null }
            Expand-Archive -LiteralPath $out -DestinationPath $userInst -Force
            $subdirs = Get-ChildItem -Path $userInst -Directory | Sort-Object Name -Descending
            if ($subdirs -and $subdirs.Count -gt 0) { $extracted = Join-Path $userInst $subdirs[0].Name }
        }
        if ($extracted) { Write-Output "압축 해제 완료: $extracted" } else { Write-Warning "압축 해제 실패" }
        $javaHome = $extracted
    } else {
        Write-Warning "지원되지 않는 패키지 형식: $ext"
    }

    Write-Output "4) 설치 폴더 감지(일반적으로 'C:\Program Files\Eclipse Adoptium')..."
    # MSI 또는 ZIP 설치로 인해 $javaHome가 설정되었을 수 있음. 아직 설정되지 않았다면 일반 위치 검색
    if (-not $javaHome) {
        $instRoot = 'C:\Program Files\Eclipse Adoptium'
        $javaHome = $null
        if (Test-Path $instRoot) {
            $dirs = Get-ChildItem -Path $instRoot -Directory | Sort-Object Name -Descending
            if ($dirs -and $dirs.Count -gt 0) { $javaHome = Join-Path $instRoot $dirs[0].Name }
        }
        if (-not $javaHome) {
            $candidates = Get-ChildItem 'C:\Program Files' -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Adoptium|Temurin|Eclipse' }
            foreach ($c in $candidates) {
                $sub = Get-ChildItem $c.FullName -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'jdk|jdk-21|temurin' } | Sort-Object Name -Descending
                if ($sub -and $sub.Count -gt 0) { $javaHome = Join-Path $c.FullName $sub[0].Name; break }
            }
        }
    }

    Write-Output "감지된 JAVA_HOME: $javaHome"

    if ($javaHome) {
        Write-Output "5) 시스템 환경변수 JAVA_HOME 설정 및 Path에 추가(영구 적용)..."
        cmd /c "setx /M JAVA_HOME \"$javaHome\"" | Out-Null
        $machinePath = [Environment]::GetEnvironmentVariable('Path',[EnvironmentVariableTarget]::Machine)
        $javaBin = Join-Path $javaHome 'bin'
        if ($machinePath -notlike "*${javaBin}*") {
            $newPath = $machinePath + ';' + $javaBin
            # 길이 제한 주의: setx는 1024자 제한이 있으므로 매우 긴 PATH에서는 수동 설정 권장
            try {
                cmd /c "setx /M Path \"$newPath\"" | Out-Null
                Write-Output "Path 업데이트 성공(머신 수준). 새 셸을 열어 변경사항을 확인하세요."
            } catch {
                Write-Warning "setx를 사용한 PATH 업데이트에 실패했습니다. 수동으로 환경변수를 업데이트하세요."
            }
        } else {
            Write-Output "JAVA_HOME\bin은 이미 Path에 포함되어 있습니다."
        }
    } else {
        Write-Warning "설치 폴더를 자동으로 감지하지 못했습니다. 수동으로 설치 경로를 확인하십시오."
    }

    Write-Output "6) 설치 검증: java -version 출력(바로 보이지 않으면 새 셸을 여세요)"
    if ($javaHome) {
        $javaExe = Join-Path $javaHome 'bin\java.exe'
        if (Test-Path $javaExe) {
            & $javaExe -version
        } else {
            Write-Warning "예상 경로에 java 실행파일이 없습니다: $javaExe"
        }
    } else {
        Write-Output "java 명령을 직접 실행하여 버전을 확인하세요 (예: java -version)."
    }

    Write-Output "=== 스크립트 완료 ==="
} catch {
    Write-Error "오류 발생: $($_.Exception.Message)"
    Write-Output "다운로드 파일이 남아있다면 제거하려면 다음을 실행하세요: Remove-Item -Force $out"
}
