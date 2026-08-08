$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$readmePath = Join-Path $repoRoot "README.md"
$metaPath = Join-Path $repoRoot "meta"
$startMarker = "<!-- GIF-GALLERY:START -->"
$endMarker = "<!-- GIF-GALLERY:END -->"

if (-not (Test-Path -LiteralPath $readmePath)) {
    throw "README.md was not found."
}

if (-not (Test-Path -LiteralPath $metaPath)) {
    throw "The meta folder was not found."
}

$gifFiles = Get-ChildItem -LiteralPath $metaPath -File -Filter "*.gif" |
    Sort-Object {
        if ($_.BaseName -match "\d+") {
            [int]$Matches[0]
        }
        else {
            [int]::MaxValue
        }
    }, Name

$galleryLines = New-Object System.Collections.Generic.List[string]
$galleryLines.Add($startMarker)

if ($gifFiles.Count -eq 0) {
    $galleryLines.Add("")
    $galleryLines.Add("No GIF files found in `meta`.")
    $galleryLines.Add("")
}
else {
    $galleryLines.Add("<table>")
    $gifNumber = 1

    for ($i = 0; $i -lt $gifFiles.Count; $i += 3) {
        $galleryLines.Add("  <tr>")

        foreach ($file in $gifFiles[$i..([Math]::Min($i + 2, $gifFiles.Count - 1))]) {
            $src = "meta/" + [System.Uri]::EscapeDataString($file.Name)
            $galleryLines.Add("    <td align=`"center`" width=`"180`"><img src=`"$src`" alt=`"Profile GIF $gifNumber`" width=`"170`"></td>")
            $gifNumber++
        }

        $galleryLines.Add("  </tr>")
    }

    $galleryLines.Add("</table>")
}

$galleryLines.Add($endMarker)
$gallery = $galleryLines -join [Environment]::NewLine

$readme = Get-Content -Raw -LiteralPath $readmePath
$pattern = [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
$options = [System.Text.RegularExpressions.RegexOptions]::Singleline

if (-not [regex]::IsMatch($readme, $pattern, $options)) {
    throw "GIF gallery markers were not found in README.md."
}

$updatedReadme = [regex]::Replace($readme, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $gallery }, $options)
[System.IO.File]::WriteAllText($readmePath, $updatedReadme, [System.Text.UTF8Encoding]::new($false))

Write-Host "Updated README.md with $($gifFiles.Count) GIF files."
