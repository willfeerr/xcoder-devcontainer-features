
# Skrbe XCoder (xcoder)

Instala o XCoder com cliente Playwright conectado a um Browserless remoto.

## Example Usage

```json
"features": {
    "ghcr.io/willfeerr/xcoder-devcontainer-features/xcoder:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| permission | Nível padrão de permissão do XCoder. Pode ser sobrescrito em runtime por SKRBE_PERMISSION. | string | ask |
| autoStart | Inicia o XCoder automaticamente quando o Dev Container iniciar. | boolean | true |
| xcoderRef | Branch, tag ou commit instalável do repositório willfeerr/xcoder. | string | release/install-without-build |
| browserlessRequired | Exige BROWSERLESS_URL e BROWSERLESS_TOKEN antes de iniciar o XCoder. | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/willfeerr/xcoder-devcontainer-features/blob/main/src/xcoder/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
