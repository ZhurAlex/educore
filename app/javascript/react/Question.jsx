import React, { useContext } from "react";
import MultipleChoiceAnswer from "./answers/MultipleChoiceAnswer";
import ShortTextAnswer from "./answers/ShortTextAnswer";
import { TranslationsContext, interpolate } from "./translations_context";

export default function Question({question, answer, updateAnswer, questionIndex, questionsAmount}) {
    const { translations } = useContext(TranslationsContext)
    return <div className="test-attempt-question">
        <p className="test-attempt-progress">
          {interpolate(translations.question_progress, { current: questionIndex, total: questionsAmount })}
        </p>
        <p className="test-attempt-body">
          {question.body}
          <span className="badge">{interpolate(translations.points_suffix, { points: question.points })}</span>
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