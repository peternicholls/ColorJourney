# How to Build and Share Your Own Swift Library with Swift Package Manager
  
*Originally published by Kevin Abram on June 12, 2024 at https://kevinabram1000.medium.com/how-to-build-and-share-your-own-swift-library-with-swift-package-manager-1905fcc4716b*

If you’ve ever copied the same utility code into multiple iOS projects, you’re not alone.  

Maybe it’s a hex-to-UIColor converter, a networking helper, or a string formatter. At first, it’s easy to duplicate code. But as your projects grow — or as you collaborate with others — things get harder to maintain. Bugs creep in, updates become inconsistent, and everything feels just a little… messier.  

That’s where **building your own Swift library** comes in.  


Instead of repeating yourself, you can turn that one-off utility into a clean, reusable, and versioned Swift library — something you can import into *any* project using Swift Package Manager (SPM). It’s fast, simple, and incredibly satisfying.  

In this guide, I’ll walk you through how to:  
 
* Create your own Swift library using SPM  
* Push it to GitHub and version it with git tags  
* Import and use it in other Xcode projects  
* Follow best practices for sharing reusable Swift code  

We’ll use a real (and very tiny) example called **HexColor**, a simple library that lets you initialize UIColor using hex codes like “#FF5733”.  

![Bering l Barten](Attachments/1F468F90-1B5E-4EFC-8683-9C27F2851D36.webp)  

*Adding the HexColor library to a project using Xcode’s “Add Package” interface is just like any third-party Swift library.*  


🔗 GitHub Repo (HexColor Library):  👉 [https://github.com/kevinabram111/HexColor](https://github.com/kevinabram111/HexColor)  

Let’s dive in and start building!  
  
## 1. Set Up and Structure Your Swift Library  

Let’s walk through setting up your Swift library. You can either use the Terminal (the classic way) or the Xcode GUI (more beginner-friendly). We’ll use a real-world example: HexColor — a simple library that lets you initialize UIColor from hex codes like “#FF5733”.  

### 🛠 Option 1: Using Terminal (Command Line)

Create a new folder for your library:  

```bash
mkdir HexColor
cd HexColor

```
Then, initialize it using Swift Package Manager:  

```bash
swift package init --type=library

```

This generates the following structure:  

```
HexColor/
├── Package.swift
├── Sources/
│   └── HexColor/
│       └── HexColor.swift
└── Tests/
    └── HexColorTests/
        └── HexColorTests.swift
```

⚠️ **Important:** Make sure that the name field inside Package.swift matches the folder name (HexColor). If they don’t match, Xcode will fail to resolve the package when importing it.

### 🧩 Option 2: Using Xcode (Graphical Approach)

If you prefer to avoid the command line, you can also create a Swift Package directly from Xcode.  

**Creating a Swift Package from Xcode — the easiest way to start.**

1. Open Xcode and go to **File > New > Package…**  
2. Select **Library**  
3. Name your package **HexColor**  
4. Choose a location (e.g., a dedicated Libraries folder)  
5. Xcode will create a Swift Package with a similar structure, including a default source file and test file  

*🔁 This approach automatically ensures the Package.swift name and folder name match — no manual fix needed.*  

### ✏️ Add Your Code

Inside Sources/HexColor, create a new file named UIColor+Hex.swift and add:  

```swift
import UIKit

public extension UIColor {

    convenience init?(hex: String, alpha: CGFloat = 1.0) {

        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted.removeFirst()
        }

        guard hexFormatted.count == 6 else {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
```

*🪄 Don’t forget to make the extension public, or it won’t be accessible from other projects that import the library.*  

### 📦 Review Package.swift

Here’s a minimal version of what your Package.swift should look like:  

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HexColor", // ⚠️ Must match the folder name!
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "HexColor",
            targets: ["HexColor"]
        ),
    ],
    targets: [
        .target(
            name: "HexColor",
            dependencies: []
        ),
        .testTarget(
            name: "HexColorTests",
            dependencies: ["HexColor"]
        ),
    ]
)
```

With that, your Swift library is now set up and ready to go — either as a local package or something you’ll soon publish and share. 🎉   
  
## 2. Publish to GitHub and Add Version Tags  

Now that your Swift library is set up, it’s time to publish it so it can be accessed from other projects — and shared with the world (or at least your team 😉).  

You’ll do this in two main steps:  

1. Push the package to a GitHub repository  
2. Add a version tag so Swift Package Manager knows what version to use  
Let’s go through both.  

### 🚀 Step 1: Push Your Library to GitHub

First, create a new empty repository on GitHub — you can call it HexColor or anything you’d like.  
Then, go back to your local library folder and run:  

```bash
git init
git remote add origin https://github.com/yourusername/HexColor.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

This uploads all your local files, including Package.swift, to GitHub.  

