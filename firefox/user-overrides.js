// --- Keep history, form history, suggestions
user_pref("browser.privatebrowsing.autostart", false);
user_pref("places.history.enabled", true);
user_pref("browser.formfill.enable", false);
user_pref("browser.urlbar.suggest.history", true);
user_pref("browser.search.suggest.enabled", true);
user_pref("browser.urlbar.suggest.searches", true);

// --- DO NOT clear on shutdown
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("privacy.clearOnShutdown.history", false);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.cache", false);
user_pref("privacy.clearOnShutdown.downloads", false);
user_pref("privacy.clearOnShutdown.formdata", false);
user_pref("privacy.clearOnShutdown.offlineApps", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("privacy.clearSiteDataOnShutdown", false);

// --- Keep cookies/session (stay signed in)
user_pref("network.cookie.lifetimePolicy", 0); // 0=accept, keep until they expire
user_pref("browser.sessionstore.privacy_level", 0); // allow session/tab restore to save cookies for non-HTTPS too
user_pref("browser.sessionstore.resume_from_crash", true);

user_pref("signon.rememberSignons", true);
user_pref("signon.autofillForms", true);


user_pref("privacy.trackingprotection.enabled", true); 
user_pref("extensions.pocket.enabled", false); 
user_pref("network.trr.mode", 3);
