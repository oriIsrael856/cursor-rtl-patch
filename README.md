# Cursor RTL Patch

תיקון תמיכת RTL (עברית/ערבית) ל‑Cursor IDE — מיישר נכון את תצוגת הצ'אט (פלט), עורך הקבצים (Monaco), ותיבת הקלט.
מבוסס על [claude-desktop-rtl-patch](https://github.com/shraga100/claude-desktop-rtl-patch) מאת shraga100.

## מה זה עושה

Cursor מציג טקסט עברי בצ'אט בכיוון שגוי: שורות שמתחילות במילה אנגלית (למשל `Frontend:`, `Backend:`) מזוהות כ‑LTR ומיושרות שמאלה, וסוגריים/נקודתיים סביב מונחים באנגלית יושבים בצד הלא נכון לקורא עברית.

ה‑patch מזריק CSS+JS לתוך `workbench.desktop.main.js` ו-RTL ל-Preview של `.md`:

- **צ'אט:** RTL על `.markdown-root` + `[data-streamdown="strong"]`; **טבלאות וקוד** נשארים LTR.
- **תיבת קלט:** `dir="rtl"` + CSS — הסמן מתחיל **מימין**, כתיבה זזה שמאלה.
- **Preview** (`Ctrl+Shift+V`): מסמך RTL מלא; טבלאות LTR בתוך המסמך.

**עורך מקור (Monaco):** VS Code/Cursor **לא** תומכים במסמך RTL מלא (מספרי שורות מימין + סמן מימין) — ניסיון CSS שובר את העורך. לקריאה/עריכה עברית: **Preview**.

## מה תוקן ב-v6

- **חיתוך משפטים** — הוסר `translateX` / `width:100%` על שורות Monaco (v5.1).
- **טבלאות** — `td`/`th` הוסרו מ-RTL; `[data-streamdown="table-wrapper"]` + `table` נשארים LTR.

## בדיקה מהירה — עורך Monaco (בלי patch)

פתח `SUMMARY.md` (או קובץ עם עברית), DevTools → Console:

```js
(()=>{const R=/[\u0590-\u05FF\u0600-\u06FF]/;let n=0;document.querySelectorAll('.monaco-editor .view-line').forEach(line=>{if(!R.test(line.textContent))return;n++;line.classList.add('cursor-rtl-line');const s=line.firstElementChild;if(s)s.setAttribute('dir','rtl');const area=(line.closest('.monaco-scrollable-element')||line.parentElement).getBoundingClientRect();let max=line.getBoundingClientRect().left;line.querySelectorAll('span').forEach(x=>{const r=x.getBoundingClientRect();if(r.width>0)max=Math.max(max,r.right);});const shift=Math.round(area.right-8-max);line.style.transform=shift>1?'translateX('+shift+'px)':'';});return{lines:n};})()
```

אמור להחזיר `{ lines: N }` עם N>0. אם `lines:0` — אין `.view-line` בעברית בטאב הפתוח.

## דרישות

- Windows + PowerShell
- Cursor מותקן בנתיב ברירת המחדל: `C:\Program Files\cursor`
- הרצה כ‑Administrator

## התקנה מהירה

פתח PowerShell כ‑Administrator והדבק:

```powershell
irm https://raw.githubusercontent.com/oriIsrael856/cursor-rtl-patch/refs/heads/main/cursor-rtl-patch.ps1 | iex
```

### או התקנה ידנית

1. הורד את `cursor-rtl-patch.ps1`.
2. פתח PowerShell כ‑Administrator בתיקייה שבה הקובץ.
3. הרץ: `.\cursor-rtl-patch.ps1`
4. בחר 1 (Install) — Cursor ייסגר, יותקן הפאץ', ו**Cursor יופעל מחדש אוטומטית**.

## הסרה

הרץ את הסקריפט שוב ובחר **2** (Restore). הוא משחזר מהגיבוי `workbench.desktop.main.js.rtl.bak`.

## הערות

- אחרי ה‑patch, Cursor עשוי להציג "Your Cursor installation appears to be corrupt" — זו בדיקת checksum של Cursor, לא תקלה אמיתית. אפשר ללחוץ "Don't show again".
- כל עדכון של Cursor דורס את הקובץ; פשוט הרץ שוב את ה‑patch אחרי עדכון.
- הסקריפט יוצר גיבוי אוטומטי בהתקנה הראשונה.

## קרדיט

מבוסס על העבודה של [shraga100/claude-desktop-rtl-patch](https://github.com/shraga100/claude-desktop-rtl-patch).

## רישיון

MIT
