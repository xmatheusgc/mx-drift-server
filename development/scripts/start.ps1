param([string]$FxServer='C:\FiveM\drift-server\server\FXServer.exe',[ValidateSet('development','production')][string]$Profile='development')
$ErrorActionPreference='Stop'
$mxRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if(-not(Test-Path -LiteralPath (Join-Path $mxRoot 'config\secrets.local.cfg'))){throw 'Copie config/secrets.cfg.example para config/secrets.local.cfg e preencha chave e credencial dedicada'}
Push-Location -LiteralPath $mxRoot
try{ & $FxServer +set onesync on +exec "config/$Profile.cfg" }finally{Pop-Location}
