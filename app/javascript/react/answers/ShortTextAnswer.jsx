import React, { useContext } from "react";
import { TranslationsContext } from "../translations_context";

export default function ShortTextAnswer({questionId, answer, updateAnswer}) {
    const { translations } = useContext(TranslationsContext)
    return <div>
        <label htmlFor={`short-text-${questionId}`}>{translations.your_answer}</label>
        <input
        id={`short-text-${questionId}`}
        type="text"
        placeholder={translations.answer_placeholder}
        value={answer}
        onChange={(e) => updateAnswer(questionId, e.target.value)}
        />
    </div>
}