const API = '/api';
const state = { token: localStorage.getItem('twc_admin_token'), user: null };
const $ = (selector) => document.querySelector(selector);

function message(text, error = true) {
    const target = $('#appView').classList.contains('hidden') ? $('#loginMessage') : $('#appMessage');
    target.textContent = text || '';
    target.className = `message${error ? '' : ' success'}`;
}

async function request(path, options = {}) {
    const headers = { Accept: 'application/json', ...(options.body ? {'Content-Type': 'application/json'} : {}), ...(state.token ? {Authorization: `Bearer ${state.token}`} : {}) };
    const response = await fetch(`${API}${path}`, {...options, headers});
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(payload.error || 'La requête a échoué.');
    return payload.data ?? payload;
}

function showApp() {
    $('#loginView').classList.add('hidden');
    $('#appView').classList.remove('hidden');
    $('#adminEmail').textContent = state.user?.email || '';
    loadSection('dashboard');
}

function renderCards(stats) {
    const values = [
        ['Utilisateurs', stats.users?.total], ['Nouveaux aujourd’hui', stats.users?.new_today],
        ['Publications', stats.content?.posts], ['Produits', stats.marketplace?.products],
        ['Commandes boost', stats.boost?.orders], ['Cours', stats.courses?.total],
        ['Signalements en attente', stats.reports?.pending], ['Revenus du jour', stats.financial?.today_revenue]
    ];
    return `<div class="cards">${values.map(([label, value]) => `<div class="card"><span class="card-label">${label}</span><strong class="card-value">${value ?? 0}</strong></div>`).join('')}</div>`;
}

function renderRows(items, columns) {
    if (!items?.length) return '<div class="empty">Aucune donnée disponible.</div>';
    return `<table class="table"><thead><tr>${columns.map((column) => `<th>${column.label}</th>`).join('')}</tr></thead><tbody>${items.map((item) => `<tr>${columns.map((column) => `<td>${column.render(item)}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
}

async function loadSection(section) {
    const titles = {dashboard:'Vue générale',users:'Utilisateurs',premium:'Demandes premium',reports:'Signalements',posts:'Publications',products:'Produits',courses:'Cours'};
    $('#sectionTitle').textContent = titles[section];
    $('#sectionContent').innerHTML = '<div class="panel">Chargement...</div>';
    try {
        if (section === 'dashboard') {
            const data = await request('/admin/dashboard');
            $('#sectionContent').innerHTML = renderCards(data.stats) + '<div class="panel"><h2>Résumé de la plateforme</h2><p class="muted">Utilisez le menu pour gérer les utilisateurs et le contenu.</p></div>';
            return;
        }
        const endpoints = {users:'/admin/users',premium:'/admin/premium-requests',reports:'/admin/reports',posts:'/admin/posts',products:'/admin/marketplace/products',courses:'/admin/courses'};
        const data = await request(endpoints[section]);
        const lists = {
            users: {key:'users', columns:[{label:'Nom',render:x=>x.name||'-'},{label:'Email',render:x=>x.email},{label:'Statut',render:x=>x.is_blocked?'<span class="badge danger">Bloqué</span>':'<span class="badge">Actif</span>'}]},
            premium: {key:'requests', columns:[{label:'Nom',render:x=>x.name},{label:'Email',render:x=>x.email},{label:'Demandé le',render:x=>x.created_at||'-'}]},
            reports: {key:'reports', columns:[{label:'Type',render:x=>x.type||'-'},{label:'Statut',render:x=>x.status||'-'},{label:'Créé le',render:x=>x.created_at||'-'}]},
            posts: {key:'posts', columns:[{label:'Auteur',render:x=>x.user?.name||'-'},{label:'Contenu',render:x=>(x.content||'').slice(0,80)},{label:'Signalé',render:x=>x.is_reported?'Oui':'Non'}]},
            products: {key:'products', columns:[{label:'Produit',render:x=>x.name||'-'},{label:'Prix',render:x=>x.price??'-'},{label:'Approuvé',render:x=>x.is_approved?'Oui':'Non'}]},
            courses: {key:'courses', columns:[{label:'Cours',render:x=>x.title||x.name||'-'},{label:'Étudiants',render:x=>x.students_count??0},{label:'Créé le',render:x=>x.created_at||'-'}]}
        };
        const config = lists[section];
        $('#sectionContent').innerHTML = `<div class="panel"><div class="toolbar"><input id="filterInput" placeholder="Rechercher..."></div><div id="dataTable">${renderRows(data[config.key] || data.items || [], config.columns)}</div></div>`;
        $('#filterInput').addEventListener('input', (event) => {
            const query = event.target.value.toLowerCase();
            const filtered = (data[config.key] || data.items || []).filter(item => JSON.stringify(item).toLowerCase().includes(query));
            $('#dataTable').innerHTML = renderRows(filtered, config.columns);
        });
    } catch (error) {
        if (error.message.includes('non activé')) {
            $('#activationField').classList.remove('hidden');
            $('#loginMessage').textContent = 'Compte non activé : saisissez le code administrateur.';
        }
        $('#sectionContent').innerHTML = `<div class="panel"><p class="message">${error.message}</p></div>`;
    }
}

$('#loginForm').addEventListener('submit', async (event) => {
    event.preventDefault();
    message('');
    try {
        if (!state.token) {
            const data = await request('/auth/login', {method:'POST', body: JSON.stringify({email:$('#email').value, password:$('#password').value})});
            state.token = data.token; state.user = data.user; localStorage.setItem('twc_admin_token', state.token);
        }
        try { await request('/admin/dashboard'); }
        catch (error) {
            if (!error.message.includes('non activé')) throw error;
            const code = $('#activationCode').value;
            if (!code) throw error;
            await request('/admin/activate', {method:'POST', body: JSON.stringify({code})});
        }
        showApp();
    } catch (error) { message(error.message); localStorage.removeItem('twc_admin_token'); state.token = null; }
});

document.querySelectorAll('.nav-item').forEach(button => button.addEventListener('click', () => {
    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    button.classList.add('active'); loadSection(button.dataset.section);
}));
$('#logoutButton').addEventListener('click', () => { localStorage.removeItem('twc_admin_token'); location.reload(); });
if (state.token) { request('/admin/dashboard').then(showApp).catch(() => { localStorage.removeItem('twc_admin_token'); state.token = null; }); }
