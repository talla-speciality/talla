const requiredLessonIDs = new Set(["1", "2", "3"]);
const maximumWrongAnswers = 3;
const answerWindowMilliseconds = 24 * 60 * 60 * 1_000;

function createEducationActivityService({ database, readJSON, writeJSON, filePath, questionsFor, now = () => new Date() }) {
    function cooldown(startedAt) {
        const error = new Error("EDUCATION_QUIZ_COOLDOWN");
        error.retryAfterSeconds = Math.max(1, Math.ceil((new Date(startedAt).getTime() + answerWindowMilliseconds - now().getTime()) / 1_000));
        return error;
    }

    async function progress(email) {
        if (!database.isEnabled()) {
            const store = readJSON(filePath);
            const activity = store.accounts?.[email] || {};
            return {
                lessonIDs: Array.isArray(activity.lessonIDs) ? activity.lessonIDs : [],
                answeredQuestionIDs: Array.isArray(activity.answeredQuestionIDs) ? activity.answeredQuestionIDs : []
            };
        }
        const result = await database.query(
            "SELECT kind, item_id FROM education_activity WHERE email = $1",
            [email]
        );
        return {
            lessonIDs: result.rows.filter((row) => row.kind === "lesson").map((row) => row.item_id),
            answeredQuestionIDs: result.rows.filter((row) => row.kind === "answer").map((row) => row.item_id)
        };
    }

    async function record(email, kind, itemID) {
        if (!database.isEnabled()) {
            const store = readJSON(filePath);
            store.accounts = store.accounts || {};
            const activity = store.accounts[email] || { lessonIDs: [], answeredQuestionIDs: [] };
            activity.lessonIDs = Array.isArray(activity.lessonIDs) ? activity.lessonIDs : [];
            activity.answeredQuestionIDs = Array.isArray(activity.answeredQuestionIDs) ? activity.answeredQuestionIDs : [];
            const field = kind === "lesson" ? "lessonIDs" : "answeredQuestionIDs";
            if (!activity[field].includes(itemID)) activity[field].push(itemID);
            store.accounts[email] = activity;
            writeJSON(filePath, store);
            return { lessonIDs: activity.lessonIDs, answeredQuestionIDs: activity.answeredQuestionIDs };
        }
        await database.query(
            `INSERT INTO education_activity (email, kind, item_id)
             VALUES ($1, $2, $3)
             ON CONFLICT (email, kind, item_id) DO NOTHING`,
            [email, kind, itemID]
        );
        return progress(email);
    }

    async function recordLesson(email, lessonID) {
        if (!requiredLessonIDs.has(lessonID)) throw new Error("INVALID_EDUCATION_LESSON");
        return record(email, "lesson", lessonID);
    }

    async function recordAnswer(email, questionID, answer) {
        if (typeof questionID !== "string" || questionID.length > 100
            || typeof answer !== "string" || answer.length > 200) {
            throw new Error("INVALID_EDUCATION_ANSWER");
        }
        const question = questionsFor().find((entry) => entry.id === questionID);
        if (!question) throw new Error("UNKNOWN_EDUCATION_QUESTION");
        const correct = question.correctAnswer === answer;
        let updatedProgress;
        if (!database.isEnabled()) {
            const store = readJSON(filePath);
            store.accounts = store.accounts || {};
            const activity = store.accounts[email] || { lessonIDs: [], answeredQuestionIDs: [] };
            activity.lessonIDs = Array.isArray(activity.lessonIDs) ? activity.lessonIDs : [];
            activity.answeredQuestionIDs = Array.isArray(activity.answeredQuestionIDs) ? activity.answeredQuestionIDs : [];
            const alreadyAnswered = correct && activity.answeredQuestionIDs.includes(questionID);
            let attempts = activity.quizAttempts || { windowStartedAt: now().toISOString(), wrongCount: 0 };
            if (now().getTime() - new Date(attempts.windowStartedAt).getTime() >= answerWindowMilliseconds) {
                attempts = { windowStartedAt: now().toISOString(), wrongCount: 0 };
            }
            if (!alreadyAnswered && attempts.wrongCount >= maximumWrongAnswers) throw cooldown(attempts.windowStartedAt);
            if (!alreadyAnswered) {
                if (correct) activity.answeredQuestionIDs.push(questionID);
                else attempts.wrongCount += 1;
                activity.quizAttempts = attempts;
                store.accounts[email] = activity;
                writeJSON(filePath, store);
            }
            updatedProgress = { lessonIDs: activity.lessonIDs, answeredQuestionIDs: activity.answeredQuestionIDs };
        } else {
            const client = await database.connect();
            try {
                await client.query("BEGIN");
                await client.query(
                    `INSERT INTO education_quiz_attempts (email, wrong_count)
                     VALUES ($1, 0) ON CONFLICT (email) DO NOTHING`, [email]
                );
                const locked = await client.query(
                    "SELECT wrong_count, window_started_at FROM education_quiz_attempts WHERE email = $1 FOR UPDATE", [email]
                );
                let attempts = locked.rows[0];
                const prior = correct ? await client.query(
                    "SELECT 1 FROM education_activity WHERE email = $1 AND kind = 'answer' AND item_id = $2", [email, questionID]
                ) : { rowCount: 0 };
                if (now().getTime() - new Date(attempts.window_started_at).getTime() >= answerWindowMilliseconds) {
                    await client.query(
                        "UPDATE education_quiz_attempts SET wrong_count = 0, window_started_at = NOW() WHERE email = $1", [email]
                    );
                    attempts = { wrong_count: 0, window_started_at: now() };
                }
                if (prior.rowCount === 0 && attempts.wrong_count >= maximumWrongAnswers) {
                    throw cooldown(attempts.window_started_at);
                }
                if (prior.rowCount === 0) {
                    if (correct) {
                        await client.query(
                            `INSERT INTO education_activity (email, kind, item_id)
                             VALUES ($1, 'answer', $2) ON CONFLICT (email, kind, item_id) DO NOTHING`,
                            [email, questionID]
                        );
                    } else {
                        await client.query(
                            "UPDATE education_quiz_attempts SET wrong_count = wrong_count + 1 WHERE email = $1", [email]
                        );
                    }
                }
                await client.query("COMMIT");
            } catch (error) {
                await client.query("ROLLBACK");
                throw error;
            } finally {
                client.release();
            }
            updatedProgress = await progress(email);
        }
        return {
            correct,
            explanation: question.explanation || "",
            progress: updatedProgress
        };
    }

    return { progress, recordLesson, recordAnswer };
}

module.exports = { createEducationActivityService, requiredLessonIDs, maximumWrongAnswers };
