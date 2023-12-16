import { createNode, focusNode } from "./node"

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLElement = this.el

      container.addEventListener("focusin", (event: FocusEvent) => {
        const target = <HTMLElement>event.target
        const domNode = target.parentElement!
        const id = domNode.getAttribute("data-id")

        this.pushEvent("set_focus", id)
      })

      container.addEventListener("focusout", (event) => {
        const target = <HTMLElement>event.target
        const domNode = target.parentElement!
        const id = domNode.getAttribute("data-id")

        this.pushEvent("remove_focus", id)
      })

      container.addEventListener("keydown", (event: KeyboardEvent) => {
        const selection = window.getSelection()
        const range = selection?.getRangeAt(0)

        switch (event.key) {
          case "Enter":
            event.preventDefault()

            const splitPos = range?.endOffset || 0

            const target = <HTMLElement>event.target
            const parent = target.parentElement!

            const content = target.textContent || ""
            const contentBefore = content.substring(0, splitPos)
            const contentAfter = content.substring(splitPos)

            const domNode = createNode({ content: contentAfter })
            parent.after(domNode)

            target.textContent = contentBefore

            focusNode(domNode)

            break
        }
      })

      container.addEventListener("keyup", (event) => {
      })

      this.handleEvent("insert", ({ nodes }) => {
        nodes.forEach(node => {
          const li = createNode(node)
          container.prepend(li)
        })
      })
    }
  }
}
