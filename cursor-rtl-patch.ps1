#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Cursor IDE RTL Patcher (v7.1)
.DESCRIPTION
    v7.1: Hebrew tables — DOM column reverse (scaleX removed, it did not work).
    Run "2. Restore" first if an older patch is installed, then "1. Install".
#>
$ErrorActionPreference = "Stop"
$TARGET = "C:\Program Files\cursor\resources\app\out\vs\workbench\workbench.desktop.main.js"
$BACKUP = "$TARGET.rtl.bak"
$MD_PREVIEW = "C:\Program Files\cursor\resources\app\extensions\markdown-language-features\media\markdown.css"
$MD_PREVIEW_BACKUP = "$MD_PREVIEW.rtl.bak"
$RTL_PAYLOAD = @'
;(function() {
    'use strict';

    function boot() {
        if (window.__cursorRtlPatched) return;
        if (typeof document === 'undefined' || !document.documentElement) return;
        window.__cursorRtlPatched = true;
        window.__cursorRtlVersion = '7.1';

        var BLOCK_SEL = 'p,li,h1,h2,h3,h4,h5,h6,blockquote';
        var INLINE_SEL = '[data-streamdown="strong"],strong,b,em,i,a';
        var CODE_ISLAND_SEL = '[data-streamdown="code-block"],pre';
        var TABLE_SEL = '[data-streamdown="table-wrapper"],table';
        var SKIP_SEL = CODE_ISLAND_SEL + ',' + TABLE_SEL;

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

        function isRtlChar(c) {
            return (c >= 0x0590 && c <= 0x05FF) ||
                (c >= 0x0600 && c <= 0x06FF) ||
                (c >= 0x0750 && c <= 0x077F) ||
                (c >= 0x08A0 && c <= 0x08FF) ||
                (c >= 0xFB50 && c <= 0xFDFF) ||
                (c >= 0xFE70 && c <= 0xFEFF);
        }

        function isLatinChar(c) {
            return (c >= 0x0041 && c <= 0x005A) || (c >= 0x0061 && c <= 0x007A);
        }

        function analyzeText(text) {
            var hasRtl = false;
            var hasLatin = false;
            for (var i = 0; i < text.length; i++) {
                var c = text.charCodeAt(i);
                if (isRtlChar(c)) hasRtl = true;
                if (isLatinChar(c)) hasLatin = true;
                if (hasRtl && hasLatin) return 'mixed';
            }
            if (hasRtl) return 'rtl';
            return 'ltr';
        }

        function clearBidiAttrs(el) {
            el.removeAttribute('data-cursor-bidi');
            el.removeAttribute('data-cursor-base');
        }

        function applyBidi(el, text) {
            var kind = analyzeText(text);
            clearBidiAttrs(el);
            el.style.removeProperty('text-align');
            el.style.removeProperty('direction');
            if (kind === 'mixed') {
                el.setAttribute('data-cursor-bidi', 'mixed');
                el.setAttribute('dir', 'rtl');
                el.style.setProperty('text-align', 'right', 'important');
                el.style.setProperty('direction', 'rtl', 'important');
                return;
            }
            el.setAttribute('dir', kind);
        }

        function dirRules(root) {
            return root + ' [dir="ltr"]:not([data-cursor-bidi="mixed"]){direction:ltr!important;' +
                'text-align:left!important;unicode-bidi:isolate!important;line-height:1.85;}' +
                root + ' [dir="rtl"]:not([data-cursor-bidi="mixed"]){direction:rtl!important;' +
                'text-align:right!important;unicode-bidi:isolate!important;line-height:1.85;}' +
                root + ' [data-cursor-bidi="mixed"],' +
                root + ' [data-cursor-bidi="mixed"][dir="rtl"]{' +
                'direction:rtl!important;text-align:right!important;unicode-bidi:embed!important;' +
                'display:block!important;width:100%!important;line-height:1.85;}' +
                root + ' [data-cursor-bidi="mixed"]>div:not([data-streamdown="table-wrapper"]):not([data-streamdown="code-block"]):not([data-cursor-ltr-island]){' +
                'direction:rtl!important;text-align:right!important;unicode-bidi:embed!important;' +
                'width:100%!important;}';
        }

        function firstHeaderRow(table) {
            return table.querySelector('thead tr') || table.querySelector('tbody tr') || table.querySelector('tr');
        }

        function isColumnsLtrOrder(table) {
            var row = firstHeaderRow(table);
            if (!row || row.children.length < 2) return true;
            var first = row.children[0].getBoundingClientRect();
            var last = row.children[row.children.length - 1].getBoundingClientRect();
            return first.left < last.left;
        }

        function reverseAllRows(table) {
            table.querySelectorAll('tr').forEach(function(tr) {
                var cells = Array.prototype.slice.call(tr.children);
                if (cells.length < 2) return;
                for (var i = cells.length - 1; i >= 0; i--) tr.appendChild(cells[i]);
            });
        }

        function syncColumnOrder(table, rtl) {
            var ltr = isColumnsLtrOrder(table);
            if (rtl && ltr) reverseAllRows(table);
            else if (!rtl && !ltr) reverseAllRows(table);
        }

        function headerHasHebrew(table) {
            var row = firstHeaderRow(table);
            if (!row) return false;
            var cells = row.querySelectorAll('th, td');
            for (var i = 0; i < cells.length; i++) {
                var text = cells[i].textContent || '';
                for (var j = 0; j < text.length; j++) {
                    if (isRtlChar(text.charCodeAt(j))) return true;
                }
            }
            return false;
        }

        function codeIslandRules(root) {
            return root + ' [data-streamdown="code-block"],' +
                root + ' [data-cursor-ltr-island],' +
                root + ' pre{' +
                'direction:ltr!important;text-align:left!important;unicode-bidi:isolate!important;' +
                'display:block!important;width:100%!important;max-width:100%!important;}' +
                root + ' [data-cursor-bidi="mixed"] [data-streamdown="code-block"],' +
                root + ' [dir="rtl"] [data-streamdown="code-block"],' +
                root + ' [data-cursor-bidi="mixed"] pre,' +
                root + ' [dir="rtl"] pre{' +
                'direction:ltr!important;text-align:left!important;unicode-bidi:isolate!important;}';
        }

        function tableDirRules(root) {
            var rtlSel = root + ' table[data-cursor-table="rtl"],' +
                root + ' table.cursor-table-rtl,' +
                root + ' [data-streamdown="table-wrapper"][data-cursor-table="rtl"]';
            var rtlCell = rtlSel + ' th,' + rtlSel + ' td';
            var ltrSel = root + ' table[data-cursor-table="ltr"],' +
                root + ' [data-streamdown="table-wrapper"][data-cursor-table="ltr"]';
            var ltrCell = ltrSel + ' th,' + ltrSel + ' td';
            return root + ' [data-streamdown="table-wrapper"]{' +
                'overflow-x:auto!important;margin:1em 0!important;' +
                'display:block!important;width:100%!important;max-width:100%!important;}' +
                rtlSel + '{direction:rtl!important;}' +
                rtlCell + '{text-align:right!important;unicode-bidi:isolate!important;' +
                'transform:none!important;}' +
                ltrSel + '{direction:ltr!important;}' +
                ltrCell + '{text-align:left!important;unicode-bidi:isolate!important;' +
                'transform:none!important;}' +
                root + ' table{border-collapse:collapse!important;width:100%!important;table-layout:auto!important;}';
        }

        function listRules(root) {
            return root + ' li{margin-bottom:.35em;}' +
                root + ' [dir="ltr"] ol,' + root + ' [dir="ltr"] ul{' +
                'padding-left:1.4em;padding-right:0;}' +
                root + ' [dir="rtl"] ol,' + root + ' [dir="rtl"] ul,' +
                root + ' [data-cursor-bidi="mixed"] ol,' + root + ' [data-cursor-bidi="mixed"] ul{' +
                'padding-right:1.4em;padding-left:0;}';
        }

        function inlineRules(root) {
            var parts = INLINE_SEL.split(',');
            var sel = parts.map(function(s) { return root + ' ' + s; }).join(',');
            var mixed = parts.map(function(s) {
                return root + ' [data-cursor-bidi="mixed"] ' + s;
            }).join(',');
            return sel + '{unicode-bidi:isolate!important;}' +
                mixed + '{unicode-bidi:isolate!important;direction:ltr!important;}';
        }

        function inlineCodeRules(root) {
            return root + ' :not(pre) > code{direction:ltr!important;margin:0 .15em;' +
                'padding:0 .25em;border-radius:4px;unicode-bidi:isolate!important;}';
        }

        function preRules(root) {
            return root + ' pre,' + root + ' pre *,' +
                root + ' [data-streamdown="code-block"],' +
                root + ' [data-streamdown="code-block"] *{' +
                'direction:ltr!important;text-align:left!important;' +
                'unicode-bidi:isolate!important;white-space:pre!important;}';
        }

        var css = '';
        for (var i = 0; i < ROOTS.length; i++) {
            var root = ROOTS[i];
            css += dirRules(root);
            css += listRules(root);
            css += inlineRules(root);
            css += inlineCodeRules(root);
            css += codeIslandRules(root);
            css += tableDirRules(root);
            css += preRules(root);
        }

        css += '.ui-plan-editor__body .ProseMirror [dir="ltr"]{' +
            'direction:ltr!important;text-align:left!important;}' +
            '.ui-plan-editor__body .ProseMirror [dir="rtl"]:not([data-cursor-bidi="mixed"]){' +
            'direction:rtl!important;text-align:right!important;}' +
            '.ui-plan-editor__body .ProseMirror [data-cursor-bidi="mixed"]{' +
            'direction:rtl!important;text-align:right!important;unicode-bidi:embed!important;}';
        css += '.aislash-editor-input[dir="ltr"]:not([data-cursor-bidi="mixed"]),' +
            '.aislash-editor-input[dir="ltr"]:not([data-cursor-bidi="mixed"]) p{' +
            'direction:ltr!important;text-align:left!important;}' +
            '.aislash-editor-input[dir="rtl"]:not([data-cursor-bidi="mixed"]),' +
            '.aislash-editor-input[dir="rtl"]:not([data-cursor-bidi="mixed"]) p{' +
            'direction:rtl!important;text-align:right!important;}' +
            '.aislash-editor-input[data-cursor-bidi="mixed"],' +
            '.aislash-editor-input[data-cursor-bidi="mixed"] p{' +
            'direction:rtl!important;text-align:right!important;unicode-bidi:embed!important;}';

        var style = document.getElementById('__cursor_rtl_style');
        if (!style) {
            style = document.createElement('style');
            style.id = '__cursor_rtl_style';
            (document.head || document.documentElement).appendChild(style);
        }
        style.textContent = css;

        var INPUT_SELECTOR = '.aislash-editor-input';
        var MD_SELECTOR = '.markdown-root,.markdown-body,.ui-markdown';

        function shouldSkipBlock(el) {
            if (el.closest(CODE_ISLAND_SEL)) return true;
            if (el.closest(TABLE_SEL)) return true;
            if (el.matches && (el.matches(CODE_ISLAND_SEL) || el.matches(TABLE_SEL))) return true;
            if (el.querySelector && el.querySelector(CODE_ISLAND_SEL + ',' + TABLE_SEL)) return true;
            return false;
        }

        function protectCodeIslands(root) {
            (root || document).querySelectorAll(CODE_ISLAND_SEL).forEach(function(el) {
                clearBidiAttrs(el);
                el.setAttribute('dir', 'ltr');
                el.setAttribute('data-cursor-ltr-island', 'true');
                el.style.setProperty('direction', 'ltr', 'important');
                el.style.setProperty('text-align', 'left', 'important');
                el.querySelectorAll('div,p,span').forEach(function(c) {
                    if (c === el) return;
                    clearBidiAttrs(c);
                    c.removeAttribute('dir');
                    c.style.removeProperty('direction');
                    c.style.removeProperty('text-align');
                });
            });
        }

        function applyTableDir(target) {
            if (!target) return;
            var table = target.matches('table') ? target : target.querySelector('table');
            if (!table) return;
            var rtl = headerHasHebrew(table);
            var tableDir = rtl ? 'rtl' : 'ltr';
            target.removeAttribute('data-cursor-ltr-island');
            target.setAttribute('data-cursor-table', tableDir);
            target.classList.toggle('cursor-table-rtl', rtl);
            if (target !== table) {
                table.setAttribute('data-cursor-table', tableDir);
                table.classList.toggle('cursor-table-rtl', rtl);
            }
            table.setAttribute('dir', rtl ? 'rtl' : 'ltr');
            clearBidiAttrs(target);
            clearBidiAttrs(table);
            table.style.removeProperty('transform');
            syncColumnOrder(table, rtl);
            requestAnimationFrame(function() { syncColumnOrder(table, rtl); });
        }

        function watchTableTarget(target) {
            if (target.__cursorTableWatched) return;
            target.__cursorTableWatched = true;
            new MutationObserver(function() {
                clearTimeout(target.__cursorTableTimer);
                target.__cursorTableTimer = setTimeout(function() { applyTableDir(target); }, 30);
            }).observe(target, { childList: true, subtree: true, characterData: true, attributes: true });
        }

        function applyTableDirs(root) {
            var seen = new Set();
            var scope = root || document;
            function process(target) {
                if (!target || seen.has(target)) return;
                seen.add(target);
                watchTableTarget(target);
                applyTableDir(target);
            }
            scope.querySelectorAll('[data-streamdown="table-wrapper"]').forEach(process);
            scope.querySelectorAll('.markdown-root table, .markdown-body table, .ui-markdown table').forEach(function(table) {
                if (table.closest(CODE_ISLAND_SEL)) return;
                process(table.closest('[data-streamdown="table-wrapper"]') || table);
            });
        }

        function applyDirFromText(el) {
            var text = (el.textContent || '').replace(/\s+/g, ' ').trim();
            if (!text) {
                clearBidiAttrs(el);
                el.setAttribute('dir', 'ltr');
                return;
            }
            applyBidi(el, text);
            if (analyzeText(text) === 'mixed') {
                el.querySelectorAll('p,div').forEach(function(child) {
                    if (!child.closest(SKIP_SEL)) {
                        child.removeAttribute('dir');
                        child.removeAttribute('data-cursor-bidi');
                        child.removeAttribute('data-cursor-base');
                        child.style.removeProperty('text-align');
                        child.style.removeProperty('direction');
                    }
                });
            }
        }

        function applyBlockDir(el) {
            if (shouldSkipBlock(el)) return;
            var text = (el.textContent || '').replace(/\s+/g, ' ').trim();
            if (!text) return;
            applyBidi(el, text);
        }

        function attachToInput(el) {
            if (el.__rtlAttached) return;
            el.__rtlAttached = true;
            function update() { applyDirFromText(el); }
            el.addEventListener('input', update);
            el.addEventListener('keyup', update);
            el.addEventListener('paste', function() { setTimeout(update, 0); });
            update();
        }

        function attachMarkdown(el) {
            if (el.__rtlMdAttached) return;
            el.__rtlMdAttached = true;
            el.querySelectorAll(BLOCK_SEL).forEach(applyBlockDir);
        }

        function attachPlanEditor(el) {
            if (el.__rtlPlanAttached) return;
            el.__rtlPlanAttached = true;
            el.querySelectorAll(BLOCK_SEL).forEach(applyBlockDir);
        }

        function rescanBlocks() {
            try {
                document.querySelectorAll(MD_SELECTOR).forEach(function(el) {
                    el.querySelectorAll(BLOCK_SEL).forEach(applyBlockDir);
                    protectCodeIslands(el);
                    applyTableDirs(el);
                });
                document.querySelectorAll('.ui-plan-editor__body').forEach(function(el) {
                    el.querySelectorAll(BLOCK_SEL).forEach(applyBlockDir);
                    protectCodeIslands(el);
                    applyTableDirs(el);
                });
                protectCodeIslands(document);
                applyTableDirs(document);
            } catch (e) {}
        }

        function scan() {
            try {
                document.querySelectorAll(INPUT_SELECTOR).forEach(attachToInput);
                document.querySelectorAll(MD_SELECTOR).forEach(attachMarkdown);
                document.querySelectorAll('.ui-plan-editor__body').forEach(attachPlanEditor);
                rescanBlocks();
            } catch (e) {}
        }

        new MutationObserver(function(m) {
            if (m.some(function(x) { return x.addedNodes.length || x.type === 'characterData'; })) {
                clearTimeout(window.__rtlScanTimer);
                window.__rtlScanTimer = setTimeout(scan, 150);
            }
        }).observe(document.body || document.documentElement, { childList: true, subtree: true, characterData: true });

        scan();
        setTimeout(scan, 500);
        setTimeout(scan, 2000);
        setTimeout(scan, 5000);
        console.log('[CursorRTL v7.1] Hebrew tables=DOM column reverse');
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

$MD_PREVIEW_CSS = @'

/* __cursor_rtl_md_preview — Cursor RTL Patch v6.7 */
body p:dir(ltr), body li:dir(ltr), body h1:dir(ltr), body h2:dir(ltr),
body h3:dir(ltr), body h4:dir(ltr), body h5:dir(ltr), body h6:dir(ltr),
body blockquote:dir(ltr) {
	direction: ltr !important;
	text-align: left !important;
	unicode-bidi: isolate !important;
	line-height: 1.85;
}
body p:dir(rtl), body li:dir(rtl), body h1:dir(rtl), body h2:dir(rtl),
body h3:dir(rtl), body h4:dir(rtl), body h5:dir(rtl), body h6:dir(rtl),
body blockquote:dir(rtl) {
	direction: rtl !important;
	text-align: right !important;
	unicode-bidi: isolate !important;
	line-height: 1.85;
}
body p, body li, body h1, body h2, body h3, body h4, body h5, body h6,
body blockquote {
	unicode-bidi: plaintext;
}
body [data-streamdown="code-block"], body pre {
	direction: ltr !important;
	text-align: left !important;
	unicode-bidi: isolate !important;
	display: block !important;
	width: 100% !important;
	max-width: 100% !important;
}
body [data-streamdown="table-wrapper"] {
	overflow-x: auto !important;
	margin: 1em 0 !important;
	display: block !important;
	width: 100% !important;
}
body [data-streamdown="table-wrapper"]:has(thead th:first-child:dir(rtl)),
body [data-streamdown="table-wrapper"]:has(thead td:first-child:dir(rtl)),
body table:has(thead th:first-child:dir(rtl)) {
	direction: rtl !important;
}
body [data-streamdown="table-wrapper"] table,
body table {
	border-collapse: collapse !important;
	width: 100% !important;
}
body table thead th:dir(rtl), body table thead td:dir(rtl),
body table tr:first-child th:dir(rtl), body table tr:first-child td:dir(rtl) {
	direction: rtl !important;
	text-align: right !important;
}
body table:dir(rtl), body table:dir(rtl) th, body table:dir(rtl) td {
	direction: rtl !important;
	text-align: right !important;
	unicode-bidi: isolate !important;
}
body table:dir(ltr), body table:dir(ltr) th, body table:dir(ltr) td {
	direction: ltr !important;
	text-align: left !important;
	unicode-bidi: isolate !important;
}
body thead th, body thead td, body tr:first-child th, body tr:first-child td {
	unicode-bidi: plaintext;
}
body pre, body pre code {
	direction: ltr !important;
	text-align: left !important;
	unicode-bidi: isolate !important;
	white-space: pre !important;
}
body :not(pre) > code {
	direction: ltr !important;
	unicode-bidi: isolate !important;
}
body strong, body b, body em, body i, body a {
	unicode-bidi: isolate !important;
}
body [dir="ltr"] ol, body [dir="ltr"] ul { padding-left: 1.4em; padding-right: 0; }
body [dir="rtl"] ol, body [dir="rtl"] ul { padding-right: 1.4em; padding-left: 0; }
'@

function Write-Step($msg)    { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "   !!  $msg" -ForegroundColor Yellow }

function Get-CursorExe {
    $candidates = @(
        "C:\Program Files\cursor\Cursor.exe",
        "C:\Program Files\Cursor\Cursor.exe",
        (Join-Path $env:LOCALAPPDATA "Programs\cursor\Cursor.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\cursor\_\Cursor.exe")
    )
    foreach ($exe in $candidates) {
        if (Test-Path $exe) { return (Resolve-Path $exe).Path }
    }

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Cursor.exe",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Cursor.exe"
    )
    foreach ($reg in $regPaths) {
        if (-not (Test-Path $reg)) { continue }
        $exe = (Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue)."(default)"
        if ($exe -and (Test-Path $exe)) { return (Resolve-Path $exe).Path }
    }

    $searchRoots = @(
        (Join-Path $env:ProgramFiles "cursor"),
        (Join-Path $env:ProgramFiles "Cursor"),
        (Join-Path $env:LOCALAPPDATA "Programs\cursor")
    )
    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) { continue }
        $found = Get-ChildItem -Path $root -Filter "Cursor.exe" -Recurse -Depth 4 -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($found) { return $found.FullName }
    }

    throw "Cursor.exe not found. Tried:`n  " + ($candidates -join "`n  ")
}

