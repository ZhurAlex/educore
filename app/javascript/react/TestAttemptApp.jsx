import React from "react";
import { useState } from "react";
import Question from "./Question";


export default function TestAttemptApp({questions=[]}) {
  const [userAnswers, setUserAnswers] = useState({})
  const [questionIndex, setQuestionIndex] = useState(0)
  console.log(`Updating answers for question:`, userAnswers);

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

  return <div className="test-attempt-app">
    <button onClick={previousQuestion}> Previous question </button>
    <button onClick={nextQuestion}> Next question </button>
    <Question 
      key={questions[questionIndex].id} 
      question={questions[questionIndex]}
      answer={userAnswers[questions[questionIndex].id] || ""}
      updateAnswer={updateAnswer}
      questionIndex={questionIndex+1}
      questionsAmount={questions.length}
    />
    <input type="submit" value="Submit Test" />
  </div>
}
