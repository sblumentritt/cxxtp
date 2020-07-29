#!/bin/sh

# - [ ] get absolute directory where the script is
# - [x] add command line parsing
#     - project name
#     - target name
#     - type (executable or library)
#     - C++ version
#     - different git username/email
# - [ ] remove .git folder
# - [ ] remove .gitmodules file
# - [ ] remove all folder in dependency/
# - [ ] git init
# - [ ] create empty initial commit
# - [ ] create commit with gitignore
# - [ ] add 'cmake_modules' submodule to dependency at specific version
# - [ ] commit submodule addition
# - [ ] replace project name in CMake
# - [ ] replace target name in CMake
# - [ ] depending of the given type uncomment a specific section and remove the other
# - [ ] commit initial files
# - [ ] remove placeholder folder?
# - [ ] remove this script

# define all variables which will be populated from the command line
project_name=
target_name=
target_type=0 # [1 = executable | 2 = library]
cxx_standard=0
git_username=
git_email=

usage() {
    printf "Usage: %s [OPTIONS]

OPTIONS:
    -h, --help
        Prints help information.
    --project <NAME>
        Name which should be used for the CMake project.
    --target <NAME>
        Name which should be used for the CMake target.
    --bin
        Use a binary (executable) CMake target.
    --lib
        Use a library CMake target.
    --standard <VERSION>
        C++ standard which should be used to build the target. [possible values: 11, 14, 17, 20]
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

eprint_multiple_target_types() {
    printf "ERROR: Target type needs to be unique.\n" >&2
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

check_required_integer_option() {
    if [ "$1" -eq 0 ]; then
        eprint_required_option "$2"
        usage
    fi
}

# parse command line arguments
while :; do
    case $1 in
        --project)
            if [ -n "$2" ]; then
                project_name=$2
                shift
            else
                eprint_empty_argument "--project"
                usage
            fi
            ;;
        --target)
            if [ -n "$2" ]; then
                target_name=$2
                shift
            else
                eprint_empty_argument "--target"
                usage
            fi
            ;;
        --bin)
            if [ $target_type -eq 0 ]; then
                target_type=1
            else
                eprint_multiple_target_types
                usage
            fi
            ;;
        --lib)
            if [ $target_type -eq 0 ]; then
                target_type=2
            else
                eprint_multiple_target_types
                usage
            fi
            ;;
        --standard)
            if [ -n "$2" ]; then
                if [ "$2" -eq 11 ] || [ "$2" -eq 14 ] || [ "$2" -eq 17 ] || [ "$2" -eq 20 ]; then
                    cxx_standard=$2
                    shift
                else
                    printf "ERROR: Unsupported argument value '%d' for '%s'\n" \
                        "$2" \
                        "--standard" \
                        >&2
                    usage
                fi
            else
                eprint_empty_argument "--standard"
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

check_required_string_option "$project_name" "--project"
check_required_string_option "$target_name" "--target"

check_required_integer_option "$target_type" "[--bin|--lib]"
check_required_integer_option "$cxx_standard" "--standard"
