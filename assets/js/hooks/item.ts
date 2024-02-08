import { Node } from "./types"

export function createItem({ uuid, temp_id, content, parent_id, prev_id }: Node) {
  const input = document.createElement("div")
  input.textContent = content
  input.contentEditable = "true" // firefox does not support "plaintext-only"

  const ol = document.createElement("ol")
  ol.className = "list-disc"

  const item = document.createElement("li")
  temp_id && (item.id = "outline-node-" + temp_id)
  uuid && (item.id = "outline-node-" + uuid)

  item.className = "my-1 ml-4"

  item.setAttribute("data-parent", parent_id || "")
  item.setAttribute("data-prev", prev_id || "")

  item.appendChild(input)
  item.appendChild(ol)

  return item
}

export function updateItem({ uuid, temp_id, content, parent_id, prev_id }: Node, container: HTMLOListElement) {
  const item = getItemById(temp_id || uuid)
  if (!item) return

  temp_id && uuid && (item.id = "outline-node-" + uuid)

  const input = item.firstChild!
  input.textContent = content

  item.setAttribute("data-parent", parent_id || "")
  item.setAttribute("data-prev", prev_id || "")

  const prevItem = getItemById(prev_id)
  const parentItem = getItemById(parent_id)

  if (prevItem) {
    prevItem.after(item)
  } else if (parentItem) {
    parentItem.querySelector("ol")?.append(item)
  } else {
    container.append(item)
  }
}

export function deleteItem({ uuid }: Node) {
  const item = getItemById(uuid)
  if (!item) return

  item.parentNode!.removeChild(item)
}

export function getItemByNode({ uuid, temp_id }: Node) {
  return getItemById(temp_id || uuid)
}

function getItemById(uuid: string | undefined) {
  if (!uuid) return null

  return document.getElementById("outline-node-" + uuid) as HTMLLIElement
}

export function getItemByEvent(event: Event): HTMLLIElement {
  const target = <HTMLDivElement>event.target
  const item = <HTMLLIElement>target.parentElement!

  return item
}

export function focusItem(item: HTMLLIElement, toEnd: boolean = true) {
  const input = item.firstChild as HTMLDivElement
  input.focus()

  if (toEnd) {
    const range = document.createRange()
    range.setStart(input, 1)
    range.collapse(true)

    const selection = window.getSelection()
    selection?.removeAllRanges()
    selection?.addRange(range)
  }
}

// export function indentNode(node: Node) {
//   // const node = event.target.parentNode
//   // const parentNode = event.target.parentNode.previousSibling
// }

// export function outdentNode(node: Node) {
// }
