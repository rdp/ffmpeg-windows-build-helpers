@ECHO on
ECHO "This will build a cross compiler then a 32 bit FFmpeg executable"
ECHO You should not need to answer any prompts, and it should run unattended
ECHO all the way to completion for you...
ECHO.
ECHO.
rem this won't have any prompts :)
build_locally_with_various_option_prompts -d "--compiler-flavors=win32"