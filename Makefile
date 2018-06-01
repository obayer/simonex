# MIT License
#
# Copyright (c) 2018 Oliver Bayer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

CC_arm := $(shell xcrun --sdk iphoneos --find clang)
CC_x86 := $(shell xcrun --sdk iphonesimulator --find clang)

SYSROOT_arm := $(shell xcrun --sdk iphoneos --show-sdk-path)
SYSROOT_x86 := $(shell xcrun --sdk iphonesimulator --show-sdk-path)

CFLAGS := -dynamiclib -Wall -x objective-c -fobjc-arc -fobjc-weak -fmodules -framework Foundation
CFLAGS_arm := ${CFLAGS} -arch arm64 -arch armv7 -isysroot ${SYSROOT_arm} -miphoneos-version-min=9.0
CFLAGS_x86 := ${CFLAGS} -arch x86_64 -isysroot ${SYSROOT_x86} -mios-simulator-version-min=9.0

ARCH := x86 arm

CODESIGN_IDENTITY := $(shell security find-identity -v -p codesigning | grep 'iPhone Developer' | head -n1 | cut -d ' ' -f4)
CODESIGN := codesign -f -s ${CODESIGN_IDENTITY}

NAME := simonex

all: dylib
	${CODESIGN} ${NAME}.dylib

dylib: ${ARCH}
	lipo -create ${NAME}_*\.dylib -output ${NAME}.dylib
	rm -f ${NAME}_*\.dylib

${ARCH}:
	${CC_$@} ${CFLAGS_$@} ${NAME}.m -o ${NAME}_$@.dylib

clean:
	rm -f ${NAME}*\.dylib
