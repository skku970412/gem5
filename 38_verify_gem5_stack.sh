#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEM5_DIR="${ROOT_DIR}/gem5"

cd "${GEM5_DIR}"

expect_files() {
    local range="$1"
    shift
    local expected
    local actual

    expected="$(printf '%s\n' "$@" | sort)"
    actual="$(git diff --name-only "${range}" | sort)"

    if [[ "${actual}" != "${expected}" ]]; then
        echo "Unexpected diff files for ${range}" >&2
        echo "Expected:" >&2
        printf '%s\n' "${expected}" >&2
        echo "Actual:" >&2
        printf '%s\n' "${actual}" >&2
        return 1
    fi
}

echo "== Fetch =="
git fetch origin

echo
echo "== Branch Drift =="
for branch in stats-txt-parser-pyunit fix-chi-protocol-case stats-name-canonicalizer; do
    printf '%s ' "${branch}"
    git rev-list --left-right --count "origin/develop...${branch}"
done
printf 'parser->reset '
git rev-list --left-right --count stats-txt-parser-pyunit...stats-reset-validator
printf 'reset->docs '
git rev-list --left-right --count stats-reset-validator...stats-reset-validation-docs

echo
echo "== Expected Diff Files =="
expect_files origin/develop...stats-txt-parser-pyunit \
    tests/pyunit/stats/__init__.py \
    tests/pyunit/stats/fixtures/duplicate_stat.txt \
    tests/pyunit/stats/fixtures/edge_values.txt \
    tests/pyunit/stats/fixtures/empty_dump.txt \
    tests/pyunit/stats/fixtures/malformed_line.txt \
    tests/pyunit/stats/fixtures/multiple_dumps.txt \
    tests/pyunit/stats/fixtures/no_dump.txt \
    tests/pyunit/stats/fixtures/single_dump.txt \
    tests/pyunit/stats/pyunit_stats_txt.py \
    tests/pyunit/stats/stats_txt.py
expect_files stats-txt-parser-pyunit...stats-reset-validator \
    tests/gem5/stats/configs/stats_reset_check.py \
    tests/gem5/stats/test_stats_reset.py
expect_files stats-reset-validator...stats-reset-validation-docs \
    tests/gem5/stats/README.md
expect_files origin/develop...fix-chi-protocol-case \
    src/mem/ruby/protocol/CHI/CHI-cache-actions.sm \
    src/mem/ruby/protocol/CHI/CHI-cache-funcs.sm \
    src/mem/ruby/protocol/CHI/CHI-cache-ports.sm \
    src/mem/ruby/protocol/CHI/CHI-cache-transitions.sm \
    src/mem/ruby/protocol/CHI/CHI-cache.sm \
    src/mem/ruby/protocol/CHI/CHI-dvm-misc-node-actions.sm \
    src/mem/ruby/protocol/CHI/CHI-dvm-misc-node-funcs.sm \
    src/mem/ruby/protocol/CHI/CHI-dvm-misc-node-ports.sm \
    src/mem/ruby/protocol/CHI/CHI-dvm-misc-node-transitions.sm \
    src/mem/ruby/protocol/CHI/CHI-dvm-misc-node.sm \
    src/mem/ruby/protocol/CHI/CHI-mem.sm \
    src/mem/ruby/protocol/CHI/CHI-msg.sm \
    src/mem/ruby/protocol/CHI/CHI.slicc \
    src/mem/ruby/protocol/CHI/Kconfig \
    src/mem/ruby/protocol/CHI/SConsopts \
    src/mem/ruby/protocol/CHI/generic/CBusy.cc \
    src/mem/ruby/protocol/CHI/generic/CBusy.hh \
    src/mem/ruby/protocol/CHI/generic/CBusy.py \
    src/mem/ruby/protocol/CHI/generic/CHIGeneric.py \
    src/mem/ruby/protocol/CHI/generic/CHIGenericController.cc \
    src/mem/ruby/protocol/CHI/generic/CHIGenericController.hh \
    src/mem/ruby/protocol/CHI/generic/SConscript \
    src/mem/ruby/protocol/CHI/tlm/SConscript \
    src/mem/ruby/protocol/CHI/tlm/SConsopts \
    src/mem/ruby/protocol/CHI/tlm/TlmController.py \
    src/mem/ruby/protocol/CHI/tlm/TlmGenerator.py \
    src/mem/ruby/protocol/CHI/tlm/controller.cc \
    src/mem/ruby/protocol/CHI/tlm/controller.hh \
    src/mem/ruby/protocol/CHI/tlm/generator.cc \
    src/mem/ruby/protocol/CHI/tlm/generator.hh \
    src/mem/ruby/protocol/CHI/tlm/port.hh \
    src/mem/ruby/protocol/CHI/tlm/python/__init__.py \
    src/mem/ruby/protocol/CHI/tlm/python/port.py \
    src/mem/ruby/protocol/CHI/tlm/python/utils.py \
    src/mem/ruby/protocol/CHI/tlm/tlm_chi.cc \
    src/mem/ruby/protocol/CHI/tlm/tlm_chi_gen.cc \
    src/mem/ruby/protocol/CHI/tlm/utils.cc \
    src/mem/ruby/protocol/CHI/tlm/utils.hh \
    src/mem/ruby/protocol/Kconfig
expect_files origin/develop...stats-name-canonicalizer \
    tests/pyunit/util/pyunit_stats_canonicalizer.py \
    util/stats_canonicalizer.py
echo "Expected diff files passed."

echo
echo "== Whitespace Checks =="
git diff --check origin/develop...stats-txt-parser-pyunit
git diff --check origin/develop...fix-chi-protocol-case
git diff --check origin/develop...stats-name-canonicalizer
git diff --check stats-txt-parser-pyunit...stats-reset-validator
git diff --check stats-reset-validator...stats-reset-validation-docs

echo
echo "== Targeted Tests =="
./build/ALL/gem5.opt tests/run_pyunit.py --directory tests/pyunit/stats
pre-commit run --files tests/gem5/stats/README.md
(
    cd tests
    ./main.py run --skip-build --uid SuiteUID:tests/gem5/stats/test_stats_reset.py:stats-reset-check-ALL-x86_64-opt
)

echo
echo "Stack verification passed."
