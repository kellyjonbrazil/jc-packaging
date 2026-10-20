/*
 * Windows launcher for a frozen Python application.
 *
 * The Windows counterpart of launcher.c, built by build-windows.py. It reads
 * the same payload (see build.py) and hands it to CPython the same way, as
 * the frozen-module table, so the application, its dependencies and the
 * standard library are all imported from memory.
 *
 * The difference is CPython itself. python-build-standalone has no
 * statically linked Windows build, so this executable is linked against
 * python3XX.dll, which ships beside it, and the few extension modules that
 * are not built into that DLL are loaded from the "jclib" folder beside it.
 *
 * It is compiled with a MinGW toolchain against the Universal C Runtime,
 * the C library python3XX.dll uses as well. No C library object crosses
 * between the two: this file only calls CPython's API.
 */
#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <windows.h>

/* Start and end of payload.bin inside the executable (see payload.s). */
extern const unsigned char app_payload[];
extern const unsigned char app_payload_end[];

/* Layout of payload.bin; keep in step with build.py and launcher.c. */
#define PAYLOAD_MAGIC "JCFROZEN"
#define PAYLOAD_VERSION 1

/* Folder beside the executable that holds the extension modules. */
#define EXTENSION_DIR L"jclib"

typedef struct {
    char magic[8];
    uint32_t version;
    uint32_t count;
    uint32_t run_command;
    uint32_t reserved;
} payload_header;

typedef struct {
    uint32_t name;
    uint32_t code;
    uint32_t size;
    uint32_t is_package;
} payload_entry;

static int
fail(PyConfig *config, PyStatus status)
{
    PyConfig_Clear(config);
    if (PyStatus_IsExit(status)) {
        return status.exitcode;
    }
    Py_ExitStatusException(status);
    return 1; /* not reached */
}

/* Return "<folder of this executable>\jclib", or NULL. */
static wchar_t *
extension_dir(void)
{
    DWORD size = MAX_PATH;
    for (;;) {
        wchar_t *path = malloc((size + 1 + wcslen(EXTENSION_DIR) + 1) * sizeof(wchar_t));
        if (path == NULL) {
            return NULL;
        }
        DWORD n = GetModuleFileNameW(NULL, path, size);
        if (n == 0) {
            free(path);
            return NULL;
        }
        if (n < size) {
            wchar_t *slash = wcsrchr(path, L'\\');
            wchar_t *end = slash ? slash + 1 : path;
            wcscpy(end, EXTENSION_DIR);
            return path;
        }
        free(path); /* truncated: try a larger buffer */
        if (size > 32768) {
            return NULL;
        }
        size *= 2;
    }
}

int
wmain(int argc, wchar_t **argv)
{
    const payload_header *header = (const payload_header *)app_payload;
    size_t payload_size = (size_t)(app_payload_end - app_payload);
    if (payload_size < sizeof(*header)
        || memcmp(header->magic, PAYLOAD_MAGIC, sizeof(header->magic)) != 0
        || header->version != PAYLOAD_VERSION) {
        fputs("this executable has no usable Python payload\n", stderr);
        return 1;
    }

    const payload_entry *entries = (const payload_entry *)(header + 1);
    /* calloc leaves the last record zeroed: the table's terminator. */
    struct _frozen *frozen = calloc((size_t)header->count + 1, sizeof(*frozen));
    wchar_t *lib = extension_dir();
    if (frozen == NULL || lib == NULL) {
        fputs("out of memory\n", stderr);
        return 1;
    }
    for (uint32_t i = 0; i < header->count; i++) {
        frozen[i].name = (const char *)app_payload + entries[i].name;
        frozen[i].code = app_payload + entries[i].code;
        frozen[i].size = (int)entries[i].size;
        frozen[i].is_package = (int)entries[i].is_package;
    }
    PyImport_FrozenModules = frozen;

    /* Isolated mode ignores PYTHON* environment variables and the registry. */
    PyPreConfig preconfig;
    PyPreConfig_InitIsolatedConfig(&preconfig);
    preconfig.configure_locale = 1;
    PyStatus status = Py_PreInitializeFromArgs(&preconfig, argc, argv);
    if (PyStatus_Exception(status)) {
        Py_ExitStatusException(status);
    }

    PyConfig config;
    PyConfig_InitIsolatedConfig(&config);

    config.site_import = 0;             /* nothing on disk to scan */
    config.write_bytecode = 0;          /* never write __pycache__ */
    config.optimization_level = 1;      /* matches how the payload was compiled */
    config.module_search_paths_set = 1; /* sys.path is only the extension folder */
    config.install_signal_handlers = 1; /* Ctrl-C -> KeyboardInterrupt */

    status = PyWideStringList_Append(&config.module_search_paths, lib);
    free(lib);
    if (PyStatus_Exception(status)) {
        return fail(&config, status);
    }
    status = PyConfig_SetArgv(&config, argc, argv);
    if (PyStatus_Exception(status)) {
        return fail(&config, status);
    }
    status = PyConfig_SetBytesString(&config, &config.run_command,
                                     (const char *)app_payload + header->run_command);
    if (PyStatus_Exception(status)) {
        return fail(&config, status);
    }
    status = Py_InitializeFromConfig(&config);
    if (PyStatus_Exception(status)) {
        return fail(&config, status);
    }
    PyConfig_Clear(&config);

    return Py_RunMain();
}
