#define accepted_major 4
#define accepted_minor 2
#define accepted_patchfix 0

#if defined(__clang_major__) && defined(__clang_minor__) && defined(__clang_patchlevel__)
    #if (__clang_major__ != accepted_major) || (__clang_minor__ != accepted_minor) || (__clang_patchlevel__ != accepted_patchfix)

#define VALUE_TO_STRING(x) #x
#define VALUE(x) VALUE_TO_STRING(x)
#define VERSION_NAME_VALUE(v1, v2, v3) VALUE(v1) "."  VALUE(v2) "." VALUE(v3)

#define GROWL_ACCEPTED "Allowed: " VERSION_NAME_VALUE(accepted_major, accepted_minor, accepted_patchfix)
#define GROWL_FOUND "Found: " VERSION_NAME_VALUE(__clang_major__, __clang_minor__, __clang_patchlevel__)
#pragma message("Toolchain mismatch")
#pragma message(GROWL_ACCEPTED)
#pragma message(GROWL_FOUND)

#error Growl requires a specific toolchain in order to build. you're more than welcome to comment this out in order to attempt building with the toolchain you have. We don't accept patches against the released versions as they are frozen in time.
    #endif
#endif
