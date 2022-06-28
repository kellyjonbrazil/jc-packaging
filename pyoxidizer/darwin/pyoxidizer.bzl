# This file defines how PyOxidizer application building and packaging is
# performed. See PyOxidizer's documentation at
# https://pyoxidizer.readthedocs.io/en/stable/ for details of this
# configuration file format.

def make_dist():
    return default_python_distribution()


def make_exe(dist):
    policy = dist.make_python_packaging_policy()

    # use the callback function to filter out source code
    # see: https://pyoxidizer.readthedocs.io/en/v0.9.0/packaging_resources.html#using-callbacks-to-influence-resource-attributes
    # and: https://github.com/indygreg/PyOxidizer/issues/312
    policy.register_resource_callback(resource_callback)

    # Package all available Python extensions in the distribution.
    # policy.extension_module_filter = "all"
    policy.extension_module_filter = "no-libraries"

    # Use in-memory location for adding resources by default.
    policy.resources_location = "in-memory"

    # Attempt to add resources relative to the built binary when
    # `resources_location` fails.
    policy.resources_location_fallback = "filesystem-relative:jclib"

    # Remove source files and docstrings from dist to reduce executable size
    policy.include_distribution_sources = False
    policy.include_non_distribution_sources = False
    policy.bytecode_optimize_level_zero = False
    policy.bytecode_optimize_level_one = False
    policy.bytecode_optimize_level_two = True

    # This variable defines the configuration of the embedded Python
    # interpreter. By default, the interpreter will run a Python REPL
    # using settings that are appropriate for an "isolated" run-time
    # environment.
    #
    # The configuration of the embedded Python interpreter can be modified
    # by setting attributes on the instance. Some of these are
    # documented below.
    python_config = dist.make_python_interpreter_config()

    # Remove docstrings for smaller executable
    python_config.optimization_level = 2

    # Enable the standard path-based importer which attempts to load
    # modules from the filesystem.
    python_config.filesystem_importer = True

    # Evaluate a string as Python code when the interpreter starts.
    python_config.run_command = "import jc.cli; jc.cli.main()"

    # Produce a PythonExecutable from a Python distribution, embedded
    # resources, and other options. The returned object represents the
    # standalone executable that will be built.
    exe = dist.to_python_executable(
        name="jc",
        packaging_policy=policy,
        config=python_config,
    )

    # Invoke `pip install` using a requirements file and add the collected resources
    # to our binary.
    exe.add_python_resources(exe.pip_install(["-r", "requirements.txt"]))

    # Return our `PythonExecutable` instance so it can be built and
    # referenced by other consumers of this target.
    return exe


def make_install(exe):
    # Create an object that represents our installed application file layout.
    files = FileManifest()

    # Add the generated executable to our install layout in the root directory.
    files.add_python_resource(".", exe)

    return files


# Tell PyOxidizer about the build targets defined above.
register_target("dist", make_dist)
register_target("exe", make_exe, depends=["dist"])
register_target("install", make_install, depends=["exe"], default=True)

# Resolve whatever targets the invoker of this configuration file is requesting
# be resolved.
resolve_targets()

# END OF COMMON USER-ADJUSTED SETTINGS.
#
# Everything below this is typically managed by PyOxidizer and doesn't need
# to be updated by people.

PYOXIDIZER_VERSION = "0.16.0"
PYOXIDIZER_COMMIT = "4053178f2ba11d29f497d171289cb847cd07ed77"
