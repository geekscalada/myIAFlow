---
mode: agent
description: Aplica un color personalizado a la ventana de VSCode para este workspace
---

Configura el archivo `.vscode/settings.json` en la raíz del workspace con los colores indicados por el usuario para diferenciar visualmente esta ventana de VSCode.

Personaliza las siguientes zonas de la UI:
- `titleBar.activeBackground` y `titleBar.inactiveBackground`
- `titleBar.activeForeground` y `titleBar.inactiveForeground`
- `activityBar.background` y `activityBar.foreground`
- `statusBar.background` y `statusBar.foreground`

Si el usuario no especifica un color, pregúntale cuál prefiere o propón uno representativo del proyecto.

Si `.vscode/settings.json` ya existe, añade o actualiza solo la sección `workbench.colorCustomizations` sin modificar el resto.
