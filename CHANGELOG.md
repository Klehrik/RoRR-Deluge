### v1.0.0
* Initial release

### v1.0.1
* Somehow managed to break it right before release so now it actually works.

### v1.0.2
* Fixed healing reduction not applying in subsequent runs (I forgot to initialize a variable).

### v1.0.3
* Made optimizations (to a few of my mods) to reduce load.
* Increased enemy move speed bonus to 30%.

### v1.0.4
* Fixed in-game text still saying +25%.

### v1.0.5
* Reverted enemy speed bonus to +25%.
    * I threw in the extra 5% almost idly, but it turned out to have (in my opinion) a noticable impact that I didn't really like.
* Health gained from leveling up is no longer subjected to the 50% "healing" reduction.
* Edited Victory result screen to display the difficulty name and icon.
    * Note: This does NOT save to the Run History or Highscores tab, and is just a visual at the very end.
* Victory count for each character on this difficulty is now kept track of in the Deluge window.

### v1.1.0
* Now actually selectable as a Difficulty option on the character select screen.
* "Healing" gained from progressing to the next stage is no longer subjected to the 50% healing reduction.
* Fixed variables not resetting properly when pressing "Try Again" after death (the following run would be easier for a bit).

### v1.1.1
* Fixed difficulty selection being ordered before Drizzle.

### v1.1.2
* Added selection sfx.