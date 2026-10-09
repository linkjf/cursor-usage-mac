# Cursor Usage Menubar (Español)

App nativa de macOS para ver el **uso de API de Cursor** en la barra de menú — especialmente cuánto cupo **has usado** para modelos named (GPT, Claude, Opus).

Documentación principal en inglés: [README.md](README.md).

## Formato menu bar

`48% | 7/16` — API **usado** % | Tier Cursor usado (Agent, Composer, Grok, Auto) / Total usado

## Instalación

```bash
./scripts/install.sh
open ~/Applications/Cursor\ Usage\ Menubar.app
```

"Iniciar con el sistema" (Elementos de inicio) viene activado por defecto. Puedes desactivarlo en **Ajustes** del popover.

Para agentes, instalación paso a paso, verificación y desinstalación: ver [AGENTS.md](AGENTS.md) (en inglés).

## Privacidad

Solo lee tu token local de Cursor y consulta `cursor.com` / `api2.cursor.sh`. Ver [PRIVACY.md](PRIVACY.md).
