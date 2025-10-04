# 관리자 권한으로 실행하세요.
$ErrorActionPreference = 'Stop'
$javaHome = 'C:\Users\teddy\AppData\Local\Programs\Temurin\jdk-21.0.8+9'
Write-Output "Setting Machine JAVA_HOME to: $javaHome"
[Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHome, 'Machine')
$machinePath = [Environment]::GetEnvironmentVariable('Path','Machine')
if ($machinePath -notlike "*$javaHome\\bin*") {
    $newPath = $machinePath + ';' + ($javaHome + '\\bin')
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
    Write-Output 'Updated Machine Path'
} else {
    Write-Output 'Machine Path already contains JAVA_HOME bin'
}
Write-Output 'Verifying java -version from new JAVA_HOME...'
& (Join-Path $javaHome 'bin\\java.exe') -version
Write-Output 'Done'