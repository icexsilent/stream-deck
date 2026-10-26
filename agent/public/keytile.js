// Renders one deck key; shared by the phone deck page and the PC editor so both look identical.
export function keyTile(b, iconUrl, live) {
  const el = document.createElement('button');
  el.className = 'key';
  el.dataset.id = b.id;
  if (b.color) el.style.background = b.color;
  if (b.type === 'widget') {
    el.classList.add('widget');
    const part = (cls) => Object.assign(document.createElement('span'), { className: cls });
    el.append(part('w-name'), part('w-text'), part('w-sub'), Object.assign(part('w-bar'), { innerHTML: '<i></i>' }));
    el.querySelector('.w-name').textContent = b.label;
    updateLive(el, live);
    return el;
  }
  if (b.icon) {
    const img = document.createElement('img');
    img.src = iconUrl(b.icon);
    img.alt = '';
    // Program icons (and small exe icons) look wrong stretched edge to edge; show them centered instead of as a cover.
    if (b.icon.startsWith('app-')) img.classList.add('small');
    img.onload = () => { if (img.naturalWidth < 128) img.classList.add('small'); };
    img.onerror = () => img.remove();
    el.append(img);
  } else if (b.type === 'game') {
    const i = document.createElement('span');
    i.className = 'initial';
    i.textContent = b.label.trim()[0] ?? '?';
    i.setAttribute('aria-hidden', 'true');
    el.append(i);
  } else {
    el.classList.add('text-only');
  }
  const label = document.createElement('span');
  label.className = 'label';
  label.textContent = b.label;
  el.append(label);
  return el;
}

/** Refreshes a live key in place, so updates every second don't rebuild the grid or steal focus. */
export function updateLive(el, v = {}) {
  el.querySelector('.w-text').textContent = v.text ?? '…';
  el.querySelector('.w-sub').textContent = v.sub ?? '';
  const bar = el.querySelector('.w-bar');
  bar.hidden = typeof v.progress !== 'number';
  bar.firstChild.style.width = `${Math.round((v.progress ?? 0) * 100)}%`;
  el.classList.toggle('alert', Boolean(v.alert));
  el.setAttribute('aria-label', `${el.querySelector('.w-name').textContent}: ${v.text ?? ''} ${v.sub ?? ''}`.trim());
}
