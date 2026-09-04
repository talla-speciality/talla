const crypto = require("crypto");

const rolePermissions = Object.freeze({
    viewer: ["admin:read"],
    support: ["admin:read", "customers:write"],
    operations: ["admin:read", "orders:write", "notifications:write"],
    manager: ["admin:read", "orders:write", "catalog:write", "customers:write", "loyalty:write", "notifications:write"],
    owner: ["*"]
});

function normalizeRole(value) {
    const role = String(value || "").trim().toLowerCase();
    return Object.hasOwn(rolePermissions, role) ? role : "viewer";
}

function permissionsForRole(role) {
    return [...rolePermissions[normalizeRole(role)]];
}

function parseAdminUsers(value, legacy = {}) {
    let candidates = [];
    if (value) {
        try {
            const parsed = JSON.parse(value);
            candidates = Array.isArray(parsed) ? parsed : [];
        } catch {
            throw new Error("ADMIN_USERS_JSON_INVALID");
        }
    }

    if (candidates.length === 0 && legacy.username && legacy.password) {
        candidates = [{ username: legacy.username, password: legacy.password, role: "owner" }];
    }

    const users = candidates.map((candidate) => ({
        username: String(candidate?.username || "").trim().toLowerCase(),
        password: String(candidate?.password || ""),
        role: normalizeRole(candidate?.role || "viewer")
    })).filter((candidate) => candidate.username && candidate.password);

    if (new Set(users.map((user) => user.username)).size !== users.length) {
        throw new Error("ADMIN_USERS_JSON_DUPLICATE_USERNAME");
    }
    return users;
}

function timingSafeTextEqual(left, right) {
    const leftDigest = crypto.createHash("sha256").update(String(left)).digest();
    const rightDigest = crypto.createHash("sha256").update(String(right)).digest();
    return crypto.timingSafeEqual(leftDigest, rightDigest);
}

function authenticateAdmin(users, username, password) {
    const normalizedUsername = String(username || "").trim().toLowerCase();
    const candidate = users.find((user) => user.username === normalizedUsername);
    if (!candidate || !timingSafeTextEqual(candidate.password, password)) return null;
    return { username: candidate.username, role: candidate.role, permissions: permissionsForRole(candidate.role) };
}

function hasPermission(principal, permission) {
    const permissions = Array.isArray(principal?.permissions) ? principal.permissions : [];
    return permissions.includes("*") || permissions.includes(permission);
}

function permissionForAdminRequest(method, pathName) {
    if (String(method).toUpperCase() === "GET") return "admin:read";
    if (/^\/admin\/api\/orders(?:\/|$)/.test(pathName)) return "orders:write";
    if (/^\/admin\/api\/(?:products|events|campaigns|home|passport-settings|app-settings)(?:\/|$)/.test(pathName)) return "catalog:write";
    if (/^\/admin\/api\/(?:customer|customers)(?:\/|$)/.test(pathName)) return "customers:write";
    if (/^\/admin\/api\/(?:loyalty|vouchers)(?:\/|$)/.test(pathName)) return "loyalty:write";
    if (/^\/admin\/api\/notifications(?:\/|$)/.test(pathName)) return "notifications:write";
    return "admin:read";
}

function mobileAdminPrincipal(email, roleByEmail = {}) {
    const normalizedEmail = String(email || "").trim().toLowerCase();
    const role = roleByEmail[normalizedEmail];
    if (!role) return null;
    return { username: normalizedEmail, email: normalizedEmail, role: normalizeRole(role), permissions: permissionsForRole(role) };
}

module.exports = {
    authenticateAdmin,
    hasPermission,
    mobileAdminPrincipal,
    normalizeRole,
    parseAdminUsers,
    permissionForAdminRequest,
    permissionsForRole,
    rolePermissions
};
