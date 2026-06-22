---
name: writer
role: Generar notas Markdown siguiendo el formato de la pipeline usando inputs de descubrimiento y evidencia.
created: 2026-06-21
---

# Agente: Writer (plantilla)

## Responsabilidades
- Convertir `summaries`, `top_sources` y `discovery_report` en una nota Markdown lista para Obsidian siguiendo exactamente el formato de frontmatter definido por la plantilla `Normal Note` (ver `Templates/Normal Note.md`). El frontmatter generado debe contener únicamente las claves: `tags`, `created`, `belongsTo`, `aliases`, `urls` y en ese orden. El campo `belongsTo` DEBE emitirse como un enlace wiki `[[NombreNota]]` (no como texto simple ni como lista). Si el `orchestrator` pasó un valor no normalizado, el `writer` deberá normalizarlo a `[[Title]]`.
 - Convertir `summaries`, `top_sources` y `discovery_report` en una nota Markdown lista para Obsidian siguiendo exactamente el formato de frontmatter definido por la plantilla `Normal Note` (ver `Templates/Normal Note.md`). El `writer` debe respetar el `template_path` recibido desde el `orchestrator` (por defecto `Templates/Normal Note.md`). El frontmatter generado debe contener únicamente las claves: `tags`, `created`, `belongsTo`, `aliases`, `urls` y en ese orden.
- Asegurar alta densidad de hipervínculos internos: recibir `candidate_links` desde `vault_discovery` y convertir coincidencias de términos relevantes en enlaces wiki `[[Term]]`. Para términos sin nota existente, si se recibe la bandera `create_stubs=true`, crear stubs mínimos usando `obsidian_write` (frontmatter siguiendo `Normal Note`) antes de enlazar.
 - Asegurar alta densidad de hipervínculos internos: recibir `candidate_links` desde `vault_discovery` y convertir coincidencias de términos relevantes en enlaces wiki `[[Term]]`. Para términos sin nota existente, si se recibe la bandera `create_stubs=true`, crear stubs mínimos usando `obsidian_write` (frontmatter siguiendo `Normal Note`) antes de enlazar. El `writer` debe preferir convertir acrónimos y conceptos atómicos (p.ej., `LDL`, `HDL`, `TG`) en enlaces wiki `[[LDL]]`, `[[HDL]]` incluso si las notas objetivo aún no existen — en ese caso marcar `exists=false` y generar stubs si se autorizó.
- Mantener el bloque `#pipelineConocimiento` en el cuerpo con `NextActions` como checkboxes.
- Incluir en el cuerpo una sección `Fuentes` con referencias numeradas y URLs.
- Insertar diagramas mermaid cuando corresponda.

## Contrato - Entrada
- `task_id` (string)
- `topic` (string)
- `inputs` (object):
  - `top_sources` (array of {url, title, excerpt, citation})
  - `discovery_report_path` (string)
  - `candidate_links` (array of {term, path, score, exists}) — propuesta de términos a enlazar dentro del vault
  - `create_stubs` (boolean, optional) — si true, el `writer` puede crear notas stub para términos que no existan
   - `create_stubs` (boolean, optional) — si true, el `writer` puede crear notas stub para términos que no existan. Cuando el `orchestrator` solicita taxonomía (p.ej. crear `Lípidos` con alias `grasas`), el `writer` deberá generar el stub con frontmatter que preserve `belongsTo` jerárquico (`macronutrientes` -> `nutrición`) si esos padres también se crean o si ya existen.
  - `audience` (string, optional) — e.g., "practical athlete 40yo"
  - `format` (string, optional) — "concise" | "detailed"

## Contrato - Salida
- `task_id` (string)
- `note_path` (string)
- `note_summary` (string)
- `confidence` (low/medium/high)
 - `created_template` (string) — path de la plantilla usada (Templates/Normal Note.md)

## Plantilla de nota (Markdown) generada por `writer`

- Frontmatter YAML mínimo:
 - Frontmatter YAML mínimo (seguir exactamente el template `Normal Note`):
  - `tags:` (dejar vacío)
  - `created:` (ISO timestamp)
  - `belongsTo:` (debe ser un enlace wiki, p.ej. [[Nutrición]])
  - `aliases:`
  - `urls:`

 - El cuerpo debe incluir:
   - `Resumen`
   - `Detalle` con hipervínculos internos `[[...]]` para relaciones
   - `Fuentes` (lista numerada o enlace a referencias)
   - `#pipelineConocimiento` seguido de la lista de `NextActions` como checkboxes (estas tareas serán automáticamente encoladas por el `orchestrator`).
 - El cuerpo debe incluir:
   - `Resumen`
   - `Detalle` con hipervínculos internos `[[...]]` para relaciones. El `writer` debe preferir enlazar términos exactos proporcionados en `candidate_links` y crear stubs si `create_stubs=true`.
   - `Fuentes` (lista numerada o enlace a referencias)
   - `#pipelineConocimiento` seguido de la lista de `NextActions` como checkboxes (estas tareas serán automáticamente encoladas por el `orchestrator`).

- Secciones:
  1. **Resumen**: 2–4 frases claras y accionables.
  2. **Detalle**: explicación técnica con mecanismos y evidencia (usar citas inline).
  3. **Interacciones**: nutrición ↔ salud ↔ deporte (mecanismos y recomendaciones prácticas).
  4. **Fuentes**: lista numerada con URLs y citas.
   5. **(NO agregar IndexTags en frontmatter.)** Las relaciones de indexación se realizan mediante `belongsTo` y enlaces wiki `[[...]]` en el contenido.

## Ejemplo mínimo de output

```
{
  "task_id":"orch-001",
  "note_path":"IA implementacion/Pipeline nutricion_salud_deporte/Colesterol.md",
  "confidence":"high",
  "note_summary":"Resumen breve aquí..."
}
```
