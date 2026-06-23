name: validator
role: Validar notas generadas por la pipeline y asignar `pipeline_confidence`.
created: 2026-06-23
---

# Agente: Validator

## Propósito
- Ejecutar comprobaciones automáticas de calidad sobre una nota Markdown generada por el `writer`.
- Devolver un `validator_report` en formato JSON que incluye `pipeline_confidence`, `issues`, `fix_suggestions` y `passed`.

## Flujo
1. Recibe `note_path`, `note_text`, `frontmatter`, `candidate_links`, `top_sources`.
2. Invoca el prompt de revisión de calidad: `IA implementacion/Pipeline nutricion_salud_deporte/prompts/quality_review_prompt.md`.
3. Ejecuta comprobaciones adicionales (opcional): comprobación de status HTTP de URLs en `Fuentes` (si está permitido), verificación de DOI.
4. Devuelve `validator_report` y, si `passed=false` y `required_rewrites=true`, encola una intención de `writer` con `enforce_template=true` y `validation_errors`.

## Contrato - Entrada
- `task_id`, `note_path`, `note_text`, `frontmatter`, `candidate_links`, `top_sources`.

## Contrato - Salida
- `task_id`, `note_path`, `validator_report` (ver prompt para formato), `pipeline_confidence`.

## Notas
- El `validator` debe ser reproducible; los checks deben ser deterministas y explicar la razón de cada issue.
- Para problemas relativos a enlaces internos faltantes, sugerir reemplazos textuales exactos para facilitar que el `writer` aplique el parche.
 - El `validator` debe comprobar explícitamente que los `candidate_links` recomendados aparecen integrados en el cuerpo del texto (Resumen / Detalle / Interacciones) y no solamente en una sección tipo "Ver también" o en una lista al final.
	 - Si un enlace aparece únicamente en secciones auxiliares, el `validator` debe añadir la issue `links_in_see_also_only` y proporcionar la inserción inline sugerida (frase exacta con `[[Term]]`) o un parche de reemplazo.
	 - Estas comprobaciones deben ser deterministas y acompañadas de `fix_suggestions` precisas (snippet a insertar y la ubicación sugerida).
