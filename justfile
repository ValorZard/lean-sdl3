_default:
    @just --list


build:
    lake build test-app
    patchelf --set-interpreter /usr/lib/ld-linux-x86-64.so.2 .lake/build/bin/test-app
    patchelf --set-rpath '$ORIGIN:/usr/lib' .lake/build/bin/test-app

run: build
    .lake/build/bin/test-app



webcam:
    lake build webcam-app
    patchelf --set-interpreter /usr/lib/ld-linux-x86-64.so.2 .lake/build/bin/webcam-app
    patchelf --set-rpath '$ORIGIN:/usr/lib' .lake/build/bin/webcam-app
    .lake/build/bin/webcam-app
