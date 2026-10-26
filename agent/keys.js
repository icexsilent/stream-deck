// Converts "ctrl+shift+m" into Windows virtual-key codes.
const NAMED = {
  ctrl: 0x11, shift: 0x10, alt: 0x12, win: 0x5b,
  enter: 0x0d, esc: 0x1b, space: 0x20, tab: 0x09, backspace: 0x08,
  up: 0x26, down: 0x28, left: 0x25, right: 0x27,
  volumeup: 0xaf, volumedown: 0xae, mute: 0xad,
  playpause: 0xb3, next: 0xb0, prev: 0xb1, printscreen: 0x2c,
};

function toVks(combo) {
  return combo.toLowerCase().split('+').map((k) => {
    k = k.trim();
    if (k in NAMED) return NAMED[k];
    if (/^[a-z0-9]$/.test(k)) return k.toUpperCase().charCodeAt(0);
    const f = /^f([1-9]|1\d|2[0-4])$/.exec(k);
    if (f) return 0x6f + Number(f[1]);
    throw new Error(`tecla desconhecida: "${k}" em "${combo}"`);
  });
}

module.exports = { toVks };
