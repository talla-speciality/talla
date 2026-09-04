const fs = require("fs");
const path = require("path");

const directory = path.resolve(__dirname, "..", "migrations");
const files = fs.readdirSync(directory).filter((name) => name.endsWith(".sql")).sort();
const seen = new Set();

for (const file of files) {
    const match = /^(\d{3})_[a-z0-9_]+\.sql$/.exec(file);
    if (!match) throw new Error(`Migration ${file} must use NNN_snake_case.sql.`);
    if (seen.has(file)) throw new Error(`Migration ${file} is duplicated.`);
    seen.add(file);
    const sql = fs.readFileSync(path.join(directory, file), "utf8").trim();
    if (!sql) throw new Error(`Migration ${file} is empty.`);
    if (/\b(BEGIN|COMMIT|ROLLBACK)\s*;/i.test(sql)) {
        throw new Error(`Migration ${file} must not manage transactions; database.js does that.`);
    }
}

console.log(`Validated ${files.length} ordered migrations.`);
