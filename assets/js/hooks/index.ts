import { createItem, updateItem, focusItem, getItemByEvent, getNodeByEvent } from "./item"

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLElement = this.el

      container.addEventListener("focusin", (event: FocusEvent) => {
        const node = getNodeByEvent(event)
        const uuid = node.uuid

        this.pushEvent("set_focus", uuid)
      })

      container.addEventListener("focusout", (event: FocusEvent) => {
        const node = getNodeByEvent(event)
        const uuid = node.uuid

        this.pushEvent("remove_focus", uuid)
      })

      container.addEventListener("input", (event: Event) => {
        const node = getNodeByEvent(event)

        this.pushEvent("update_node", node)
      })

      container.addEventListener("keydown", (event: KeyboardEvent) => {
        const selection = window.getSelection()
        const range = selection?.getRangeAt(0)

        const node = getNodeByEvent(event)

        switch (event.key) {
          case "Enter":
            event.preventDefault()
            break

          case "ArrowUp":
            if (selection?.anchorOffset == 0) {
              event.preventDefault()
            }
            break

          case "ArrowDown":
            if (selection?.anchorOffset == node.content.length) {
              event.preventDefault()
            }
            break

          case "Tab":
            event.preventDefault()

            if (event.shiftKey) {
            }
            break

          case "Backspace":
            if (node.content.length == 0) {
              const item = getItemByEvent(event)
              item.parentNode!.removeChild(item)

              // focus next item

              this.pushEvent("delete_node", node.uuid)
            }
            break

          case "Delete":
            if (node.content.length == 0) {
              const item = getItemByEvent(event)
              item.parentNode!.removeChild(item)

              // focus next item

              this.pushEvent("delete_node", node.uuid)
            }
            break
        }
      })

      this.handleEvent("list", ({ nodes }) => {
        nodes.forEach(node => {
          const item = createItem(node)
          container.prepend(item)
        })
      })
    }
  }
}
