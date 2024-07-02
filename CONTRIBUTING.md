## Contributing to Blurhash FFI

- this project is an implementation of the blurhash algorithm in C via dart:ffi
- the goal of the project is to provide the fastest encoding and decoding of blurhash for flutter, and also be easy to use

## Setting up environment
### Prerequisites
- Linux, Mac OS X, or Windows

- git (used for source version control)

- An IDE, such as Android Studio with the Flutter plugin or VS Code

- Android platform tools

  - Mac: brew install --cask android-platform-tools
  - Linux: sudo apt-get install android-tools-adb

Verify that adb is in your PATH (that which adb prints sensible output)


1. Clone the folksable/blurhash_ffi repo using either SSH or HTTPS (SSH is recommended, but requires a working SSH key on your GitHub account):

  - SSH: `git clone git@github.com:folksable/blurhash_ffi.git`
  - HTTPS: `git clone https://github.com/folksable/blurhash_ffi.git`

2. Change into the directory of the cloned repository and rename the origin remote to upstream:
     1. `cd blurhash_ffi`
     2. `git remote rename origin upstream`

3. If you're planning to test it for android, make sure to enable these SDK Tools
   1. NDK (Side by Side)
   2. CMake
      - Android NDK uses CMake to create a shared library from our [native code](./src) in the build process
   
![Screenshot 2024-06-27 at 14 19 16](https://github.com/folksable/blurhash_ffi/assets/59935432/4b9268a7-ba7c-4644-8d10-4657878eb154)

## Changes to Native Code
- Recheck for memory leaks your pull request may introduce.

## Pull Requests
- Make sure the [example](./example) builds correctly & runs without introducing errors
- Optionally make sure to mention an [issue](https://github.com/folksable/blurhash_ffi/issues) in your PR fixes or [Create one](https://github.com/folksable/blurhash_ffi/issues/new) if doesn't exist.


## Attributions
- [Blurhash website](https://blurha.sh/)
- [Official repository](https://github.com/woltapp/blurhash)
