import React from "react";

export default function MultipleChoiceAnswer({options, questionId, answer, updateAnswer}) {
    return options.map((option) => (
        <div key={option.id}>
            <input 
            type="radio"
            name={`multiple-choice-${questionId}`}
            value={option.id}
            checked={option.id === answer}
            onChange={() => updateAnswer(questionId, option.id)}
            />
            {option.body}
        </div>
    ))

        
    
}