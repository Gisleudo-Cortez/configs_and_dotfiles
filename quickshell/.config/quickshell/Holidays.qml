pragma Singleton
import QtQuick

QtObject {
    id: root

    // { "YYYY-MM-DD": "Holiday name", ... }
    property var data: ({})
    property int _loadedYear: 0

    // Mossoró/RN municipal holidays (fixed dates, hardcoded)
    readonly property var _municipal: ({
        "06-30": "Morte de Lampião (Mossoró)",
        "09-30": "Aniversário de Mossoró"
    })

    function loadYear(year) {
        if (_loadedYear === year) return
        _loadedYear = year

        const combined = {}

        // Inject municipal
        for (const [md, name] of Object.entries(_municipal))
            combined[`${year}-${md}`] = name

        // Fetch national from nager.at
        const xhr = new XMLHttpRequest()
        xhr.open("GET", `https://date.nager.at/api/v3/publicholidays/${year}/BR`)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    const holidays = JSON.parse(xhr.responseText)
                    for (const h of holidays)
                        combined[h.date] = h.localName
                } catch (_) {}
            }
            root.data = combined
        }
        xhr.send()
    }
}
