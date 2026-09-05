const test = require("node:test");
const assert = require("node:assert/strict");
const {
    authenticateAdmin,
    hasPermission,
    parseAdminUsers,
    permissionForAdminRequest
} = require("../modules/account/admin-authorization");

test("admin roles grant only their declared permissions", () => {
    const users = parseAdminUsers(JSON.stringify([
        { username: "ops@example.com", password: "test-password", role: "operations" },
        { username: "viewer@example.com", password: "read-only", role: "viewer" }
    ]));
    const operations = authenticateAdmin(users, "OPS@example.com", "test-password");
    const viewer = authenticateAdmin(users, "viewer@example.com", "read-only");
    assert.equal(hasPermission(operations, "orders:write"), true);
    assert.equal(hasPermission(operations, "customers:write"), false);
    assert.equal(hasPermission(viewer, "admin:read"), true);
    assert.equal(hasPermission(viewer, "orders:write"), false);
    assert.equal(authenticateAdmin(users, "ops@example.com", "wrong"), null);
});

test("admin request permissions distinguish reads from sensitive mutations", () => {
    assert.equal(permissionForAdminRequest("GET", "/admin/api/customers"), "admin:read");
    assert.equal(permissionForAdminRequest("POST", "/admin/api/orders/status"), "orders:write");
    assert.equal(permissionForAdminRequest("POST", "/admin/api/customer/delete"), "customers:write");
    assert.equal(permissionForAdminRequest("POST", "/admin/api/loyalty/adjust"), "loyalty:write");
    assert.equal(permissionForAdminRequest("POST", "/admin/api/products/update"), "catalog:write");
});

test("legacy admin credentials retain owner access during migration", () => {
    const [legacy] = parseAdminUsers("", { username: "admin", password: "secret" });
    assert.equal(legacy.role, "owner");
    assert.equal(hasPermission(authenticateAdmin([legacy], "admin", "secret"), "catalog:write"), true);
});
