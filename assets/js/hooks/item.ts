interface Node {
  uuid?: string
  content: string
  creator_id?: number
  parent_id?: string
  prev_id?: string
}

export function createItem({ uuid, content, parent_id, prev_id }: Node) {
  const input = document.createElement("div")
  input.textContent = content
  input.contentEditable = "plaintext-only"

  // const ol = document.createElement("ol")

  const item = document.createElement("li")
  uuid && (item.id = "outline-node-" + uuid)

  item.className = "my-2 ml-2"

  item.setAttribute("data-parent", parent_id || "")
  item.setAttribute("data-prev", prev_id || "")

  item.appendChild(input)
  // item.appendChild(ol)

  return item
}

export function updateItem({ uuid, content, parent_id, prev_id }: Node) {
  const item = uuid && getItemById(uuid)

  if (item) {
    const input = item.firstChild!
    input.textContent = content

    item.setAttribute("data-parent", parent_id || "")
    item.setAttribute("data-prev", prev_id || "")
  }
}

export function getItemById(uuid: string) {
  const item = <HTMLLIElement>document.getElementById("outline-node-" + uuid)

  return item
}

export function getNodeByEvent(event: Event): Node {
  const item = getItemByEvent(event)

  return getNodeByItem(item)
}

export function getItemByEvent(event: Event): HTMLLIElement {
  const target = <HTMLElement>event.target
  const item = <HTMLLIElement>target.parentElement!

  return item
}

export function getNodeByItem(item: HTMLLIElement): Node {
  const uuid = item.id.split("outline-node-")[1]
  const input = item.firstChild as HTMLDivElement
  const content = input.textContent!

  const parent_id = item.getAttribute("data-parent")!
  const prev_id = item.getAttribute("data-prev")!

  return { uuid, content, parent_id, prev_id }
}

export function focusItem(item: HTMLLIElement, toEnd: boolean = true) {
  const uuid = item.id.split("outline-node-")[1]
  const input = item.firstChild as HTMLDivElement
  input.focus()

  if (toEnd) {
    const range = document.createRange()
    range.selectNodeContents(input)
    range.collapse(false)

    const selection = window.getSelection()
    selection?.removeAllRanges()
    selection?.addRange(range)
  }

  this.pushEvent("set_focus", uuid)
}
