# Whiskerwood-Mods

To download mods, clone this repository or download the ZIP from the green "Code" button and extract it somewhere.

> [!IMPORTANT]
> Do not submit crash or bug reports to the developers when using mods. Make sure you can reproduce the issue without mods installed first!

## Official Mod Support

#### Installation

Copy each mod's folder to `%localappdata/Whiskerwood/Saved/mods` and launch game.

### Mods

[Camera Tweaks](Official/CameraTweaks/) - Tweaks the camera settings. Hold Shift to pan faster

[Copper Slides](Official/CopperSlides/) - Changes the 

[Dump Data Tables](Official/DumpDataTables/) - Dumps all moddable data tables to `%localappdata/Whiskerwood/Saved/Logs`

[Higher Crop Yields](Official/HigherCropYields/) - Increases crop yields by 3x

[Prettier Path](Official/PrettierPath/) - Changes the stone path texture to a prettier one

[Short Night](Official/ShortNight/) - Speeds up night time to a configurable setting (0.5x speed to 10x speed)!

[Whisker POV](Official/WhiskerPOV) - Click on a Whisker to view its point of view! (WIP)

## UE4SS Mods

#### Installation

If you don't have UE4SS installed already:
1. Grab the `UE4SS_v3.0.1-xx.zip` file from [the releases page](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest)
2. Navigate to your game directory:
`\steamapps\common\Wiskerwood\Wiskerwood\Binaries\Win64\`
3. Extract all files from the zip directly into the Win64 folder

To install `LUA` mods:
1. Navigate to your game directory:
`\steamapps\common\Wiskerwood\Wiskerwood\Binaries\Win64\ue4ss\Mods\`
2. Copy the mod folder (e.g. `DynamicResearchCostsMod`) into the Mods folder
3. Inside the mod folder, create an empty text file called `enabled.txt` to enable the mod
    - Alternatively, edit `mods.txt` to add the mod name followed by ` : 1` to enable it, or ` : 0` to disable it

To install `.pak` mods:
1. Navigate to your game directory:
`\steamapps\common\Wiskerwood\Wiskerwood\Content\Paks\LogicMods`
2. Copy the `.pak` file into the LogicMods folder

#### Uninstallation

If you just want to uninstall the mod, navigate to mods folder and delete:
`\steamapps\common\Whiskerwood\Whiskerwood\Binaries\Win64\ue4ss\Mods\<mod name>\enabled.txt`

If you want to uninstall the mod loader (UE4SS):
1. Navigate to game directory
`\steamapps\common\Whiskerwood\Whiskerwood\Binaries\Win64\`
2. Delete or rename file `dwmapi.dll`

### Mods

[DynamicResearchCostsMod](UE4SS/DynamicResearchCostsMod) - Adjusts research costs. Makes late-game research increasingly cheaper (i.e. tier 2 has 20% cost decrease, tier 3 has 40% decrease, etc.)

[FasterTimeControlMod](UE4SS/FasterTimeControlMod) - Finer time control options (deprecated)

[NoResearchCostMod](UE4SS/NoResearchCostMod) - Unlocks all researches

[OrbitalCameraTweaksMod](UE4SS/OrbitalCameraTweaksMod) - Tweaks the orbital camera settings. Press Shift to pan faster

[PhotoModeMod](UE4SS/PhotoModeMod) - Press P to hide the player HUD

[QuickpickMod](UE4SS/QuickpickMod) - Press F when hovering over a building to select it (deprecated)

## Asset Replacement Mods


## Dumper-7 C++ Mods