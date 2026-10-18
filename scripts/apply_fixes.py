from pathlib import Path
import re

# 1) Unlock FF MAX
cv = Path("ThreeOneOSFive/ContentView.swift")
text = cv.read_text(encoding="utf-8")
old = 'lockedLaunchButton(title: "FF MAX", subtitle: "Locked • Coming Soon", color: AppTheme.secondaryAccent)'
new = 'launchButton(title: "FF MAX", subtitle: "Free Fire MAX", color: AppTheme.secondaryAccent, scheme: "freefiremax")'
if old in text:
    text = text.replace(old, new)
    print("FF MAX unlocked")

# 2) openGame with fallbacks
pattern = r'private func openGame\(scheme: String\) \{[\s\S]*?^    \}'
replacement = '''private func openGame(scheme: String) {
        var candidates = [scheme]
        if scheme == "freefireth" {
            candidates += ["freefire", "freefireth", "garena.freefire"]
        } else if scheme == "freefiremax" {
            candidates += ["freefiremax", "freefirethmax", "freefiremaxth", "garena.freefiremax"]
        }
        var seen = Set<String>()
        candidates = candidates.filter { seen.insert($0).inserted }

        func tryNext(_ list: [String]) {
            guard let first = list.first else {
                DispatchQueue.main.async {
                    self.patchMessage = "GAME NOT INSTALLED — install Free Fire / FF MAX first"
                }
                log("launch: all schemes failed")
                return
            }
            guard let url = URL(string: "\\(first)://") else {
                tryNext(Array(list.dropFirst()))
                return
            }
            UIApplication.shared.open(url, options: [:]) { success in
                log("launch: \\(first) success=\\(success)")
                if success {
                    DispatchQueue.main.async {
                        self.patchMessage = "LAUNCHED — \\(first)"
                    }
                } else {
                    tryNext(Array(list.dropFirst()))
                }
            }
        }
        tryNext(candidates)
    }'''
new_text, n = re.subn(pattern, replacement, text, count=1, flags=re.M)
if n:
    text = new_text
    print("openGame replaced")
else:
    print("openGame pattern not matched")
cv.write_text(text)

# 3) License always active
lm = Path("ThreeOneOSFive/helpers/LicenseManager.swift")
t = lm.read_text(encoding="utf-8")
t = t.replace("isActive = hasRememberedKey", "isActive = true")
t = t.replace(
    'message = isActive ? "Ready to use" : "Key required — enter your access key"',
    'message = "Ready to use"'
)
lm.write_text(t)
print("License forced active")

# 4) Fix .3105 extension
lib = Path("ThreeOneOSFive/helpers/PatchProjectLibrary.swift")
lt = lib.read_text(encoding="utf-8")
lt = lt.replace(
    'bundle.urls(forResourcesWithExtension: "OGIOS", subdirectory: "Patches") ?? []',
    'bundle.urls(forResourcesWithExtension: "3105", subdirectory: "Patches") ?? []'
)
lt = lt.replace(
    'bundle.urls(forResourcesWithExtension: "OGIOS", subdirectory: nil) ?? []',
    '(bundle.urls(forResourcesWithExtension: "3105", subdirectory: nil) ?? []) + (bundle.urls(forResourcesWithExtension: "OGIOS", subdirectory: nil) ?? []) + (bundle.urls(forResourcesWithExtension: "OGIOS", subdirectory: "Patches") ?? [])'
)
lt = lt.replace(
    'for url in urls where url.pathExtension.lowercased() == "OGIOS" {',
    'for url in urls where ["ogios", "3105"].contains(url.pathExtension.lowercased()) {'
)
lib.write_text(lt)
print("PatchProjectLibrary extension fixed")
print("ALL FIXES APPLIED")
