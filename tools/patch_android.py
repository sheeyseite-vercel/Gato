"""Run after `flutter create`: adds permissions, deep links, widget and minSdk."""
import pathlib
import re
import shutil
import sys

root = pathlib.Path(".")
overlay = root / "android_overlay"
manifest = root / "android/app/src/main/AndroidManifest.xml"
if not manifest.exists():
    sys.exit("AndroidManifest.xml not found - did `flutter create` run?")

s = manifest.read_text()
perms = (
    '    <uses-permission android:name="android.permission.INTERNET"/>\n'
    '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n'
)
if "RECORD_AUDIO" not in s:
    s = s.replace("<application", perms + "    <application", 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="GATO"', s, count=1)
if "flutter_deeplinking_enabled" not in s:
    if "</activity>" not in s:
        sys.exit("No </activity> in manifest")
    s = s.replace("</activity>", (overlay / "filters.xml").read_text() + "        </activity>", 1)
if "GatoWidget" not in s:
    s = s.replace("</application>", (overlay / "receiver.xml").read_text() + "    </application>", 1)
manifest.write_text(s)

main = root / "android/app/src/main"
kotlin_dir = main / "kotlin/com/gato/gato"
kotlin_dir.mkdir(parents=True, exist_ok=True)
shutil.copy(overlay / "kotlin/GatoWidget.kt", kotlin_dir / "GatoWidget.kt")
for sub in ("layout", "xml", "drawable"):
    dst = main / "res" / sub
    dst.mkdir(parents=True, exist_ok=True)
    for f in (overlay / "res" / sub).glob("*.xml"):
        shutil.copy(f, dst / f.name)

for name in ("android/app/build.gradle.kts", "android/app/build.gradle"):
    p = root / name
    if p.exists():
        t = p.read_text()
        t = t.replace("minSdk = flutter.minSdkVersion", "minSdk = 23")
        t = t.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 23")
        p.write_text(t)
print("Android project patched.")
