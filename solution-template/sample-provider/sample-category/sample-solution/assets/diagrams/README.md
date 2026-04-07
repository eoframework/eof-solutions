# Architecture Diagram

This directory contains the architecture diagram for this solution.

## Authoritative Guide

Read **`eof-tools/guidance/diagrams/DIAGRAMS.md`** before editing any diagram files.
It covers:
- How to derive provider-specific icon imports from `metadata.yml`
- EO brand standards (cluster colours, edge styles, layout direction)
- Draw.io vendor icon discovery (works for any vendor)
- Fallback rules when a specific icon doesn't exist

## Files in This Directory

| File | Purpose |
|------|---------|
| `architecture-diagram.drawio` | **Authoritative source** — edit this in Draw.io |
| `generate_diagram.py` | Python fallback script — used when Draw.io CLI is not available |
| `architecture-diagram.png` | Generated output — used in presentations and docs |
| `DIAGRAM_REQUIREMENTS.md` | Component spec for this solution — edit for your solution |
| `README.md` | This file |

## Generating the PNG

```bash
cd solutions/{provider}/{category}/{solution}/assets/diagrams
python3 /mnt/c/projects/wsl/eof-tools/utils/export_drawio.py
# Output: architecture-diagram.png
```

The exporter auto-detects the best available method — no configuration needed:
1. **Draw.io CLI** (Linux) — pixel-perfect match to the `.drawio` visual
2. **Draw.io desktop on Windows** (WSL) — pixel-perfect match, auto-detected
3. **`generate_diagram.py`** — fallback, always available, different visual style

## Editing the Diagram

1. Open `architecture-diagram.drawio` in Draw.io Desktop
2. Enable your vendor's icon pack: **More Shapes → [vendor] → Apply**
   - See DIAGRAMS.md "Draw.io with Vendor Icons" for shape discovery instructions
3. Edit the diagram
4. Regenerate the PNG:
   ```bash
   python3 /mnt/c/projects/wsl/eof-tools/utils/export_drawio.py
   ```

## Checklist

- [ ] `architecture-diagram.drawio` updated with solution architecture
- [ ] `DIAGRAM_REQUIREMENTS.md` updated with this solution's components
- [ ] PNG regenerated via `export_drawio.py` after any `.drawio` changes
- [ ] Diagram shows all major components and data flows
- [ ] Vendor-specific icons used where available
- [ ] EO brand cluster colours applied
