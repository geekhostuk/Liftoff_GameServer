#!/bin/sh
export DOORSTOP_ENABLE=TRUE
export DOORSTOP_INVOKE_DLL_PATH=./BepInEx/core/BepInEx.Preloader.dll
export LD_LIBRARY_PATH=./doorstop_libs:$LD_LIBRARY_PATH
export LD_PRELOAD=libdoorstop_x64.so:$LD_PRELOAD
vglrun ./Liftoff.x86_64 $@;
