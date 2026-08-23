# Maintainer: void <null275@proton.me>
pkgname=soltui
pkgver=0.4
pkgrel=1
pkgdesc="RNG TUI game for mac / linux (haha windows users fuck off)"
arch=('any')
url="https://github.com/null275/soltui"
license=('GPL-3.0-or-later')
depends=('sh')
source=("https://github.com/null275/soltui/releases/download/release3/soltui.0.4.tar.gz")
sha256sums=('SKIP')

package() {
	cd "$srcdir"
	
	install -Dm755 soltui.sh "${pkgdir}/usr/bin/soltui"
}
