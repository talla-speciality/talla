const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const createServer = require("../modules/application/create-server");
const { createEducationContentStore } = require("../modules/application/education-content");
const { createEducationActivityService } = require("../modules/loyalty/education-activity");
const { educationProgressComplete } = require("../modules/loyalty/education-claim");

const questions = createEducationContentStore().read().questions;

function activityStore() {
    const filePath = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "talla-education-")), "activity.json");
    fs.writeFileSync(filePath, JSON.stringify({ accounts: {} }));
    return {
        filePath,
        readJSON: (file) => JSON.parse(fs.readFileSync(file, "utf8")),
        writeJSON: (file, value) => fs.writeFileSync(file, JSON.stringify(value))
    };
}

test("education progress records distinct, account-bound lessons and correct answers", async () => {
    const store = activityStore();
    const activity = createEducationActivityService({
        database: { isEnabled: () => false }, ...store,
        questionsFor: () => questions
    });
    const email = "student@example.com";
    for (const id of ["1", "2", "3", "3"]) await activity.recordLesson(email, id);
    assert.equal((await activity.recordAnswer(email, questions[0].id, "wrong")).correct, false);
    await activity.recordAnswer(email, questions[0].id, questions[0].correctAnswer);
    await activity.recordAnswer(email, questions[0].id, questions[0].correctAnswer);
    assert.equal(educationProgressComplete(await activity.progress(email)), false);
    await activity.recordAnswer(email, questions[1].id, questions[1].correctAnswer);
    assert.equal(educationProgressComplete(await activity.progress(email)), true);
    assert.equal(educationProgressComplete(await activity.progress("other@example.com")), false);
    assert.deepEqual((await activity.progress(email)).answeredQuestionIDs.sort(), [questions[0].id, questions[1].id].sort());
});

test("incorrect education answers pause new checks per account and reset after a day", async () => {
    const store = activityStore();
    let currentTime = new Date("2026-11-06T10:00:00Z");
    const activity = createEducationActivityService({
        database: { isEnabled: () => false }, ...store,
        questionsFor: () => questions,
        now: () => currentTime
    });
    const email = "student@example.com";
    await activity.recordAnswer(email, questions[0].id, questions[0].correctAnswer);
    for (let index = 0; index < 3; index += 1) {
        assert.equal((await activity.recordAnswer(email, questions[1].id, "wrong")).correct, false);
    }
    await assert.rejects(
        activity.recordAnswer(email, questions[1].id, questions[1].correctAnswer),
        (error) => error.message === "EDUCATION_QUIZ_COOLDOWN" && error.retryAfterSeconds === 86_400
    );
    assert.equal((await activity.recordAnswer(email, questions[0].id, questions[0].correctAnswer)).correct, true);
    assert.equal((await activity.recordAnswer("other@example.com", questions[1].id, questions[1].correctAnswer)).correct, true);
    currentTime = new Date("2026-11-07T10:00:00Z");
    assert.equal((await activity.recordAnswer(email, questions[1].id, questions[1].correctAnswer)).correct, true);
});

test("PostgreSQL activity inserts are idempotent and read progress by account", async () => {
    const rows = [];
    const attempts = new Map();
    const statements = [];
    let currentTime = new Date("2026-11-06T10:00:00Z");
    const query = async (sql, params = []) => {
        statements.push({ sql: String(sql), params });
        const statement = String(sql);
        if (statement.includes("INSERT INTO education_quiz_attempts")) {
            if (!attempts.has(params[0])) attempts.set(params[0], { wrong_count: 0, window_started_at: currentTime });
            return { rowCount: 1, rows: [] };
        }
        if (statement.includes("SELECT wrong_count, window_started_at")) {
            return { rowCount: 1, rows: [attempts.get(params[0])] };
        }
        if (statement.includes("SELECT 1 FROM education_activity")) {
            const exists = rows.some((row) => row.email === params[0] && row.kind === "answer" && row.item_id === params[1]);
            return { rowCount: exists ? 1 : 0, rows: exists ? [{}] : [] };
        }
        if (statement.includes("UPDATE education_quiz_attempts SET wrong_count = wrong_count + 1")) {
            attempts.get(params[0]).wrong_count += 1;
            return { rowCount: 1, rows: [] };
        }
        if (statement.includes("UPDATE education_quiz_attempts SET wrong_count = 0")) {
            attempts.set(params[0], { wrong_count: 0, window_started_at: currentTime });
            return { rowCount: 1, rows: [] };
        }
        if (statement.includes("INSERT INTO education_activity")) {
            const [email, kindOrID, itemID] = params;
            const kind = itemID === undefined ? "answer" : kindOrID;
            const id = itemID === undefined ? kindOrID : itemID;
            if (!rows.some((row) => row.email === email && row.kind === kind && row.item_id === id)) {
                rows.push({ email, kind, item_id: id });
            }
            return { rowCount: 1, rows: [] };
        }
        if (statement.includes("SELECT kind, item_id FROM education_activity")) {
            return { rowCount: 1, rows: rows.filter((row) => row.email === params[0]) };
        }
        return { rowCount: 0, rows: [] };
    };
    const database = {
        isEnabled: () => true,
        query,
        connect: async () => ({ query, release() {} })
    };
    const activity = createEducationActivityService({ database, questionsFor: () => questions, now: () => currentTime });
    await activity.recordLesson("one@example.com", "1");
    await activity.recordLesson("one@example.com", "1");
    await activity.recordAnswer("one@example.com", questions[0].id, questions[0].correctAnswer);
    await activity.recordAnswer("two@example.com", questions[1].id, questions[1].correctAnswer);
    assert.deepEqual(await activity.progress("one@example.com"), {
        lessonIDs: ["1"], answeredQuestionIDs: [questions[0].id]
    });
    assert.equal(rows.length, 3);
    assert.ok(statements.filter(({ sql }) => sql.includes("INSERT INTO education_activity"))
        .every(({ sql }) => sql.includes("ON CONFLICT")));
    assert.ok(statements.some(({ sql }) => sql.includes("FOR UPDATE")));
    for (let index = 0; index < 3; index += 1) await activity.recordAnswer("one@example.com", questions[1].id, "wrong");
    await assert.rejects(activity.recordAnswer("one@example.com", questions[1].id, questions[1].correctAnswer),
        { message: "EDUCATION_QUIZ_COOLDOWN" });
    assert.equal((await activity.recordAnswer("one@example.com", questions[0].id, questions[0].correctAnswer)).correct, true);
    currentTime = new Date("2026-11-07T10:00:00Z");
    assert.equal((await activity.recordAnswer("one@example.com", questions[1].id, questions[1].correctAnswer)).correct, true);
    assert.ok(statements.some(({ sql }) => sql.includes("SET wrong_count = 0")));
});

