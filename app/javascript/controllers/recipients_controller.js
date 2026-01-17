import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  add() {
    const template = this.containerTarget.querySelector('[data-recipient-template]')
    const newRecipient = template.content.cloneNode(true)
    this.containerTarget.appendChild(newRecipient)
  }

  remove(event) {
    event.target.closest('[data-recipient-fields]').remove()
  }
}
