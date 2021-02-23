#!/bin/sh

# absolute directory path to this script
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# dependency commits/tags
cmake_modules_tag="v0.3.0"
catch2_tag="v2.13.4"

# define all variables which will be populated from the command line
project_name=
target_name_lib=
target_name_exe=
cxx_standard=17
enable_testing=0
no_git=0

usage() {
    printf "Usage: %s [OPTIONS]

OPTIONS:
    -h, --help
        Prints help information.
    -p, --project <NAME>
        Name which should be used for the CMake project.
    -l, --lib <NAME>
        Create a library CMake target with the given name.
    -e, --executable <NAME>
        Create a executable CMake target with the given name.
    -s, --standard <VERSION>
        C++ standard which should be used to build the target. [possible values: 11, 14, 17, 20]
        Default: 17
    -t, --testing
        Create targets, files and add submodule for testing. Only possible with a library target.
    --no-git
        No Git repository and commits will be created. '.git/' will no be deleted.
" "$(basename "$0")" 1>&2

    exit 1
}

eprint_empty_argument() {
    printf "ERROR: '%s' requires a non-empty option argument.\n" "$1" >&2
}

eprint_required_option() {
    printf "ERROR: '%s' command line option is required.\n" "$1" >&2
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

    printf "\nYou can now change the Git config before creating the first commit.\n"
    printf "Use a separate terminal or split!\nPress any key to continue..."
    # shellcheck disable=SC2034 # variable is intentionally unused
    read -r _tmp

    # create first commit as empty commit
    git commit --allow-empty -m "Initial empty commit"

    # add/commit .gitignore file
    git add "${script_dir}/.gitignore"
    git commit -m "Add .gitignore file"

    mkdir "${script_dir}/dependency"

    # add 'cmake_modules' as submodule
    git submodule add https://github.com/sblumentritt/cmake_modules.git "dependency/cmake_modules"

    cd "${script_dir}/dependency/cmake_modules" || \
        { printf "Unable to change to '%s'\n" "${script_dir}/dependency/cmake_modules" >&2 ; exit 1; }

    git checkout "${cmake_modules_tag}"

    cd "${script_dir}" || { printf "Unable to change to '%s'\n" "${script_dir}" >&2; exit 1; }

    git add "${script_dir}/dependency/cmake_modules"
    git commit -m "Add 'cmake_modules' submodule"

    if [ "${enable_testing}" -eq 1 ]; then
        # add 'Catch2' as submodule
        git submodule add https://github.com/catchorg/Catch2.git "dependency/Catch2"

        cd "${script_dir}/dependency/Catch2" || \
        { printf "Unable to change to '%s'\n" "${script_dir}/dependency/Catch2" >&2 ; exit 1; }

        git checkout "${catch2_tag}"

        cd "${script_dir}" || { printf "Unable to change to '%s'\n" "${script_dir}" >&2; exit 1; }

        git add "${script_dir}/dependency/Catch2"
        git commit -m "Add 'Catch2' submodule"
    fi

    # commit all relevant files from the template
    git add "${script_dir}/.clang-format"
    git add "${script_dir}/.clang-tidy"
    git add "${script_dir}/CMakeLists.txt"
    git add "${script_dir}/doc/"
    git add "${script_dir}/src/"
    git add "${script_dir}/test/"
    git add "${script_dir}/cmake/"

    git commit -m "Add initial files which come from the 'cxxtp' project template"
}

