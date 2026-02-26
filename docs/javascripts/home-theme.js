// docs/javascripts/home-theme.js

(function() {
    // Save the original scheme, defaulting to 'default' if none is set
    let originalScheme = document.body.getAttribute('data-md-color-scheme') || 'default';

    const applyTheme = () => {
        const isHome = document.querySelector('.mdx-hero') !== null;
        
        if (isHome) {
            // Force dark mode on the homepage
            document.body.setAttribute('data-md-color-scheme', 'slate');
        } else {
            // Restore the user's preferred theme on standard pages
            document.body.setAttribute('data-md-color-scheme', originalScheme);
        }
    };

    // Safely intercept LocalStorage to prevent saving the forced homepage theme
    const originalSetItem = localStorage.setItem;
    localStorage.setItem = function(key, value) {
        const isHome = document.querySelector('.mdx-hero') !== null;
        if (isHome && typeof value === 'string' && value.includes('slate')) {
            return; 
        }
        originalSetItem.apply(this, arguments);
    };

    // Track genuine user theme changes on non-home pages
    const observer = new MutationObserver((mutations) => {
        const isHome = document.querySelector('.mdx-hero') !== null;
        if (!isHome) {
            mutations.forEach((mutation) => {
                if (mutation.attributeName === 'data-md-color-scheme') {
                    const newScheme = document.body.getAttribute('data-md-color-scheme');
                    if (newScheme) {
                        originalScheme = newScheme;
                    }
                }
            });
        }
    });
    
    // Watch for manual theme toggles
    observer.observe(document.body, { attributes: true, attributeFilter: ['data-md-color-scheme'] });

    // Hook into MkDocs Material's native SPA lifecycle
    if (typeof document$ !== 'undefined') {
        document$.subscribe(function() {
            applyTheme();
        });
    }
})();