#!/usr/bin/env bash
set -euo pipefail

CXX="clang++"
CXXFLAGS="-std=c++17 -Wall -Wextra -pedantic"

Z3_PREFIX="$(brew --prefix z3)"
INCLUDES="-I${Z3_PREFIX}/include -Iinclude"
LIBS="-L${Z3_PREFIX}/lib -Wl,-rpath,${Z3_PREFIX}/lib -lz3"

BUILD_DIR="build"
SEARCH_ROOT="."

mkdir -p "$BUILD_DIR"

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

print_colored_line() {
    line="$1"
    case "$line" in
        *.cpp)  printf "${BLUE}%s${NC}\n" "$line" ;;
        *.py)   printf "${GREEN}%s${NC}\n" "$line" ;;
        *.smt2) printf "${RED}%s${NC}\n" "$line" ;;
        *)      printf "%s\n" "$line" ;;
    esac
}

echo "Project tree:"

if command -v tree >/dev/null 2>&1; then
    tree -a -I 'build|.git|__pycache__|.venv' | while IFS= read -r line; do
        print_colored_line "$line"
    done
else
    find . \
        -not -path './build/*' \
        -not -path './.git/*' \
        -not -path './__pycache__/*' \
        -not -path './.venv/*' \
        | sort | while IFS= read -r line; do
            print_colored_line "$line"
        done
fi

echo
echo "Runnable targets:"

targets=()
kinds=()

while IFS= read -r file; do
    [ -n "$file" ] || continue
    if grep -Eq '^[[:space:]]*(int|auto)[[:space:]]+main[[:space:]]*\(' "$file" || grep -Eq '[[:space:]]main[[:space:]]*\(' "$file"; then
        targets+=("$file")
        kinds+=("cpp")
    fi
done <<EOF
$(find "$SEARCH_ROOT" -type f -name "*.cpp" \
    -not -path "./build/*" \
    -not -path "./.git/*" \
    -not -path "./.venv/*" | sort)
EOF

while IFS= read -r file; do
    [ -n "$file" ] || continue
    targets+=("$file")
    kinds+=("py")
done <<EOF
$(find "$SEARCH_ROOT" -type f -name "*.py" \
    -not -path "./build/*" \
    -not -path "./.git/*" \
    -not -path "./.venv/*" | sort)
EOF

while IFS= read -r file; do
    [ -n "$file" ] || continue
    targets+=("$file")
    kinds+=("smt2")
done <<EOF
$(find "$SEARCH_ROOT" -type f -name "*.smt2" \
    -not -path "./build/*" \
    -not -path "./.git/*" \
    -not -path "./.venv/*" | sort)
EOF

if [ ${#targets[@]} -eq 0 ]; then
    echo "No runnable targets found."
    echo "Recognized types:"
    echo "  *.cpp   with main()"
    echo "  *.py"
    echo "  *.smt2"
    exit 1
fi

i=0
while [ $i -lt ${#targets[@]} ]; do
    file="${targets[$i]#./}"
    kind="${kinds[$i]}"
    case "$kind" in
        cpp)  printf "%2d) ${BLUE}[C++]${NC} %s\n" "$((i+1))" "$file" ;;
        py)   printf "%2d) ${GREEN}[PY ]${NC} %s\n" "$((i+1))" "$file" ;;
        smt2) printf "%2d) ${RED}[SMT]${NC} %s\n" "$((i+1))" "$file" ;;
    esac
    i=$((i+1))
done

echo
printf "Select a target number: "
read -r choice

case "$choice" in
    ''|*[!0-9]*)
        echo "Invalid selection."
        exit 1
        ;;
esac

index=$((choice - 1))

if [ "$index" -lt 0 ] || [ "$index" -ge "${#targets[@]}" ]; then
    echo "Selection out of range."
    exit 1
fi

selected="${targets[$index]}"
kind="${kinds[$index]}"
safe_name="$(echo "${selected#./}" | tr '/' '_' | sed 's/\.[^.]*$//')"

echo
echo "Selected: ${selected#./}"
echo

case "$kind" in
    cpp)
        output="${BUILD_DIR}/${safe_name}"
        echo "Compiling C++ -> $output"
        $CXX $CXXFLAGS "$selected" $INCLUDES $LIBS -o "$output"
        echo
        "$output"
        ;;
    py)
        if [ ! -x ".venv/bin/python" ]; then
            echo "No .venv Python found at project root."
            echo "Create it with:"
            echo "  uv venv --python 3.12"
            echo "  uv pip install z3-solver"
            exit 1
        fi

        .venv/bin/python "$selected"
        ;;
    smt2)
        z3 "$selected"
        ;;
    *)
        echo "Unknown target type."
        exit 1
        ;;
esac