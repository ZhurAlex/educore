import React from "react";

export default function MultipleChoiceAnswer({options, questionId, answer, updateAnswer}) {
    return options.map((option) => (
        <div key={option.id} className="option-row">
            <input
            type="radio"
            name={`multiple-choice-${questionId}`}
            value={option.id}
            checked={option.id === answer}
            onChange={() => updateAnswer(questionId, option.id)}
            id={`multiple-choice-${questionId}-${option.id}`}
            />
            <label htmlFor={`multiple-choice-${questionId}-${option.id}`}>
                {option.body}
            </label>
        </div>
    ))

        
    
}