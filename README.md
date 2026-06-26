# Cursor RTL Patch

תיקון תמיכת RTL (עברית/ערבית) ל‑Cursor IDE — מיישר נכון את תצוגת הצ'אט (פלט) ואת תיבת הקלט.
מבוסס על [claude-desktop-rtl-patch](https://github.com/shraga100/claude-desktop-rtl-patch) מאת shraga100.

## מה זה עושה

Cursor מציג טקסט עברי בצ'אט בכיוון שגוי: שורות שמתחילות במילה אנגלית (למשל `Frontend:`, `Backend:`) מזוהות כ‑LTR ומיושרות שמאלה, וסוגריים/נקודתיים סביב מונחים באנגלית יושבים בצד הלא נכון לקורא עברית.

ה‑patch מזריק CSS+JS לתוך `workbench.desktop.main.js` ש:

- כופה `direction: rtl` + `unicode-bidi: isolate` על פסקאות הפלט (במקום ה‑`plaintext` הטבעי שגרם לבעיה).
- מבודד מונחי אנגלית inline (בולד, קוד, קישורים) כך שסימני פיסוק סביבם נשארים בהקשר עברי.
- שומר בלוקי קוד כ‑LTR מלא.
- מוסיף `dir="auto"` לתיבת הקלט (Lexical) כך שגם הקלט תומך RTL.

## דרישות

- Windows + PowerShell
- Cursor מותקן בנתיב ברירת המחדל: `C:\Program Files\cursor`
- הרצה כ‑Administrator

## התקנה מהירה

פתח PowerShell כ‑Administrator והדבק:

```powershell
irm https://raw.githubusercontent.com/<USERNAME>/cursor-rtl-patch/main/cursor-rtl-patch.ps1 | iex
```

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
