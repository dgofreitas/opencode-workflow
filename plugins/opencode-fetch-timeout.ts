// @ts-ignore
import type { Plugin } from "@opencode-ai/plugin";

interface FetchTimeoutConfig {
  timeoutMs?: number;
  enabled?: boolean;
}

const DEFAULT_TIMEOUT = 600000; // 10 minutos

function getTimeout(): number {
  const env = process.env.OPENCODE_FETCH_TIMEOUT_MS;
  if (env) {
    const parsed = parseInt(env, 10);
    if (!isNaN(parsed) && parsed > 0) return parsed;
  }
  return DEFAULT_TIMEOUT;
}

function log(msg: string) {
  const line = `[${new Date().toISOString()}] [fetch-timeout] ${msg}\n`;
  process.stderr.write(line);
}

/**
 * opencode-fetch-timeout
 * 
 * Plugin que intercepta requisições fetch aos provedores de IA e adiciona
 * um timeout via AbortController. Se o provedor não responder dentro do
 * limite, a requisição é abortada e retorna erro, permitindo que o
 * fallback plugin ou o próprio OpenCode tente outro modelo.
 */
export const FetchTimeoutPlugin: Plugin = async () => {

  const enabled = process.env.OPENCODE_FETCH_TIMEOUT_ENABLED !== "false";
  if (!enabled) {
    return {};
  }

  const timeoutMs = getTimeout();
  log(`Plugin inicializado. Timeout configurado: ${timeoutMs}ms`);

  // @ts-ignore
  const originalFetch = globalThis.fetch;
  if (!originalFetch) {
    log("AVISO: globalThis.fetch não encontrado. Plugin não será aplicado.");
    return {};
  }

  // @ts-ignore
  globalThis.fetch = async function (input: any, init?: any) {
    const url = typeof input === "string" ? input : input?.url || "";

    // Só intercepta chamadas a provedores de IA (evita quebrar outros serviços)
    const isProvider = url.includes("api") || url.includes("openai") || url.includes("openrouter") || url.includes("anthropic") || url.includes("ollama");
    
    if (!isProvider) {
      return originalFetch.call(this, input, init);
    }

    const controller = new AbortController();
    const id = setTimeout(() => {
      controller.abort();
      log(`TIMEOUT ABORTADO após ${timeoutMs}ms: ${url}`);
    }, timeoutMs);

    try {
      const response = await originalFetch.call(this, input, {
        ...(init || {}),
        signal: controller.signal,
      });
      clearTimeout(id);
      return response;
    } catch (err: any) {
      clearTimeout(id);
      if (err.name === "AbortError" || err.code === "ABORT_ERR") {
        const error = new Error(`[FetchTimeout] Provedor não respondeu em ${timeoutMs}ms. URL: ${url}`);
        // @ts-ignore
        error.code = "ETIMEDOUT";
        // @ts-ignore
        error.url = url;
        throw error;
      }
      throw err;
    }
  };

  log(`Fetch interceptado com timeout de ${timeoutMs}ms para chamadas de provedores.`);

  return {};
};

export default FetchTimeoutPlugin;