generate_and_configure_cmake_files() {
    local cmake_template_file="${script_dir}/src/CMakeLists.template"

    if [ -n "${target_name_lib}" ]; then
        target_specific_dir="${script_dir}/src/${target_name_lib}"

        mkdir -p "${target_specific_dir}"
        cp "${cmake_template_file}" "${target_specific_dir}/CMakeLists.txt"

        find_and_sed "s/##LIBRARY_TARGET_NAME##/${target_name_lib}/g"
        sed -i -E "s/##SECTION_LIBRARY_TYPE##//g" "${script_dir}/CMakeLists.txt"
        sed -i -E "s/##SECTION_LIBRARY_TYPE##//g" "${script_dir}/src/CMakeLists.txt"
        sed -i -E "s/##SECTION_LIBRARY_TYPE##//g" "${target_specific_dir}/CMakeLists.txt"
        sed -i -E "s/##TARGET_NAME##/${target_name_lib}/g" "${target_specific_dir}/CMakeLists.txt"
    fi

    if [ -n "${target_name_exe}" ]; then
        target_specific_dir="${script_dir}/src/${target_name_exe}"

        mkdir -p "${target_specific_dir}"
        cp "${cmake_template_file}" "${target_specific_dir}/CMakeLists.txt"

        find_and_sed "s/##EXECUTABLE_TARGET_NAME##/${target_name_exe}/g"
        sed -i -E "s/##SECTION_EXECUTABLE_TYPE##//g" "${script_dir}/CMakeLists.txt"
        sed -i -E "s/##SECTION_EXECUTABLE_TYPE##//g" "${script_dir}/src/CMakeLists.txt"
        sed -i -E "s/##SECTION_EXECUTABLE_TYPE##//g" "${target_specific_dir}/CMakeLists.txt"
        sed -i -E "s/##TARGET_NAME##/${target_name_exe}/g" "${target_specific_dir}/CMakeLists.txt"
    fi

    find_and_sed "s/##TEMPLATE_PROJECT_NAME##/${project_name}/g"
    find_and_sed "s/##TEMPLATE_CXX_STANDARD##/${cxx_standard}/g"

    # delete sections when they are still available
    find_and_sed "/##SECTION_LIBRARY_TYPE##/d"
    find_and_sed "/##SECTION_EXECUTABLE_TYPE##/d"

    if [ "${enable_testing}" -eq 1 ]; then
        mv "${script_dir}/test/library_target_name" "${script_dir}/test/${target_name_lib}"
        find_and_sed "s/##SECTION_TESTING##//g"
    else
        rm -rf "${script_dir}/test"
        find_and_sed "/##SECTION_TESTING##/d"
    fi

    # remove template file which is no longer needed
    rm "${cmake_template_file}"
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
        -l|--lib)
            if [ -n "$2" ]; then
                target_name_lib=$2
                shift
            else
                eprint_empty_argument "-l, --lib"
                usage
            fi
            ;;
        -e|--executable)
            if [ -n "$2" ]; then
                target_name_exe=$2
                shift
            else
                eprint_empty_argument "-e, --executable"
                usage
            fi
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
        -t|--testing)
            enable_testing=1
            ;;
        --no-git)
            no_git=1
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

# check that required options are set
if [ -z "${project_name}" ]; then
    eprint_required_option "-p, --project"
    usage
fi

if [ -z "${target_name_lib}" ] && [ -z "${target_name_exe}" ]; then
    printf "ERROR: At least one target type has to be used on the command line.\n" >&2
    printf "ERROR: Set either '-l, --lib' or '-e, --executable'.\n" >&2
    usage
elif [ "${target_name_lib}" = "${target_name_exe}" ]; then
    printf "ERROR: Library and executable target can not use the same name.\n" >&2
    usage
fi

if [ "${enable_testing}" -eq 1 ] && [ -z "${target_name_lib}" ]; then
    printf "INFO: Testing related configurations will not be created.\n" >&2
    printf "INFO: Provide the '-l, --lib' flag for the testing configurations.\n" >&2
    enable_testing=0
fi

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

    if [ "${enable_testing}" -eq 1 ]; then
        printf "    - https://github.com/catchorg/Catch2 %s\n" "${catch2_tag}"
    fi
fi

# remove some irrelevant files from the template
rm -f "${script_dir}/LICENSE"
rm -f "${script_dir}/README.md"

# self-delete this script
rm -- "${script_dir}/$(basename "$0")"
