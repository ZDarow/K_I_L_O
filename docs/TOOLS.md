# Инструменты (Tools) Kilo

Инструменты — TypeScript-модули для Kilo Plugin SDK, доступные как
дополнительные функции в среде агента.

В текущей версии проекта инструменты отсутствуют. Все ранее
разработанные BLE-инструменты (ble-scan, gatt-to-yaml, hex-analyzer)
перемещены в `ble-backup/` для последующей доработки.

---

## Структура инструмента

Каждый инструмент располагается в `.kilo/tools/<name>.ts` и
экспортирует функцию с аннотацией `@tool`.

Пример:

```typescript
import { tool } from "@kilocode/plugin";

@tool({
  name: "my-tool",
  description: "Описание инструмента",
})
export async function myTool(param: string): Promise<string> {
  return `Hello, ${param}!`;
}
```

---

## Создание нового инструмента

1. Создай файл `.kilo/tools/<name>.ts`
2. Экспортируй функцию с декоратором `@tool`
3. Обнови `docs/TOOLS.md`
