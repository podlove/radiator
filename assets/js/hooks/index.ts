import { createItem, updateItem, focusItem, getItemByEvent, getItemById, getNodeByItem, getNodeByEvent } from "./item"
import { Node } from "./types"

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLElement = this.el

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

        const item = getItemByEvent(event)
        const prevItem = <HTMLLIElement>item.previousSibling
        const nextItem = <HTMLLIElement>item.nextSibling

        switch (event.key) {
          case "ArrowUp":
            if (selection?.anchorOffset != 0) return
            event.preventDefault()

            if (!prevItem) return
            // otherwise parentItem

            focusItem(prevItem)
            this.pushEvent("set_focus", node.uuid)
            break

          case "ArrowDown":
            if (selection?.anchorOffset != node.content.length) return
            event.preventDefault()

            if (!nextItem) return
            // otherwise firstChildItem

            focusItem(nextItem)
            this.pushEvent("set_focus", node.uuid)
            break

          case "Enter":
            event.preventDefault()

            const splitPos = selection?.anchorOffset || 0

            const content = node.content
            node.content = content?.substring(0, splitPos)

            updateItem(node, container)

            const newNode: Node = {
              temp_id: self.crypto.randomUUID(),
              content: content?.substring(splitPos),
              parent_id: node.parent_id,
              prev_id: node.uuid
            }

            const newItem = createItem(newNode)
            item.after(newItem)

            focusItem(newItem, false)

            this.pushEvent("update_node", node)
            this.pushEvent("create_node", newNode)
            break

          case "Backspace":
            if (selection?.anchorOffset != 0) return
            event.preventDefault()

            if (!prevItem) return

            const prevNode = getNodeByItem(prevItem)
            prevNode.content += node.content
            updateItem(prevNode, container)

            item.parentNode?.removeChild(item)

            focusItem(prevItem)
            this.pushEvent("delete_node", node.uuid)
            break

          case "Delete":
            if (selection?.anchorOffset != node.content.length) return
            event.preventDefault()

            if (!nextItem) return

            const nextNode = getNodeByItem(nextItem)
            node.content += nextNode.content
            updateItem(node, container)

            nextItem.parentNode?.removeChild(nextItem)

            focusItem(item)
            this.pushEvent("delete_node", nextNode.uuid)
            break

          case "Tab":
            event.preventDefault()

            if (event.shiftKey) {
              if (node.parent_id) {
                node.prev_id = node.parent_id
                node.parent_id = undefined

                updateItem(node, container)
                focusItem(item)

                this.pushEvent("update_node", node)
              }
            } else {
              if (node.prev_id) {
                node.parent_id = node.prev_id
                node.prev_id = undefined

                updateItem(node, container)
                focusItem(item)

                this.pushEvent("update_node", node)
              }
            }
            break
        }
      })

      // container.addEventListener("keyup", (event) => {
      //   console.log("keyup", event)
      // })

      this.handleEvent("list", ({ nodes }) => {
        if ((nodes.length) == 0) {
          nodes = [{
            temp_id: self.crypto.randomUUID(),
            content: "",
          }]
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
      //   // console.log(node)
      //   // updateItem(node)
      // })

      // this.handleEvent("delete", ({ uuid }: Node) => {
      //   const item = getItemById(uuid!)
      //   item.parentNode!.removeChild(item)
      // })
    }
  }
}
