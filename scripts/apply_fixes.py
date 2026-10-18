from pathlib import Path
import shutil

inj = Path("inject")
shutil.copy2(inj / "App.swift", "ThreeOneOSFive/App.swift")
shutil.copy2(inj / "ContentView.swift", "ThreeOneOSFive/ContentView.swift")
print("copied App + ContentView")

dps = Path("ThreeOneOSFive/helpers/DevicePatchService.swift")
text = dps.read_text(encoding="utf-8")
inject = (inj / "FFInjectService.swift").read_text(encoding="utf-8")
if "enum FFInjectService" not in text:
    dps.write_text(text + "\n\n" + inject)
    print("FFInjectService merged")
else:
    print("FFInjectService already present")

t = dps.read_text(encoding="utf-8")
if "runWithRetries" not in t:
    t = t.replace(
        "guard KernelExploit.hasSandboxAccess() || KernelExploit.run() else {",
        "guard KernelExploit.hasSandboxAccess() || KernelExploit.runWithRetries(maxAttempts: 5, delaySeconds: 2.5) else {"
    )
    dps.write_text(t)
    print("FFInjectService uses runWithRetries")

ke = Path("ThreeOneOSFive/helpers/KernelExploit.swift")
kt = ke.read_text(encoding="utf-8")
if "runWithRetries" not in kt:
    extra = (inj / "KernelExploit_retry.swift").read_text(encoding="utf-8")
    ke.write_text(kt.rstrip() + "\n\n" + extra + "\n")
    print("KernelExploit retries appended")
else:
    print("KernelExploit retries already present")

print("ALL INJECT FIXES APPLIED")
