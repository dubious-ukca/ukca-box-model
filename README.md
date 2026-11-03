# ukca_box_model

Standalone box-model interface to UKCA for experiments, testing, and
development. The repository contains two buildable pieces:

- `ukca_standalone`: a library built from the UKCA source submodule.
- `ukca_box_model`: the box-model executable that links against that library.

## Building

To clean the build directory

```bash
rm -rf build
```

The project is built with CMake. A typical local build looks like this:

```bash
cmake -S . -B build
cmake --build build
```

To install the executable, library, module files, and example inputs:

```bash
cmake --install build
```

The CMake configuration supports split builds through these options:

- `BUILD_UKCA_LIBRARY` (default `ON`)
- `BUILD_BOX_MODEL` (default `ON`)
- `UKCA_USE_EXTERNAL_LIBRARY` (default `OFF`)
- `UKCA_EXTERNAL_MODULE_DIR` (required when `UKCA_USE_EXTERNAL_LIBRARY=ON`)

If you are building the box model against an already-installed UKCA library,
turn on `UKCA_USE_EXTERNAL_LIBRARY` and point `UKCA_EXTERNAL_MODULE_DIR` at the
directory containing the UKCA `.mod` files.

## Running

### Running a config

The only input on the command line is the box config namelist:

```bash
./build/src/ukca_box_model examples/default/namelist.nml --debug 1
```

The namelist's `IO` section names the other input files. Each has a default,
so a config folder that uses the standard file names needs no `IO` section
for them:

| `IO` option                 | Contents                                  | Default               |
| --------------------------- | ----------------------------------------- | --------------------- |
| `environment_data_file`     | Environment namelist                      | `env_namelist.nml`    |
| `initial_tracer_file`       | Initial tracer values                     | `initial_tracers.txt` |
| `initial_ntp_file`          | Initial non-transported prognostics (NTP) | `initial_ntp.txt`     |
| `offline_photol_rates_file` | Offline photolysis rates                  | none                  |
| `output_dir`                | Folder for output files (see below)       | working directory     |

Relative paths are resolved against the namelist's folder, so a config folder
can be run from any working directory. To use a different file, set its
option in the namelist, for example:

```fortran
&IO
initial_tracer_file="my_tracers.txt"
&end
```

An example config folder is provided in `examples/default/` (it is installed
to `share/ukca-box-model/examples/default/` by `cmake --install`).

The model writes `tracer_output.csv` to `output_dir`. Unlike the input
files, a relative `output_dir` is relative to the working directory (where the
model is run), so outputs never land inside a config folder. The folder must
already exist.

If the namelist or an input file is missing, the model stops with an error
naming it, for example `Input file not found: 'my_run/initial_ntp.txt' (set
by initial_ntp_file in the IO namelist)`. Run `ukca_box_model --help` for a
usage summary. `--debug LEVEL` (`-d`) sets the debug level (0=off, 1=info,
2=detailed, 3=verbose).

### Making a new experiment

Copy the example folder, edit it, and run it:

```bash
cp -r examples/default my_experiment
# edit my_experiment/initial_tracers.txt, namelist.nml, ...
mkdir -p out/my_experiment && cd out/my_experiment
../../build/src/ukca_box_model ../../my_experiment/namelist.nml
```

### Run script

`scripts/run_box_model.sh` runs a config folder reproducibly. It checks that
the `ukca` submodule is at the expected tag (default `um13.9`) and unmodified,
rebuilds, copies the config folder into a fresh timestamped directory under
`runs/`, and runs it there, recording provenance (commits, compiler, input
checksums):

```bash
scripts/run_box_model.sh                    # examples/default
scripts/run_box_model.sh -C my_experiment   # another config folder
scripts/run_box_model.sh -c my_experiment/other.nml   # a different namelist
```

The whole folder holding the namelist is copied, so keep config folders for
inputs only. Run `scripts/run_box_model.sh -h` for all options.

The box model is tied to UKCA `um13.9`. Clone with
`git clone --recurse-submodules` (or run `git submodule update --init` in an
existing clone) so that `ukca/` is checked out at the pinned commit.

## Compiler flags

The current CMake build uses GNU Fortran-style flags.

For `ukca_standalone` the compile options are:

- `-O0`
- `-fcheck=all,no-bounds`
- `-ffpe-trap=invalid,zero,overflow`
- `-fdefault-real-8`
- `-fdefault-double-8`

For `ukca_box_model` the compile options are:

- `-O0`
- `-g`
- `-fcheck=all`
- `-fbacktrace`
- `-ffpe-trap=invalid,zero,overflow`
- `-finit-real=snan`
- `-finit-integer=-999999`
- `-finit-logical=true`
- `-Wall`
- `-Wextra`
- `-Warray-temporaries`
- `-Wimplicit-interface`
- `-fimplicit-none`
- `-fdefault-real-8`
- `-fdefault-double-8`
- `-std=f2008`
- `-Wpedantic`
- `-Werror`
- `-pedantic-errors`
- `-Wimplicit-procedure`
- `-Wcharacter-truncation`
- `-Wline-truncation`
- `-Wconversion`
- `-Wsurprising`
- `-Wunderflow`
- `-Wintrinsics-std`
- `-Wno-error=maybe-uninitialized`

## What this code does

This repository provides a standalone UKCA box model for running a reduced
chemistry and photolysis configuration outside the full UM/UKCA host model.
It includes the chemistry core, photolysis, emissions, deposition,
environment/setup helpers, and the executable wrapper that reads namelists and
drives a simulation step-by-step.

## Conda packaging

Two conda recipes are provided under `conda/`:

- `conda/ukca`: builds and installs the `ukca_standalone` library and the
  generated Fortran module files (`.mod`).
- `conda/ukca-box-model`: builds only the `ukca_box_model` executable and links
  against the installed `ukca` package.

Build `ukca` first, then `ukca-box-model`:

```bash
conda build -c conda-forge conda/ukca
conda build -c conda-forge conda/ukca-box-model
```

For local testing after building both packages:

```bash
conda install --use-local ukca ukca-box-model
```
