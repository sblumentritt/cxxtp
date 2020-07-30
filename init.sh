#!/bin/sh

# absolute directory path to this script
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# dependency commits/tags
cmake_modules_tag="v0.1.0"

# define all variables which will be populated from the command line
project_name=
target_name=
target_type=0 # [0 = executable | 1 = library]
cxx_standard=17
git_username=
git_email=

usage() {
    printf "Usage: %s [OPTIONS]

OPTIONS:
    -h, --help
        Prints help information.
    -p, --project <NAME>
        Name which should be used for the CMake project.
    -t, --target <NAME>
        Name which should be used for the CMake target.
    -l, --lib
        Create a library CMake target. Without this option an executable CMake target is created.
    -s, --standard <VERSION>
        C++ standard which should be used to build the target. [possible values: 11, 14, 17, 20]
        Default: 17
    --git-username <NAME>
        Name which should be used locally in the Git repository to create commits.
    --git-email <ADDRESS>
        Email address which should be used locally in the Git repository to create commits.
" "$(basename "$0")" 1>&2

    exit 1
}

eprint_empty_argument() {
    printf "ERROR: '%s' requires a non-empty option argument.\n" "$1" >&2
}

eprint_required_option() {
    printf "ERROR: '%s' command line option is required.\n" "$1" >&2
}

check_required_string_option() {
    if [ -z "$1" ]; then
        eprint_required_option "$2"
        usage
    fi
}

# parse command line arguments
while :; do
    case $1 in
        -p|--project)
            if [ -n "$2" ]; then
                project_name=$2
                shift
            else
                eprint_empty_argument "-p, --project"
                usage
            fi
            ;;
        -t|--target)
            if [ -n "$2" ]; then
                target_name=$2
                shift
            else
                eprint_empty_argument "-t, --target"
                usage
            fi
            ;;
        -l|--lib)
            target_type=1
            ;;
        -s|--standard)
            if [ -n "$2" ]; then
                if [ "$2" -eq 11 ] || [ "$2" -eq 14 ] || [ "$2" -eq 17 ] || [ "$2" -eq 20 ]; then
                    cxx_standard=$2
                    shift
                else
                    printf "ERROR: Unsupported argument value '%d' for '%s'\n" \
                        "$2" \
                        "-s, --standard" \
                        >&2
                    usage
                fi
            else
                eprint_empty_argument "-s, --standard"
                usage
            fi
            ;;
        --git-username)
            if [ -n "$2" ]; then
                git_username=$2
                shift
            else
                eprint_empty_argument "--git-username"
                usage
            fi
            ;;
        --git-email)
            if [ -n "$2" ]; then
                git_email=$2
                shift
            else
                eprint_empty_argument "--git-email"
                usage
            fi
            ;;
        -h|--help)
            usage
            ;;
        -?*)
            printf "ERROR: Unknown option: %s\n" "$1" >&2
            usage
            ;;
        *) # no more arguments available
            break
    esac

    shift
done

check_required_string_option "$project_name" "-p, --project"
check_required_string_option "$target_name" "-t, --target"

printf "\nIs '%s' the correct template dir which should be configured? [y/n] " "${script_dir}"
read -r answer

if [ ! "${answer}" = "y" ]; then
    printf "Aborting '%s'!\n" "$(basename "$0")" 1>&2
    exit 1
fi

cd "${script_dir}" || { printf "Unable to change to '%s'\n" "${script_dir}" >&2; exit 1; }

# remove old Git related files/folder
rm -rdf "${script_dir}/.git"
rm -f "${script_dir}/.gitmodules"
rm -rdf "${script_dir}/dependency/"*

# initialize the Git repo and set local config if requested
git init

if [ -n "${git_username}" ]; then
    git config user.name "${git_username}"
fi

if [ -n "${git_email}" ]; then
    git config user.email "${git_email}"
fi

# create first commit as empty commit
git commit --allow-empty -m "Initial empty commit"

# add/commit .gitignore file
git add "${script_dir}/.gitignore"
git commit -m "Add .gitignore file"

# add 'cmake_modules' as submodule
git submodule add https://gitlab.com/s.blumentritt/cmake_modules.git "dependency/cmake_modules"

cd "${script_dir}/dependency/cmake_modules" || \
    { printf "Unable to change to '%s'\n" "${script_dir}/dependency/cmake_modules" >&2 ; exit 1; }

git checkout "${cmake_modules_tag}"

cd "${script_dir}" || { printf "Unable to change to '%s'\n" "${script_dir}" >&2; exit 1; }

git add "${script_dir}/dependency/cmake_modules"
git commit -m "Add 'cmake_modules' submodule"

# replace text placeholder in top-level CMakeLists.txt
sed -i -E "s/##TEMPLATE_PROJECT_NAME##/${project_name}/g" "${script_dir}/CMakeLists.txt"
sed -i -E "s/##TEMPLATE_TARGET_NAME##/${target_name}/g" "${script_dir}/CMakeLists.txt"
sed -i -E "s/##TEMPLATE_CXX_STANDARD##/${cxx_standard}/g" "${script_dir}/CMakeLists.txt"

if [ "${target_type}" -eq 0 ]; then
    sed -i -E "s/##SECTION_EXECUTABLE_TYPE##//g" "${script_dir}/CMakeLists.txt"
    sed -i -E "/##SECTION_LIBRARY_TYPE##/d" "${script_dir}/CMakeLists.txt"
else
    sed -i -E "s/##SECTION_LIBRARY_TYPE##//g" "${script_dir}/CMakeLists.txt"
    sed -i -E "/##SECTION_EXECUTABLE_TYPE##/d" "${script_dir}/CMakeLists.txt"
fi

# commit all relevant files from the template
git add "${script_dir}/.clang-format"
git add "${script_dir}/.clang-tidy"
git add "${script_dir}/CMakeLists.txt"
git add "${script_dir}/doc/CMakeLists.txt"
git add "${script_dir}/doc/Doxyfile.in"
git add "${script_dir}/src/CMakeLists.txt"

git commit -m "Add initial files which come from the 'cxxtp' project template"

# self-delete this script
rm -- "${script_dir}/$(basename "$0")"
