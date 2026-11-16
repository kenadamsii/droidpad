#!/bin/bash
set -e

echo "🚀 Building Android APK using Docker..."
cd /home/khadamsii/.openclaw/workspace/android-notepad

# Build the APK in a Docker container with pre-installed JDK 17 and Android SDK
docker run --rm \
    -v $(pwd):/project \
    mingchen/android-build-box \
    bash -c 'cd /project && ./gradlew bundleRelease --stacktrace' || echo "Build completed or failed"
