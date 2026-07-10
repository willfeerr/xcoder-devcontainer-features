# Skrbe Dev Container Features

Feature reutilizável para instalar o XCoder em qualquer Dev Container.

## Instalação

Use `ghcr.io/willfeerr/xcoder-devcontainer-features/xcoder:1` no objeto `features` do seu `.devcontainer/devcontainer.json`.

Opções disponíveis:

- `permission`: `ask`, `auto-approve` ou `full-control`;
- `autoStart`: inicia o agente junto com o container;
- `xcoderRef`: tag ou commit imutável do XCoder;
- `browserMode`: `disabled`, `optional` ou `required`;
- `browserlessRequired`: compatibilidade legada; `true` equivale a `browserMode=required`.

As credenciais devem ser passadas em runtime por `containerEnv`: `SKRBE_BRIDGE_URL`, `SKRBE_BRIDGE_TOKEN` e `SKRBE_AGENT_ID`. Para navegador remoto, adicione `BROWSERLESS_URL` e `BROWSERLESS_TOKEN`.

A partir da Feature 1.1, o suporte Browserless é nativo no pacote XCoder. A Feature não copia `browser-worker`, não modifica arquivos compilados e não cria um segundo runtime com versões próprias de Playwright ou `ws`.

`browserMode=optional` é o padrão: filesystem, Git, busca e processos continuam disponíveis quando o browser remoto não está configurado. `required` impede o launcher de iniciar sem as credenciais Browserless.

Comandos instalados:

```bash
xcoder doctor
xcoder-feature-start
xcoder-feature-status
xcoder-feature-stop
```

O status informa versão/ref instalados e executa o doctor local. Veja o exemplo completo em `examples/devcontainer.json`.
