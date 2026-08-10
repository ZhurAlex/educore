import React from "react";
import { createRoot } from "react-dom/client";
import TestAttemptApp from "./TestAttemptApp";

const container = document.getElementById("test-attempt-react-root");

if (container) {
  const questionsData = container.dataset.questions;
  const testAttemptId = container.dataset.testAttemptId;
  const parsedQuestions = questionsData ? JSON.parse(questionsData) : [];
  createRoot(container).render(
    parsedQuestions.length === 0 ? <p>No questions available.</p> : <TestAttemptApp questions={parsedQuestions} testAttemptId={testAttemptId} />
  );
}
