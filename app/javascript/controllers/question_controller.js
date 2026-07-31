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
    if(value === "multiple_choice"){
      this.correctAnswerTarget.hidden = true
      this.optionsContainerTarget.hidden = false
    } else {
      this.correctAnswerTarget.hidden = false
      this.optionsContainerTarget.hidden = true
    }
  }
}