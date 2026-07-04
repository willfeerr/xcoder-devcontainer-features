import { copyFile, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const [packageRoot, workerSource] = process.argv.slice(2);

if (!packageRoot || !workerSource) {
  throw new Error("Uso: node patch-xcoder.mjs <package-root> <browser-worker.mjs>");
}

const distDir = path.join(packageRoot, "dist");

async function patchFile(filePath, transform) {
  const original = await readFile(filePath, "utf8");
  const patched = transform(original);
  if (patched === original) {
    throw new Error(`Nenhuma alteração foi aplicada em ${filePath}.`);
  }
  await writeFile(filePath, patched);
}

function replaceWorkerResolver(source, workerRelativeUrl) {
  let next = source;

  next = next.replace(
    /import \{ createRequire \} from ["']node:module["'];\nimport path from ["']node:path["'];/,
    'import { fileURLToPath } from "node:url";',
  );

  next = next.replace(
    /function resolveWorkerPath\(\) \{[\s\S]*?\n\}/,
    `function resolveWorkerPath() {\n    return fileURLToPath(new URL("${workerRelativeUrl}", import.meta.url));\n}`,
  );

  return next;
}

await copyFile(workerSource, path.join(distDir, "browser-worker.js"));

await patchFile(path.join(distDir, "browser-tools.js"), (source) => {
  let next = replaceWorkerResolver(source, "./browser-worker.js");
  next = next.replace(
    "Abre URL em Chromium, Firefox ou WebKit em worker isolado.",
    "Abre URL usando Playwright conectado ao Browserless remoto.",
  );
  next = next.replace(
    /Instale o navegador com:[^`\n]*/g,
    "Verifique BROWSERLESS_URL, BROWSERLESS_TOKEN e a conectividade com o Browserless remoto.",
  );
  return next;
});

await patchFile(path.join(distDir, "browser-record-tool.js"), (source) => {
  let next = replaceWorkerResolver(source, "./browser-worker.js");
  next = next.replace(
    "Grava vídeo WebM e trace de uma página animada, com rolagem automática e diagnóstico de console/rede.",
    "Grava vídeo WebM e trace usando o Browserless remoto, com diagnóstico de console/rede.",
  );
  return next;
});

const worker = await readFile(path.join(distDir, "browser-worker.js"), "utf8");
if (!worker.includes("connectOverCDP") || !worker.includes("BROWSERLESS_TOKEN")) {
  throw new Error("Worker Browserless inválido após instalação.");
}

console.log(`[xcoder-feature] Browserless aplicado em ${packageRoot}`);
