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
window.quizneticAnalytics = {
  // All-ages release: no import or consent grant, even if called directly.
  async load() {
    throw new Error('Web Analytics is paused');
  },
  disable() {
    const id = window.firebase_core?.getApp()?.options?.measurementId;
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
