import React, { useState } from 'react'
import { useContext } from 'react'
import { TranslationsContext } from './translations_context'

export default function ConfirmDialog({ onConfirm, onCancel, isSubmitting, error }) {
    const { translations } = useContext(TranslationsContext)

    return (
        <div className="confirm-dialog-overlay">
            <div className="confirm-dialog">
                <p>{translations.confirm_submit}</p>
                {error && <p className="confirm-dialog-error">{error}</p>}
                <div className="confirm-dialog-actions">
                    <button className="confirm-no" onClick={onCancel} disabled={isSubmitting}>{translations.confirm_no}</button>
                    <button className="confirm-yes" onClick={onConfirm} disabled={isSubmitting}>
                        {isSubmitting ? translations.submitting : translations.confirm_yes}
                    </button>
                </div>
            </div>
        </div>
    )
}