#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Cursor IDE RTL Patcher (final)
.DESCRIPTION
    Hebrew/Arabic RTL for Cursor chat OUTPUT (and input).
    IMPORTANT: This version uses direction:rtl + unicode-bidi:isolate.
    It does NOT use unicode-bidi:plaintext - plaintext forces each paragraph's
    direction from its first character, so lines starting with English
    (Frontend:, Backend:, Deploy:) were detected as LTR and pushed left.
    Targets the real container: .markdown-root . Inline English (strong/code/
    links) is isolated so colons and parentheses around them sit correctly for
    a Hebrew reader. Code blocks stay LTR.
    Run "2. Restore" first if an older patch is installed, then "1. Install".
#>
$ErrorActionPreference = "Stop"
$TARGET = "C:\Program Files\cursor\resources\app\out\vs\workbench\workbench.desktop.main.js"
$BACKUP = "$TARGET.rtl.bak"
$RTL_PAYLOAD = @'
;(function() {
    'use strict';
    if (typeof document === 'undefined') return;
    if (window.__cursorRtlPatched) return;
    window.__cursorRtlPatched = true;

    // ---- OUTPUT (chat messages): force RTL via CSS. NEVER plaintext. ----
    var css =
      '.markdown-root p,.markdown-root li,.markdown-root h1,.markdown-root h2,' +
      '.markdown-root h3,.markdown-root h4,.markdown-root h5,.markdown-root h6,' +
      '.markdown-root ol,.markdown-root ul,.markdown-root blockquote{' +
      '  direction:rtl!important;text-align:right!important;' +
      '  unicode-bidi:isolate!important;line-height:1.85;}' +
      '.markdown-root li{margin-bottom:.35em;}' +
      '.markdown-root ol,.markdown-root ul{padding-right:1.4em;padding-left:0;}' +
      // isolate inline English so surrounding colons/parens stay in Hebrew (RTL) context.
      // Cursor renders bold as <span data-streamdown="strong"> (not <strong>), so target both.
      '.markdown-root [data-streamdown="strong"],' +
      '.markdown-root strong,.markdown-root b,.markdown-root em,.markdown-root i,' +
      '.markdown-root a,.markdown-root code{unicode-bidi:isolate!important;}' +
      '.markdown-root :not(pre) > code{direction:ltr!important;margin:0 .15em;' +
      '  padding:0 .25em;border-radius:4px;}' +
      // code blocks stay full LTR
      '.markdown-root pre,.markdown-root pre *{direction:ltr!important;' +
      '  text-align:left!important;unicode-bidi:isolate!important;}';

    var style = document.createElement('style');
    style.id = '__cursor_rtl_style';
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);

    // ---- INPUT (chat box): Lexical contenteditable. Use dir="auto" (Cursor
    // never sets it on the input). This does NOT touch messages. ----
    var INPUT_SELECTOR = '.aislash-editor-input';
    function setAuto(el){ if (el.getAttribute('dir') !== 'auto') el.setAttribute('dir','auto'); }
    function attachToInput(el){
        if (el.__rtlAttached) return;
        el.__rtlAttached = true;
        function update(){ setAuto(el); el.querySelectorAll('p, div').forEach(setAuto); }
        el.addEventListener('input', update);
        el.addEventListener('keyup', update);
        el.addEventListener('paste', function(){ setTimeout(update, 0); });
        update();
    }
    function scan(){ try { document.querySelectorAll(INPUT_SELECTOR).forEach(attachToInput); } catch(e){} }

    new MutationObserver(function(m){
        if (m.some(function(x){ return x.addedNodes.length; })) {
            clearTimeout(window.__rtlScanTimer);
            window.__rtlScanTimer = setTimeout(scan, 150);
        }
    }).observe(document.body || document.documentElement, { childList: true, subtree: true });

    scan();
    setTimeout(scan, 1000);
    setTimeout(scan, 3000);
    console.log('[CursorRTL] Patch active (rtl+isolate, no plaintext)');
})();
'@
function Write-Step($msg)    { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "   !!  $msg" -ForegroundColor Yellow }
function Install-Patch {
    Write-Step "Checking target file..."
    if (-not (Test-Path $TARGET)) { throw "File not found: $TARGET" }
    Write-Success "Found: $TARGET"
    Write-Step "Stopping Cursor..."
    Get-Process -Name "cursor" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Success "Cursor stopped."
    Write-Step "Backing up..."
    if (-not (Test-Path $BACKUP)) {
        Copy-Item -LiteralPath $TARGET -Destination $BACKUP -Force
        Write-Success "Backup created: $BACKUP"
    } else {
        Write-Warn "Backup already exists, skipping."
    }
    Write-Step "Injecting RTL payload..."
    $content = [System.IO.File]::ReadAllText($TARGET, [System.Text.Encoding]::UTF8)
    if ($content.Contains('__cursorRtlPatched')) {
        Write-Warn "Already patched. Restoring backup first..."
        Copy-Item -LiteralPath $BACKUP -Destination $TARGET -Force
        $content = [System.IO.File]::ReadAllText($TARGET, [System.Text.Encoding]::UTF8)
    }
    $newContent = $RTL_PAYLOAD + "`n" + $content
    [System.IO.File]::WriteAllText($TARGET, $newContent, [System.Text.Encoding]::UTF8)
    Write-Success "Payload injected."
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "   Patch installed! Restart Cursor."      -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}
function Restore-Original {
    Write-Step "Restoring original..."
    if (-not (Test-Path $BACKUP)) { throw "No backup found at: $BACKUP" }
    Get-Process -Name "cursor" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Copy-Item -LiteralPath $BACKUP -Destination $TARGET -Force
    Write-Success "Restored. Restart Cursor."
}
do {
    Write-Host ""
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "   Cursor RTL Patch"          -ForegroundColor Cyan
    Write-Host "============================"  -ForegroundColor Cyan
    Write-Host "  1. Install RTL Patch"       -ForegroundColor White
    Write-Host "  2. Restore Original"        -ForegroundColor White
    Write-Host "  3. Exit"                    -ForegroundColor White
    Write-Host "============================`n" -ForegroundColor Cyan
    $choice = Read-Host "Choose (1-3)"
    switch ($choice) {
        '1' { try { Install-Patch    } catch { Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red } }
        '2' { try { Restore-Original } catch { Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red } }
        '3' { Write-Host "Bye!" -ForegroundColor Gray; break }
        default { Write-Host "Invalid choice." -ForegroundColor Red }
    }
} while ($choice -ne '3')
