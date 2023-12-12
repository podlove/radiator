import { createNode, focusNode } from "./node"

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLElement = this.el

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

            const node = createNode({ content: contentAfter })
            parent.after(node)

            target.textContent = contentBefore

            focusNode(node)
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
