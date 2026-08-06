import React from "react";
import MultipleChoiceAnswer from "./answers/MultipleChoiceAnswer";
import ShortTextAnswer from "./answers/ShortTextAnswer";

export default function Question({question, answer, updateAnswer, questionIndex, questionsAmount}) {
    return <div>
        <p>{`Question ${questionIndex} of ${questionsAmount}`}</p>
        {question.body}
        <p>Points: {question.points}</p>
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
}