import React from "react";
import { useState } from "react";
import Question from "./Question";
import ConfirmDialog from "./ConfirmDialog";
import { formatAnswersForSubmission, sendAnswers } from "./api";
import { TranslationsContext } from "./translations_context";


export default function TestAttemptApp({translations, questions=[], testAttemptId}) {
  const [userAnswers, setUserAnswers] = useState({})
  const [questionIndex, setQuestionIndex] = useState(0)
  const [showConfirm, setShowConfirm] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState(null)


  function updateAnswer(questionId, answer) {
    setUserAnswers(prev => ({
      ...prev,
      [questionId]: answer
    }))
  }

  function nextQuestion() {
    if (questionIndex < questions.length - 1) {
      setQuestionIndex(prev => prev + 1)
    }
  }

  function previousQuestion() {
    if (questionIndex > 0) {
      setQuestionIndex(prev => prev - 1)
    }
  }

  async function handleSubmit() {
    setIsSubmitting(true)
    setSubmitError(null)
    try {
      const answers = formatAnswersForSubmission(questions, userAnswers);
      await sendAnswers(testAttemptId, answers);
      // On success sendAnswers navigates the browser away — nothing left to do here.
    } catch (error) {
      setSubmitError(translations.submit_error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return <TranslationsContext.Provider value={{translations}}>
    <div className="test-attempt-app">
      <Question
        key={questions[questionIndex].id}
        question={questions[questionIndex]}
        answer={userAnswers[questions[questionIndex].id] || ""}
        updateAnswer={updateAnswer}
        questionIndex={questionIndex+1}
        questionsAmount={questions.length}
      />
      <div className="test-attempt-nav">
        <div className="test-attempt-nav-group">
          <button onClick={previousQuestion} aria-label={translations.previous_question}>←</button>
          <button onClick={nextQuestion} aria-label={translations.next_question}>→</button>
        </div>
        <button className="test-attempt-submit" onClick={() => setShowConfirm(true)}>{translations.submit}</button>
      </div>

      {showConfirm && (
        <ConfirmDialog
          onConfirm={handleSubmit}
          onCancel={() => {
            setShowConfirm(false)
            setSubmitError(null)
          }}
          isSubmitting={isSubmitting}
          error={submitError}
        />
      )}
    </div>
  </TranslationsContext.Provider>
}
