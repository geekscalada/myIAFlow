# Skill: Reference Linking for Documentation

Descripción
- Este documento describe el comportamiento que debe implementar el agente/skill encargado de añadir referencias bibliográficas en la documentación del repositorio.

Objetivo
- Al añadir referencias bibliográficas en archivos del repositorio, el agente debe intentar enlazar cada referencia con:
  - Un DOI resolvible usando https://doi.org/<DOI> cuando la referencia dispone de DOI.
  - La URL oficial de la guía o documento (WHO, USDA, EFSA, NHS, editoriales académicas) cuando aplique.

Reglas y prioridad
1. Si la referencia incluye un DOI válido, añadir el hipervínculo con el prefijo `https://doi.org/` apuntando al DOI.
2. Si no hay DOI, buscar la URL oficial del documento en el sitio del editor o la institución y usarla.
3. Evitar enlaces temporales o enlaces que apunten a un recurso con fecha de caducidad cuando exista un DOI o una URL canónica.
4. No incluir enlaces a PDFs privados detrás de paywalls a menos que sean abiertos y estables; en su lugar enlazar a la página del artículo/DOI.
5. Cuando el usuario lo solicite, exportar la bibliografía adicionalmente en formatos `BibTeX` o `RIS`.

Formato recomendado en Markdown
- Para un artículo con DOI: "Author et al. Título. Revista. Año. doi:[10.xxxx/xxxx](https://doi.org/10.xxxx/xxxx)"
- Para guías oficiales: "Organización. Título. Consultar: [https://example.org](https://example.org)"

Metadatos de la skill
- Nombre: reference_linking
- Versión: 1.0
- Autor: Equipo de documentación (auto-aplicable por agentes)
- Ubicación de referencia: `.github/skills/reference_linking/SKILL.md`

Notas para implementadores
- Los agentes deben priorizar enlaces DOI y URLs canónicas.
- Si el agente no encuentra un DOI automáticamente, puede sugerir referencias para revisión manual.
- Mantener registro en la salida del cambio indicando qué enlaces se añadieron y cómo fueron resueltos.

Ejemplo de uso
- Agente detecta una cita con DOI `10.1136/bmj.f6879` → sustituye/añade: `doi:[10.1136/bmj.f6879](https://doi.org/10.1136/bmj.f6879)`.

Cambio de preferencia
- Si se debe cambiar la política (p. ej., incluir PDFs directos), actualizar este archivo y notificar a los agentes que consulten esta skill antes de aplicar cambios.
