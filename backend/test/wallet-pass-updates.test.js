const assert = require("node:assert/strict");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const dataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-wallet-updates-test-"));
process.env.DATA_DIRECTORY = dataDirectory;
process.env.APP_URL = "https://merchant.example";
delete process.env.DATABASE_URL;

const { server } = require("../server");

const passTypeIdentifier = "pass.talla.me.talla-speciality";
const serialNumber = "TALLA-MEMBER-TEST";
const authenticationToken = "test-wallet-authentication-token-123456";
const deviceLibraryIdentifier = "device-library-test-123";
const pushToken = "a".repeat(64);
const walletStorePath = path.join(dataDirectory, "walletPasses.json");
let serverBaseURL = "";

test.before(async () => {
    fs.writeFileSync(walletStorePath, JSON.stringify({
        passes: {
            [serialNumber]: {
                email: "member@example.com",
                serialNumber,
                passTypeIdentifier,
                authenticationToken,
                updateTag: 12345,
                lastGeneratedAt: new Date().toISOString()
            }
        },
        devices: {},
        registrations: []
    }, null, 2));
    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    const address = server.address();
    serverBaseURL = `http://127.0.0.1:${address.port}`;
});

test.after(async () => {
    await new Promise((resolve, reject) => {
        server.close((error) => error ? reject(error) : resolve());
    });
    fs.rmSync(dataDirectory, { recursive: true, force: true });
});

function request(method, pathname, { authorization = authenticationToken, body } = {}) {
    return new Promise((resolve, reject) => {
        const url = new URL(pathname, serverBaseURL);
        const payload = body === undefined ? null : JSON.stringify(body);
        const request = http.request(url, {
            method,
            headers: {
                ...(authorization ? { Authorization: `ApplePass ${authorization}` } : {}),
                ...(payload ? {
                    "Content-Type": "application/json",
                    "Content-Length": Buffer.byteLength(payload)
                } : {})
            }
        }, (response) => {
            const chunks = [];
            response.on("data", (chunk) => chunks.push(chunk));
            response.on("end", () => resolve({
                statusCode: response.statusCode,
                body: Buffer.concat(chunks).toString("utf8")
            }));
        });
        request.on("error", reject);
        request.end(payload);
    });
}

test("Wallet registers, lists, and unregisters an updatable pass", async () => {
    const registrationPath = `/wallet/v1/devices/${deviceLibraryIdentifier}/registrations/${passTypeIdentifier}/${serialNumber}`;
    const created = await request("POST", registrationPath, { body: { pushToken } });
    assert.equal(created.statusCode, 201);

    const duplicate = await request("POST", registrationPath, { body: { pushToken } });
    assert.equal(duplicate.statusCode, 200);

    const updates = await request(
        "GET",
        `/wallet/v1/devices/${deviceLibraryIdentifier}/registrations/${passTypeIdentifier}`,
        { authorization: "" }
    );
    assert.equal(updates.statusCode, 200);
    assert.deepEqual(JSON.parse(updates.body), {
        serialNumbers: [serialNumber],
        lastUpdated: "12345"
    });

    const noUpdates = await request(
        "GET",
        `/wallet/v1/devices/${deviceLibraryIdentifier}/registrations/${passTypeIdentifier}?passesUpdatedSince=12345`,
        { authorization: "" }
    );
    assert.equal(noUpdates.statusCode, 204);

    const removed = await request("DELETE", registrationPath);
    assert.equal(removed.statusCode, 200);

    const store = JSON.parse(fs.readFileSync(walletStorePath, "utf8"));
    assert.deepEqual(store.registrations, []);
    assert.equal(store.devices[deviceLibraryIdentifier], undefined);
});

test("Wallet registration rejects an invalid pass token", async () => {
    const response = await request(
        "POST",
        `/wallet/v1/devices/${deviceLibraryIdentifier}/registrations/${passTypeIdentifier}/${serialNumber}`,
        { authorization: "wrong-token", body: { pushToken } }
    );
    assert.equal(response.statusCode, 401);
});
