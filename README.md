# CloudBrowser CLI

The `cloudbrowser` CLI manages persistent Chrome browsers and their CDP or Live View links. It does not proxy browser traffic and it does not need to stay running after a link is created.

## Install

Install the CLI with the command for your operating system below. Full instructions: [CLI documentation](https://cloudbrowser.tv/docs/cli).

```bash
curl -fsSL https://cloudbrowser.tv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

Windows PowerShell:

```powershell
irm https://cloudbrowser.tv/install.ps1 | iex
```

Installers select amd64/arm64 and verify the release checksum before replacing the binary. No sudo is needed. Set `CLOUDBROWSER_VERSION=0.2.0` to pin a release and `CLOUDBROWSER_INSTALL_DIR` to choose another directory. Run the installer again to update. Scripts are public at the URLs above.

## Authenticate

Sign in through the browser with Auth0:

```bash
cloudbrowser auth login
cloudbrowser auth status
```

The CLI opens a loopback callback and stores the exchanged API credential in the per-user config directory with mode `0600` on Unix systems. CI and headless Agents can set `CLOUDBROWSER_API_KEY` instead.

## Create a browser and link

```bash
cloudbrowser create --name research
cloudbrowser links create br_123 --audience cdp --output url
```

The CDP URL can be used by Playwright, Playwright CLI, agent-browser, Puppeteer and other Chrome DevTools Protocol clients. Live View links are created with `--audience live-view`; they require account access and can be read-only or control links.

Lifecycle commands wait for completion by default. Use `--wait=false` when a script only needs the operation response; the operation remains an internal API detail and is not exposed as a CLI resource.
