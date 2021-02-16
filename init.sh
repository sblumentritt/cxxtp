#!/bin/sh

# absolute directory path to this script
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# dependency commits/tags
cmake_modules_tag="v0.2.0"

# define all variables which will be populated from the command line
project_name=
target_name=
target_type=0 # [0 = executable | 1 = library]
cxx_standard=17
git_username=
git_email=
full_dir_structure=0
no_git=0

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
    -f, --full-dir-structure
        Create all common top-level directories according to the coding guidelines.
    --no-git
        No Git repository and commits will be created. '.git/' will no be deleted.
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

# find all CMakeLists.txt and call sed with the given string
find_and_sed() {
    find "${script_dir}" -type f -name CMakeLists.txt -exec sed -i -E "$1" {} \;
}

create_git_repository_and_commits() {
    # remove old Git related files/folder
    rm -rdf "${script_dir}/.git"

    # initialize the Git repo and set local config if requested
    git init

    printf "\nIs '%s' the correct template dir which should be configured? [y/n] " "${script_dir}"
    read -r answer

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
    mkdir "${script_dir}/dependency"
    git submodule add https://github.com/sblumentritt/cmake_modules.git "dependency/cmake_modules"

    cd "${script_dir}/dependency/cmake_modules" || \
        { printf "Unable to change to '%s'\n" "${script_dir}/dependency/cmake_modules" >&2 ; exit 1; }

    # git checkout "${cmake_modules_tag}"

    cd "${script_dir}" || { printf "Unable to change to '%s'\n" "${script_dir}" >&2; exit 1; }

    git add "${script_dir}/dependency/cmake_modules"
    git commit -m "Add 'cmake_modules' submodule"

    # commit all relevant files from the template
    git add "${script_dir}/.clang-format"
    git add "${script_dir}/.clang-tidy"
    git add "${script_dir}/CMakeLists.txt"
    git add "${script_dir}/doc/"
    git add "${script_dir}/src/"

    git commit -m "Add initial files which come from the 'cxxtp' project template"
}

generate_and_configure_cmake_files() {
    if [ "${target_type}" -eq 0 ]; then
        target_specific_dir="${script_dir}/src/${target_name}"

        mkdir -p "${target_specific_dir}"
        mv src/CMakeLists.template "${target_specific_dir}/CMakeLists.txt"
        sed -i -E "s/##TARGET_NAME##/${target_name}/g" "${target_specific_dir}/CMakeLists.txt"

        find_and_sed "s/##SECTION_EXECUTABLE_TYPE##//g"
        find_and_sed "/##SECTION_LIBRARY_TYPE##/d"
    else
        target_specific_dir="${script_dir}/src/lib${target_name}"

        mkdir -p "${target_specific_dir}"
        mv src/CMakeLists.template "${target_specific_dir}/CMakeLists.txt"
        sed -i -E "s/##TARGET_NAME##/lib${target_name}/g" "${target_specific_dir}/CMakeLists.txt"

        find_and_sed "s/##SECTION_LIBRARY_TYPE##//g"
        find_and_sed "/##SECTION_EXECUTABLE_TYPE##/d"
    fi

    find_and_sed "s/##TEMPLATE_PROJECT_NAME##/${project_name}/g"
    find_and_sed "s/##TEMPLATE_TARGET_NAME##/${target_name}/g"
    find_and_sed "s/##TEMPLATE_CXX_STANDARD##/${cxx_standard}/g"
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
        -f|--full-dir-structure)
            full_dir_structure=1
            ;;
        --no-git)
            no_git=1
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

generate_and_configure_cmake_files

if [ "${no_git}" -eq 0 ]; then
    create_git_repository_and_commits
else
    printf "\nThe template depends on the following Git repositories:\n"
    printf "    - https://github.com/sblumentritt/cmake_modules %s\n" "${cmake_modules_tag}"
fi

# create common top-level directories if requested
if [ "${full_dir_structure}" -eq 1 ]; then
    mkdir "${script_dir}/cmake"
    mkdir "${script_dir}/include"
    mkdir "${script_dir}/test"
    mkdir "${script_dir}/example"
    mkdir "${script_dir}/script"
    mkdir "${script_dir}/packaging"
fi

# remove some irrelevant files from the template
rm -f "${script_dir}/LICENSE"
rm -f "${script_dir}/README.md"

# self-delete this script
rm -- "${script_dir}/$(basename "$0")"
