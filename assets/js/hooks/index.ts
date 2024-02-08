import { Node } from "./types"
import { createItem, updateItem, deleteItem, getItemByNode, focusItem } from "./item"
import { getNodeByEvent, getNodeByItem } from "./node"

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLOListElement = this.el

      container.addEventListener("focusin", (event: FocusEvent) => {
        const { uuid } = getNodeByEvent(event)

        this.pushEvent("set_focus", uuid)
      })

      container.addEventListener("focusout", (event: FocusEvent) => {
        const { uuid } = getNodeByEvent(event)

        this.pushEvent("remove_focus", uuid)
      })

      container.addEventListener("input", (event: Event) => {
        const node = getNodeByEvent(event)

        this.pushEvent("update_node", node)
      })

      container.addEventListener("keydown", (event: KeyboardEvent) => {
        const selection = window.getSelection()
        // const range = selection?.getRangeAt(0)

        const node = getNodeByEvent(event)

        const item = getItemByNode(node)!
        const prevItem = item.previousSibling as HTMLLIElement | null
        const nextItem = item.nextSibling as HTMLLIElement | null

        const prevNode = prevItem && getNodeByItem(prevItem)
        const nextNode = nextItem && getNodeByItem(nextItem)

        switch (event.key) {
          case "ArrowUp":
            if (selection?.anchorOffset != 0) return
            event.preventDefault()

            if (!prevItem || !prevNode) return
            // TODO: if no prevItem exists, try to select the parent item

            focusItem(prevItem)
            this.pushEvent("set_focus", prevNode.uuid)
            break

          case "ArrowDown":
            if (selection?.anchorOffset != node.content.length) return
            event.preventDefault()

            if (!nextItem || !nextNode) return
            // TODO: if no nextItem exists, try to select the first child

            focusItem(nextItem)
            this.pushEvent("set_focus", nextNode.uuid)
            break

          case "Enter":
            event.preventDefault()

            const splitPos = selection?.anchorOffset || 0

            const content = node.content
            node.content = content?.substring(0, splitPos)

            updateItem(node, container)
            this.pushEvent("update_node", node)

            const newNode: Node = {
              temp_id: self.crypto.randomUUID(),
              content: content?.substring(splitPos),
              parent_id: node.parent_id,
              prev_id: node.uuid
            }

            this.pushEvent("create_node", newNode, (node: Node, _ref: Number) => {
              const newItem = createItem(node)
              item.after(newItem)
              focusItem(newItem, false)
            })
            break

          case "Backspace":
            if (selection?.anchorOffset != 0) return
            event.preventDefault()

            if (!prevItem || !prevNode) return

            prevNode.content += node.content
            updateItem(prevNode, container)
            focusItem(prevItem)
            this.pushEvent("update_node", node)

            deleteItem(node)
            this.pushEvent("delete_node", node.uuid)
            break

          case "Delete":
            if (selection?.anchorOffset != node.content.length) return
            event.preventDefault()

            if (!nextItem || !nextNode) return

            node.content += nextNode.content
            updateItem(node, container)
            focusItem(item)
            this.pushEvent("update_node", node)

            deleteItem(nextNode)
            this.pushEvent("delete_node", nextNode.uuid)
            break

          // case "Tab":
          //   event.preventDefault()

          //   if (event.shiftKey) {
          //     if (node.parent_id) {
          //       // outdent
          //       node.prev_id = node.parent_id
          //       node.parent_id = undefined
          //       updateItem(node, container)

          //       focusItem(item)
          //       this.pushEvent("update_node", node)
          //     }
          //   } else {
          //     if (node.prev_id) {
          //       // indent
          //       node.parent_id = node.prev_id
          //       node.prev_id = undefined // TODO: prev_id should be the id of the last child of the parent node
          //       updateItem(node, container)

          //       focusItem(item)
          //       this.pushEvent("update_node", node)
          //     }
          //   }
          //   break
        }
      })

      // container.addEventListener("keyup", (event) => {
      //   console.log("keyup", event)
      // })

      this.handleEvent("list", ({ nodes }: { nodes: Node[] }) => {
        if ((nodes.length) == 0) {
          const node: Node = { temp_id: self.crypto.randomUUID(), content: "" }
          nodes = [node]
        }

        // add all items
        nodes.forEach(node => {
          const item = createItem(node)
          container.append(item)
        })

        // sort & indent all items
        nodes.forEach(node => {
          updateItem(node, container)
        })

        // focus last item
        const lastItem = container.lastElementChild as HTMLLIElement
        focusItem(lastItem)
      })

      // this.handleEvent("insert", (node: Node) => {
      //   const item = createItem(node)
      //   container.append(item)
      // })

      // this.handleEvent("update", (node: Node) => {
      //   updateItem(node, container)
      // })

      // this.handleEvent("delete", (node: Node) => {
      //   deleteItem(node)
      // })
    }
  }
}
