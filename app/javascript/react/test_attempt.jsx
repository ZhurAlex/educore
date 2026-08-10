import React from "react";
import { createRoot } from "react-dom/client";
import TestAttemptApp from "./TestAttemptApp";

const container = document.getElementById("test-attempt-react-root");

if (container) {
  const testAttemptId = container.dataset.testAttemptId;

  const questionsData = container.dataset.questions;
  const parsedQuestions = questionsData ? JSON.parse(questionsData) : [];

  const translationsData = container.dataset.translations;
  const translations = translationsData ? JSON.parse(translationsData) : {};

  createRoot(container).render(
    parsedQuestions.length === 0 ?
      <p>{translations.no_questions}</p> :
      <TestAttemptApp questions={parsedQuestions} testAttemptId={testAttemptId} translations={translations} />
  );
}
