# Opening JourneyPreview in Xcode

## Option 1: Xcode Preview (Recommended)

This allows you to see the UI directly in Xcode with live preview:

1. Open the ColorJourney project root in Xcode:
   ```sh
   open Package.swift
   ```

2. In Xcode's Project Navigator (left sidebar), navigate to:
   ```
   Examples/JourneyPreview/ContentView.swift
   ```

3. Open the Canvas (if not already open):
   - Press `⌥⌘↩` (Option-Command-Return), or
   - Click Editor > Canvas in the menu bar

4. The preview will show all three color journeys with their discrete swatches

5. To preview in iOS simulator instead of macOS:
   - Click the device selector at the bottom of the Canvas
   - Choose an iPhone or iPad simulator

## Option 2: Run as Standalone App

From the terminal:

```sh
cd Examples/JourneyPreview
swift run
```

This will launch a window showing the color journeys.

## Option 3: Open JourneyPreview as Separate Project

If you want to work on just this app:

```sh
cd Examples/JourneyPreview
open Package.swift
```

This opens JourneyPreview as its own Xcode project.

## Customizing

Edit `ContentView.swift` to change:
- **Journey count**: Change the `count` parameter in `generateJourney()`
- **Colors**: Adjust the `anchor` RGB values (0.0 to 1.0 range)
- **Styles**: Try `.balanced`, `.pastelDrift`, `.vividLoop`, `.nightMode`, `.warmEarth`, `.coolSky`
- **Layout**: Modify the grid columns or add more journeys to the array

## Troubleshooting

**Canvas not showing?**
- Make sure you're using Xcode 15 or later
- Check that Canvas is enabled: Editor > Canvas
- Try closing and reopening the file

**App not launching?**
- Run `swift build` first to ensure compilation succeeds
- Check that ColorJourney library is properly built

**Colors look wrong?**
- RGB values must be in 0.0-1.0 range (not 0-255)
- Try one of the preset examples first to verify setup
