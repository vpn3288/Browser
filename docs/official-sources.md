# Official Sources

The optimizer uses two documentation layers:

1. Engine/upstream documentation, because most policy names come from Chromium
   or Mozilla.
2. Browser-brand documentation, because vendors add their own surfaces and may
   not support every upstream policy in the same way.

## Engine and upstream sources

- Chromium policy and extension administration:
  - https://chromeenterprise.google/policies/
  - https://www.chromium.org/administrators/configuring-policy-for-extensions/
- Mozilla Enterprise Policy Templates:
  - https://mozilla.github.io/policy-templates/
  - https://firefox-source-docs.mozilla.org/browser/enterprise/

## Browser brand sources

- Google Chrome Enterprise policy list:
  - https://chromeenterprise.google/policies/
- Microsoft Edge policy documentation:
  - https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/
- Brave policy and support documentation:
  - https://support.brave.app/
  - https://github.com/brave/brave-browser
- Opera Help:
  - https://help.opera.com/en/latest/
- Vivaldi Help:
  - https://help.vivaldi.com/desktop/
- Mozilla Firefox Enterprise:
  - https://mozilla.github.io/policy-templates/
- LibreWolf documentation:
  - https://librewolf.net/docs/settings/
  - https://librewolf.net/docs/faq/
- Zen Browser documentation and source:
  - https://docs.zen-browser.app/
  - https://github.com/zen-browser/desktop

## Important compatibility notes

- Chrome, Edge, Brave, Chromium, and Vivaldi share many Chromium policies, but
  brand-specific policies must be written under that browser's own policy root.
- Microsoft Edge has additional policies for first-run experience,
  recommendations, personalization reporting, startup boost, rewards, shopping,
  wallet checkout, sidebar, collections, workspaces, tracking prevention, and
  new tab content.
- Brave has additional policy names for Brave News, Rewards, Wallet, VPN, Talk,
  P3A, Web Discovery, and similar product features.
- Opera is Chromium-based, but Opera does not document the same Windows
  enterprise policy surface as Chrome and Edge. The toolkit therefore does not
  pretend Opera supports every Chrome registry policy. Opera cleanup is done
  through profile preferences where the setting is stable and observable.
- Firefox, LibreWolf, and Zen Browser are Gecko/Firefox-family browsers. They
  support Mozilla policy templates and profile preferences, but each browser
  has its own install directory and profile root.
- Opening bookmarks in a new foreground tab has an official Firefox-family
  preference. Chromium-family browsers do not expose an equivalent official
  enterprise policy for native bookmark bar clicks, so the toolkit reports that
  as unsupported instead of faking it.
