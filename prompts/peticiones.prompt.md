---
description: "Escanea el vault en busca de #agente_peticiones y ejecuta todas las instrucciones en bucle hasta resolverlas."
---

Activa el agente `vault-peticiones-orchestrator`.

**Uso**: escribe `/peticiones` (sin argumentos) para lanzar el ciclo completo.

Sigue exactamente el protocolo definido en el agente:
1. Escanea todo el vault buscando `#agente_peticiones`
2. Clasifica y ejecuta cada instrucción (delegando notas al agente `Obsidian Note Writer`)
3. Marca cada petición como `#peticion_completada` al resolverla
4. Repite el escaneo hasta que no queden ocurrencias
5. Presenta el informe final

No termines hasta que el re-escaneo confirme cero ocurrencias de `#agente_peticiones`.
