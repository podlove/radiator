interface Node {
  uuid?: string
  content?: string
  creator_id?: number
  parent_id?: string
  prev_id?: string
}

export function createNode({ uuid, content }: Node) {
  const input = document.createElement("div")
  input.textContent = content || ""
  input.contentEditable = "plaintext-only"

  // const ol = document.createElement("ol")
  // ol.className = "ml-2 list-disc list-inside"

  const domNode = document.createElement("li")
  domNode.className = "my-2 ml-2"
  domNode.appendChild(input)
  // domNode.appendChild(ol)
  uuid && (domNode.id = "outline-node-" + uuid)

  return domNode
}


export function focusNode(domNode: HTMLElement) {
  const input = domNode.firstChild as HTMLElement
  input.focus()
}
