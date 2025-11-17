# Script para copiar tilesets de Sector 4 a assets
# Ejecutar: .\copy_tilesets.ps1

Write-Host "Copiando tilesets del Sector 4..." -ForegroundColor Cyan

# Crear directorio de destino si no existe
$destDir = "assets\tiles\kenney_roguelike-rpg-pack"
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "✓ Directorio creado: $destDir" -ForegroundColor Green
}

# Archivos TSX necesarios
$tsxFiles = @(
    "out_vitage.tsx",
    "university.tsx",
    "cespedBest.tsx",
    "temple.tsx",
    "casas.tsx",
    "rio.tsx"
)

# Archivos PNG necesarios (tilesets)
$pngFiles = @(
    "Outside.png",
    "un_cuarto.png",
    "cespedBest.png",
    "temple-removebg-preview.png",
    "houses-removebg-preview.png",
    "rio-removebg-preview.png"
)

# Copiar archivos TSX
Write-Host "`nCopiando archivos TSX..." -ForegroundColor Yellow
foreach ($file in $tsxFiles) {
    $source = "C:\sector4-materials\kenney_roguelike-rpg-pack\$file"
    $dest = "$destDir\$file"
    
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $dest -Force
        Write-Host "✓ Copiado: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ No encontrado: $file" -ForegroundColor Red
    }
}

# Copiar archivos PNG
Write-Host "`nCopiando archivos PNG..." -ForegroundColor Yellow
foreach ($file in $pngFiles) {
    $source = "C:\sector4-materials\kenney_roguelike-rpg-pack\$file"
    $dest = "$destDir\$file"
    
    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $dest -Force
        Write-Host "✓ Copiado: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ No encontrado: $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Tilesets copiados exitosamente!" -ForegroundColor Green
Write-Host "Ahora necesitas actualizar las rutas en capitulo1.1.tmx" -ForegroundColor Cyan
