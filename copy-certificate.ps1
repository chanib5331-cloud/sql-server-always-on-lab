$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

function Assert-Ok($step) {
    if ($LASTEXITCODE -ne 0) { throw "Certificate copy failed: $step" }
}

New-Item -ItemType Directory -Force -Path ".\certs" -ErrorAction Stop | Out-Null
docker cp sql1:/var/opt/mssql/data/dbm_certificate.cer .\certs\
Assert-Ok "read .cer from sql1"
docker cp sql1:/var/opt/mssql/data/dbm_certificate.pvk .\certs\
Assert-Ok "read .pvk from sql1"
docker cp .\certs\dbm_certificate.cer sql2:/var/opt/mssql/data/
Assert-Ok "write .cer to sql2"
docker cp .\certs\dbm_certificate.pvk sql2:/var/opt/mssql/data/
Assert-Ok "write .pvk to sql2"
docker exec -u 0 sql2 bash -c "chown mssql /var/opt/mssql/data/dbm_certificate.*"
Assert-Ok "set file owner on sql2"
Write-Host "Certificate copied to sql2." -ForegroundColor Green
