$ErrorActionPreference = "Continue"
$pw = "Lab_Passw0rd!2026"
Set-Location $PSScriptRoot

function Invoke-Sql($node, $file) {
    Write-Host ">> [$node] $file" -ForegroundColor Cyan
    docker exec $node /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $pw -C -b -i "/scripts/$file"
    if ($LASTEXITCODE -ne 0) { throw "Script $file failed on $node" }
}

function Wait-SqlReady($node) {
    Write-Host "Waiting for $node to accept connections..." -NoNewline
    for ($i = 0; $i -lt 60; $i++) {
        docker exec $node /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $pw -C -Q "SELECT 1" *> $null
        if ($LASTEXITCODE -eq 0) { Write-Host " ready"; return }
        Start-Sleep -Seconds 3; Write-Host "." -NoNewline
    }
    throw "$node did not start - check: docker logs $node"
}

# Start
docker compose up -d
if ($LASTEXITCODE -ne 0) { throw "docker compose failed - is Docker Desktop running?" }
Wait-SqlReady "sql1"
Wait-SqlReady "sql2"

# Logins
Invoke-Sql "sql1" "01_logins_ALL_NODES.sql"
Invoke-Sql "sql2" "01_logins_ALL_NODES.sql"
Invoke-Sql "sql1" "02_certificate_PRIMARY_sql1.sql"

# Certificate
& "$PSScriptRoot\copy-certificate.ps1"
Invoke-Sql "sql2" "03_certificate_SECONDARY_sql2.sql"

# AG
Invoke-Sql "sql1" "04_endpoint_ALL_NODES.sql"
Invoke-Sql "sql2" "04_endpoint_ALL_NODES.sql"
Invoke-Sql "sql1" "05_create_ag_PRIMARY_sql1.sql"
Invoke-Sql "sql2" "06_join_ag_SECONDARY_sql2.sql"
Invoke-Sql "sql1" "07_create_db_add_to_ag_PRIMARY_sql1.sql"

Start-Sleep -Seconds 10
Invoke-Sql "sql1" "08_ag_health_ANY_NODE.sql"

Write-Host ""
Write-Host "Done. Connect with SSMS: localhost,14331 (primary) and localhost,14332 (secondary), user sa." -ForegroundColor Green
Write-Host "Continue with scripts 09-16 (see README.md)." -ForegroundColor Green
