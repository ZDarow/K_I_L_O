import { tool } from "@kilocode/plugin"

export default tool({
  description: "Capture live BLE traffic via btmon for N seconds",
  args: {
    duration: tool.schema
      .number()
      .default(10)
      .describe("Capture duration in seconds (default: 10)"),
    output: tool.schema
      .string()
      .default("/tmp/ble_capture.log")
      .describe("Output log file path"),
  },
  async execute(args, context) {
    const cmd = `timeout ${args.duration} btmon -T -w ${args.output} 2>/dev/null; echo "Capture saved to ${args.output}"`
    return cmd
  },
})