test("claim route ignores a one-shot proof and awards once from recorded activity", async () => {
    const store = activityStore();
    const account = { pointsBalance: 0, transactions: [] };
    const responses = [];
    let body = {};
    let mutationCount = 0;
    const handler = createServer({
        URL, host: "localhost", port: 0,
        http: { createServer: (callback) => callback },
        applyRateLimit: () => true,
        benefitPathMatches: () => false,
        isBenefitBrowserReturnPath: () => false,
        appAttest: { protectedPaths: new Set(), verifyRequest: async () => ({ allowed: true }) },
        database: { isEnabled: () => false },
        educationActivityStorePath: store.filePath,
        readJSON: store.readJSON,
        writeJSON: store.writeJSON,
        normalizeEmail: (value) => String(value || "").toLowerCase(),
        readBody: async () => body,
        parseAuthenticatedCustomer: () => ({ email: "student@example.com" }),
        resolveCustomerSession: async () => ({ email: "student@example.com" }),
        ensureLoyaltyAccount: async () => account,
        updateLoyaltyAccount: async (_email, mutate) => { mutationCount += 1; mutate(account); return account; },
        loyaltyPayload: (value) => value,
        sendJSON: (_response, status, payload, headers) => responses.push({ status, payload, headers })
    });
    const call = async (route, payload) => {
        body = { email: "student@example.com", ...payload };
        await handler({ method: "POST", url: `/loyalty/activities/${route}`, headers: {} }, { on() {} });
        return responses.at(-1);
    };
    assert.equal((await call("education-claim", {
        lessonIDs: ["1", "2", "3"], answers: questions.slice(0, 2).map(({ id, correctAnswer }) => ({ id, answer: correctAnswer }))
    })).status, 409);
    assert.equal(mutationCount, 0);

    for (const lessonID of ["1", "2", "3"]) assert.equal((await call("education-lesson", { lessonID })).status, 200);
    assert.equal((await call("education-answer", { questionID: questions[0].id, answer: "wrong" })).payload.correct, false);
    assert.equal((await call("education-answer", { questionID: questions[0].id, answer: questions[0].correctAnswer })).payload.correct, true);
    assert.equal((await call("education-answer", { questionID: questions[1].id, answer: questions[1].correctAnswer })).payload.correct, true);
    assert.equal((await call("education-claim", {})).status, 200);
    assert.equal(account.pointsBalance, 25);
    assert.equal((await call("education-claim", {})).status, 200);
    assert.equal(account.pointsBalance, 25);
    assert.equal(mutationCount, 1);
    for (let index = 0; index < 2; index += 1) {
        assert.equal((await call("education-answer", { questionID: questions[2].id, answer: "wrong" })).status, 200);
    }
    const paused = await call("education-answer", { questionID: questions[2].id, answer: questions[2].correctAnswer });
    assert.equal(paused.status, 429);
    assert.ok(paused.payload.retryAfterSeconds > 0);
    assert.equal(paused.headers["Retry-After"], String(paused.payload.retryAfterSeconds));
});

test("public education content omits grading data", async () => {
    const responses = [];
    const handler = createServer({
        URL, host: "localhost", port: 0,
        http: { createServer: (callback) => callback },
        applyRateLimit: () => true,
        benefitPathMatches: () => false,
        isBenefitBrowserReturnPath: () => false,
        appAttest: { protectedPaths: new Set(), verifyRequest: async () => ({ allowed: true }) },
        sendJSON: (_response, status, payload) => responses.push({ status, payload })
    });
    await handler({ method: "GET", url: "/education-content", headers: {} }, { on() {} });
    assert.equal(responses[0].status, 200);
    assert.ok(responses[0].payload.questions.length > 0);
    assert.ok(responses[0].payload.questions.every((question) =>
        !Object.hasOwn(question, "correctAnswer") && !Object.hasOwn(question, "explanation")));
});
