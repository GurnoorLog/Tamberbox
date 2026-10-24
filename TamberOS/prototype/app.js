/* TamberOS browser prototype. All data are static, local and demonstrative. */
(() => {
  'use strict';
  const pages = ['home', 'ai', 'games', 'files', 'system', 'settings', 'boot', 'login', 'welcome'];
  const names = {home:'OVERVIEW', ai:'TAMBER AI', games:'GAME MODE', files:'FILES', system:'SYSTEM CENTER', settings:'SETTINGS', boot:'BOOT PREVIEW', login:'SIGN-IN PREVIEW', welcome:'WELCOME PREVIEW'};
  const overlays = [...document.querySelectorAll('.overlay')];
  const toast = document.getElementById('toast');
  let toastTimer;
  const showToast = message => {
    toast.textContent = message;
    toast.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.hidden = true, 3600);
  };
  const closeOverlays = () => overlays.forEach(el => el.hidden = true);
  const show = page => {
    if (!pages.includes(page)) return;
    closeOverlays();
    document.querySelectorAll('.screen').forEach(el => el.classList.toggle('active', el.dataset.page === page));
    document.querySelectorAll('.nav-item').forEach(el => el.classList.toggle('active', el.dataset.screen === page));
    document.getElementById('breadcrumb').textContent = names[page];
    document.getElementById('viewport').scrollTop = 0;
    window.scrollTo({top:0,behavior:'instant'});
    document.title = names[page] + ' · TamberOS Concept';
  };
  document.addEventListener('click', event => {
    const route = event.target.closest('[data-screen]');
    if (route) show(route.dataset.screen);
    if (event.target.closest('[data-close]')) closeOverlays();
    if (overlays.includes(event.target)) closeOverlays();
    const game = event.target.closest('[data-game]');
    if (game) showToast(`${game.dataset.game} is a fictional placeholder; no game installed.`);
  });
  const quick = document.getElementById('quickOverlay');
  const search = document.getElementById('searchOverlay');
  document.getElementById('quickBtn').addEventListener('click', () => { closeOverlays(); quick.hidden = false; });
  document.getElementById('searchBtn').addEventListener('click', () => { closeOverlays(); search.hidden = false; renderResults(''); document.getElementById('searchInput').focus(); });
  document.getElementById('clockBtn').addEventListener('click', () => showToast('Sample time, not synced to your system.'));
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') { closeOverlays(); return; }
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); document.getElementById('searchBtn').click(); }
  });
  const input = document.getElementById('searchInput');
  const list = document.getElementById('searchResults');
  const renderResults = query => {
    list.replaceChildren();
    pages.filter(page => names[page].toLowerCase().includes(query.toLowerCase())).forEach(page => {
      const btn = document.createElement('button');
      btn.textContent = `↗  ${names[page]}`;
      btn.addEventListener('click', () => show(page));
      list.appendChild(btn);
    });
    if (!list.children.length) list.textContent = 'No demo screens match.';
  };
  input.addEventListener('input', () => renderResults(input.value));
  document.getElementById('reduceMotion').addEventListener('change', e => document.body.classList.toggle('reduced-motion', e.target.checked));
  document.getElementById('focusMode').addEventListener('change', e => document.body.classList.toggle('high-focus', e.target.checked));
  const submitDemo = event => {
    event.preventDefault();
    const message = document.getElementById('chatText').value.trim();
    if (!message) return;
    document.getElementById('chatText').value = '';
    showToast('This is a visual prototype — Ollama is not connected. Nothing was sent.');
  };
  document.getElementById('chatForm').addEventListener('submit', submitDemo);
  document.querySelectorAll('.suggestion').forEach(button => button.addEventListener('click', () => {
    document.getElementById('chatText').value = button.textContent;
    document.getElementById('chatText').focus();
  }));
  document.getElementById('aiInfo').addEventListener('click', () => showToast('Ollama localhost integration is on the roadmap; no model is connected.'));
  document.getElementById('fakePlay').addEventListener('click', () => showToast('Game launching is not implemented in this visual prototype.'));
  document.querySelectorAll('.folder').forEach(button => button.addEventListener('click', () => showToast('Demo folders are not connected to your filesystem.')));
  document.getElementById('loginDemo').addEventListener('click', () => {
    document.getElementById('demoPassword').value = '';
    showToast('Authentication is intentionally disabled in this UI mock.');
  });
  let step = 1;
  document.getElementById('welcomeDemo').addEventListener('click', () => {
    step = (step % 4) + 1;
    const titles = ['Welcome', 'Language', 'Connection', 'Privacy'];
    document.getElementById('stepMessage').textContent = `Step ${step} / 4: ${titles[step - 1]} · mock only, no settings changed.`;
  });
  renderResults('');
})();
