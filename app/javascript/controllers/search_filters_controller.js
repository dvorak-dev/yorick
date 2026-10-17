import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "fields", "summary", "summaryText", "toggle"]

  connect() {
    this.collapsed = window.localStorage.getItem(this.storageKey) === "true"
    this.apply(false)
    document.documentElement.classList.remove("filters-collapsed")
  }

  toggle(event) {
    event.preventDefault()
    this.collapsed = !this.collapsed
    window.localStorage.setItem(this.storageKey, String(this.collapsed))
    this.apply(true)
  }

  apply(animate) {
    this.summaryTextTarget.textContent = this.summaryText()
    this.toggleTarget.setAttribute("aria-expanded", String(!this.collapsed))
    this.toggleTarget.textContent = this.collapsed ? "Mostrar filtros" : "Ocultar filtros"
    this.fieldsTarget.inert = this.collapsed

    if (!animate) this.withoutTransition(() => this.render())
    else this.render()
  }

  render() {
    this.panelTarget.classList.toggle("grid-rows-[0fr]", this.collapsed)
    this.panelTarget.classList.toggle("grid-rows-[1fr]", !this.collapsed)
    this.fieldsTarget.classList.toggle("opacity-0", this.collapsed)
    this.fieldsTarget.classList.toggle("opacity-100", !this.collapsed)
    this.summaryTarget.classList.toggle("grid-rows-[0fr]", !this.collapsed)
    this.summaryTarget.classList.toggle("grid-rows-[1fr]", this.collapsed)
    this.summaryTarget.classList.toggle("opacity-0", !this.collapsed)
    this.summaryTarget.classList.toggle("opacity-100", this.collapsed)
  }

  withoutTransition(callback) {
    const targets = [this.panelTarget, this.fieldsTarget, this.summaryTarget]
    targets.forEach((target) => { target.style.transition = "none" })
    callback()
    this.panelTarget.offsetHeight
    targets.forEach((target) => { target.style.transition = "" })
  }

  summaryText() {
    const params = new URLSearchParams(window.location.search)
    const name = params.get("full_name")?.trim() || ""
    const content = params.get("content")?.trim() || ""
    const from = params.get("year_from")?.trim() || ""
    const to = params.get("year_to")?.trim() || ""
    const order = params.get("order")
    const parts = []

    if (name) parts.push(`Nombre: ${name}`)
    if (content) parts.push(`Texto: ${content}`)
    if (from || to) parts.push(`Publicado: ${from || "…"}–${to || "…"}`)
    parts.push(`Orden: ${this.sortLabel(order, Boolean(name || content || from || to))}`)

    return parts.join(" · ")
  }

  sortLabel(order, searchActive) {
    if (order === "asc") return "Más antiguos"
    if (searchActive && order !== "desc") return "Relevancia"

    return "Más recientes"
  }

  get storageKey() {
    return "funeral-notices-filters-collapsed"
  }
}
