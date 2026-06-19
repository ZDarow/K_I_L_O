import { tool } from "@kilocode/plugin"

export default tool({
  description: "Convert GATT JSON discovery result to YAML profile",
  args: {
    jsonPath: tool.schema
      .string()
      .describe("Path to GATT JSON file (from gatt-discover)"),
  },
  async execute(args, context) {
    return `Convert ${args.jsonPath} to YAML...\n` +
      `Run: python3 -c "
import json, sys
with open('${args.jsonPath}') as f:
    data = json.load(f)
yaml_path = '${args.jsonPath}'.replace('.json', '.yaml')
with open(yaml_path, 'w') as out:
    out.write('# GATT Profile - ' + data['device'] + '\\n')
    out.write('# Recovered: ' + str(len(data['services'])) + ' services, ' + str(len(data['characteristics'])) + ' characteristics\\n\\n')
    out.write('device: ' + data['device'] + '\\n')
    out.write('services:\\n')
    for s in data['services']:
        out.write('  - {handle: ' + s['handle'] + ', uuid: ' + s['uuid'] + '}\\n')
    out.write('\\ncharacteristics:\\n')
    for c in data['characteristics']:
        out.write('  - {handle: ' + c['handle'] + ', uuid: ' + c['uuid'] + ', props: ' + c['properties'] + '}\\n')
print('YAML saved:', yaml_path)
"`
  },
})
