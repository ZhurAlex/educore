import React from "react";
import MultipleChoiceAnswer from "./answers/MultipleChoiceAnswer";
import ShortTextAnswer from "./answers/ShortTextAnswer";

export default function Question({question, answer, updateAnswer, questionIndex, questionsAmount}) {
    return <div className="test-attempt-question">
        <p className="test-attempt-progress">{`Question ${questionIndex} of ${questionsAmount}`}</p>
        <p className="test-attempt-body">
          {question.body}
          <span className="badge">{question.points} pts</span>
        </p>
        <div className="test-attempt-answer">
          { question.answer_type === "multiple_choice" ? (
              <MultipleChoiceAnswer
               options={question.options}
               questionId={question.id}
               answer={answer}
               updateAnswer={updateAnswer}
              />
          ) : (
              <ShortTextAnswer
               questionId={question.id}
               answer={answer}
               updateAnswer={updateAnswer}
              />
          )}
        </div>
    </div>
}