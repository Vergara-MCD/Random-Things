$carpeta = "ruta"
$nombreBuscar = "Name1"
$nombreSerie = "Name2"
$modoPrueba = $false

$extensiones = @(".mkv", ".mp4", ".avi")
$nombreEscapado = [regex]::Escape($nombreBuscar)
$patrones = @(
    '[Ss]\d{1,2}[Ee](\d{1,3}(?:\.\d)?)',
    "$nombreEscapado\s+special\s+(\d{1,3}(?:\.\d)?)",
    "$nombreEscapado\s*-\s*(\d{1,3}(?:\.\d)?).*special",
    "$nombreEscapado\s+(\d{1,3}(?:\.\d)?)",
    "$nombreEscapado\s*-\s*(\d{1,3}(?:\.\d)?)",
    '\[(\d{1,3}(?:\.\d)?)\]',
    '\((\d{1,3}(?:\.\d)?)\)',
    '\b[Ee]p(?:isode)?\.?\s*(\d{1,3}(?:\.\d)?)\b'
'#\s*(\d{1,3}(?:\.\d)?)',            # <-- NUEVO: Captura el formato "#02"
    '\b[Ee](\d{1,3}(?:\.\d)?)\b'         # <-- NUEVO: Captura el formato "E01"

)

$archivos = Get-ChildItem -LiteralPath $carpeta -File | Where-Object { $extensiones -contains $_.Extension.ToLower() }
$sinCoincidencia = @()
$planRenombrado = @()

foreach ($archivo in $archivos) {
    $nombreBase = $archivo.BaseName -replace '_', ' '
    $numeroEncontrado = $null

    foreach ($patron in $patrones) {
        if ($nombreBase -match $patron) {
            $numeroEncontrado = $matches[1]
            break
        }
    }

    if ($null -eq $numeroEncontrado) {
        $sinCoincidencia += $archivo.Name
        continue
    }

    if ($numeroEncontrado -like "*.*") {
        $partes = $numeroEncontrado -split '\.'
        $numeroFormateado = "{0:D2}.{1}" -f [int]$partes[0], $partes[1]
    } else {
        $numeroFormateado = "{0:D2}" -f [int]$numeroEncontrado
    }

    $nuevoNombre = "$nombreSerie E$numeroFormateado$($archivo.Extension)"

    $planRenombrado += [PSCustomObject]@{
        Original = $archivo.Name
        Nuevo    = $nuevoNombre
        RutaOriginal = $archivo.FullName
    }
}

Write-Host "`n=== PLAN DE RENOMBRADO ===" -ForegroundColor Cyan
$planRenombrado | Sort-Object { [double]($_.Nuevo -replace '.*E([\d\.]+)\..*','$1') } | ForEach-Object {
    Write-Host "$($_.Original)  -->  $($_.Nuevo)"
}

if ($sinCoincidencia.Count -gt 0) {
    Write-Host "`n=== SIN COINCIDENCIA ===" -ForegroundColor Yellow
    $sinCoincidencia | ForEach-Object { Write-Host $_ }
}

$duplicados = $planRenombrado | Group-Object Nuevo | Where-Object { $_.Count -gt 1 }
if ($duplicados.Count -gt 0) {
    Write-Host "`n=== DUPLICADOS ===" -ForegroundColor Red
    $duplicados | ForEach-Object {
        Write-Host "El numero $($_.Name) se repite en:"
        $_.Group | ForEach-Object { Write-Host "  - $($_.Original)" }
    }
    Read-Host "`nPulsa Enter para salir"
    exit
}

if ($modoPrueba) {
    Write-Host "`n[MODO PRUEBA] Nada renombrado todavia." -ForegroundColor Green
} else {
    foreach ($item in $planRenombrado) {
        Rename-Item -LiteralPath $item.RutaOriginal -NewName $item.Nuevo
    }
    Write-Host "`nListo. $($planRenombrado.Count) archivos renombrados." -ForegroundColor Green
}

Read-Host "`nPulsa Enter para salir"