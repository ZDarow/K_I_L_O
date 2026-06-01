import { tool } from "@kilocode/plugin"

export default tool({
  description: "Parse and analyze hex dump from BLE traffic",
  args: {
    hexData: tool.schema
      .string()
      .describe("Hex string or path to log file containing hex data"),
    format: tool.schema
      .string()
      .default("auto")
      .describe("Input format: auto | raw | btmon | btsnoop"),
  },
  async execute(args, context) {
    return `Hex analysis requested:\n` +
      `- Data length: ${args.hexData.length} chars\n` +
      `- Format: ${args.format}\n\n` +
      `Extracted bytes: ${args.hexData.replace(/[^0-9a-fA-F]/g, '').length / 2} bytes`
  },
})
