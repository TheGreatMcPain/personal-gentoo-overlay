# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: xdg-utils.eclass
# @MAINTAINER:
# gnome@gentoo.org
# @AUTHOR:
# Original author: Gilles Dartiguelongue <eva@gentoo.org>
# @BLURB: Auxiliary functions commonly used by XDG compliant packages.
# @DESCRIPTION:
# This eclass provides a set of auxiliary functions needed by most XDG
# compliant packages.
# It provides XDG stack related functions such as:
#  * XDG .desktop files cache management
#  * XDG mime information database management

case "${EAPI:-0}" in
	0|1|2|3|4|5|6|7) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

# @ECLASS-VARIABLE: DESKTOP_DATABASE_UPDATE_BIN
# @INTERNAL
# @DESCRIPTION:
# Path to update-desktop-database
: "${DESKTOP_DATABASE_UPDATE_BIN:="/usr/bin/update-desktop-database"}"

# @ECLASS-VARIABLE: DESKTOP_DATABASE_DIR
# @INTERNAL
# @DESCRIPTION:
# Directory where .desktop files database is stored
: "${DESKTOP_DATABASE_DIR="/usr/share/applications"}"

# @ECLASS-VARIABLE: GTK_UPDATE_ICON_CACHE
# @INTERNAL
# @DESCRIPTION:
# Path to gtk-update-icon-cache
: "${GTK_UPDATE_ICON_CACHE:="/usr/bin/gtk-update-icon-cache"}"

# @ECLASS-VARIABLE: MIMEINFO_DATABASE_UPDATE_BIN
# @INTERNAL
# @DESCRIPTION:
# Path to update-mime-database
: "${MIMEINFO_DATABASE_UPDATE_BIN:="/usr/bin/update-mime-database"}"

# @ECLASS-VARIABLE: MIMEINFO_DATABASE_DIR
# @INTERNAL
# @DESCRIPTION:
# Directory where .desktop files database is stored
: "${MIMEINFO_DATABASE_DIR:="/usr/share/mime"}"

# @ECLASS-VARIABLE: XDG_ECLASS_ICONS
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of icons provided by the package

# @FUNCTION: xdg_environment_reset
# @DESCRIPTION:
# Clean up environment for clean builds.
xdg_environment_reset() {
	# Prepare XDG base directories
	export XDG_DATA_HOME="${HOME}/.local/share"
	export XDG_CONFIG_HOME="${HOME}/.config"
	export XDG_CACHE_HOME="${HOME}/.cache"
	export XDG_RUNTIME_DIR="${T}/run"
	mkdir -p "${XDG_DATA_HOME}" "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}" \
		"${XDG_RUNTIME_DIR}" || die
	# This directory needs to be owned by the user, and chmod 0700
	# https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
	chmod 0700 "${XDG_RUNTIME_DIR}" || die

	unset DBUS_SESSION_BUS_ADDRESS
}

# @FUNCTION: xdg_desktop_database_update
# @DESCRIPTION:
# Updates the .desktop files database.
# Generates a list of mimetypes linked to applications that can handle them
xdg_desktop_database_update() {
		has ${EAPI:-0} 7 || BROOT="${EROOT}"
        local updater="${BROOT%/}${DESKTOP_DATABASE_UPDATE_BIN}"

        if [[ ${EBUILD_PHASE} != post* ]] ; then
                die "xdg_desktop_database_update must be used in pkg_post* phases."
        fi

        if [[ ! -x "${updater}" ]] ; then
                debug-print "${updater} is not executable"
                return
        fi

        ebegin "Updating .desktop files database"
        "${updater}" -q "${EROOT}${DESKTOP_DATABASE_DIR}"
        eend $?
}

# @FUNCTION: xdg_icon_savelist
# @DESCRIPTION:
# Find the icons that are about to be installed and save their location
# in the XDG_ECLASS_ICONS environment variable. This is only
# necessary for eclass implementations that call
# xdg_icon_cache_update conditionally.
# This function should be called from pkg_preinst.
xdg_icon_savelist() {
	XDG_ECLASS_ICONS=()
	while IFS= read -r -d '' f; do
		XDG_ECLASS_ICONS+=( "${f}" )
	done < <(cd "${D}" && find 'usr/share/icons' -type f -print0 2>/dev/null)

	export XDG_ECLASS_ICONS
}

# @FUNCTION: xdg_icon_cache_update
# @DESCRIPTION:
# Updates Gtk+ icon cache files under /usr/share/icons.
# This function should be called from pkg_postinst and pkg_postrm.
xdg_icon_cache_update() {
	has ${EAPI:-0} 7 || BROOT="${EROOT}"
	local updater="${BROOT%/}${GTK_UPDATE_ICON_CACHE}"

	if [[ ! -x "${updater}" ]] ; then
		debug-print "${updater} is not executable"
		return
	fi

	ebegin "Updating icons cache"

	local retval=0
	local fails=( )

	for dir in "${EROOT%/}"/usr/share/icons/*
	do
		if [[ -f "${dir}/index.theme" ]] ; then
			local rv=0

			"${updater}" -qf "${dir}"
			rv=$?

			if [[ ! $rv -eq 0 ]] ; then
					debug-print "Updating cache failed on ${dir}"

					# Add to the list of failures
					fails+=( "${dir}" )

					retval=2
			fi
		elif [[ $(ls "${dir}") = "icon-theme.cache" ]]; then
			# Clear stale cache files after theme uninstallation
			rm "${dir}/icon-theme.cache"
		fi

		if [[ -z $(ls "${dir}") ]]; then
			# Clear empty theme directories after theme uninstallation
			rmdir "${dir}"
		fi
	done

	eend ${retval}

	for f in "${fails[@]}" ; do
		eerror "Failed to update cache with icon $f"
	done
}

# @FUNCTION: xdg_mimeinfo_database_update
# @DESCRIPTION:
# Update the mime database.
# Creates a general list of mime types from several sources
xdg_mimeinfo_database_update() {
	has ${EAPI:-0} 7 || BROOT="${EROOT}"
	local updater="${BROOT%/}${MIMEINFO_DATABASE_UPDATE_BIN}"

	if [[ ${EBUILD_PHASE} != post* ]] ; then
		die "xdg_mimeinfo_database_update must be used in pkg_post* phases."
	fi

	if [[ ! -x "${updater}" ]] ; then
		debug-print "${updater} is not executable"
		return
	fi

	ebegin "Updating shared mime info database"
	"${updater}" "${BROOT%/}${MIMEINFO_DATABASE_DIR}"
	eend $?
}
