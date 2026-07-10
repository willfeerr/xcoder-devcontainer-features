# Changelog

## 1.1.0 — 2026-07-10

- Instala o pacote canônico XCoder 0.5.0 a partir de ref imutável.
- Remove `patch-xcoder.mjs`, a cópia de `browser-worker.mjs` e o runtime paralelo em `/opt/xcoder-runtime`.
- Usa o suporte Browserless nativo do XCoder.
- Adiciona `browserMode=disabled|optional|required` e mantém `browserlessRequired` como compatibilidade.
- Registra versão e commit instalados em `/etc/xcoder/feature.env`.
- Melhora validação de PID, encerramento do grupo de processos e saída de status/doctor.
- Atualiza testes para garantir pacote único, doctor funcional e ausência de browser local baixado.