function Start-CursorDetached {
    param([string]$ExePath)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ExePath
    $psi.UseShellExecute = $true
    $psi.WorkingDirectory = $env:USERPROFILE
    [void][System.Diagnostics.Process]::Start($psi)
}

function Restart-Cursor {
    $exe = Get-CursorExe
    Write-Step "Starting Cursor (detached from this terminal)..."
    try {
        Start-CursorDetached -ExePath $exe
    } catch {
        Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", "start", '""', "`"$exe`"") -WindowStyle Hidden
    }
    Write-Success "Cursor started: $exe"
    Write-Host "   >>  Safe to close this window. Ctrl+C here will NOT close Cursor." -ForegroundColor DarkGray
}

function Install-MdPreview {
    if (-not (Test-Path $MD_PREVIEW)) {
        Write-Warn "markdown.css not found, skipping Preview patch."
        return
    }
    Write-Step "Patching Markdown Preview CSS..."
    if (-not (Test-Path $MD_PREVIEW_BACKUP)) {
        Copy-Item -LiteralPath $MD_PREVIEW -Destination $MD_PREVIEW_BACKUP -Force
        Write-Success "Preview backup created."
    }
    $css = [System.IO.File]::ReadAllText($MD_PREVIEW, [System.Text.Encoding]::UTF8)
    if ($css -match '__cursor_rtl_md_preview') {
        $css = [System.IO.File]::ReadAllText($MD_PREVIEW_BACKUP, [System.Text.Encoding]::UTF8)
    }
    $css = $css.TrimEnd() + "`n" + $MD_PREVIEW_CSS + "`n"
    [System.IO.File]::WriteAllText($MD_PREVIEW, $css, [System.Text.Encoding]::UTF8)
    Write-Success "Markdown Preview RTL patched (tables stay LTR)."
}

function Restore-MdPreview {
    if (-not (Test-Path $MD_PREVIEW_BACKUP)) { return }
    Write-Step "Restoring Markdown Preview CSS..."
    Copy-Item -LiteralPath $MD_PREVIEW_BACKUP -Destination $MD_PREVIEW -Force
    Write-Success "Markdown Preview restored."
}

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
    Write-Success "Workbench payload injected."
    Install-MdPreview
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Patch v7.1 installed!"               -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Restart-Cursor
}

function Restore-Original {
    Write-Step "Restoring original..."
    if (-not (Test-Path $BACKUP)) { throw "No backup found at: $BACKUP" }
    Get-Process -Name "cursor" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Copy-Item -LiteralPath $BACKUP -Destination $TARGET -Force
    Restore-MdPreview
    Write-Success "Restored. Restart Cursor."
}

do {
    Write-Host ""
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "   Cursor RTL Patch (v7.1)"  -ForegroundColor Cyan
    Write-Host "============================"  -ForegroundColor Cyan
    Write-Host "  Script: $PSCommandPath"     -ForegroundColor DarkGray
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
