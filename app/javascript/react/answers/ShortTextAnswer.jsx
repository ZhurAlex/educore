import React from "react";

export default function ShortTextAnswer({questionId, answer, updateAnswer}) {
    return <div>
        <input 
        type="text" 
        placeholder="Enter your answer here..." 
        value={answer}
        onChange={(e) => updateAnswer(questionId, e.target.value)}
        />
    </div>
}