# KickNotes

KickNotes is a lightweight learning and reminder addon for **World of Warcraft** dungeons and raids. It shows a curated list of interrupts, stops, dispels, purges, and other mechanics worth paying attention to for the character you are currently playing.

KickNotes is deliberately **not** a real-time combat assistant. It does not inspect combat-log casts and shout which button to press. The goal is to tell you what matters when you enter an instance, help you learn it, and gradually get out of the way once the mechanics stick.

Current release: **0.3.1**  
WoW interface: **12.1 / 120100**

## Features

- Curated **Midnight Season 2** dungeon and raid reminders.
- Current-season content enabled by default.
- Class/spec-aware utility suggestions based on abilities known by the logged-in character.
- Type-aware friendly dispels for **Magic, Poison, Disease, and Curse** where the mechanic type has been verified.
- Separate **KICK / STOP / DISPEL / PURGE / WATCH** categories.
- **MUST STOP** highlighting for a deliberately small set of especially dangerous mechanics.
- Clear boss/trash distinction with configurable boss and warning colors.
- Full and compact **Mini** reminder layouts.
- One-click Full/Mini switch directly on the reminder window.
- Zip the window into a small draggable `KN` button.
- Optional auto-zip and start-collapsed behavior.
- Maximum window height with scrolling.
- Separate Full and Mini width, text size, opacity, and spacing settings.
- Per-character window position and Full/Mini state.
- Preview/test controls plus `/kn test <dungeon>`.
- Automatic show on supported instance entry and hide on exit.
- Account-wide learned-mechanics tracking across alts.

## Learned mechanics

KickNotes is intended to become *smaller* as you learn a dungeon.

**Right-click any mechanic row** to mark it learned. Learned mechanics are stored account-wide, so learning a mechanic on your Priest also counts when you log your Rogue, Monk, or another alt.

Learned rows can be configured to:

- **Dim** them, the default.
- **Hide** them completely.
- **Show normally** while retaining learned state.

The header shows how many currently filtered mechanics remain to learn, and learned rows get a `✓` marker when visible.

A typical workflow is:

1. Enter a supported dungeon or run `/kn test <name>`.
2. Keep the full reminder list visible while learning the dungeon.
3. Right-click mechanics once you are comfortable with them.
4. Leave learned mechanics dimmed for occasional reinforcement.
5. Switch learned mechanics to **Hide** once you want a very small list containing only things you still need to remember.

Learning state can be reset for the current instance or globally from **Options → KickNotes → Learning**.

## Installation

### Recommended: GitHub Releases

1. Open the repository's **Releases** page.
2. Download the latest file named similar to `KickNotes-0.3.1.zip`.
3. Extract it into:

   `World of Warcraft/_retail_/Interface/AddOns/`

4. Confirm the final path is:

   `Interface/AddOns/KickNotes/KickNotes.toc`

5. Start WoW or run `/reload` if the game is already open.

> **Do not use GitHub's automatic “Source code (zip)” download as the addon package.** That archive normally extracts to a repository-named folder such as `KickNotes-main`, which is not the release layout KickNotes expects. Use the attached release ZIP instead.

### Installing from source

For development, clone the repository and copy or symlink the repository root to:

`World of Warcraft/_retail_/Interface/AddOns/KickNotes`

The repository root contains `KickNotes.toc` directly.

## Commands

| Command | Description |
| --- | --- |
| `/kn` or `/kn help` | Show command help |
| `/kn options` | Open KickNotes settings |
| `/kn show` | Show the current reminder |
| `/kn hide` | Hide the reminder |
| `/kn toggle` | Toggle the reminder |
| `/kn zip` | Collapse to the `KN` button |
| `/kn unzip` | Restore the reminder |
| `/kn mini` | Use Mini mode for this character |
| `/kn full` | Use Full mode for this character |
| `/kn learning` | Show learning status |
| `/kn learning dim` | Dim learned mechanics |
| `/kn learning hide` | Hide learned mechanics |
| `/kn learning show` | Show learned mechanics normally |
| `/kn test <name>` | Preview a dungeon or raid, e.g. `/kn test ruby` |
| `/kn test next` | Preview the next bundled instance |
| `/kn test prev` | Preview the previous bundled instance |
| `/kn test list` | List available test content |
| `/kn reset` | Reset the reminder-window position |

## Data philosophy

KickNotes intentionally favors a **small, useful list** over dumping every interruptible spell in an instance onto the screen. Accuracy for current Mythic+ content is the priority.

Mechanics can be sorted by **Dungeon order** (the default) or by **Priority** in General settings.

`Essential`, `Important`, and `Optional` describe general reminder priority. `MUST STOP` is a separate, deliberately rarer severity marker for mechanics where a failed stop can cause deaths, severe group damage, or major pull failure. It is not intended to claim that every missed cast is a literal guaranteed wipe at every key level.

Friendly-dispel matching is conservative. If a debuff type has not been verified, KickNotes avoids confidently recommending an incorrect class ability.

Mechanic data and class capability logic are kept separate from the UI so they can be reviewed and improved independently.

## Reporting incorrect mechanics

Accuracy reports are extremely useful. When opening a GitHub issue, include as much of the following as possible:

- Dungeon or raid name.
- Mob or boss name.
- Spell/mechanic name.
- Your class and spec.
- What KickNotes currently recommends.
- What you believe it should recommend instead.
- A current Wowhead spell/guide link or other supporting source when available.
- A screenshot if the problem is visual.

For UI bugs, please also mention whether you were using **Full or Mini mode**, your KickNotes window scale, and anything that reliably reproduces the problem.

## Contributing

Pull requests are welcome, especially for:

- Verified current-season mechanic corrections.
- Class/spec utility corrections.
- UI bugs and accessibility improvements.
- Additional content packs that follow the same conservative data approach.

Please avoid adding speculative recommendations. If a mechanic's dispel type, interrupt behavior, or class interaction is uncertain, it is better for KickNotes to say less than to confidently teach the wrong thing.

## Repository layout

```text
KickNotes.toc       Addon metadata and load order
Core.lua            Saved variables, instance detection, commands, learning state
ClassTools.lua      Class/spec utility and dispel capability logic
Data_Season2.lua    Current Midnight Season 2 mechanic data
UI.lua              Reminder window, Full/Mini layouts, tooltips
Options.lua         Settings and preview UI
CHANGELOG.md        Release history
README.md           Project documentation
LICENSE             MIT License
```

## Release packaging

Official GitHub release archives should contain a single top-level `KickNotes/` directory so users can extract the ZIP directly into `Interface/AddOns/`.

Example:

```text
KickNotes-0.3.1.zip
└── KickNotes/
    ├── KickNotes.toc
    ├── Core.lua
    ├── ClassTools.lua
    ├── Data_Season2.lua
    ├── UI.lua
    ├── Options.lua
    ├── README.md
    ├── CHANGELOG.md
    └── LICENSE
```

Release history is maintained in [`CHANGELOG.md`](CHANGELOG.md).

## License

KickNotes is released under the **MIT License**. See [`LICENSE`](LICENSE) for the full license text.


## Development disclosure 

KickNotes was developed with AI-assisted programming, documentation, and project artwork. Addon behavior and mechanic data are reviewed and tested in-game.
