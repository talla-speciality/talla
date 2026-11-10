const requiredLessonIDs = new Set(["1", "2", "3"]);

function educationProgressComplete(progress) {
    const lessons = new Set(Array.isArray(progress?.lessonIDs) ? progress.lessonIDs : []);
    const answered = new Set(Array.isArray(progress?.answeredQuestionIDs) ? progress.answeredQuestionIDs : []);
    if (lessons.size !== 3 || [...lessons].some((id) => !requiredLessonIDs.has(id))) return false;
    return answered.size >= 2;
}

module.exports = { educationProgressComplete };
