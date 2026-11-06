# ukca_box_model

Standalone box-model interface to UKCA for experiments, testing, and
development. The repository contains two buildable pieces:

- `ukca_standalone`: a library built from the UKCA source submodule.
- `ukca_box_model`: the box-model executable that links against that library.

## What this code does

This repository provides a standalone UKCA box model for running a reduced
chemistry and photolysis configuration outside the full UM/UKCA host model.
It includes the chemistry core, photolysis, emissions, deposition,
environment/setup helpers, and the executable wrapper that reads namelists and
drives a simulation step-by-step.

## Prerequisites

- A Fortran compiler: GNU Fortran (`gfortran`); the build uses GNU-specific
  flags
- CMake 3.20 or newer
- git (the UKCA source is a submodule)

Optional:

- Python 3, for the scripts in `tools/`
- [FORD](https://forddocs.readthedocs.io/), to build the API documentation
- [pre-commit](https://pre-commit.com/), for development (see
  [Contributing](#contributing))
- conda-build, for the conda packages

## Getting the code

The UKCA source is a git submodule (`ukca/`), pinned to UKCA `um13.9`. Clone
with submodules so it is checked out at the pinned commit:

```bash
git clone --recurse-submodules https://github.com/dubious-ukca/ukca-box-model.git
```

In an existing clone, run `git submodule update --init` instead.

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

A run is described by a **config folder**: a box config namelist
(`namelist.nml`) plus the input files it names. An example is provided in
`examples/default/` (installed to `share/ukca-box-model/examples/default/` by
`cmake --install`).

There are two ways to run a config:

1. **Call the executable directly** (`build/src/ukca_box_model`). The
   namelist holds almost all of the inputs, so this is all you need for
   everyday runs.
2. **Use the run script** (`scripts/run_box_model.sh`). This is a convenience
   wrapper around the executable for reproducible runs: it checks the UKCA
   submodule, rebuilds, runs in a fresh directory and records provenance.

### The config folder

The namelist's `&IO` section names the other input files. Each has a default,
so a config folder that uses the standard file names needs no `&IO` entry
for them:

| `&IO` option                | Contents                                  | Default               |
| --------------------------- | ----------------------------------------- | --------------------- |
| `environment_data_file`     | Environment namelist                      | `env_namelist.nml`    |
| `initial_tracer_file`       | Initial tracer values                     | `initial_tracers.txt` |
| `initial_ntp_file`          | Initial non-transported prognostics (NTP) | `initial_ntp.txt`     |
| `offline_photol_rates_file` | Offline photolysis rates                  | none                  |
| `output_dir`                | Folder for output files (see below)       | working directory     |

`examples/default/` contains:

```text
examples/default/
├── namelist.nml          # box config; &IO sets offline_photol_rates_file="jrate.txt"
├── env_namelist.nml      # environment (default name)
├── initial_tracers.txt   # initial tracers (default name)
├── initial_ntp.txt       # initial NTP (default name)
└── jrate.txt             # offline photolysis rates
```

Relative input paths are resolved against the namelist's folder, so a config
folder can be run from any working directory. To use a different file, set
its option in the namelist, for example:

```fortran
&IO
initial_tracer_file="my_tracers.txt"
&end
```

The model writes `tracer_output.csv` to `output_dir`. Unlike the input
files, a relative `output_dir` is relative to the working directory (where the
model is run), so outputs never land inside a config folder. The folder must
already exist.

The format of each file is described in
[Input and output formats](#input-and-output-formats).

If the namelist or an input file is missing, the model stops with an error
naming it, for example `Input file not found: 'my_run/initial_ntp.txt' (set
by initial_ntp_file in the IO namelist)`.

### Option 1: calling the executable directly

```text
ukca_box_model <namelist_file> [--debug <level>]
```

| Argument              | Meaning                                                        |
| --------------------- | -------------------------------------------------------------- |
| `<namelist_file>`     | Path to the box config namelist (required, exactly one)        |
| `--debug`, `-d LEVEL` | Debug level: 0=off (default), 1=info, 2=detailed, 3=verbose    |
| `--help`, `-h`        | Print a usage summary and exit                                 |

The executable has no options for individual input files or for a config
folder: point it at the namelist inside the config folder, and set any
non-default file names in the namelist's `&IO` section. For example, to run
the default example from the repository root:

```bash
./build/src/ukca_box_model examples/default/namelist.nml --debug 1
```

`tracer_output.csv` is written to the current directory (unless `output_dir`
is set), so it is usually best to run from a dedicated output folder:

```bash
mkdir -p out/default && cd out/default
../../build/src/ukca_box_model ../../examples/default/namelist.nml
```

To dump every UKCA API input and output, set the environment variable
`UKCA_DUMP_FILE` to the file to write (see `src/box_dump.F90`):

```bash
UKCA_DUMP_FILE=ukca_dump.txt ./build/src/ukca_box_model examples/default/namelist.nml
```

Note that UKCA's legacy error reporting can stop the model with exit status 0
on a fatal error, so check the log for `UKCA ERROR in` rather than relying on
the exit status alone (the run script does this for you).

### Option 2: the run script

`scripts/run_box_model.sh` wraps the executable for reproducible runs. Since
most inputs now live in the namelist, it is mainly a convenience: it does not
pass any extra model inputs, but it

- checks that the `ukca` submodule is at the expected tag (default `um13.9`)
  and unmodified,
- rebuilds the model (configuring `build/` first if needed),
- copies the whole config folder into a fresh timestamped directory
  `runs/run_YYYYMMDD_HHMMSS/` and runs it there,
- records provenance (commits, compiler, executable and input checksums) in
  `provenance.txt` and the model output in `run.log`,
- treats a reported `UKCA ERROR` as a failure, even if the model exited 0.

```bash
scripts/run_box_model.sh                              # examples/default
scripts/run_box_model.sh -C my_experiment             # another config folder
scripts/run_box_model.sh -c my_experiment/other.nml   # a different namelist
scripts/run_box_model.sh -n -d 2 -D                   # no rebuild, debug 2, UKCA dump
```

| Option     | Meaning                                                    | Default            |
| ---------- | ---------------------------------------------------------- | ------------------ |
| `-C DIR`   | Config folder; runs `DIR/namelist.nml`                     | `examples/default` |
| `-c FILE`  | Namelist to run (overrides `-C`)                           |                    |
| `-d LEVEL` | Debug level passed to the model                            | `1`                |
| `-D`       | Dump UKCA API inputs/outputs to `ukca_dump.txt`            | off                |
| `-n`       | Do not rebuild; use the existing executable                | rebuild            |
| `-o DIR`   | Parent directory for run directories                       | `runs`             |
| `-t TAG`   | Expected UKCA tag for the submodule                        | `um13.9`           |
| `-h`       | Show help                                                  |                    |

`-C` and `-c` are options of the script only, not of the executable. The
whole folder holding the namelist is copied, so keep config folders for
inputs only.

### Making a new experiment

Copy the example folder, edit it, and run it either way:

```bash
cp -r examples/default my_experiment
# edit my_experiment/initial_tracers.txt, namelist.nml, ...

# directly
mkdir -p out/my_experiment && cd out/my_experiment
../../build/src/ukca_box_model ../../my_experiment/namelist.nml

# or with the run script (from the repository root)
scripts/run_box_model.sh -C my_experiment
```

## Input and output formats

### Input file formats

**Box config namelist** (`namelist.nml`). Fortran namelist groups that set up
UKCA: `&general_config` (run length, timestep, start date, chemistry
scheme), `&chemistry`, `&photolysis`, `&emissions`, `&aerosol`,
`&deposition`, `&feedbacks`, `&landsurface`, `&constants` and `&IO`. See
`examples/default/namelist.nml` for a working set, and `src/box_config.F90`
for every option and its default.

**Environment namelist** (`env_namelist.nml`). The state of the box, in the
groups `&core_environment` (location, temperature, pressure, humidity,
cloud), `&photolysis_environment`, `&prescribed_conc_environment`,
`&deposition_environment`, `&emissions_environment`, `&aerosol_environment`
and `&offlinechem_environment` (offline oxidant fields). A missing group is
reported as a warning and its fields are left at missing values. The fields
are documented in `src/box_environment.F90`.

**Initial tracers, initial NTP and offline photolysis rates**
(`initial_tracers.txt`, `initial_ntp.txt`, `jrate.txt`). Plain text with one
`<name> <value>` pair per line. Blank lines and lines starting with `#` are
ignored, and a `DEFAULT` line sets the value of every species not listed:

```text
# Chemistry initial conditions
DEFAULT 1e-15

O3        1.0e-7
NO        5.0e-10
CH4       1.02e-6
```

Tracer and NTP values are UKCA mass mixing ratios (kg/kg) and photolysis
rates are in s⁻¹. Names must match the species in the chosen chemistry
scheme; an unknown name, or a species that falls back to `DEFAULT`, is
reported as a warning in the log. Offline photolysis rates are used when
`l_offline_photol` is true in `&photolysis` (the default).

### Output

`tracer_output.csv` has a `TimeStep` column followed by one column per
tracer. Row `0` holds the initial values and row `n` the values after
timestep `n`, in the same units as the inputs. The log (stdout) reports the
setup, any warnings, and the tracer values as the run progresses; use
`--debug` for more detail.

## Compiler flags

The build uses GNU Fortran (`gfortran`) flags: double precision by default
(`-fdefault-real-8`), runtime checks and floating-point traps, and strict
warnings treated as errors for the box model code. See the
`target_compile_options` calls in `src/CMakeLists.txt` for the full lists.

## Documentation

API documentation is generated from the source comments with
[FORD](https://forddocs.readthedocs.io/), configured in `project.md`. The
generated HTML is committed in `doc/` (open `doc/index.html`) and is
rebuilt automatically on pull requests. Science notes and other pages live
in `page_dir/`. To build a local copy:

```bash
ford project.md -o doc_local
```

## Debugging and comparing runs

Setting `UKCA_DUMP_FILE` (or passing `-D` to the run script) writes every
UKCA API input and output to a text dump, which the scripts in `tools/` can
compare:

- `tools/compare_dumps.py OLD_DUMP NEW_DUMP` reports which values differ
  between two dumps, step by step, and where two runs first diverge
  (`--steps`, `--all` and `--ignore` narrow the comparison).
- `tools/compare_tracer_hex.py OLD_TRACER_OUT_HEX NEW_UKCA_DUMP` checks the
  tracers for bit-for-bit agreement with the old (UM) box model's
  `tracer_out.hex`.

Run either with `--help` for details.

## Contributing

The repository uses [pre-commit](https://pre-commit.com/) hooks. Install
them once per clone:

```bash
pip install pre-commit
pre-commit install
```

On each commit that touches Fortran or CMake files, `.pre-commit-config.yaml`
runs:

- **FORD documentation check**: builds the docs (`ford project.md`), so FORD
  must be installed.
- **CMake build**: configures and builds into `build/`. The box model is
  compiled with `-Werror`, so any new compiler warning blocks the commit.
- **[fortitude](https://github.com/PlasmaFAIR/fortitude)** (v0.8.0): a
  Fortran linter, configured in `fortitude.toml` (Fortran 2008, 80-character
  lines, 2-space indents; `ukca/` is excluded).

To run every hook on the whole repository:

```bash
pre-commit run --all-files
```

`.fprettify.rc` holds the formatting settings for
[fprettify](https://github.com/fortran-lang/fprettify) and `cspell.json` the
spell-check word list; neither runs as a hook. On pull requests, GitHub
Actions build the conda packages and the FORD documentation.

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

## AI declaration

AI tools were used in parts of this project (code review, the UKCA dump code
and drafting this README); see [`aidecl.yaml`](aidecl.yaml) for details.
