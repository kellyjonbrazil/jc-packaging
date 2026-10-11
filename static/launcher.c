/*
 * Single-file launcher for a frozen Python application.
 *
 * Links statically against libpython and carries every Python module
 * (application, dependencies, standard library) as marshalled code inside
 * the executable. Modules are handed to CPython through its own frozen-module
 * table (PyImport_FrozenModules), so imports are served from memory by the
 * interpreter's built-in FrozenImporter: nothing is unpacked to disk and no
 * custom importer is involved.
 *
 * This file knows nothing about the application. The modules and the
 * statement to run arrive as one blob (payload.bin, written by build.py)
 * that is added at link time, so the launcher is compiled once per Python
 * version, not once per application release.
 */
#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Start and end of payload.bin inside the executable (see payload.s). */
extern const unsigned char app_payload[];
extern const unsigned char app_payload_end[];

/* Layout of payload.bin. Offsets count from its first byte; integers are
   little-endian, as on every platform this is built for. */
#define PAYLOAD_MAGIC "JCFROZEN"
#define PAYLOAD_VERSION 1

typedef struct {
    char magic[8];
    uint32_t version;
    uint32_t count;       /* number of payload_entry records that follow */
    uint32_t run_command; /* NUL-terminated statement to execute */
    uint32_t reserved;
} payload_header;

typedef struct {
    uint32_t name; /* NUL-terminated dotted module name */
    uint32_t code; /* marshalled code object */
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

int
main(int argc, char **argv)
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
    if (frozen == NULL) {
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

    /* Isolated mode ignores PYTHON* environment variables, but still honour
       the user's locale (LC_ALL/LANG) so stdout gets the right encoding. */
    PyPreConfig preconfig;
    PyPreConfig_InitIsolatedConfig(&preconfig);
    preconfig.configure_locale = 1;
    PyStatus status = Py_PreInitializeFromBytesArgs(&preconfig, argc, argv);
    if (PyStatus_Exception(status)) {
        Py_ExitStatusException(status);
    }

    PyConfig config;
    PyConfig_InitIsolatedConfig(&config);

    config.site_import = 0;             /* nothing on disk to scan */
    config.write_bytecode = 0;          /* never write __pycache__ */
    config.optimization_level = 1;      /* matches how the payload was compiled */
    config.module_search_paths_set = 1; /* start with an empty sys.path */
    config.install_signal_handlers = 1; /* Ctrl-C -> KeyboardInterrupt */

    status = PyConfig_SetBytesArgv(&config, argc, argv);
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
