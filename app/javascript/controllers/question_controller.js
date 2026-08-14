import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answerTypes", "correctAnswer", "optionsContainer", 
                    "optionsList", "template"]

  connect() {
    this.updateVisibility(this.answerTypesTarget.value)
    if (this.optionsListTarget.children.length === 0) {
      this.addOption()
    }
  }

  addOption() {
    this.optionsListTarget.insertAdjacentHTML("beforeend", 
      this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now()))
  }

  showFields(event) {
    this.updateVisibility(event.target.value)
  }

  updateVisibility(value) {
    switch(value) {
      case "multiple_choice":
        this.correctAnswerTarget.hidden = true
        this.optionsContainerTarget.hidden = false
        break
      case "short_text":
        this.correctAnswerTarget.hidden = false
        this.optionsContainerTarget.hidden = true
        break
      default:
        this.correctAnswerTarget.hidden = true
        this.optionsContainerTarget.hidden = true
    }
  }
}