*💡 Tip: If you used Xcode’s “New > Package” option, Git may already be initialized — just make sure you’ve set the remote repository URL and pushed your commits.*  

### 🏷️ Step 2: Add a Version Tag

To make your Swift package discoverable in Xcode and usable via SPM, you need to create a **git tag**. Swift Package Manager uses semantic versioning, so tags like 1.0.0, 1.1.0, or 2.0.0 tell SPM which version to fetch.  

```bash
git tag 1.0.0
git push origin 1.0.0
```

*🎯 This creates a 1.0.0 tag and uploads it to GitHub. Once that’s done, Xcode can detect and fetch your library at that version.*  

### 🌐 GitHub GUI Method:

If you prefer to use the GitHub website:  

1. Go to your GitHub repo (e.g., [https://github.com/yourusername/HexColor)](https://github.com/yourusername/HexColor))  
2. Click the **“⚙️ Releases”** tab or go to the **“Tags”** section  
3. Click **“Create a new release”**  
4. Enter a **tag version** like **1.0.0**, and tap** create new tag: 1.0.0**  
5. Set the branch that you want to use for this version like **main**  
6. (Optional) Add a title and description  
7. Click **“Publish release”**  

This does the same thing as the CLI, just through the GitHub web interface.  
 
Once your library is tagged and pushed, it’s ready to be imported into any iOS project using Xcode.  
In the next section, I’ll walk you through how to do just that — no manual cloning, no copying files, just one clean import HexColor.  
  
## 3. Add Your Library in Xcode Using Swift Package Manager  

Once your Swift library is tagged and live on GitHub, the final step is adding it into another project — the fun part: using your creation! 😄  

Xcode makes this incredibly easy through Swift Package Manager (SPM), and you don’t even need to touch the terminal for this part.  

### 🧭 Steps to Add Your Swift Package in Xcode:

![Bering l Barten](Attachments/EEFB8C05-5B96-4C31-A1B4-A9EB899965F4.webp)  
Adding the HexColor library via Xcode’s built-in Swift Package Manager UI — no manual setup needed.  

1. **Open your existing Xcode project**  
2. In the top menu bar, go to: **File > Add Packages…**  
3. In the search bar or URL field, paste the link to your GitHub repo: [https://github.com/yourusername/HexColor](https://github.com/yourusername/HexColor)  
4. Xcode will fetch the available versions (make sure you’ve pushed a tag!)  
5. Choose the version rule — e.g., *“Up to Next Major Version”* (this is the default)  
6. Click **Add Package**  

### ✅ Import and Use It

Once the package is added, you can immediately use it in your code by importing it:  

```swift
import HexColor

let customColor = UIColor(hex: "#3498db")
```
 

### 📝 Tip for Newcomers:

If your package doesn’t show up in Xcode or it says “No Package.swift found”, double-check:  

* You’ve **pushed the tag** (e.g., 1.0.0)  
* The **GitHub URL is public** (or you’re authenticated)  
* The Package.swift file is at the **root of the repo**  
* You named the **target the same as your library folder** (e.g., HexColor)  

In the final section, I’ll share some closing thoughts and outline where you can take your package from here, including how to share it with teammates or make it open-source.  
  
## 4. Where to Go From Here  
 
🎉 Congrats — you’ve just made and used your very own Swift library! You’ve now laid the foundation for scalable, reusable Swift code.  

At this point, your library is:  

* 📦 Packaged with Package.swift  
* 🔗 Hosted on GitHub with versioning  
* 📲 Added to another project via Xcode’s Swift Package Manager  
* ✅ Ready for the world to use — including yourself!  

### 🚀 What You Can Do Next:

Here are a few ideas to take things even further:  

* **Refactor more code** from your projects into libraries  
* **Use internal packages** across the company or team apps  
* **Make it open-source** with docs, a license, and a README  
* **List it on the [Swift Package Index](https://swiftpackageindex.com/)** to reach even more developers  
* **Share it on LinkedIn or Medium** (like this 😉) to help others  

### 📌 A Few Final Tips:

* 💡 Keep your Package.swift minimal, and tidy  
* 🧪 Add unit tests so your package is trusted in production  
* ✨ Add a README badge for SPM support or test coverage if open-source  

### 👀 Example: HexColor

The example used in this article — HexColor — is a very simple Swift library that extends UIColor to support hex values like #3498db.  
 
You can view the full code here:  

🔗 **GitHub Repo**: [https://github.com/kevinabram111/HexColor](https://github.com/kevinabram111/HexColor)  

## 🙌 Final Thoughts

Creating your own Swift library might seem intimidating at first, but once you’ve done it, you’ll realize how much cleaner and more modular your codebase can become , not just for yourself, but for your team or the entire community.  

This small step can open doors to:  

* Better architecture  
* Faster onboarding  
* Shared code quality across projects 

So… what will *your* next Swift library be?  
