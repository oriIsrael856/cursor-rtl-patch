#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Cursor IDE RTL Patcher v2 — Chat, Plans, MD Preview, Canvas
.DESCRIPTION
    Hebrew/Arabic RTL for Cursor markdown UIs.
    Uses direction:rtl + unicode-bidi:isolate (NOT plaintext).
    Covers: chat (.markdown-root), Plan editor (ProseMirror), MD preview
    (.markdown-body), and any .markdown-root in Canvas panels.
    Code blocks and Monaco source editors stay LTR.
    Run "2. Restore" before "1. Install" if upgrading from v1.
#>
$ErrorActionPreference = "Stop"
$PATCH_VERSION = "2"
$TARGET = "C:\Program Files\cursor\resources\app\out\vs\workbench\workbench.desktop.main.js"
$BACKUP = "$TARGET.rtl.bak"
$RTL_PAYLOAD = @'
;(function() {
    'use strict';
    if (typeof document === 'undefined') return;
    if (window.__cursorRtlPatched) return;
    window.__cursorRtlPatched = true;
    window.__cursorRtlVersion = '2';

    var BLOCK_SEL = 'p,li,h1,h2,h3,h4,h5,h6,ol,ul,blockquote,td,th';
    var INLINE_SEL = '[data-streamdown="strong"],strong,b,em,i,a,code';

    var ROOTS = [
      '.markdown-root',
      '.ui-plan-editor__body .ProseMirror',
      '.ui-plan-editor .markdown-root',
      '.markdown-body',
      '.markdown-preview',
      '[class*="markdown-preview"] .markdown-body',
      '[class*="canvas"] .markdown-root'
    ];

    function blockRules(root) {
      var parts = BLOCK_SEL.split(',');
      var sel = parts.map(function(s){ return root + ' ' + s; }).join(',');
      return sel + '{direction:rtl!important;text-align:right!important;' +
        'unicode-bidi:isolate!important;line-height:1.85;}';
    }

    function listRules(root) {
      return root + ' li{margin-bottom:.35em;}' +
        root + ' ol,' + root + ' ul{padding-right:1.4em;padding-left:0;}';
    }

    function inlineRules(root) {
      var parts = INLINE_SEL.split(',');
      var sel = parts.map(function(s){ return root + ' ' + s; }).join(',');
      return sel + '{unicode-bidi:isolate!important;}';
    }

    function inlineCodeRules(root) {
      return root + ' :not(pre) > code{direction:ltr!important;margin:0 .15em;' +
        'padding:0 .25em;border-radius:4px;}';
    }

    function preRules(root) {
      return root + ' pre,' + root + ' pre *{direction:ltr!important;' +
        'text-align:left!important;unicode-bidi:isolate!important;}';
    }

    var css = '';
    for (var i = 0; i < ROOTS.length; i++) {
      var root = ROOTS[i];
      css += blockRules(root);
      css += listRules(root);
      css += inlineRules(root);
      css += inlineCodeRules(root);
      css += preRules(root);
    }

    css += '.ui-plan-editor__body .ProseMirror{direction:rtl;text-align:right;}';

    var style = document.createElement('style');
    style.id = '__cursor_rtl_style';
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);

    var INPUT_SELECTOR = '.aislash-editor-input';
    function setAuto(el) {
      if (el.getAttribute('dir') !== 'auto') el.setAttribute('dir', 'auto');
    }
    function attachToInput(el) {
      if (el.__rtlAttached) return;
      el.__rtlAttached = true;
      function update() {
        setAuto(el);
        el.querySelectorAll('p, div').forEach(setAuto);
      }
      el.addEventListener('input', update);
      el.addEventListener('keyup', update);
      el.addEventListener('paste', function(){ setTimeout(update, 0); });
      update();
    }

    function attachPlanEditor(el) {
      if (el.__rtlPlanAttached) return;
      el.__rtlPlanAttached = true;
      var pm = el.querySelector('.ProseMirror');
      if (pm && pm.getAttribute('dir') !== 'rtl') pm.setAttribute('dir', 'rtl');
    }

    function scan() {
      try {
        document.querySelectorAll(INPUT_SELECTOR).forEach(attachToInput);
        document.querySelectorAll('.ui-plan-editor__body').forEach(attachPlanEditor);
      } catch (e) {}
    }

    new MutationObserver(function(m) {
      if (m.some(function(x){ return x.addedNodes.length; })) {
        clearTimeout(window.__rtlScanTimer);
        window.__rtlScanTimer = setTimeout(scan, 150);
      }
    }).observe(document.body || document.documentElement, { childList: true, subtree: true });

    scan();
    setTimeout(scan, 1000);
    setTimeout(scan, 3000);
    console.log('[CursorRTL v2] Patch active — chat, plans, MD preview, canvas markdown');
})();
'@

