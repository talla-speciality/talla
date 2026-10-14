const { spawn } = require("child_process");
const path = require("path");

function createCoffeeConcierge({ config = {} } = {}) {
    const root = path.resolve(config.coffeeAIPath || path.resolve(__dirname, "../../../../coffee_ai_from_scratch"));
    const python = path.resolve(config.coffeeAIPython || path.join(root, ".venv", "bin", "python"));
    let processHandle = null;
    let buffer = "";
    const pending = [];

    const start = () => {
        if (processHandle && !processHandle.killed) return;
        processHandle = spawn(python, [path.join(root, "serve.py")], { cwd: root, stdio: ["pipe", "pipe", "pipe"] });
        processHandle.stdout.on("data", (chunk) => {
            buffer += chunk.toString();
            let newlineIndex;
            while ((newlineIndex = buffer.indexOf("\n")) >= 0) {
                const line = buffer.slice(0, newlineIndex).trim();
                buffer = buffer.slice(newlineIndex + 1);
                const waiter = pending.shift();
                if (!waiter) continue;
                try {
                    const payload = JSON.parse(line);
                    if (payload.error) waiter.reject(new Error(payload.error));
                    else waiter.resolve(payload);
                } catch (error) {
                    waiter.reject(error);
                }
            }
        });
        processHandle.on("exit", () => {
            processHandle = null;
            const error = new Error("COFFEE_AI_PROCESS_EXITED");
            while (pending.length) pending.shift().reject(error);
        });
        processHandle.on("error", (error) => {
            processHandle = null;
            while (pending.length) pending.shift().reject(error);
        });
    };

    const ask = ({ question, context = "" }) => new Promise((resolve, reject) => {
        start();
        pending.push({ resolve, reject });
        processHandle.stdin.write(`${JSON.stringify({ question, context })}\n`);
    });

    return { ask };
}

module.exports = { createCoffeeConcierge };
