from pathlib import Path
import shutil

root = Path(".")
inj = Path("inject")

shutil.copy2(inj / "App.swift", "ThreeOneOSFive/App.swift")
shutil.copy2(inj / "ContentView.swift", "ThreeOneOSFive/ContentView.swift")
print("copied App + ContentView")

dps = Path("ThreeOneOSFive/helpers/DevicePatchService.swift")
text = dps.read_text(encoding="utf-8")
inject = (inj / "FFInjectService.swift").read_text(encoding="utf-8")
if "enum FFInjectService" not in text:
    dps.write_text(text + "\n\n" + inject)
    print("FFInjectService merged into DevicePatchService")
else:
    print("FFInjectService already present")

print("ALL INJECT FIXES APPLIED")
