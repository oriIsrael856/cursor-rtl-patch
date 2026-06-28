#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Cursor IDE RTL Patcher (v3)
.DESCRIPTION
    Hebrew/Arabic RTL for Cursor chat OUTPUT (and input).
    v3 fixes: RTL on the markdown container itself (not only p/li), div
    wrappers from streamdown, deferred boot if document is not ready yet,
    and dir="rtl" on live .markdown-root nodes via MutationObserver.
    Run "2. Restore" first if an older patch is installed, then "1. Install".
#>
$ErrorActionPreference = "Stop"
$TARGET = "C:\Program Files\cursor\resources\app\out\vs\workbench\workbench.desktop.main.js"
$BACKUP = "$TARGET.rtl.bak"
$RTL_PAYLOAD = @'
;(function() {
    'use strict';

    function boot() {
        if (window.__cursorRtlPatched) return;
        if (typeof document === 'undefined' || !document.documentElement) return;
        window.__cursorRtlPatched = true;
        window.__cursorRtlVersion = '3';

        var BLOCK_SEL = 'p,li,h1,h2,h3,h4,h5,h6,ol,ul,blockquote,td,th,div';
        var INLINE_SEL = '[data-streamdown="strong"],strong,b,em,i,a,code';

        var ROOTS = [
            '.markdown-root',
            '.ui-markdown',
            '.ui-plan-editor__body .ProseMirror',
            '.ui-plan-editor .markdown-root',
            '.markdown-body',
            '.markdown-preview',
            '[class*="markdown-preview"] .markdown-body',
            '[class*="canvas"] .markdown-root'
        ];

        function rootRules(root) {
            return root + '{direction:rtl!important;text-align:right!important;' +
                'unicode-bidi:isolate!important;}';
        }

        function blockRules(root) {
            var parts = BLOCK_SEL.split(',');
            var sel = parts.map(function(s) { return root + ' ' + s; }).join(',');
            return sel + '{direction:rtl!important;text-align:right!important;' +
                'unicode-bidi:isolate!important;line-height:1.85;}';
        }

        function listRules(root) {
            return root + ' li{margin-bottom:.35em;}' +
                root + ' ol,' + root + ' ul{padding-right:1.4em;padding-left:0;}';
        }

        function inlineRules(root) {
            var parts = INLINE_SEL.split(',');
            var sel = parts.map(function(s) { return root + ' ' + s; }).join(',');
            return sel + '{unicode-bidi:isolate!important;}';
        }

        function inlineCodeRules(root) {
            return root + ' :not(pre) > code{direction:ltr!important;margin:0 .15em;' +
                'padding:0 .25em;border-radius:4px;unicode-bidi:isolate!important;}';
        }

        function preRules(root) {
            return root + ' pre,' + root + ' pre *,' +
                root + ' [data-streamdown="code-block"],' +
                root + ' [data-streamdown="code-block"] *,' +
                root + ' [data-streamdown="table-wrapper"] table{' +
                'direction:ltr!important;text-align:left!important;' +
                'unicode-bidi:isolate!important;}';
        }

        var css = '';
        for (var i = 0; i < ROOTS.length; i++) {
            var root = ROOTS[i];
            css += rootRules(root);
            css += blockRules(root);
            css += listRules(root);
            css += inlineRules(root);
            css += inlineCodeRules(root);
            css += preRules(root);
        }

        css += '.ui-plan-editor__body .ProseMirror{direction:rtl!important;text-align:right!important;}';

        var style = document.getElementById('__cursor_rtl_style');
        if (!style) {
            style = document.createElement('style');
            style.id = '__cursor_rtl_style';
            (document.head || document.documentElement).appendChild(style);
        }
        style.textContent = css;

        var INPUT_SELECTOR = '.aislash-editor-input';
        var MD_SELECTOR = '.markdown-root,.markdown-body,.ui-markdown';

        function setAuto(el) {
            if (el.getAttribute('dir') !== 'auto') el.setAttribute('dir', 'auto');
        }

        function setRtl(el) {
            if (el.getAttribute('dir') !== 'rtl') el.setAttribute('dir', 'rtl');
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
            el.addEventListener('paste', function() { setTimeout(update, 0); });
            update();
        }

        function attachMarkdown(el) {
            if (el.__rtlMdAttached) return;
            el.__rtlMdAttached = true;
            setRtl(el);
        }

        function attachPlanEditor(el) {
            if (el.__rtlPlanAttached) return;
            el.__rtlPlanAttached = true;
            var pm = el.querySelector('.ProseMirror');
            if (pm) setRtl(pm);
        }

        function scan() {
            try {
                document.querySelectorAll(INPUT_SELECTOR).forEach(attachToInput);
                document.querySelectorAll(MD_SELECTOR).forEach(attachMarkdown);
                document.querySelectorAll('.ui-plan-editor__body').forEach(attachPlanEditor);
            } catch (e) {}
        }

        new MutationObserver(function(m) {
            if (m.some(function(x) { return x.addedNodes.length; })) {
                clearTimeout(window.__rtlScanTimer);
                window.__rtlScanTimer = setTimeout(scan, 150);
            }
        }).observe(document.body || document.documentElement, { childList: true, subtree: true });

        scan();
        setTimeout(scan, 500);
        setTimeout(scan, 2000);
        setTimeout(scan, 5000);
        console.log('[CursorRTL v3] Patch active — container RTL + dir=rtl on markdown nodes');
    }

    boot();
    if (typeof window !== 'undefined') {
        if (typeof document !== 'undefined' && document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', boot);
        }
        window.addEventListener('load', boot);
        setTimeout(boot, 0);
        setTimeout(boot, 250);
    }
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
    Write-Host "   Patch v3 installed! Restart Cursor."   -ForegroundColor Green
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
    Write-Host "   Cursor RTL Patch (v3)"   -ForegroundColor Cyan
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
