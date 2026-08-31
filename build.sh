#!/bin/zsh
set -e
cd "$(dirname "$0")"
APP=SlopWindow.app
mkdir -p $APP/Contents/MacOS
cp Info.plist $APP/Contents/
swiftc -O -framework AppKit -framework WebKit \
  Sources/main.swift -o $APP/Contents/MacOS/SlopWindow
codesign --force --sign - $APP 2>/dev/null || true
echo "built $APP"
