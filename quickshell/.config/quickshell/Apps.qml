pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// App search for the launcher: fuzzy matching + frecency (launch counts that
// decay over ~2 weeks), persisted to ~/.local/state/quickshell/.../apps.json.
Singleton {
    id: root

    readonly property var entries: {
        const seen = {}
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && e.name && !seen[e.id] && (seen[e.id] = true))
    }

    FileView {
        path: Quickshell.statePath("apps.json")
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }
        JsonAdapter {
            id: store
            property var launches: ({})   // id -> { n, last (ms) }
        }
    }

    function frecency(id) {
        const r = store.launches[id]
        if (!r) return 0
        const days = (Date.now() - r.last) / 86400000
        return r.n * Math.pow(0.5, days / 14)
    }

    // Subsequence match. Rewards prefix, word starts and contiguous runs,
    // penalises skipped chars;
    // -1 when not every query char is found in order.
    function fuzzy(q, text) {
        if (!text || !text.length) return -1
        const t = String(text).toLowerCase()   // keywords/categories are lists
        if (t.startsWith(q)) return 100 + q.length
        let score = 0, ti = 0, run = 0
        for (const c of q) {
            const at = t.indexOf(c, ti)
            if (at < 0) return -1
            run = at === ti ? run + 1 : 0
            score += 1 + run * 2 + (at === 0 || " -_.".includes(t[at - 1]) ? 6 : 0) - (at - ti) * 0.5
            ti = at + 1
        }
        return score - (t.length - q.length) * 0.05
    }

    function search(query) {
        const q = query.trim().toLowerCase()
        if (!q) return entries.slice().sort((a, b) => frecency(b.id) - frecency(a.id) || a.name.localeCompare(b.name))
        const hits = []
        for (const e of entries) {
            const s = Math.max(fuzzy(q, e.name),
                               fuzzy(q, e.genericName) * 0.6,
                               fuzzy(q, e.keywords) * 0.4,
                               fuzzy(q, e.id) * 0.5)
            if (s > 0) hits.push({ e, s: s + frecency(e.id) * 3 })
        }
        return hits.sort((a, b) => b.s - a.s).map(h => h.e)
    }

    function launch(e, action) {
        const r = store.launches[e.id] ?? { n: 0, last: 0 }
        const launches = Object.assign({}, store.launches)
        launches[e.id] = { n: r.n * Math.pow(0.5, (Date.now() - r.last) / 86400000 / 14) + 1, last: Date.now() }
        store.launches = launches

        if (action) action.execute()
        else if (e.runInTerminal) Quickshell.execDetached(["kitty", "-e", ...e.command])
        else e.execute()
    }

    // Safe calculator: only digits/operators reach the evaluator.
    function calc(q) {
        const s = q.replace(/^=/, "").trim()
        if (!/^[\d\s+\-*/%^().]+$/.test(s) || !/\d/.test(s) || !/[+\-*/%^]/.test(s)) return null
        try {
            const v = Function(`"use strict"; return (${s.replace(/\^/g, "**")})`)()
            return typeof v === "number" && isFinite(v) ? String(+v.toPrecision(12)) : null
        } catch (e) { return null }
    }
}
