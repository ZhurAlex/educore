import React, { useState } from 'react'

export default function ConfirmDialog({ onConfirm, onCancel }) {
    return (
        <div className="confirm-dialog-overlay">
            <div className="confirm-dialog">
                <p>Are you sure you want to submit the test?</p>
                <div className="confirm-dialog-actions">
                    <button className="confirm-no" onClick={onCancel}>No</button>
                    <button className="confirm-yes" onClick={onConfirm}>Yes</button>
                </div>
            </div>
        </div>
    )
}