# Top bar plugin

Provides a `ShellSurface` for its UI and an exclusive `ShellWorkArea` for its
native reservation. The plugin reads layout preferences and declares its own
edge, thickness, selected outputs and fullscreen/overview visibility policy.
The date in its clock opens Flutter's localized calendar picker, which expands
from the clock edge and collapses when dismissed. It provides month and year
browsing, Today and close controls. Small dots under date numbers distinguish
official mainland China days off and make-up workdays for 2025–2027. The agenda
lists the same dates for the displayed month. Select a row to jump to its date.
The time opens the dashboard.
Checkout changes do not enter a candidate automatically. Select the local Top
Bar source in Plugins before building a candidate.
All platform access uses the public SDK. See [plugin development](../../docs/PLUGIN_DEVELOPMENT.md).
