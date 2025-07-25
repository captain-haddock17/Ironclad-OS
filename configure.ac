#  configure.ac: Configure template of the project.
#  Copyright (C) 2023-2024 streaksu
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Project initialization.
AC_INIT([Ironclad], [m4_esyscmd([./version.sh])], [https://ironclad-os.org/contributing.html], [ironclad])
AC_PREREQ([2.69])
###############################################################################
# General project options.
AC_CONFIG_AUX_DIR([build-aux])

SRCDIR="$(cd "$srcdir" && pwd -P)"
AC_SUBST([SRCDIR])

AC_CANONICAL_HOST
case "$host_cpu" in
    amd64) host_cpu=x86_64 ;;
esac

# Portably convert relative paths into absolute paths.
rel2abs() {
    rel2abs_first=true
    for i in $1; do
        if test $rel2abs_first = true; then
            case "$i" in
                /*)
                    printf "%s" "$i"
                    ;;
                */*)
                    if test -d "$(dirname "$i")"; then
                        printf "%s" "$(cd "$(dirname "$i")" && pwd -P)/$(basename "$i")"
                    else
                        printf "false"
                    fi
                    ;;
                *)
                    printf "%s" "$i"
                    ;;
            esac
            rel2abs_first=false
        else
            printf " %s" "$i"
        fi
    done
    printf "\n"
}

werror_state="no"
AC_ARG_ENABLE([werror],
    [AS_HELP_STRING([--enable-werror], [treat warnings as errors])],
    [werror_state="$enableval"])
if test "$werror_state" = "yes"; then
    AC_SUBST([WERROR_FLAG], [-Werror])
else
    AC_SUBST([WERROR_FLAG], [-Wno-error])
fi

AC_PROG_MKDIR_P
MKDIR_P="$(rel2abs "$MKDIR_P")"
AC_PROG_INSTALL
INSTALL="$(rel2abs "$INSTALL")"
AC_PROG_GREP
GREP="$(rel2abs "$GREP")"
AC_PROG_SED
SED="$(rel2abs "$SED")"

AC_CHECK_PROG([FIND_FOUND], [find], [yes])
if ! test "x$FIND_FOUND" = "xyes"; then
    AC_MSG_ERROR([find not found, please install find before configuring])
fi

# $1 - UPPERCASEVAR, $2 - default program
AC_DEFUN([GET_PROG_FROM_TOOLCHAIN], [
    AC_ARG_VAR([$1], [$2 command @<:@default: $2@:>@])

    if ! test -z "$$1"; then
        first_elem="$(echo "$$1" | cut -f 1 -d " ")"
        case "$first_elem" in
            */*)
                if test -f "$first_elem" && test -x "$first_elem"; then
                    $1_USER_FOUND=yes
                fi
                ;;
            *)
                AC_CHECK_PROG([$1_USER_FOUND], [$$1], [yes])
                ;;
        esac

        if ! test "x$$1_USER_FOUND" = "xyes"; then
            AC_MSG_ERROR([$2 not found, please install $2 before configuring])
        fi
    else
        AC_CHECK_TOOL([$1], [$2], [:])
        if test "x$$1" = "x:"; then
            AC_MSG_ERROR([$2 not found, please install $2 or set $1 to a valid command])
        fi
    fi

    $1="$(rel2abs "$$1")"
])

GET_PROG_FROM_TOOLCHAIN([AR], [gcc-ar])
GET_PROG_FROM_TOOLCHAIN([CC], [gcc])
GET_PROG_FROM_TOOLCHAIN([OBJDUMP], [objdump])
GET_PROG_FROM_TOOLCHAIN([STRIP], [strip])

GCC_VERSION="$($CC -dumpversion)"
if test "${GCC_VERSION%%.*}" -lt "14"; then
    AC_MSG_ERROR([GCC version 14 or greater is required to build Ironclad])
fi

m4_define([DEFAULT_ADAFLAGS], [-g -O2 -pipe])
AC_ARG_VAR([ADAFLAGS], [Ada flags @<:@default: ]DEFAULT_ADAFLAGS[@:>@])
test "x${ADAFLAGS+set}" = "x" && ADAFLAGS="DEFAULT_ADAFLAGS"

m4_define([DEFAULT_ASFLAGS], [-g -O2 -pipe])
AC_ARG_VAR([ASFLAGS], [assembler flags @<:@default: ]DEFAULT_ASFLAGS[@:>@])
test "x${ASFLAGS+set}" = "x" && ASFLAGS="DEFAULT_ASFLAGS"

m4_define([DEFAULT_CFLAGS], [-g -O2 -pipe])
AC_ARG_VAR([CFLAGS], [C compiler flags @<:@default: ]DEFAULT_CFLAGS[@:>@])
test "x${CFLAGS+set}" = "x" && CFLAGS="DEFAULT_CFLAGS"

m4_define([DEFAULT_LDFLAGS], [])
AC_ARG_VAR([LDFLAGS], [linker flags @<:@default: ]DEFAULT_LDFLAGS[@:>@])
test "x${LDFLAGS+set}" = "x" && LDFLAGS="DEFAULT_LDFLAGS"
###############################################################################
# A ton of tools use source date epoch in order to not use date in the effort
# of doing reproducible builds.
# This command uses git, but thats no biggie because there is a fallback if
# no git is present and it is meant to only be run when regenerating, so
# tarball users will (ideally) never see this.
SOURCE_DATE_EPOCH="m4_esyscmd([if git log -1 >/dev/null 2>&1; then git log -1 --pretty=%ct | tr -d '\n'; else printf 1546300800; fi])"
AC_SUBST([SOURCE_DATE_EPOCH])
###############################################################################
# Get programs and put them in comfortable variables.

# $1 - UPPERCASEVAR, $2 - default program, $3 - nice name, $4 - set to "err" to error
# on not program found
AC_DEFUN([GET_PROG], [
    m4_define([DEFAULT_$1], [$2])
    AC_ARG_VAR([$1], [$3 command @<:@default: ]DEFAULT_$1[@:>@])

    if ! test -z "$$1"; then
        first_elem="$(echo "$$1" | cut -f 1 -d " ")"
        case "$first_elem" in
            */*)
                if test -f "$first_elem" && test -x "$first_elem"; then
                    $1_USER_FOUND=yes
                fi
                ;;
            *)
                AC_CHECK_PROG([$1_USER_FOUND], [$$1], [yes])
                ;;
        esac

        if ! test "x$$1_USER_FOUND" = "xyes"; then
            AC_MSG_ERROR([$3 not found, please install $3 or set $1 to a valid command])
        fi
    else
        $1="DEFAULT_$1"
        AC_CHECK_PROG([$1_FOUND], [$$1], [yes])
        if ! test "x$$1_FOUND" = "xyes"; then
            if test "x$4" = "xerr"; then
                AC_MSG_ERROR([$3 not found, please install $3 or set $1 to a valid command])
            else
                AC_MSG_WARN([$3 not found, please install $3 or set $1 to a valid command])
            fi
        fi
    fi

    $1="$(rel2abs "$$1")"
])

