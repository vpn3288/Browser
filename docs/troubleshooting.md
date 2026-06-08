# Troubleshooting

## Extension force install still fails

On this machine, extension force-install policies are not currently configured.
The toolkit provides the correct policy writer, but extension entries are
disabled in `config/extensions.json` until you opt in to specific trusted
extensions.

For Chromium-family browsers, force install requires:

- A valid 32-character extension ID using letters `a` through `p`.
- A browser-compatible update URL:
  - Chrome/Chromium/Brave/Vivaldi:
    `https://clients2.google.com/service/update2/crx`
  - Microsoft Edge Add-ons:
    `https://edge.microsoft.com/extensionwebstorebase/v1/crx`
- A writable policy path under either:
  - `HKLM\SOFTWARE\Policies\<Vendor>\<Browser>`
  - `HKCU\SOFTWARE\Policies\<Vendor>\<Browser>`

For Firefox-family browsers, force install requires:

- A stable add-on ID.
- A valid HTTPS `.xpi` install URL.
- A writable `distribution\policies.json` under the browser install directory.

## Why policies could not be written in the current run

The current PowerShell process is not elevated. In addition, this machine has
`HKCU\SOFTWARE\Policies` locked so the current user has read-only access.
Because of that, the optimizer could not write HKCU policy keys for Chrome,
Chromium, Edge, Brave, or Vivaldi.

Use an elevated PowerShell window for machine-level policies:

```powershell
.\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1
```

Opening an elevated PowerShell window is not enough by itself if the command is
still launched from a non-elevated Codex process. Windows blocks lower-integrity
processes from driving higher-integrity windows. Paste or type the optimizer
command directly in the elevated PowerShell window.

For a dry run that does not change registry or profile files:

```powershell
.\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1 -DryRun
```

For a read-only verification snapshot:

```powershell
.\scripts\deployment\Verify-BrowserOptimization.ps1
```

For strict HKLM verification after an elevated run:

```powershell
.\scripts\deployment\Verify-BrowserOptimization.ps1 -RequireMachinePolicy
```

Then restart each browser and check the browser's policy page:

- Chrome: `chrome://policy`
- Chromium: `chrome://policy`
- Edge: `edge://policy`
- Brave: `brave://policy`
- Vivaldi: `vivaldi://policy`

## Browser is running

The optimizer skips direct profile file edits when a browser process is running.
This prevents corrupting JSON preference files while the browser owns them.
Close the browser fully, confirm no background processes remain, and run the
optimizer again.

## Bookmarks opening in a new tab

Firefox, LibreWolf, and Zen support this through Mozilla preferences:

- `browser.tabs.loadBookmarksInTabs = true`
- `browser.tabs.loadBookmarksInBackground = false`

Chrome, Chromium, Edge, Brave, Vivaldi, and Opera do not expose an official
enterprise policy that forces native bookmark-bar clicks to open in a new
foreground tab. The verifier reports this as unsupported instead of pretending
the setting exists.

## New tab blank page

Firefox-family browsers support disabling the new tab page through Mozilla
policy and preferences.

Chromium-family browsers can be configured with `NewTabPageLocation=about:blank`
where the browser accepts that policy. Chrome may ignore this policy on
unmanaged Windows devices; always verify on the browser's policy page after
restart.
