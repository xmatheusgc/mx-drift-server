param([string]$Root=(Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$mxRoot=[IO.Path]::GetFullPath($Root)
$mxVendor=Join-Path $mxRoot 'resources\[vendor]'
[IO.Directory]::CreateDirectory($mxVendor) | Out-Null
$mxTemp=Join-Path $mxRoot ('development\runtime\deps-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($mxTemp) | Out-Null
$mxPackages=@(
    @{Name='oxmysql'; Url='https://github.com/overextended/oxmysql/releases/download/v2.14.3/oxmysql.zip'; Sha='F6DB8F612A36A8A75FCCDE300E8C4135696B5BBCA5770CD7F26458949E1F7872'; Folder='oxmysql'},
    @{Name='pma-voice'; Url='https://github.com/AvarianKnight/pma-voice/archive/refs/tags/v6.6.2.zip'; Sha='1D6380E04FD80DBE2F2733D6C62B97C50E5362E375E85AAADF5C462892CDEBE8'; Folder='pma-voice-6.6.2'}
)
foreach($mxPackage in $mxPackages){
    $mxTarget=Join-Path $mxVendor $mxPackage.Name
    if(Test-Path -LiteralPath $mxTarget){ Write-Output "$($mxPackage.Name) presente; confira development/dependencies.lock.json antes de atualizar"; continue }
    $mxZip=Join-Path $mxTemp ($mxPackage.Name+'.zip')
    Invoke-WebRequest -Uri $mxPackage.Url -OutFile $mxZip
    if((Get-FileHash -LiteralPath $mxZip -Algorithm SHA256).Hash -ne $mxPackage.Sha){throw "Checksum inválido: $($mxPackage.Name)"}
    $mxExtract=Join-Path $mxTemp $mxPackage.Name
    [IO.Compression.ZipFile]::ExtractToDirectory($mxZip,$mxExtract)
    Copy-Item -LiteralPath (Join-Path $mxExtract $mxPackage.Folder) -Destination $mxTarget -Recurse
    Write-Output "$($mxPackage.Name) instalado e hash conferido"
}
