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
      case "long_text":
        acc[q.id] = { "answer_text": userAnswers[q.id] };
        break;
    }

    return acc;
  }, {});
}

export async function sendAnswers(testAttemptId, answers) {
  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;

  const response = await fetch(`/test_attempts/${testAttemptId}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": csrfToken
    },
    body: JSON.stringify({ answers: answers }),
    signal: AbortSignal.timeout(15000)
  });

  if (!response.ok) {
    throw new Error(`Submit failed with status ${response.status}`);
  }

  const data = await response.json();
  window.location.href = data.redirect_url;
}
