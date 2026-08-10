import React from "react";
import { useState } from "react";
import Question from "./Question";
import ConfirmDialog from "./ConfirmDialog";
import { formatAnswersForSubmission, sendAnswers } from "./api";


export default function TestAttemptApp({questions=[], testAttemptId}) {
  const [userAnswers, setUserAnswers] = useState({})
  const [questionIndex, setQuestionIndex] = useState(0)
  const [showConfirm, setShowConfirm] = useState(false)


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

  function handleSubmit() {
    const answers = formatAnswersForSubmission(questions, userAnswers);
    sendAnswers(testAttemptId, answers);
  }

  return <div className="test-attempt-app">
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
        <button onClick={previousQuestion} aria-label="Previous question">←</button>
        <button onClick={nextQuestion} aria-label="Next question">→</button>
      </div>
      <button className="test-attempt-submit" onClick={() => setShowConfirm(true)}>Submit Test</button>
    </div>

    {showConfirm && (
      <ConfirmDialog
        onConfirm={() => { handleSubmit() }}
        onCancel={() => setShowConfirm(false)}
      />
    )}
  </div>
}
