# Skrbe Dev Container Features

Feature reutilizável para instalar o XCoder em qualquer Dev Container.

## Instalação

Use `ghcr.io/willfeerr/devcontainer-features/xcoder:1` no objeto `features` do seu `.devcontainer/devcontainer.json`.

Opções disponíveis:

- `permission`: `ask`, `auto-approve` ou `full-control`.
- `autoStart`: inicia o agente junto com o container.
- `xcoderRef`: branch, tag ou commit do XCoder.
- `browserlessRequired`: exige as credenciais Browserless para iniciar automaticamente.

As credenciais devem ser passadas em runtime por `containerEnv`: `SKRBE_BRIDGE_URL`, `SKRBE_BRIDGE_TOKEN`, `SKRBE_AGENT_ID`, `BROWSERLESS_URL` e `BROWSERLESS_TOKEN`.

A Feature instala o cliente Playwright exigido pelo XCoder, define `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` e conecta as tools de navegador ao Browserless por CDP. Nenhum navegador local é baixado.

Comandos instalados:

```bash
xcoder-feature-start
xcoder-feature-status
xcoder-feature-stop
```

Veja o exemplo completo em `examples/devcontainer.json`.