function Write-Step($msg)    { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "   !!  $msg" -ForegroundColor Yellow }

function Get-InstalledVersion {
    if (-not (Test-Path $TARGET)) { return $null }
    $content = [System.IO.File]::ReadAllText($TARGET, [System.Text.Encoding]::UTF8)
    if (-not $content.Contains('__cursorRtlPatched')) { return $null }
    if ($content -match "__cursorRtlVersion\s*=\s*'(\d+)'") { return $Matches[1] }
    return "1"
}

function Show-Version {
    Write-Step "Checking installed patch..."
    if (-not (Test-Path $TARGET)) {
        Write-Warn "Cursor workbench not found: $TARGET"
        return
    }
    $ver = Get-InstalledVersion
    if ($ver) {
        Write-Success "RTL patch installed (version $ver). Latest script: v$PATCH_VERSION"
    } else {
        Write-Warn "No RTL patch detected."
    }
    if (Test-Path $BACKUP) {
        Write-Success "Backup exists: $BACKUP"
    } else {
        Write-Warn "No backup file."
    }
}

function Install-Patch {
    Write-Step "Checking target file..."
    if (-not (Test-Path $TARGET)) { throw "File not found: $TARGET" }
    Write-Success "Found: $TARGET"
    $existing = Get-InstalledVersion
    if ($existing -and $existing -eq $PATCH_VERSION) {
        Write-Warn "v$PATCH_VERSION already installed. Re-run Restore first to reinstall."
        return
    }
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
    Write-Step "Injecting RTL payload v$PATCH_VERSION..."
    $content = [System.IO.File]::ReadAllText($TARGET, [System.Text.Encoding]::UTF8)
    if ($content.Contains('__cursorRtlPatched')) {
        Write-Warn "Existing patch found. Restoring backup first..."
        Copy-Item -LiteralPath $BACKUP -Destination $TARGET -Force
        $content = [System.IO.File]::ReadAllText($TARGET, [System.Text.Encoding]::UTF8)
    }
    $newContent = $RTL_PAYLOAD + "`n" + $content
    [System.IO.File]::WriteAllText($TARGET, $newContent, [System.Text.Encoding]::UTF8)
    Write-Success "Payload v$PATCH_VERSION injected."
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "   Patch v$PATCH_VERSION installed!" -ForegroundColor Green
    Write-Host "   Restart Cursor." -ForegroundColor Green
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
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "   Cursor RTL Patch v$PATCH_VERSION" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "  1. Install RTL Patch"             -ForegroundColor White
    Write-Host "  2. Restore Original"              -ForegroundColor White
    Write-Host "  3. Show installed version"        -ForegroundColor White
    Write-Host "  4. Exit"                          -ForegroundColor White
    Write-Host "====================================`n" -ForegroundColor Cyan
    $choice = Read-Host "Choose (1-4)"
    switch ($choice) {
        '1' { try { Install-Patch    } catch { Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red } }
        '2' { try { Restore-Original } catch { Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red } }
        '3' { try { Show-Version     } catch { Write-Host "`nError: $($_.Exception.Message)" -ForegroundColor Red } }
        '4' { Write-Host "Bye!" -ForegroundColor Gray; break }
        default { Write-Host "Invalid choice." -ForegroundColor Red }
    }
} while ($choice -ne '4')
