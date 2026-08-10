export function formatAnswersForSubmission(questions, userAnswers) {
  return questions.reduce((acc, q) => {
    if (!Object.hasOwn(userAnswers, q.id)) return acc;

    switch (q.answer_type) {
      case "multiple_choice":
        acc[q.id] = { "option_id": userAnswers[q.id] };
        break;
      case "short_text":
        acc[q.id] = { "answer_text": userAnswers[q.id] };
        break;
    }

    return acc;
  }, {});
}

export async function sendAnswers(testAttemptId, answers) {
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
  try {
    const response = await fetch(`/test_attempts/${testAttemptId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ answers: answers })
    });

    if (response.ok) {
      const data = await response.json();
      window.location.href = data.redirect_url;
    } else {
      console.error("Submit failed:", response.status);
    }
  } catch (error) {
    console.error("Error submitting answers:", error);
  }
}
