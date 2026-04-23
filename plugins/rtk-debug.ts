import type { Plugin } from "@opencode-ai/plugin"

export const RtkDebugPlugin: Plugin = async ({ $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      console.error("[rtk-debug] tool:", JSON.stringify(input?.tool), "args:", JSON.stringify(output?.args))
    },
  }
}
