// Basic opt-in: do not even import the Analytics SDK until explicit consent.
window.flutterfire_ignore_scripts = [
  ...(window.flutterfire_ignore_scripts || []), 'analytics'
];
window.dataLayer = window.dataLayer || [];
window.gtag = window.gtag || function () { window.dataLayer.push(arguments); };
const denied = {
  analytics_storage: 'denied', ad_storage: 'denied',
  ad_user_data: 'denied', ad_personalization: 'denied'
};
window.gtag('consent', 'default', denied);
let loading;
let revision = 0;
window.quizneticAnalytics = {
  async load() {
    const current = ++revision;
    if (!loading) {
      loading = import(`https://www.gstatic.com/firebasejs/${window.firebase_core.SDK_VERSION}/firebase-analytics.js`)
        .then(module => { window.firebase_analytics = module; })
        .catch(error => { loading = undefined; throw error; });
    }
    await loading;
    if (current !== revision) throw new Error('Analytics consent changed');
    const app = window.firebase_core.getApp();
    const id = app.options.measurementId;
    if (id) window[`ga-disable-${id}`] = false;
    window.gtag('consent', 'update', { ...denied, analytics_storage: 'granted' });
    // Ad-free MVP: never enable advertising signals or personalization.
    window.gtag('set', 'allow_google_signals', false);
    window.gtag('set', 'allow_ad_personalization_signals', false);
  },
  disable() {
    ++revision;
    const id = window.firebase_core?.getApp().options.measurementId;
    if (id) window[`ga-disable-${id}`] = true;
    window.gtag('consent', 'update', denied);
    // Remove first-party GA identifiers, including cookies scoped to parent domains.
    const host = location.hostname.split('.');
    const domains = ['', ...host.map((_, i) => host.slice(i).join('.'))];
    for (const cookie of document.cookie.split(';')) {
      const name = cookie.split('=')[0].trim();
      if (name !== '_ga' && !name.startsWith('_ga_') && name !== '_gid' && !name.startsWith('_gat')) continue;
      for (const domain of domains) {
        document.cookie = `${name}=; Max-Age=0; Path=/;${domain ? ` Domain=${domain};` : ''}`;
      }
    }
  },
  // Discard Analytics listeners and pending page state after withdrawing consent.
  reload() { location.reload(); }
};
