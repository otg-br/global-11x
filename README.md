<p align="center">
  <a href="https://postimg.cc/FkVHHTbg">
    <img src="https://i.postimg.cc/2yPbTJVJ/Chat-GPT-Image-17-de-ago-de-2026-08-31-17.png" alt="OTG Global 11x" width="100%" />
  </a>
</p>

<div align="center">

# OTG Global 11x

**Modern OpenTibia server base built on The Forgotten Server, focused on protocol 11.x, modular systems and customizable classic-style gameplay.**

[![Protocol](https://img.shields.io/badge/PROTOCOL-11.x-0d6efd?style=for-the-badge)](#protocol-and-classic-styles)
[![Engine](https://img.shields.io/badge/ENGINE-TFS%20Fork-212529?style=for-the-badge)](#about-the-project)
[![Client](https://img.shields.io/badge/CLIENT-OTC%20FULL-f97316?style=for-the-badge)](#client-configuration)
[![Repository size](https://img.shields.io/github/repo-size/otg-br/global?style=for-the-badge)](https://github.com/otg-br/global)
[![Issues](https://img.shields.io/github/issues/otg-br/global?style=for-the-badge)](https://github.com/otg-br/global/issues)

[Repository](https://github.com/otg-br/global) · [Issues](https://github.com/otg-br/global/issues) · [WhatsApp Support](https://chat.whatsapp.com/EWV3dVvS6nt1em7q23FGu7)

</div>

---

## About the Project

**OTG Global 11x** is a fork of **The Forgotten Server** maintained for the OpenTibia community.

Project focus:

- Stable and reviewed server base.
- Clean and maintainable code.
- No intentionally malicious modifications.
- Modern OpenTibia systems.
- Modular datapacks and gameplay rules.
- Support for modern and classic-looking experiences without changing the native network protocol.
- Continuous improvements, fixes and community contributions.

Supported modern systems include:

- Store System
- Imbuements
- Prey
- Market
- Trade NPC
- Charms
- Bestiary
- Additional systems provided by the project

---

## Protocol and Classic Styles

> [!IMPORTANT]
> **OTG Global uses protocol 11.x.**
>
> There is no native OTG protocol **7.4**, **7.6**, **8.0** or **8.6** build.
> Classic versions are reproduced through **datapack, gameplay and client-side visual adaptations** while server communication remains **11.x**.

This distinction is important.

A server configured to look and play like **7.4** or **8.6** is still an **OTG 11.x server internally**.

### How classic-style profiles work

To reproduce a classic version, adapt only layers responsible for gameplay and presentation.

| Layer | Can be adapted | Remains unchanged |
|---|---|---|
| Protocol | — | **11.x** |
| Monsters | Stats, attacks, loot, behavior | Server protocol |
| Spells | Formulas, requirements, cooldowns | Server protocol |
| Movement | Speed and gameplay rules | Server protocol |
| Items / sprites | Visual assets and definitions | Server protocol |
| Effects | Visual presentation | Server protocol |
| Interface / HUD | Classic or custom layout | Server protocol |
| Datapack | Quests, NPCs, monsters, spells and balance | Core network protocol |

### Example: creating a 7.4-style server

For a **7.4-style experience**, keep OTG running on **protocol 11.x** and adapt the desired gameplay profile:

1. Adjust monster files and behavior.
2. Adjust spell formulas, requirements and cooldowns.
3. Reproduce classic movement and combat rules where desired.
4. Use matching sprites, effects, items and client interface.
5. Adapt NPCs, quests, loot and balance.
6. Keep network protocol and OTG engine on **11.x**.

Same logic can be applied to **7.6**, **8.0**, **8.6** or another visual/gameplay profile.

**Classic style does not mean classic protocol.**

---

## Datapack Profiles

OTG can be organized around different content profiles while keeping same server protocol:

- **Native OTG / Global 11.x style**
- **Modern RealMap-style content**
- **8.6 visual and gameplay profile**
- **8.0 visual and gameplay profile**
- **7.6 visual and gameplay profile**
- **7.4 visual and gameplay profile**

These profiles should be treated as **content/presentation presets**, not separate protocol branches.

This approach allows project to preserve modern server infrastructure while reproducing older Tibia eras through data and client presentation.

---

## Client Configuration

When using **OTCv8 / OTC FULL**, required game features must be enabled in:

```text
/modules/game_features/features.lua
```

For magic effects handled with 16-bit IDs, enable:

```lua
g_game.enableFeature(GameMagicEffectU16)
```

Client and server feature flags must always match.

Incorrect feature configuration can cause packet parsing errors, invalid effect IDs or protocol desynchronization.

---

## Architecture Philosophy

OTG separates **protocol**, **gameplay** and **presentation**.

```text
OTG Engine / Protocol 11.x
          |
          +-- Datapack
          |     +-- Monsters
          |     +-- Spells
          |     +-- NPCs
          |     +-- Quests
          |     +-- Items / loot
          |     +-- Gameplay balance
          |
          +-- Client presentation
                +-- Sprites
                +-- Effects
                +-- Interface / HUD
                +-- Classic or modern visual style
```

This makes it possible to build different server identities without maintaining separate legacy protocol implementations.

---

## Highlights

- **Protocol 11.x** as project foundation.
- Based on **The Forgotten Server**.
- Modern server systems with classic-style customization.
- Datapack-driven gameplay profiles.
- OTC FULL visual customization.
- Classic 7.x / 8.x presentation without protocol downgrade.
- Community-focused development.
- Issue tracking and contribution workflow through GitHub.

---

## Getting Started

Clone repository:

```bash
git clone https://github.com/otg-br/global.git
cd global
```

Before starting a production server:

1. Review server configuration.
2. Configure database credentials.
3. Select or prepare desired datapack profile.
4. Configure matching client feature flags.
5. Verify monsters, spells, items and effects.
6. Test login, movement, combat and packet parsing.
7. Run server in a test environment before public deployment.

Build steps depend on operating system and project toolchain.

---

## Project Structure

Main customization areas generally include:

```text
data/
├── monsters/
├── npc/
├── scripts/
├── spells/
└── world/

modules/
└── game_features/
```

Exact folders may vary according to datapack and client organization.

When creating a classic-style profile, prefer changing **datapack and client presentation** before changing protocol code.

---

## Contributing

Bug reports, fixes and pull requests are welcome.

When reporting a problem, include:

- Clear description.
- Steps to reproduce.
- Expected behavior.
- Actual behavior.
- Relevant server logs.
- Client protocol/parser logs when applicable.
- Screenshots or videos when useful.
- Exact client and datapack profile used.

Keep pull requests focused and avoid unrelated changes in same PR.

---

## Issue Tracking

Use GitHub Issues for reproducible bugs, regressions and technical requests:

**https://github.com/otg-br/global/issues**

Avoid comments without technical information such as `+1`.

Useful reports help maintainers reproduce and fix issues faster.

---

## Community & Support

### WhatsApp

PT-BR: Para dúvidas e suporte da comunidade, entre no grupo:

**https://chat.whatsapp.com/EWV3dVvS6nt1em7q23FGu7**

EN: For community help and general support, join the WhatsApp group above.

---

## English Summary

<details>
<summary><strong>Open English project summary</strong></summary>

### OTG Global 11x

OTG Global is a **The Forgotten Server fork** designed around **protocol 11.x**.

The project can reproduce older Tibia experiences such as **7.4** or **8.6**, but these are **visual and gameplay adaptations**, not native protocol downgrades.

To create a classic profile, adjust:

- Monsters
- Spells
- Cooldowns
- Movement rules
- NPCs and quests
- Items and loot
- Sprites and effects
- Client interface / HUD
- Gameplay balance

The server still communicates using **protocol 11.x**.

This architecture allows OTG to keep modern infrastructure and systems while offering different classic or modern gameplay identities.

</details>

---

## Special Thanks

- Erick Nunes
- Johncore
- Leonardo Pereira
- worthdavi
- marson schneider
- LukST
- guibruxo
- Mateus Roberto
- OTG contributors
- OpenTibia community
- The Forgotten Server contributors

---

<div align="center">

**OTG Global 11x**

Modern engine. Protocol 11.x. Customizable gameplay.

</div>

