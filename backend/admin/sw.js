self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

self.addEventListener("push", (event) => {
    let payload = {};
    try {
        payload = event.data ? event.data.json() : {};
    } catch {
        payload = { title: "New Talla order", body: event.data?.text() || "A new order arrived." };
    }

    event.waitUntil((async () => {
        const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
        windows.forEach((client) => client.postMessage({ type: "new-order", order: payload.order || null }));
        if (windows.some((client) => client.visibilityState === "visible")) return;

        await self.registration.showNotification(payload.title || "New Talla order", {
            body: payload.body || "A new order arrived.",
            icon: "/admin/icon.svg",
            badge: "/admin/icon.svg",
            tag: payload.order?.id ? `talla-order-${payload.order.id}` : "talla-new-order",
            renotify: true,
            data: { url: payload.url || "/admin/#orders-section" }
        });
    })());
});

self.addEventListener("notificationclick", (event) => {
    event.notification.close();
    const targetURL = new URL(event.notification.data?.url || "/admin/#orders-section", self.location.origin).href;
    event.waitUntil((async () => {
        const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
        const existing = windows.find((client) => client.url.startsWith(`${self.location.origin}/admin`));
        if (existing) {
            await existing.focus();
            existing.navigate(targetURL);
            return;
        }
        await self.clients.openWindow(targetURL);
    })());
});
