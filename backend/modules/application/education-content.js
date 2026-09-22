const fs = require("fs");
const path = require("path");

const defaultQuestions = [
    { id: "grind-french-press", prompt: "Which grind is usually best for a French press?", options: ["Fine", "Medium-fine", "Coarse"], correctAnswer: "Coarse", explanation: "A coarse grind suits the longer immersion and helps keep the cup clear." },
    { id: "water-temperature", prompt: "What does hotter water generally do?", options: ["Extracts more quickly", "Stops extraction", "Makes coffee caffeine-free"], correctAnswer: "Extracts more quickly", explanation: "Heat speeds up extraction, so very hot water can pull bitterness if the recipe is not adjusted." },
    { id: "sour-cup", prompt: "Your coffee tastes sharp and sour. What is a good first adjustment?", options: ["Grind finer", "Grind much coarser", "Use less coffee and less time"], correctAnswer: "Grind finer", explanation: "A finer grind increases surface area and usually extracts more flavour." },
    { id: "roast-flavour", prompt: "Which flavour is commonly associated with a darker roast?", options: ["Cocoa and roast", "Fresh cucumber", "Lemon sherbet only"], correctAnswer: "Cocoa and roast", explanation: "Longer roasting develops deeper caramelised, cocoa, and roasted notes." },
    { id: "bloom", prompt: "Why do pour-over brewers bloom coffee?", options: ["To release trapped gas", "To cool the water", "To remove all caffeine"], correctAnswer: "To release trapped gas", explanation: "Blooming lets carbon dioxide escape so water can contact the grounds more evenly." }
];

function createEducationContentStore(filePath = path.join(__dirname, "../../data/education-content.json")) {
    function read() {
        try { return JSON.parse(fs.readFileSync(filePath, "utf8")); } catch { return { version: 1, questions: defaultQuestions }; }
    }
    function write(payload) {
        const questions = Array.isArray(payload?.questions) ? payload.questions : [];
        if (!questions.length) throw new Error("At least one education question is required.");
        for (const question of questions) {
            if (!question.id || !question.prompt || !Array.isArray(question.options) || question.options.length < 2 || !question.correctAnswer || !question.options.includes(question.correctAnswer)) throw new Error("Every question needs an id, prompt, at least two options, and a valid correctAnswer.");
        }
        fs.mkdirSync(path.dirname(filePath), { recursive: true });
        const saved = { version: 1, updatedAt: new Date().toISOString(), questions };
        fs.writeFileSync(filePath, JSON.stringify(saved, null, 2));
        return saved;
    }
    return { read, write };
}

module.exports = { createEducationContentStore, defaultQuestions };
