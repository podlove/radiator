interface Node {
  uuid?: string
  content?: string
  creator_id?: number
  parent_id?: string
  prev_id?: string
}

export function createNode({ uuid, content }: Node) {
  const input = document.createElement("div")
  input.innerText = content || ""
  input.contentEditable = "plaintext-only"

  const node = document.createElement("li")
  node.className = "my-2 ml-2"
  node.appendChild(input)
  uuid && (node.id = "outline-node-" + uuid)

  return node
}
