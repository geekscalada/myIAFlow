---
name: nombre_del_agente
role: breve descripción del rol
created: 2026-06-21
---

# Plantilla de agente

## Metadatos
- `name`: identificador único
- `role`: resumen de responsabilidades
- `version`: semántico opcional

## Responsabilidades
- Lista de responsabilidades (p.ej. "explorar notas existentes" o "buscar evidencia web sobre X").

## Contrato de entrada
- `task_id` (string)
- `topic` (string)
- `params` (objeto): {depth:int, max_sources:int, query:string}

## Contrato de salida
- `task_id` (string)
- `outputs`: objeto con campos específicos (p.ej. `sources`, `summary`, `snippets`)
- `confidence`: low/medium/high

## Herramientas permitidas
- `web_fetch`, `vault_read`, `obsidian_write`, `mermaid_render` (describir limitaciones)

## Ejemplo de uso
- Entrada:
  - `{"task_id":"t1","topic":"colesterol","params":{"max_sources":5}}`
- Salida esperada:
  - `{"task_id":"t1","outputs":{"sources":[...],"summary":"..."},"confidence":"medium"}`

## Notas operativas
- Respetar rate-limits y priorizar fuentes whitelist.