GET_PROG([MAKEINFO], [makeinfo], [makeinfo])
GET_PROG([TEXI2DVI], [texi2dvi], [texi2dvi])
GET_PROG([TEXI2HTML], [makeinfo --no-split --html], [texi2html])
GET_PROG([GPRBUILD], [gprbuild], [gprbuild], [err])
GET_PROG([GNATPROVE], [gnatprove], [gnatprove])
GET_PROG([TYPOS], [typos], [typos])

# $1 - UPPERCASEVAR, $2 - default program
AC_DEFUN([GET_TOOL_FROM_GPRBUILD], [
    AC_ARG_VAR([$1], [$2 executable path])

    gprbuild_path="$(command -v "$(echo "$GPRBUILD" | cut -f 1 -d " ")")"

    if test "x$$1" = "x"; then
        $1="$(dirname "$gprbuild_path")"/../libexec/gprbuild/$2
        if ! ( test -f "$$1" && test -x "$$1"); then
            $1="$(dirname "$gprbuild_path")"/../lib/gprbuild/$2
        fi
        if ! ( test -f "$$1" && test -x "$$1"); then
            AC_MSG_ERROR([No recorded path to $2 valid])
        fi
    else
        if ! ( test -f "$$1" && test -x "$$1"); then
            AC_MSG_ERROR([Provided $2 path not valid])
        fi
    fi
])

GET_TOOL_FROM_GPRBUILD([GPRBIND], [gprbind])
GET_TOOL_FROM_GPRBUILD([GPRLIB], [gprlib])
###############################################################################
# Platform acquisition and checking.
AC_ARG_VAR([PLATFORM], [target platform to build Ironclad for @<:@default: limine@:>@])

if test "x$PLATFORM" = "x"; then
    PLATFORM=limine
fi

case $PLATFORM in
    limine)
        ;;
    *)
        AC_MSG_ERROR([$PLATFORM is not a valid target platform])
        ;;
esac

GPRBUILD_TARGET="$($CC -dumpmachine)"
AC_SUBST([GPRBUILD_TARGET])
###############################################################################
# Finalize the settings and output the files.
AC_PREFIX_DEFAULT([/usr/local])
AC_CONFIG_FILES([GNUmakefile ironclad.gpr rts.gpr gprconfig/compilers.xml gprconfig/gprconfig.xml])
AC_OUTPUT
