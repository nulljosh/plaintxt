// Hero wall: Plaintxt's editor on its own repo (ide-files.js). Each pane gets a different stretch of a real file, never
// the same one twice, types it line by line with the app's colouring, and keeps the count in the corner like the app.
(function () {
  var wall = document.getElementById('pwall'), data = window.IDE_FILES; if (!wall || !data) return;
  var still = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var n = innerWidth <= 560 ? 4 : innerWidth <= 900 ? 6 : 9;
  var esc = function (s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); };
  var KW = /\b(import|struct|var|let|init|for|in|where|if|else|return|func|extension|self|true|false)\b/g;
  function swiftLine(l) {
    var ci = l.indexOf('//'), head = ci < 0 ? l : l.slice(0, ci), tail = ci < 0 ? '' : l.slice(ci);
    return head.split(/("(?:[^"\\]|\\.)*")/).map(function (p, i) {
      return i % 2 ? '<span class="s">' + esc(p) + '</span>' : esc(p).replace(KW, '<span class="k">$1</span>').replace(/\b([A-Z][A-Za-z]+)\b/g, '<span class="t">$1</span>');
    }).join('') + (tail ? '<span class="c">' + esc(tail) + '</span>' : '');
  }
  function mdLine(l) { return /^#{1,6} /.test(l) ? '<span class="h">' + esc(l) + '</span>' : esc(l); }
  function count(t) {
    var lines = 1 + (t.match(/\n/g) || []).length - (t.endsWith('\n') ? 1 : 0), words = t.split(/\s+/).filter(Boolean).length;
    var chars = window.Intl && Intl.Segmenter ? [...new Intl.Segmenter().segment(t)].length : [...t].length;
    var pl = function (v, w) { return v + ' ' + w + (v === 1 ? '' : 's'); };
    return pl(lines, 'line') + ', ' + pl(words, 'word') + ', ' + pl(chars, 'char');
  }
  // Distinct stretches: 7 non-empty lines at a time, skipping image and badge lines.
  var chunks = [];
  data.files.forEach(function (f) {
    var md = /\.md$/.test(f.path), lines = f.text.split('\n').filter(function (l) { return l.trim() && !/^<|^!\[|^<p>/.test(l); }).map(function (l) { return l.length > 64 ? l.slice(0, 63) + '…' : l; });
    for (var i = 0; i + 4 <= lines.length; i += 7) chunks.push({ name: f.path.split('/').pop(), md: md, lines: lines.slice(i, i + 7) });
  });
  // interleave files so neighbouring panes differ
  chunks.sort(function (a, b) { return (chunks.indexOf(a) % 3) - (chunks.indexOf(b) % 3); });
  var el = function (t, c, x) { var e = document.createElement(t); if (c) e.className = c; if (x != null) e.textContent = x; return e; };
  var wait = function (ms) { return new Promise(function (r) { setTimeout(r, still ? 0 : ms); }); };
  for (var i = 0; i < Math.min(n, chunks.length); i++) (function (i) {
    var a = wall.appendChild(el('div', 'pe')), hd = a.appendChild(el('div', 'pe-hd')), pre = a.appendChild(el('pre')), ft = a.appendChild(el('div', 'pe-ft'));
    var k = i;
    function play() {
      var c = chunks[k % chunks.length]; k += n;
      hd.textContent = ''; hd.appendChild(el('span', '', c.name)); hd.appendChild(el('span', '', 'Saved'));
      var typed = '';
      pre.innerHTML = '';
      return c.lines.reduce(function (q, l) { return q.then(function () {
        typed += l + '\n'; pre.innerHTML = typed.replace(/\n$/, '').split('\n').map(c.md ? mdLine : swiftLine).join('\n');
        ft.textContent = count(typed); return wait(380 + l.length * 12);
      }); }, wait(300)).then(function () { return wait(3200); });
    }
    if (still) play(); else wait(i * 260).then(function loop() { return play().then(loop); });
  })(i);
})();

// Hero parallax: the wall drifts at 0.45, the copy lifts at 0.2 and fades. Off under reduced motion.
(function () {
  var bg = document.querySelector('.hero-bg'), copy = document.querySelector('.hero-copy');
  if (!bg || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var t = 0;
  addEventListener('scroll', function () {
    if (t) return;
    t = requestAnimationFrame(function () {
      t = 0; var y = scrollY, h = innerHeight; if (y > h * 1.2) return;
      bg.style.setProperty('--py', (y * .45) + 'px');
      copy.style.transform = 'translate3d(0,' + (y * .2) + 'px,0)'; copy.style.opacity = Math.max(0, 1 - y / (h * .7));
    });
  }, { passive: true });
})();
