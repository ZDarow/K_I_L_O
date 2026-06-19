# Frida JavaScript API — Cheatsheet

## Process & Module

| API | Description |
|-----|-------------|
| `Process.id` | PID |
| `Process.arch` | `arm64` / `ia32` / `x64` |
| `Process.platform` | `linux` / `windows` / `darwin` |
| `Process.pointerSize` | 4 or 8 |
| `Process.getCurrentThreadId()` | Current thread ID |
| `Process.enumerateModules()` | All loaded modules |
| `Process.findModuleByAddress(addr)` | Module containing addr |
| `Process.setExceptionHandler(cb)` | Catch crashes |
| `Module.load(name)` | Load library |
| `Module.findBaseAddress(name)` | Base of library |
| `Module.findExportByName(mod, exp)` | Export address |
| `Module.enumerateExports(mod, cb)` | All exports |
| `Module.enumerateImports(mod, cb)` | All imports |
| `Module.enumerateSymbols(mod, cb)` | All symbols |

## Memory

| API | Description |
|-----|-------------|
| `Memory.readByteArray(addr, size)` | Read bytes |
| `Memory.readUtf8String(addr [,size])` | Read string |
| `Memory.readCString(addr)` | Read null-terminated |
| `Memory.readPointer(addr)` | Read pointer |
| `Memory.readS8/U8/S16/U16/S32/U32/S64/U64(addr)` | Read int |
| `Memory.writeByteArray(addr, arr)` | Write bytes |
| `Memory.writeUtf8String(addr, str)` | Write string |
| `Memory.writePointer(addr, ptr)` | Write pointer |
| `Memory.alloc(size)` | Allocate memory |
| `Memory.copy(dst, src, size)` | Copy memory |
| `Memory.scan(addr, size, pattern, cb)` | Scan pattern |
| `Memory.scanSync(addr, size, pattern)` | Sync scan |
| `ptr(address)` | Create NativePointer |
| `ptr("0x1234")` | From string |

## Interceptor

| API | Description |
|-----|-------------|
| `Interceptor.attach(target, callbacks)` | Hook function |
| `Interceptor.replace(target, replacement)` | Replace function |
| `Interceptor.detachAll()` | Remove all hooks |
| `NativeFunction(ptr, retType, argTypes)` | Call native |
| `NativeCallback(func, retType, argTypes)` | Native callback |

### Callbacks
```javascript
{
  onEnter(args) {
    args[0] = ptr(0);  // modify
    this.context.x0;   // register value (arm64)
    this.retval;       // return value (before onLeave)
  },
  onLeave(retval) {
    retval.replace(ptr(0));  // modify return
  }
}
```

## Java (Android)

| API | Description |
|-----|-------------|
| `Java.perform(fn)` | Run in Java thread |
| `Java.performNow(fn)` | Run immediately |
| `Java.use(className)` | Get class wrapper |
| `Java.choose(className, cb)` | Find instances |
| `Java.enumerateLoadedClasses(cb)` | All loaded classes |
| `Java.enumerateClassLoaders(cb)` | All class loaders |
| `Java.array(type, arr)` | Create Java array |
| `Java.cast(obj, cls)` | Cast object |

### Java.use() — Instance methods
```javascript
var cls = Java.use("com.example.Klass");
cls.method.overload("int", "java.lang.String").implementation = function(a, b) { ... };
cls.method.overloads.forEach(function(o) { o.implementation = function() { ... }; });
cls.$init.overload("int").implementation = function(a) { ... };  // constructor
cls.$new();  // create instance
```

## ObjC (iOS)

| API | Description |
|-----|-------------|
| `ObjC.classes` | All registered classes |
| `ObjC.classes.ViewController` | Access class |
| `ObjC.enumerateLoadedClasses(cb)` | Enumerate |
| `ObjC.choose(cls, cb)` | Find instances |
| `ObjC.protocols` | All protocols |

```javascript
var cls = ObjC.classes.ViewController;
var method = cls["- someMethod:withArg:"];
Interceptor.attach(method.implementation, {
  onEnter(args) {
    // args[0] = self, args[1] = _cmd, args[2+] = params
  }
});
```

## Stalker

| API | Description |
|-----|-------------|
| `Stalker.follow(tid, options)` | Trace thread |
| `Stalker.unfollow(tid)` | Stop tracing |
| `Stalker.queueDumpCallback(cb)` | Queue callback |
| `Stalker.flush()` | Flush queue |
| `Stalker.invalidate(addr)` | Invalidate code |

Options:
```javascript
{
  events: { call: true, ret: false, exec: false, block: false, compile: false },
  onReceive(events) { /* process binary events */ },
  transform(iterator) { /* modify instruction stream at runtime */ }
}
```

## Socket & Communication

| API | Description |
|-----|-------------|
| `send(message [, data])` | Send JSON + optional blob to client |
| `recv(callback)` | Receive JSON from client |
| `recv(callback, options)` | With options |

Python client:
```python
import frida
session = frida.get_usb_device().attach("com.app")
script = session.create_script(src)
script.on('message', lambda msg, data: print(msg))
```

## Thread & Time

| API | Description |
|-----|-------------|
| `setTimeout(fn, ms)` | Delayed execution |
| `setInterval(fn, ms)` | Periodic execution |
| `clearTimeout(id)` | Cancel timeout |
| `clearInterval(id)` | Cancel interval |

## Socket API (new in Frida 16+)

```javascript
// TCP connect from inside target process
var sock = new Socket();
sock.connect({ address: "127.0.0.1", port: 9999 });
sock.on('data', function(data) { ... });
sock.write("hello");
```

## Gum API (low-level)

| API | Description |
|-----|-------------|
| `Gum.addBreakpoint(addr)` | Add breakpoint |
| `Gum.removeBreakpoint(addr)` | Remove |
| `Gum.memoryAccessMonitor.enable(ranges, cb)` | Watch memory access |
| `Gum.CodeWriter` | Dynamic code gen |
| `Gum.AddressSet` | Address range set |

## Patterns & Best Practices

### Safe hook pattern
```javascript
Java.perform(function() {
  try {
    var cls = Java.use("com.example.Target");
    cls.method.implementation = function() { ... };
  } catch (e) {
    console.warn("Hook failed: " + e);
  }
});
```

### Retry on class not loaded
```javascript
function hookWithRetry(className, fn, retries = 10) {
  Java.perform(function() {
    for (var i = 0; i < retries; i++) {
      try {
        Java.use(className);
        fn();
        return;
      } catch (e) {
        if (i === retries - 1) console.warn("Failed after " + retries + " retries");
      }
    }
  });
}
```

### Deferred hook (after class loads)
```javascript
Java.enumerateClassLoaders({
  onMatch: function(loader) {
    try {
      loader.findClass("com.example.LateClass");
      Java.classFactory.loader = loader;
      // now hook LateClass
    } catch (e) {}
  }
});
```

### ArrayBuffer to hex
```javascript
function buf2hex(buf) {
  return Array.prototype.map.call(
    new Uint8Array(buf), function(b) { return ('0' + b.toString(16)).slice(-2); }
  ).join('');
}
```
