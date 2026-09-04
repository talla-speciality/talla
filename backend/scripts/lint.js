const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const ignored = new Set(["node_modules", "data"]);

function javascriptFiles(directory) {
    return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
        if (ignored.has(entry.name)) return [];
        const target = path.join(directory, entry.name);
        if (entry.isDirectory()) return javascriptFiles(target);
        return entry.isFile() && entry.name.endsWith(".js") ? [target] : [];
    });
}

for (const file of javascriptFiles(root)) {
    execFileSync(process.execPath, ["--check", file], { stdio: "inherit" });
    const text = fs.readFileSync(file, "utf8");
    if (/\t/.test(text)) throw new Error(`${path.relative(root, file)} contains tab indentation.`);
    if (/[ \t]+$/m.test(text)) throw new Error(`${path.relative(root, file)} contains trailing whitespace.`);
}

console.log("Backend JavaScript lint passed.");
