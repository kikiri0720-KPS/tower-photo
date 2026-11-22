# CI에서 cap add android 직후 실행: 권한 추가, 버전 번호 지정
import os, re, sys
build = os.environ.get('BUILD_NO', '1')
man = 'android/app/src/main/AndroidManifest.xml'
s = open(man, encoding='utf-8').read()
perms = [
 'ACCESS_COARSE_LOCATION','ACCESS_FINE_LOCATION','ACCESS_BACKGROUND_LOCATION',
 'FOREGROUND_SERVICE','FOREGROUND_SERVICE_LOCATION','POST_NOTIFICATIONS',
 'WAKE_LOCK','CAMERA','READ_MEDIA_IMAGES','INTERNET','ACCESS_NETWORK_STATE']
add = ''.join('    <uses-permission android:name="android.permission.%s" />\n' % p
              for p in perms if ('android.permission.%s"' % p) not in s)
s = s.replace('</manifest>', add + '</manifest>', 1)
if 'android.hardware.camera' not in s:
    s = s.replace('</manifest>', '    <uses-feature android:name="android.hardware.camera" android:required="false" />\n</manifest>', 1)
open(man, 'w', encoding='utf-8').write(s)
g = 'android/app/build.gradle'
t = open(g, encoding='utf-8').read()
t = re.sub(r'versionCode \d+', 'versionCode %s' % build, t, 1)
t = re.sub(r'versionName "[^"]*"', 'versionName "1.0.%s"' % build, t, 1)
open(g, 'w', encoding='utf-8').write(t)
print('patched; versionCode', build)
