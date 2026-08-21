# Maintainer: void <null275@proton.me>
pkgname=soltui
pkgver=0.2
pkgrel=1
pkgdesc="RNG TUI game for posix shells"
arch=('any')
url="https://github.com/null275/soltui"
license=('GPL-3.0-or-later')
depends=('sh')
source=("https://github.com/null275/soltui/releases/download/release2/soltui.0.2.tar.gz")
sha256sums=('SKIP')

package() {
	cd "$srcdir"
	
	install -Dm755 soltui.sh "${pkgdir}/usr/bin/soltui"
}
