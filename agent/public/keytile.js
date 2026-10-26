// Renders one deck key; shared by the phone deck page and the PC editor so both look identical.
export function keyTile(b, iconUrl) {
  const el = document.createElement('button');
  el.className = 'key';
  el.dataset.id = b.id;
  if (b.color) el.style.background = b.color;
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
