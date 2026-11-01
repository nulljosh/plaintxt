// The Mac IDE demo: Plaintxt's own files (ide-files.js, from tools/ide-demo.py), coloured by a few regexes,
// with the panes the Mac app has. Nothing runs on a server; the chat lines are canned and say so.
(function () {
  var data = window.IDE_FILES; if (!data) return;
  var $ = function (id) { return document.getElementById(id); };
  var filesEl = $('ideFiles'), code = $('ideCode'), pane = $('idePane'), title = $('ideTitle'), stat = $('ideStat');
  if (!filesEl) return;
  var open = 0, tab = 'chat';
  function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
  function name(p) { return p.split('/').pop(); }
  // Same rules as ios/App/Stats.swift: an empty doc is 1 line, a trailing newline adds none, chars are graphemes.
  function count(t) {
    var lines = 1 + (t.match(/\n/g) || []).length - (t.endsWith('\n') ? 1 : 0);
    var words = t.split(/\s+/).filter(Boolean).length;
    var chars = window.Intl && Intl.Segmenter ? [...new Intl.Segmenter().segment(t)].length : [...t].length;
    return lines + ' lines, ' + words + ' words, ' + chars + ' chars';
  }
  var KW = /\b(import|struct|var|let|init|for|in|where|if|else|return|func|extension|self|true|false)\b/g;
  function swiftLine(l) {
    var ci = l.indexOf('//'), head = ci < 0 ? l : l.slice(0, ci), tail = ci < 0 ? '' : l.slice(ci);
    // strings first, then keywords and types outside them
    var parts = head.split(/("(?:[^"\\]|\\.)*")/);
    var out = parts.map(function (p, i) {
      if (i % 2) return '<span class="s">' + esc(p) + '</span>';
      return esc(p).replace(KW, '<span class="k">$1</span>').replace(/\b([A-Z][A-Za-z]+)\b/g, '<span class="t">$1</span>');
    }).join('');
    return out + (tail ? '<span class="c">' + esc(tail) + '</span>' : '');
  }
  function mdLine(l) { return /^#{1,6} /.test(l) ? '<span class="h">' + esc(l) + '</span>' : esc(l); }
  function show(i) {
    open = i;
    var f = data.files[i], md = /\.md$/.test(f.path);
    code.innerHTML = f.text.replace(/\n$/, '').split('\n').map(function (l) { return '<span class="l">' + (md ? mdLine(l) : swiftLine(l)) + '</span>'; }).join('');
    code.scrollTop = 0;
    title.textContent = name(f.path);
    stat.textContent = count(f.text);
    filesEl.querySelectorAll('button').forEach(function (b) { b.setAttribute('aria-current', String(+b.dataset.i === i)); });
    paint();
  }
  function paint() {
    var f = data.files[open];
    if (tab === 'chat') pane.innerHTML = '<span class="me">You: what does ' + esc(name(f.path)) + ' do?</span>\n' + esc(answer(f)) + '\n\n<span class="me">Chat sees the open file and runs on your own Mac. These lines are a sample.</span>';
    else if (tab === 'build') pane.innerHTML = '<span class="me">$ swiftc ios/App/*.swift ios/Checks/main.swift -o checks && ./checks</span>\n' + data.build.map(function (l) { return '<span class="ok">' + esc(l) + '</span>'; }).join('\n');
    else pane.innerHTML = '<span class="me">$ plain stat ' + esc(f.path) + '</span>\n' + count(f.text);
  }
  function answer(f) {
    var first = (f.text.match(/^\/\/ (.+)$/m) || [])[1];
    if (/\.md$/.test(f.path)) return 'The README. It says what Plaintxt is for: a text file is a string, and the system already edits strings well.';
    return first ? 'Its first comment says it: ' + first : 'It is a Swift file in the app.';
  }
  var lastDir = '';
  data.files.forEach(function (f, i) {
    var dir = f.path.includes('/') ? f.path.slice(0, f.path.lastIndexOf('/')) : '';
    if (dir !== lastDir) { var d = document.createElement('div'); d.className = 'dir'; d.textContent = dir || 'plaintxt'; filesEl.appendChild(d); lastDir = dir; }
    var b = document.createElement('button'); b.type = 'button'; b.dataset.i = i; b.textContent = name(f.path);
    b.addEventListener('click', function () { show(i); });
    filesEl.appendChild(b);
  });
  document.querySelectorAll('.ide-tabs [role=tab]').forEach(function (b) {
    b.addEventListener('click', function () {
      tab = b.dataset.pane;
      document.querySelectorAll('.ide-tabs [role=tab]').forEach(function (o) { o.setAttribute('aria-selected', String(o === b)); });
      paint();
    });
  });
  show(0);
})();
