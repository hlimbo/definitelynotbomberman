# Definitely Not Bomberman

[Rough Ideas](https://docs.google.com/document/d/1P4i41Mh9UhIbkjDY2ukQ7sIjr8ZSlzI-NxZsAi25rxE/edit?usp=sharing)

# Software Used
* [Godot 4.4](https://godotengine.org/download/archive/4.4-stable/)

# Credits
## Art
| Artist | Asset Link | License |
| ----------- | ----------- | ----------- |
| Buch | [The Field of the Floating Islands](https://opengameart.org/content/the-field-of-the-floating-islands) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| kenney | [Cursor Pack](https://kenney.nl/assets/cursor-pack)| [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| kenney | [Kenney Fonts](https://kenney.nl/assets/kenney-fonts) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| adamgda1199 | [Keyboard and Controller Icons Demo](https://adamgamer1111.itch.io/keyboard-and-controller-icons) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| craftpix.net | [Free Sky Backgrounds](https://free-game-assets.itch.io/free-sky-with-clouds-background-pixel-art-set) | [License](https://craftpix.net/file-licenses/) |
| mounirtohami | [Pixel Art GUI Elements](https://web.archive.org/web/20200922120712/https://mounirtohami.itch.io/pixel-art-gui-elements) | ... |
| ansimuz | [sunny-land-pixel-game-art](https://ansimuz.itch.io/sunny-land-pixel-game-art) | [CC0](https://creativecommons.org/public-domain/cc0/)


## Music
| Musician/Composer | Asset Link | License |
| ----------- | ----------- | ----------- |
| Nid | [game over sound](https://aoha-music.itch.io/game-over-bgm) |  Composer mentions "Feel free to use it!" |
| JDSherbert | [Pixel Explosions SFX Pack](https://jdsherbert.itch.io/pixel-explosions-sfx-pack) | https://jdsherbert.itch.io/pixel-explosions-sfx-pack |
| JDSherbert | [Ultimate UI SFX Pack](https://jdsherbert.itch.io/ultimate-ui-sfx-pack) | https://jdsherbert.itch.io/ultimate-ui-sfx-pack |
| Shapeforms Audio |  [ShapeForms Audio Free Sounds](https://shapeforms.itch.io/shapeforms-audio-free-sfx) | Royalty Free Sounds |
| doranarasi | [shmup-bgm-pack](https://doranarasi.itch.io/shmup-bgm-pack) | https://doranarasi.itch.io/shmup-bgm-pack |
| Nathan Gibson | [Universal UI Soundpack](https://cyrex-studios.itch.io/universal-ui-soundpack) | [CC by 4.0](https://creativecommons.org/licenses/by/4.0/) |
| congusbongus | [and the winner is](https://opengameart.org/content/and-the-winner-is) | [CC0](http://creativecommons.org/publicdomain/zero/1.0/) |

## Shaders I used for reference
* [Swirl Shader](https://godotshaders.com/shader/swirl-sink/)
* [Flipbook Shader](https://godotshaders.com/shader/flipbook-shader/)
* [Godot Sprite Shader](https://duongvituan.itch.io/godot-sprite-shader)
*  [The Book of Shaders](https://thebookofshaders.com/)

## Programming
* My friend Alan and me!

## Were there any LLMs used in the production?
LLMs like ChatGPT was used to create the following:
* Bomb Sprite
* Shadow Sprite underneath fox player character
* Boilerplate code for `Player.gd` (player controller) and `Bomb.gd` scripts. The rest were hand-coded and used LLM tooling like ChatGPT or Claude to plan, brainstorm, and verify ideas for correctness.


### What to put on front itch.io page

--- Use this copy to when publishing the game to itch.io
--- create gifs / screenshots for game for background images
--- create main screenshot to preview the game (capsule screenshot)

https://www.steamcapsule.com/guide

https://hedgiespresso.itch.io/itch-page-image-templates

https://www.youtube.com/watch?v=IS7bA7ep9qc




### Content on itch.io page to include

Made with - Godot

Genre - Action, Arcade, Survival

Tags - Action, Arcade, 2D, Topdown, Pixel Art, Single Player, Short, Godot, Indie, Survival

Average Session - about 10 minutes


Inputs: Keyboards and Mouse


Can you beat all the rooms before time runs out?

### Features

#### 4 Bomb Types (Add gifs per each one)
* Goo - slows down enemies hit by explosion
* Root - roots enemies down for X seconds hit by explosion
* Poison - deals damage over time for enemies hit by explosion
* Gravity - pulls enemies towards explosion's center

####  Bomb Auto Switcher
* Bomb auto-switches to the last bomb type you picked up - add gif to showcase this by running through a bomb pickup

* Use Scroll wheel to switch between different bomb types - (add gif of player cycling through different bomb types)

#### Random Enemy Generations
* Random enemy and wave generation per room
* As you progress through more rooms, different kinds of enemies appear

### 3 Enemy Types
* Noob Slime
* Ranger Slime
* Dasher Slime


### Background Info
* This was originally made during a 2 day game jam on July 2025 and was extended over the course of 2 months to continuously add features/polish/refinement to the game. Game serves mostly as a tech demo to discover what's possible in the Godot 4.4 game engine.

### Stretch Goals
* Add Root, Slow, Poison and Gravity visuals on enemies affected by these status effects
* Add dust particles as enemies move around. Enemies should hop around similar to how the bomb bounces
* Add shadows underneath enemies
* Implement a system to dynamically change the draw order layers of moving actors in the game. This will help keep
enemies appear in front of or behind the player to keep things visually consistent
* Draw different sprite for Ranger Slime
* Draw slime pellet for Ranger Slime and add line renderer to show pellet trajectory
* Add bomb spawn pickup animation - bomb pickups should land from the sky as if it was a care package
* Add a background random generator for adding mushrooms, rocks, grass to give each room more character
* Add a boss in the last room
* Add Forcefield Bomb
* Add falling tiles
* Add jumping
* Add Multiplayer

### Known Issues
* Audio on while playing web isn't the best quality due to link here: (It's a known issue on Godot Engine's end as of v4.4). Using the stream mode on web rather than samples as samples doesn't allow me to crossfade between the 2 audio tracks when transitioning between the menu music and bg music.
* Game Balance on Mobs -- needs further tweaking but that task is an infinite time sink