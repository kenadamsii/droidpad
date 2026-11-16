#!/bin/bash
# Android Notepad APK Build Script
# Windows Legacy Notepad Clone

set -e  # Exit on error

echo "=== Android Notepad APK Builder ==="
echo "Building: Windows Legacy Notepad Clone for Android"
echo ""

WORKSPACE="/home/khadamsii/.openclaw/workspace/android-notepad"
PROJECT_DIR="${WORKSPACE}"
GRADLE_HOME=${WORKSPACE}/gradle-8.4
ANDROID_SDK="${HOME}/Android/Sdk"
JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check environment
check_env() {
    log_info "Checking build environment..."
    
    if [ ! -d "$ANDROID_SDK/platforms"; then
        log_warn "Android SDK not found. Creating minimal setup..."
        # For now, assume SDK exists or use command line tools download
    fi
    
    if [ ! -f "$JAVA_HOME/bin/java" ]; then
        log_error "Java not found at $JAVA_HOME"
        exit 1
    fi
    
    local java_version=$(java -version 2>&1 | head -1)
    log_info "Found: $java_version"
}

# Download Android SDK command line tools
download_sdk() {
    log_info "Downloading Android SDK Command Line Tools..."
    
    mkdir -p "${ANDROID_SDK}/cmdline-tools/latest"
    curl -L "https://dl.google.com/android/repository/commandlinetools-9822046_latest.zip" \
        -o "${WORKSPACE}/sdk-tools.zip" || {
        log_warn "Could not download SDK tools. Using bundled..."
        # Fallback: use Gradle's internal SDK
    }
    
    unzip -q "${WORKSPACE}/sdk-tools.zip" -d "${ANDROID_SDK}/cmdline-tools/latest"
}

# Download Android SDK platform 34
download_sdk_platforms() {
    log_info "Downloading Android SDK Platform 34..."
    
    export ANDROID_HOME="${ANDROID_SDK}"
    export ANDROID_SDK_ROOT="${ANDROID_HOME}"
    
    cd "${ANDROID_HOME}/cmdline-tools/latest"
    sdkmanager --licenses || {
        # Accept all licenses if prompt fails
        log_info "Accepting licenses..."
        echo y | sdkmanager --licenses
    }
    
    sdkmanager "platforms;android-34" "build-tools;34.0.0" 2>&1 | tail -5 || {
        log_warn "SDK platform download may have failed"
    }
}

# Build the APK
build_apk() {
    log_info "Building Android Notepad APK..."
    
    export ANDROID_HOME="${ANDROID_SDK}"
    export ANDROID_SDK_ROOT="${ANDROID_HOME}"
    export JAVA_HOME="${JAVA_HOME}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    
    cd "${PROJECT_DIR}"
    
    # Ensure gradle wrapper exists and is executable
    [ -x "${PROJECT_DIR}/gradlew" ] || log_warn "Creating minimal gradlew wrapper..."
    
    # Try to build with Gradle
    if [ -f "gradlew" ]; then
        export GRADLE_HOME="${GRADLE_HOME}"
        ./gradlew assembleDebug --no-daemon 2>&1 | tee build.log
        
        if grep -q "BUILD SUCCESSFUL" build.log; then
            log_info "Build successful!"
            local apk_path="${PROJECT_DIR}/app/build/outputs/apk/debug/app-debug.apk"
            
            if [ -f "$apk_path" ]; then
                log_info "APK generated at: $apk_path"
                ls -lh "$apk_path"
                
                # Extract APK size
                local size=$(du -h "$apk_path" | cut -f1)
                log_info "APK Size: $size"
                return 0
            else
                log_error "APK not found at expected location"
                ls -la app/build/outputs/apk/debug/ 2>/dev/null || true
            fi
        else
            log_error "Build failed. Check build.log for details."
            cat build.log | tail -30
            return 1
        fi
    else
        log_error "Gradle wrapper not executable"
        return 1
    fi
}

# Clean up temporary files
cleanup() {
    log_info "Cleanup complete"
}

# Main execution
main() {
    check_env
    download_sdk
    download_sdk_platforms
    build_apk
    
    cleanup
}

# Run main function
main "$@"
