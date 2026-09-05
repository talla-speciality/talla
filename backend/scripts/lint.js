const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const repositoryRoot = path.resolve(root, "..");
const ignored = new Set(["node_modules", "data"]);

const entryPointBudgets = new Map([
    ["Talla Speciality/ContentView.swift", 3_500],
    ["Talla Speciality/BrewingSectionView.swift", 750],
    ["backend/server.js", 9_350]
]);

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

for (const [relativePath, maximumLines] of entryPointBudgets) {
    const file = path.join(repositoryRoot, relativePath);
    const lineCount = fs.readFileSync(file, "utf8").split(/\r?\n/).length;
    if (lineCount > maximumLines) {
        throw new Error(`${relativePath} has ${lineCount} lines; its composition budget is ${maximumLines}. Move feature code into Modules.`);
    }
}

console.log("Backend JavaScript lint and entry-point size checks passed.");
