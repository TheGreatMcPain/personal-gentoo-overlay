# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_8 )
inherit distutils-r1

DESCRIPTION="Cast media from Jellyfin to MPV"
HOMEPAGE="https://github.com/jellyfin/jellyfin-mpv-shim"

SRC_URI="
	https://github.com/jellyfin/jellyfin-mpv-shim/archive/v${PV}.tar.gz -> ${P}.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systray display-mirroring shaders discord"

DEPEND="
	media-video/mpv[libmpv]
	dev-python/python-mpv
	dev-python/python-mpv-jsonipc
	dev-python/jellyfin-apiclient-python
	dev-lang/python:*[tk]
	systray? ( dev-python/pystray )
	display-mirroring? (
		dev-python/jinja
		dev-python/pywebview
	)
	shaders? ( dev-util/mpv-shim-default-shaders )
	discord? ( dev-python/pypresence )
"
RDEPEND="${DEPEND}"
BDEPEND=""

shaders_symlink() {
	ln -sv "/usr/share/mpv-shim-default-shaders" \
		"${ED}/$(python_get_sitedir)/jellyfin_mpv_shim/default_shader_pack" || die
}

src_install() {
	distutils-r1_src_install

	# Setup symlink to mpv-shim-default-shaders
	if use shaders; then
		python_foreach_impl shaders_symlink
	fi
}